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
  bool isSwitchingCamera = false;

  MediaStream? _localStream;
  final Map<String, RTCPeerConnection> _viewerPeers = {};
  /// Fallback for older signaling servers that use [start-offer] instead of [viewer-joined].
  RTCPeerConnection? _legacyPeer;
  bool _useLegacySignaling = true;
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  WebSocketChannel? _channel;
  bool _rendererReady = false;
  bool _useFrontCamera = false;
  bool _switchInFlight = false;
  List<Map<String, dynamic>>? _iceServers;
  final Set<String> _pendingViewers = {};

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
      _iceServers = await StreamConfigService.loadIceServers(
        signalingUrl: settings.signalingUrl,
        roomId: settings.roomId,
      );

      _channel = WebSocketChannel.connect(Uri.parse(settings.signalingUrl));

      _channel!.stream.listen(_onSignalMessage, onError: (e) {
        errorMessage = e.toString();
        streamState = StreamState.error;
        notifyListeners();
      }, onDone: () {
        if (streamState == StreamState.live) {
          unawaited(stop());
        }
      });

      await _waitForSocket();
      await _createLocalStream();

      // Join only after camera is ready so viewer-joined can create offers immediately.
      _send({'type': 'join', 'room': settings.roomId, 'role': 'publisher'});

      streamState = StreamState.live;
      notifyListeners();
      await _flushPendingViewers();
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

  Future<RTCPeerConnection> _createPeerConnectionForViewer(
    String viewerId, {
    bool legacySignaling = false,
  }) async {
    final config = <String, dynamic>{
      'iceServers': _iceServers ?? await _loadIceServersFallback(),
    };
    final pc = await createPeerConnection(config);

    pc.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        final ice = <String, dynamic>{
          'type': 'ice',
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        };
        if (!legacySignaling) ice['viewerId'] = viewerId;
        _send(ice);
      }
    };

    final stream = _localStream;
    if (stream != null) {
      for (final track in stream.getTracks()) {
        await pc.addTrack(track, stream);
      }
    }

    return pc;
  }

  Future<List<Map<String, dynamic>>> _loadIceServersFallback() async {
    final settings = AppSettings.instance;
    return StreamConfigService.loadIceServers(
      signalingUrl: settings.signalingUrl,
      roomId: settings.roomId,
    );
  }

  Future<void> _onViewerJoined(String viewerId) async {
    _useLegacySignaling = false;
    await _closeLegacyPeer();

    if (_localStream == null || !isLive) {
      _pendingViewers.add(viewerId);
      debugPrint('Queued viewer $viewerId (stream not live yet)');
      return;
    }
    if (_viewerPeers.containsKey(viewerId)) return;

    try {
      final pc = await _createPeerConnectionForViewer(viewerId);
      _viewerPeers[viewerId] = pc;
      await _sendOfferToViewer(viewerId, pc);
    } catch (e) {
      debugPrint('viewer-joined failed for $viewerId: $e');
      await _closeViewer(viewerId);
    }
  }

  Future<void> _closeLegacyPeer() async {
    if (_legacyPeer == null) return;
    try {
      await _legacyPeer!.close();
    } catch (_) {}
    _legacyPeer = null;
  }

  Future<void> _flushPendingViewers() async {
    if (_pendingViewers.isEmpty) return;
    final ids = _pendingViewers.toList();
    _pendingViewers.clear();
    for (final id in ids) {
      await _onViewerJoined(id);
    }
  }

  Future<void> _sendOfferToViewer(
    String viewerId,
    RTCPeerConnection pc, {
    bool legacySignaling = false,
  }) async {
    final offer = await pc.createOffer({
      'offerToReceiveAudio': false,
      'offerToReceiveVideo': false,
    });
    await pc.setLocalDescription(offer);
    final payload = <String, dynamic>{
      'type': 'offer',
      'sdp': offer.sdp,
      'sdpType': offer.type,
    };
    if (!legacySignaling) payload['viewerId'] = viewerId;
    _send(payload);
  }

  Future<void> _onLegacyStartOffer() async {
    if (!_useLegacySignaling) return;
    if (!isLive || _localStream == null) return;
    if (_viewerPeers.isNotEmpty) return;

    try {
      _legacyPeer ??= await _createPeerConnectionForViewer(
        'legacy',
        legacySignaling: true,
      );
      await _sendOfferToViewer('legacy', _legacyPeer!, legacySignaling: true);
    } catch (e) {
      debugPrint('legacy start-offer failed: $e');
    }
  }

  Future<void> _closeViewer(String viewerId) async {
    final pc = _viewerPeers.remove(viewerId);
    if (pc != null) {
      try {
        await pc.close();
      } catch (_) {}
    }
  }

  void _onSignalMessage(dynamic raw) {
    final msg = jsonDecode(raw as String) as Map<String, dynamic>;
    switch (msg['type']) {
      case 'viewer-count':
        viewerCount = msg['count'] as int? ?? 0;
        notifyListeners();
      case 'start-offer':
        unawaited(_flushPendingViewers());
        if (_useLegacySignaling) unawaited(_onLegacyStartOffer());
      case 'viewer-joined':
        final id = msg['viewerId'] as String?;
        if (id != null) unawaited(_onViewerJoined(id));
      case 'viewer-left':
        final id = msg['viewerId'] as String?;
        if (id != null) unawaited(_closeViewer(id));
      case 'answer':
        unawaited(_handleAnswer(msg));
      case 'ice':
        unawaited(_handleIce(msg));
      case 'error':
        errorMessage = msg['message'] as String? ?? 'Signaling error';
        streamState = StreamState.error;
        notifyListeners();
    }
  }

  RTCPeerConnection? _peerForAnswer(String? viewerId) {
    if (viewerId != null && viewerId != 'legacy') {
      return _viewerPeers[viewerId];
    }
    if (_useLegacySignaling && _legacyPeer != null) {
      return _legacyPeer;
    }
    if (_viewerPeers.length == 1) {
      return _viewerPeers.values.first;
    }
    return null;
  }

  RTCPeerConnection? _peerForIce(String? viewerId) {
    if (viewerId != null && viewerId != 'legacy') {
      return _viewerPeers[viewerId];
    }
    if (_useLegacySignaling && _legacyPeer != null) {
      return _legacyPeer;
    }
    return null;
  }

  Future<void> _handleAnswer(Map<String, dynamic> msg) async {
    final answer = RTCSessionDescription(
      msg['sdp'] as String,
      msg['sdpType'] as String? ?? 'answer',
    );
    final pc = _peerForAnswer(msg['viewerId'] as String?);
    if (pc == null) {
      debugPrint('Ignoring answer — no peer for viewer ${msg['viewerId']}');
      return;
    }
    if (pc.signalingState != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
      debugPrint('Ignoring duplicate answer (state=${pc.signalingState})');
      return;
    }
    try {
      await pc.setRemoteDescription(answer);
    } catch (e) {
      debugPrint('setRemoteDescription failed: $e');
    }
  }

  Future<void> _handleIce(Map<String, dynamic> msg) async {
    final candidate = RTCIceCandidate(
      msg['candidate'] as String?,
      msg['sdpMid'] as String?,
      msg['sdpMLineIndex'] as int?,
    );
    final pc = _peerForIce(msg['viewerId'] as String?);
    if (pc == null) return;
    try {
      await pc.addCandidate(candidate);
    } catch (e) {
      debugPrint('addCandidate failed: $e');
    }
  }

  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  MediaStreamTrack? get _videoTrack {
    final tracks = _localStream?.getVideoTracks() ?? [];
    return tracks.isEmpty ? null : tracks.first;
  }

  /// Switch front/back while live — keeps WebSocket + peer connections alive.
  Future<bool> switchCameraWhileStreaming(bool front) async {
    if (!isLive || _switchInFlight) return false;
    if (_useFrontCamera == front) return true;

    _switchInFlight = true;
    isSwitchingCamera = true;
    notifyListeners();

    try {
      await _switchVideoTrackWithNewStream(front).timeout(
        const Duration(seconds: 12),
        onTimeout: () => throw TimeoutException('Camera switch timed out'),
      );
      _useFrontCamera = front;
      localRenderer.srcObject = _localStream;
      if (_viewerPeers.isNotEmpty) {
        await _renegotiateWithAllViewers();
      }
      return true;
    } catch (e) {
      debugPrint('switchCameraWhileStreaming: $e');
      errorMessage = 'Camera switch failed: $e';
      notifyListeners();
      return false;
    } finally {
      isSwitchingCamera = false;
      _switchInFlight = false;
      notifyListeners();
    }
  }

  Future<void> _switchVideoTrackWithNewStream(bool front) async {
    final stream = _localStream;
    if (stream == null) {
      throw StateError('Stream not ready');
    }

    final oldVideo = _videoTrack;
    if (oldVideo != null) {
      try {
        await oldVideo.stop();
      } catch (_) {}
      try {
        await stream.removeTrack(oldVideo);
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    final videoOnly = await navigator.mediaDevices.getUserMedia({
      'audio': false,
      'video': {
        'facingMode': front ? 'user' : 'environment',
        'width': 1280,
        'height': 720,
      },
    });

    final newVideo = videoOnly.getVideoTracks().first;
    await stream.addTrack(newVideo);
    localRenderer.srcObject = stream;

    for (final entry in _viewerPeers.entries) {
      final senders = await entry.value.getSenders();
      for (final sender in senders) {
        if (sender.track?.kind == 'video') {
          await sender.replaceTrack(newVideo);
          break;
        }
      }
    }

    for (final t in videoOnly.getAudioTracks()) {
      try {
        await t.stop();
      } catch (_) {}
    }
  }

  Future<void> _renegotiateWithAllViewers() async {
    for (final entry in Map<String, RTCPeerConnection>.from(_viewerPeers).entries) {
      final pc = entry.value;
      final state = pc.signalingState;
      if (state != RTCSignalingState.RTCSignalingStateStable &&
          state != RTCSignalingState.RTCSignalingStateHaveRemoteOffer) {
        continue;
      }
      try {
        await _sendOfferToViewer(entry.key, pc);
      } catch (e) {
        debugPrint('Renegotiation failed for ${entry.key}: $e');
      }
    }
  }

  Future<void> stop() async {
    streamState = StreamState.off;
    viewerCount = 0;
    isSwitchingCamera = false;
    _switchInFlight = false;
    notifyListeners();

    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    for (final id in _viewerPeers.keys.toList()) {
      await _closeViewer(id);
    }

    await _closeLegacyPeer();
    _useLegacySignaling = true;

    try {
      await _localStream?.dispose();
    } catch (_) {}
    _localStream = null;
    try {
      localRenderer.srcObject = null;
    } catch (_) {}

    _iceServers = null;
    _pendingViewers.clear();
    unawaited(DashcamService.instance.initialize());
  }
}
