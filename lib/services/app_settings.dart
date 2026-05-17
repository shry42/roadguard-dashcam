import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _keySignalingUrl = 'signaling_url';
  static const _keyRoomId = 'room_id';
  static const _keyStreamConfigVersion = 'stream_config_version';

  /// Stable URL after one-time deploy (see render.yaml or setup-stable-url.sh).
  /// Quick trycloudflare URLs change every restart — do not use for production.
  static const defaultSignalingUrl = 'wss://roadguard-signaling.onrender.com';
  static const defaultRoomId = 'dashcam-1';
  static const _streamConfigVersion = 4;

  String signalingUrl = defaultSignalingUrl;
  String roomId = defaultRoomId;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVersion = prefs.getInt(_keyStreamConfigVersion) ?? 0;
    if (savedVersion < _streamConfigVersion) {
      await prefs.setString(_keySignalingUrl, defaultSignalingUrl);
      await prefs.setString(_keyRoomId, defaultRoomId);
      await prefs.setInt(_keyStreamConfigVersion, _streamConfigVersion);
    }
    signalingUrl = prefs.getString(_keySignalingUrl) ?? defaultSignalingUrl;
    roomId = prefs.getString(_keyRoomId) ?? defaultRoomId;
  }

  Future<void> saveSignalingUrl(String url) async {
    signalingUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySignalingUrl, signalingUrl);
  }

  Future<void> saveRoomId(String id) async {
    roomId = id.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRoomId, roomId);
  }
}
