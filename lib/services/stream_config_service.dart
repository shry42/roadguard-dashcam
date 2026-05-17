import 'dart:convert';

import 'package:http/http.dart' as http;

/// Fetches `/api/stream-config` from the signaling host (same machine as WebSocket).
class StreamConfigService {
  static const defaultIceServers = [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun.relay.metered.ca:443'},
    {
      'urls': 'turn:global.relay.metered.ca:80',
      'username': 'openrelayproject',
      'credential': 'openrelayproject',
    },
    {
      'urls': 'turn:global.relay.metered.ca:443',
      'username': 'openrelayproject',
      'credential': 'openrelayproject',
    },
    {
      'urls': 'turn:global.relay.metered.ca:443?transport=tcp',
      'username': 'openrelayproject',
      'credential': 'openrelayproject',
    },
  ];

  static Future<List<Map<String, dynamic>>> loadIceServers({
    required String signalingUrl,
    required String roomId,
  }) async {
    try {
      final wsUri = Uri.parse(signalingUrl);
      final httpScheme = wsUri.scheme == 'wss' ? 'https' : 'http';
      final port = wsUri.hasPort ? wsUri.port : (httpScheme == 'https' ? 443 : 80);
      final uri = Uri(
        scheme: httpScheme,
        host: wsUri.host,
        port: port,
        path: '/api/stream-config',
        queryParameters: {'room': roomId},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return List.from(defaultIceServers);
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final servers = body['iceServers'] as List<dynamic>?;
      if (servers == null || servers.isEmpty) return List.from(defaultIceServers);
      return servers.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return List.from(defaultIceServers);
    }
  }
}
