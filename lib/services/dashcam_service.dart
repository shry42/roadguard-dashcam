import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:wakelock_plus/wakelock_plus.dart';

import 'recordings_repository.dart';

enum DashcamState { idle, initializing, ready, recording, error }

class DashcamService extends ChangeNotifier {
  DashcamService._();
  static final DashcamService instance = DashcamService._();

  CameraController? controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  DashcamState state = DashcamState.idle;
  String? errorMessage;
  bool isRecording = false;
  Duration recordDuration = Duration.zero;
  Timer? _recordTimer;
  bool useFrontCamera = false;

  ResolutionPreset resolution = ResolutionPreset.high;

  bool get isReady => state == DashcamState.ready || state == DashcamState.recording;

  bool get isInitialized {
    final c = controller;
    if (c == null) return false;
    try {
      return c.value.isInitialized;
    } on CameraException {
      return false;
    }
  }

  CameraDescription? get _currentCamera =>
      _cameras.isEmpty ? null : _cameras[_cameraIndex.clamp(0, _cameras.length - 1)];

  Future<void> initialize() async {
    if (state == DashcamState.initializing) return;
    state = DashcamState.initializing;
    errorMessage = null;
    notifyListeners();

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        throw CameraException('none', 'No cameras found on this device');
      }
      _cameraIndex = _indexForLens(useFrontCamera);
      await _initController();
      state = DashcamState.ready;
    } on CameraException catch (e) {
      state = DashcamState.error;
      errorMessage = e.description ?? e.code;
    } catch (e) {
      state = DashcamState.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  int _indexForLens(bool front) {
    final idx = _cameras.indexWhere(
      (c) => front ? c.lensDirection == CameraLensDirection.front : c.lensDirection == CameraLensDirection.back,
    );
    return idx >= 0 ? idx : 0;
  }

  Future<void> _initController() async {
    await controller?.dispose();
    final camera = _currentCamera!;
    controller = CameraController(
      camera,
      resolution,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await controller!.initialize();
  }

  Future<void> switchCamera({required bool front}) async {
    if (_cameras.isEmpty) return;
    useFrontCamera = front;
    _cameraIndex = _indexForLens(front);
    state = DashcamState.initializing;
    notifyListeners();
    try {
      await _initController();
      state = isRecording ? DashcamState.recording : DashcamState.ready;
    } catch (e) {
      state = DashcamState.error;
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> flipCamera() => switchCamera(front: !useFrontCamera);

  Future<void> setResolution(ResolutionPreset preset) async {
    if (isRecording) return;
    resolution = preset;
    await _initController();
    state = DashcamState.ready;
    notifyListeners();
  }

  Future<File?> startRecording() async {
    if (controller == null || !isInitialized || isRecording) return null;
    try {
      await WakelockPlus.enable();
      await controller!.startVideoRecording();
      isRecording = true;
      recordDuration = Duration.zero;
      state = DashcamState.recording;
      _recordTimer?.cancel();
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        recordDuration += const Duration(seconds: 1);
        notifyListeners();
      });
      notifyListeners();
      return null;
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<File?> stopRecording() async {
    if (controller == null || !isRecording) return null;
    try {
      final xfile = await controller!.stopVideoRecording();
      _recordTimer?.cancel();
      isRecording = false;
      state = DashcamState.ready;
      await WakelockPlus.disable();

      final destPath = await RecordingsRepository.instance.newRecordingPath();
      await File(xfile.path).copy(destPath);
      try {
        await File(xfile.path).delete();
      } catch (_) {}

      notifyListeners();
      return File(destPath);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<File?> takeSnapshot() async {
    if (controller == null || !isInitialized) return null;
    try {
      final xfile = await controller!.takePicture();
      final dir = await RecordingsRepository.instance.recordingsDir;
      final dest = p.join(dir.path, 'snap_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await File(xfile.path).copy(dest);
      return File(dest);
    } catch (e) {
      errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  String formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '${h.toString().padLeft(2, '0')}:$m:$s';
    return '$m:$s';
  }

  Future<void> disposeCamera() async {
    _recordTimer?.cancel();
    if (isRecording) {
      try {
        await controller?.stopVideoRecording();
      } catch (_) {}
    }
    isRecording = false;
    try {
      await controller?.dispose();
    } catch (_) {}
    controller = null;
    state = DashcamState.idle;
    await WakelockPlus.disable();
    notifyListeners();
  }
}
