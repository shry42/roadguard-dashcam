import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

enum BadgeType { live, recording, offline, warning, info }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.pulse = false,
  });

  final String label;
  final BadgeType type;
  final bool pulse;

  Color get _color => switch (type) {
        BadgeType.live => AppColors.live,
        BadgeType.recording => AppColors.recordRed,
        BadgeType.offline => AppColors.textMuted,
        BadgeType.warning => AppColors.warning,
        BadgeType.info => AppColors.accent,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse)
            Container(
              width: 7,
              height: 7,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: _color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: _color.withValues(alpha: 0.6), blurRadius: 6),
                ],
              ),
            ),
          Text(
            label,
            style: TextStyle(
              color: _color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
