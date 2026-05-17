import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 220,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Stack(
                children: [
                  CustomPaint(
                    painter: _MapPainter(),
                    size: const Size(double.infinity, 220),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Map preview', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Morning commute',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text('May 16, 2026 · 8:42 AM – 9:06 AM', style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _StatBox(label: 'Distance', value: '12.4 km', icon: Icons.straighten_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatBox(label: 'Duration', value: '24 min', icon: Icons.schedule_rounded)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _StatBox(label: 'Avg speed', value: '42 km/h', icon: Icons.speed_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _StatBox(label: 'Max speed', value: '68 km/h', icon: Icons.trending_up_rounded)),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const Text('Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  _TimelineEvent(time: '8:42', title: 'Trip started', icon: Icons.play_circle_outline_rounded, color: AppColors.live),
                  _TimelineEvent(time: '8:55', title: 'Harsh braking detected', icon: Icons.warning_amber_rounded, color: AppColors.warning),
                  _TimelineEvent(time: '9:02', title: 'Speed alert (68 km/h)', icon: Icons.speed_rounded, color: AppColors.danger),
                  _TimelineEvent(time: '9:06', title: 'Trip ended', icon: Icons.stop_circle_outlined, color: AppColors.textMuted),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.video_library_outlined),
                      label: const Text('View trip recordings'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  const _TimelineEvent({
    required this.time,
    required this.title,
    required this.icon,
    required this.color,
  });

  final String time;
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(time, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontFeatures: [])),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(40, size.height - 40);
    path.lineTo(size.width * 0.3, size.height * 0.5);
    path.lineTo(size.width * 0.6, size.height * 0.6);
    path.lineTo(size.width - 40, 40);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
