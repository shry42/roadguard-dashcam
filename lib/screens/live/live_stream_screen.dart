import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../core/theme/app_colors.dart';
import '../../services/dashcam_service.dart';
import '../../services/location_service.dart';
import '../../services/permissions_service.dart';
import '../../services/webrtc_stream_service.dart';
import '../../widgets/status_badge.dart';

class LiveStreamScreen extends StatefulWidget {
  const LiveStreamScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<LiveStreamScreen> createState() => _LiveStreamScreenState();
}

class _LiveStreamScreenState extends State<LiveStreamScreen> with WidgetsBindingObserver {
  final _dashcam = DashcamService.instance;
  final _stream = WebRTCStreamService.instance;
  final _location = LocationService.instance;

  bool _useRoadCamera = true;
  bool _isStreaming = false;
  String _quality = '1080p';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _dashcam.addListener(_onUpdate);
    _stream.addListener(_onUpdate);
    _location.addListener(_onUpdate);
    _boot();
  }

  Future<void> _boot() async {
    final ok = await PermissionsService.instance.requestDashcamPermissions();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera, mic & location permissions are required')),
      );
    }
    await _location.start();
    if (!_stream.isLive) {
      await _dashcam.initialize();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _dashcam.removeListener(_onUpdate);
    _stream.removeListener(_onUpdate);
    _location.removeListener(_onUpdate);
    if (!widget.embedded) {
      _stream.stop();
      _dashcam.disposeCamera();
      _location.stop();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_dashcam.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      if (!_stream.isLive && !_stream.isConnecting) {
        unawaited(_dashcam.disposeCamera());
      }
    } else if (state == AppLifecycleState.resumed &&
        !_stream.isLive &&
        !_stream.isConnecting) {
      unawaited(_dashcam.initialize());
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  ResolutionPreset _presetFromLabel(String q) => switch (q) {
        '720p' => ResolutionPreset.medium,
        '4K' => ResolutionPreset.max,
        _ => ResolutionPreset.high,
      };

  Future<void> _toggleRecording() async {
    if (_stream.isLive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stop streaming before local recording')),
      );
      return;
    }
    if (_dashcam.isRecording) {
      final file = await _dashcam.stopRecording();
      if (file != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved: ${file.path.split('/').last}')),
        );
      }
    } else {
      await _dashcam.startRecording();
    }
  }

  Future<void> _toggleStream() async {
    if (_isStreaming || _stream.isLive || _stream.isConnecting) {
      await _stream.stop(); // also re-inits dashcam camera in background
      if (mounted) setState(() => _isStreaming = false);
      return;
    }

    if (mounted) setState(() => _isStreaming = true);
    await _stream.start(frontCamera: !_useRoadCamera);
    if (!mounted) return;

    if (_stream.streamState == StreamState.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_stream.errorMessage ?? 'Stream failed')),
      );
      setState(() => _isStreaming = false);
    }
  }

  Future<void> _switchCamera(bool road) async {
    setState(() => _useRoadCamera = road);
    if (_stream.isLive) {
      await _stream.switchCameraWhileStreaming(!road);
    } else {
      await _dashcam.switchCamera(front: !road);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      fit: StackFit.expand,
      children: [
        _buildPreview(),
        _buildTopBar(),
        _buildBottomControls(),
        if (_dashcam.isRecording) _buildRecordingIndicator(),
        if (_stream.isConnecting) _buildConnectingOverlay(),
      ],
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: body),
      );
    }

    return Scaffold(backgroundColor: Colors.black, body: body);
  }

  Widget _buildPreview() {
    // While streaming, never touch the disposed dashcam CameraController.
    if (_stream.isLive || _stream.isConnecting) {
      return RTCVideoView(
        _stream.localRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    }

    if (_dashcam.state == DashcamState.initializing) {
      return _messageView('Starting camera…', showSpinner: true);
    }
    if (_dashcam.state == DashcamState.error) {
      return _messageView(_dashcam.errorMessage ?? 'Camera error', showRetry: true);
    }

    final controller = _dashcam.controller;
    if (controller == null) {
      return _messageView('Camera not ready', showRetry: true);
    }

    try {
      if (controller.value.isInitialized) {
        return CameraPreview(controller);
      }
    } on CameraException catch (_) {
      return _messageView('Camera not ready', showRetry: true);
    }

    return _messageView('Camera not ready', showRetry: true);
  }

  Widget _messageView(String text, {bool showSpinner = false, bool showRetry = false}) {
    return Container(
      color: const Color(0xFF0d1520),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner) const CircularProgressIndicator(color: AppColors.primary),
            if (showSpinner) const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
            if (showRetry) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: _dashcam.initialize,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final top = widget.embedded ? 8.0 : MediaQuery.paddingOf(context).top + 8;
    final gpsLabel = _location.label;
    final streaming = _stream.isLive;

    return Positioned(
      top: top,
      left: 12,
      right: 12,
      child: Row(
        children: [
          if (!widget.embedded)
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              style: IconButton.styleFrom(backgroundColor: AppColors.overlay),
            )
          else if (streaming)
            StatusBadge(label: 'LIVE', type: BadgeType.live, pulse: true)
          else
            const SizedBox.shrink(),
          const Spacer(),
          if (streaming)
            _TopChip(
              icon: Icons.visibility_rounded,
              label: '${_stream.viewerCount} watching',
            ),
          const SizedBox(width: 8),
          _TopChip(icon: Icons.gps_fixed, label: gpsLabel),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            enabled: !_stream.isLive,
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: AppColors.overlay, borderRadius: BorderRadius.circular(8)),
              child: Text(_quality, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            onSelected: (v) async {
              setState(() => _quality = v);
              await _dashcam.setResolution(_presetFromLabel(v));
            },
            itemBuilder: (_) => ['720p', '1080p', '4K'].map((q) => PopupMenuItem(value: q, child: Text(q))).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    final top = widget.embedded ? 52.0 : MediaQuery.paddingOf(context).top + 56;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.recordRed.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.fiber_manual_record, size: 10, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                'REC  ${_dashcam.formatDuration(_dashcam.recordDuration)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectingOverlay() {
    return Container(
      color: AppColors.overlay,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text('Connecting to admin panel…', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    final bottom = widget.embedded ? 16.0 : MediaQuery.paddingOf(context).bottom + 20;
    final streaming = _stream.isLive;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 24, 20, bottom),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xEE000000), Colors.transparent],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CamToggle(label: 'Road', selected: _useRoadCamera, onTap: () => _switchCamera(true)),
                const SizedBox(width: 12),
                _CamToggle(label: 'Cabin', selected: !_useRoadCamera, onTap: () => _switchCamera(false)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ControlBtn(
                  icon: Icons.flip_camera_ios_rounded,
                  label: 'Flip',
                  onTap: () => _switchCamera(!_useRoadCamera),
                ),
                GestureDetector(
                  onTap: _toggleRecording,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: _dashcam.isRecording ? AppColors.recordRed : Colors.white24,
                    ),
                    child: Icon(
                      _dashcam.isRecording ? Icons.stop_rounded : Icons.fiber_manual_record,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                _ControlBtn(
                  icon: streaming ? Icons.stop_circle_outlined : Icons.cast_connected_rounded,
                  label: streaming ? 'Stop' : 'Stream',
                  highlight: streaming,
                  onTap: _toggleStream,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ControlBtn(
                  icon: Icons.photo_camera_rounded,
                  label: 'Snap',
                  onTap: () async {
                    final f = await _dashcam.takeSnapshot();
                    if (f != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Snapshot saved')));
                    }
                  },
                ),
                _ControlBtn(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Torch',
                  onTap: () async {
                    final c = _dashcam.controller;
                    if (c != null && c.value.isInitialized) {
                      await c.setFlashMode(
                        c.value.flashMode == FlashMode.torch ? FlashMode.off : FlashMode.torch,
                      );
                      setState(() {});
                    }
                  },
                ),
                if (streaming)
                  _ControlBtn(icon: Icons.sensors, label: 'Live', highlight: true, onTap: () {})
                else
                  _ControlBtn(icon: Icons.refresh_rounded, label: 'Retry', onTap: _dashcam.initialize),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopChip extends StatelessWidget {
  const _TopChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.overlay, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.live),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CamToggle extends StatelessWidget {
  const _CamToggle({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.overlay,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.background : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: highlight ? AppColors.primary.withValues(alpha: 0.3) : AppColors.overlay,
              shape: BoxShape.circle,
              border: highlight ? Border.all(color: AppColors.primary) : null,
            ),
            child: Icon(icon, color: highlight ? AppColors.primary : Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }
}
