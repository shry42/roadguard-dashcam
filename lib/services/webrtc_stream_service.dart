import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'app_settings.dart';
import 'dashcam_service.dart';
import 'stream_config_service.dart';

enum StreamState { off, connecting, live, error }

class WebRTCStreamService extends ChangeNotifier {
  WebRTCStreamService._();
  static final WebRTCStreamService instance = WebRTCStreamService._();

  StreamState streamState = StreamState.off;
  String? errorMessage;
  int viewerCount = 0;

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  WebSocketChannel? _channel;
  bool _rendererReady = false;
  bool _useFrontCamera = false;

  bool get isLive => streamState == StreamState.live;
  bool get isConnecting => streamState == StreamState.connecting;

  Future<void> initRenderer() async {
    if (_rendererReady) return;
    await localRenderer.initialize();
    _rendererReady = true;
  }

  Future<void> start({bool frontCamera = false}) async {
    if (streamState == StreamState.connecting || streamState == StreamState.live) return;

    streamState = StreamState.connecting;
    errorMessage = null;
    viewerCount = 0;
    _useFrontCamera = frontCamera;
    notifyListeners();

    try {
      await initRenderer();
      await DashcamService.instance.disposeCamera();

      final settings = AppSettings.instance;
      _channel = WebSocketChannel.connect(Uri.parse(settings.signalingUrl));

      _channel!.stream.listen(_onSignalMessage, onError: (e) {
        errorMessage = e.toString();
        streamState = StreamState.error;
        notifyListeners();
      }, onDone: () {
        if (streamState == StreamState.live) {
          stop();
        }
      });

      await _waitForSocket();
      _send({'type': 'join', 'room': settings.roomId, 'role': 'publisher'});

      await _createLocalStream();
      await _createPeerConnection();

      streamState = StreamState.live;
      notifyListeners();
    } catch (e) {
      errorMessage = e.toString();
      streamState = StreamState.error;
      await stop();
      notifyListeners();
    }
  }

  Future<void> _waitForSocket() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  Future<void> _createLocalStream() async {
    final mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': {
        'facingMode': _useFrontCamera ? 'user' : 'environment',
        'width': 1280,
        'height': 720,
      },
    };
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    localRenderer.srcObject = _localStream;
  }

  Future<void> _createPeerConnection() async {
    final settings = AppSettings.instance;
    final iceServers = await StreamConfigService.loadIceServers(
      signalingUrl: settings.signalingUrl,
      roomId: settings.roomId,
    );
    final config = <String, dynamic>{'iceServers': iceServers};
    _peerConnection = await createPeerConnection(config);

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        _send({
          'type': 'ice',
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      }
    };

    for (final track in _localStream!.getTracks()) {
      await _peerConnection!.addTrack(track, _localStream!);
    }
  }

  void _onSignalMessage(dynamic raw) {
    final msg = jsonDecode(raw as String) as Map<String, dynamic>;
    switch (msg['type']) {
      case 'viewer-count':
        viewerCount = msg['count'] as int? ?? 0;
        notifyListeners();
      case 'start-offer':
        _sendOffer();
      case 'answer':
        _handleAnswer(msg);
      case 'ice':
        _handleIce(msg);
      case 'error':
        errorMessage = msg['message'] as String? ?? 'Signaling error';
        streamState = StreamState.error;
        notifyListeners();
    }
  }

  Future<void> _sendOffer() async {
    if (_peerConnection == null) return;
    final offer = await _peerConnection!.createOffer({
      'offerToReceiveAudio': false,
      'offerToReceiveVideo': false,
    });
    await _peerConnection!.setLocalDescription(offer);
    _send({'type': 'offer', 'sdp': offer.sdp, 'sdpType': offer.type});
  }

  Future<void> _handleAnswer(Map<String, dynamic> msg) async {
    final answer = RTCSessionDescription(msg['sdp'] as String, msg['sdpType'] as String? ?? 'answer');
    await _peerConnection?.setRemoteDescription(answer);
  }

  Future<void> _handleIce(Map<String, dynamic> msg) async {
    final candidate = RTCIceCandidate(
      msg['candidate'] as String?,
      msg['sdpMid'] as String?,
      msg['sdpMLineIndex'] as int?,
    );
    await _peerConnection?.addCandidate(candidate);
  }

  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  Future<void> stop() async {
    streamState = StreamState.off;
    viewerCount = 0;
    notifyListeners();

    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    try {
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
    try {
      localRenderer.srcObject = null;
    } catch (_) {}

    try {
      await _peerConnection?.close();
    } catch (_) {}
    _peerConnection = null;

    // Restore dashcam preview without blocking the UI thread.
    unawaited(DashcamService.instance.initialize());
  }

  Future<void> switchCameraWhileStreaming(bool front) async {
    if (!isLive) return;
    _useFrontCamera = front;
    await stop();
    await start(frontCamera: front);
  }

}
