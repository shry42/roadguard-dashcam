import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final alerts = [
      (Icons.warning_amber_rounded, 'Harsh braking', '9:15 AM · MG Road', AppColors.warning, true),
      (Icons.speed_rounded, 'Speed limit exceeded', '6:52 PM · Highway', AppColors.danger, true),
      (Icons.bedtime_rounded, 'Possible drowsiness', 'Yesterday', AppColors.accent, false),
      (Icons.phone_android_rounded, 'Phone use detected', 'May 14', AppColors.danger, false),
      (Icons.gps_off_rounded, 'GPS signal lost', 'May 13', AppColors.textMuted, false),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        automaticallyImplyLeading: !embedded,
        actions: [
          TextButton(onPressed: () {}, child: const Text('Mark all read')),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final (icon, title, subtitle, color, unread) = alerts[i];
          return _AlertTile(
            icon: icon,
            title: title,
            subtitle: subtitle,
            color: color,
            unread: unread,
            onTap: () => Navigator.pushNamed(context, AppRoutes.alertDetail),
          );
        },
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.unread,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: unread ? color.withValues(alpha: 0.06) : AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unread ? color.withValues(alpha: 0.3) : AppColors.border,
              width: unread ? 1 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
