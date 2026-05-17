import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../services/app_settings.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          _Section(title: 'Recording'),
          _SettingsTile(
            icon: Icons.high_quality_rounded,
            title: 'Video quality',
            subtitle: '1080p',
            onTap: () => _showQualitySheet(context),
          ),
          _SettingsTile(
            icon: Icons.timer_rounded,
            title: 'Loop recording',
            subtitle: '5 min segments',
            trailing: Switch(value: true, onChanged: (_) {}),
          ),
          _SettingsTile(
            icon: Icons.nightlight_round,
            title: 'Night mode boost',
            trailing: Switch(value: false, onChanged: (_) {}),
          ),
          _Section(title: 'Live stream (WebRTC)'),
          _SettingsTile(
            icon: Icons.hub_outlined,
            title: 'Signaling server',
            subtitle: settings.signalingUrl,
            onTap: () => _showStreamSettings(context),
          ),
          _SettingsTile(
            icon: Icons.meeting_room_outlined,
            title: 'Room ID',
            subtitle: settings.roomId,
            onTap: () => _showStreamSettings(context),
          ),
          _SettingsTile(
            icon: Icons.api_outlined,
            title: 'Stream API (for website)',
            subtitle: _apiConfigUrl(settings),
            onTap: () => _showStreamApiHelp(context, settings),
          ),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Stream over internet',
            subtitle: 'Deploy server, set wss:// URL here',
            onTap: () => _showStreamHelp(context),
          ),
          _Section(title: 'Safety alerts'),
          _SettingsTile(icon: Icons.speed_rounded, title: 'Speed alerts', subtitle: 'Above 80 km/h'),
          _SettingsTile(icon: Icons.vibration_rounded, title: 'Harsh event detection', trailing: Switch(value: true, onChanged: (_) {})),
          _SettingsTile(icon: Icons.notifications_active_rounded, title: 'Push notifications', trailing: Switch(value: true, onChanged: (_) {})),
          _Section(title: 'Device'),
          _SettingsTile(
            icon: Icons.devices_rounded,
            title: 'Dashcam setup',
            onTap: () => Navigator.pushNamed(context, AppRoutes.deviceSetup),
          ),
          _SettingsTile(icon: Icons.sd_storage_rounded, title: 'Storage', subtitle: '12.4 GB used · 128 GB'),
          _Section(title: 'Account'),
          _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Profile',
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          _SettingsTile(icon: Icons.lock_outline_rounded, title: 'Change password'),
          _SettingsTile(icon: Icons.privacy_tip_outlined, title: 'Privacy policy'),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Sign out',
            titleColor: AppColors.danger,
            onTap: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false),
          ),
          const SizedBox(height: 32),
          const Center(
            child: Text('RoadGuard v1.0.0', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _apiConfigUrl(AppSettings settings) {
    final ws = settings.signalingUrl.trim();
    if (ws.isEmpty) return 'Set signaling URL first';
    try {
      final u = Uri.parse(ws);
      final httpScheme = u.scheme == 'wss' ? 'https' : 'http';
      final port = u.hasPort ? u.port : (httpScheme == 'https' ? 443 : 80);
      return Uri(
        scheme: httpScheme,
        host: u.host,
        port: port,
        path: '/api/stream-config',
        queryParameters: {'room': settings.roomId},
      ).toString();
    } catch (_) {
      return '/api/stream-config?room=${settings.roomId}';
    }
  }

  void _showStreamApiHelp(BuildContext context, AppSettings settings) {
    final api = _apiConfigUrl(settings);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Stream API'),
        content: SelectableText(
          'Give your website developer this HTTP URL:\n\n$api\n\n'
          'They GET JSON with signalingUrl, roomId, iceServers.\n'
          'Video still plays in the browser with WebRTC (see web_admin/index.html).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showStreamHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Stream from anywhere'),
        content: const Text(
          'Stable URL (set once, never changes):\n\n'
          'A) Render (recommended, free)\n'
          '   Deploy render.yaml from the repo → get\n'
          '   https://roadguard-signaling.onrender.com\n'
          '   App Settings → wss://roadguard-signaling.onrender.com\n\n'
          'B) Your domain + Cloudflare Tunnel\n'
          '   server/scripts/setup-cloudflare-named-tunnel.sh\n'
          '   → e.g. wss://dashcam.yourdomain.com\n\n'
          'Do NOT use trycloudflare.com — that URL changes daily.\n\n'
          'Phone: Live → Stream · Website: same host, room dashcam-1',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showStreamSettings(BuildContext context) {
    final urlCtrl = TextEditingController(text: AppSettings.instance.signalingUrl);
    final roomCtrl = TextEditingController(text: AppSettings.instance.roomId);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Stream settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'WebSocket URL',
                hintText: 'wss://roadguard-signaling.onrender.com',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: roomCtrl,
              decoration: const InputDecoration(labelText: 'Room ID', hintText: 'dashcam-1'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await AppSettings.instance.saveSignalingUrl(urlCtrl.text);
                await AppSettings.instance.saveRoomId(roomCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stream settings saved')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showQualitySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Video quality', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...['720p', '1080p', '4K'].map(
              (q) => ListTile(
                title: Text(q),
                trailing: q == '1080p' ? const Icon(Icons.check_rounded, color: AppColors.primary) : null,
                onTap: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted, letterSpacing: 1),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(title, style: TextStyle(color: titleColor, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted) : null),
      onTap: onTap,
    );
  }
}
