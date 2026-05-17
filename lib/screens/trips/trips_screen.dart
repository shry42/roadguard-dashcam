import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trips'),
        automaticallyImplyLeading: !embedded,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.calendar_month_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list_rounded)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryBanner(),
          const SizedBox(height: 20),
          ...List.generate(5, (i) {
            final titles = ['Morning commute', 'Office run', 'Client visit', 'Grocery run', 'Evening return'];
            final dates = ['Today', 'Today', 'Yesterday', 'Yesterday', 'May 14'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TripCard(
                title: titles[i],
                date: dates[i],
                distance: '${8 + i * 2.3} km',
                duration: '${20 + i * 8} min',
                maxSpeed: '${55 + i * 5} km/h',
                alerts: i == 1 ? 2 : 0,
                onTap: () => Navigator.pushNamed(context, AppRoutes.tripDetail),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.accent.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(value: '5', label: 'Trips'),
          _SummaryItem(value: '48 km', label: 'Distance'),
          _SummaryItem(value: '2h 14m', label: 'Duration'),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({
    required this.title,
    required this.date,
    required this.distance,
    required this.duration,
    required this.maxSpeed,
    required this.alerts,
    required this.onTap,
  });

  final String title;
  final String date;
  final String distance;
  final String duration;
  final String maxSpeed;
  final int alerts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        Text(date, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  if (alerts > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('$alerts alerts', style: const TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600)),
                    ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomPaint(
                  painter: _RoutePainter(),
                  size: const Size(double.infinity, 80),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Metric(icon: Icons.straighten_rounded, value: distance),
                  _Metric(icon: Icons.schedule_rounded, value: duration),
                  _Metric(icon: Icons.speed_rounded, value: maxSpeed),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(20, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.3, size.height * 0.2, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.7, size.height * 0.8, size.width - 20, size.height * 0.3);
    canvas.drawPath(path, paint);

    canvas.drawCircle(const Offset(20, 56), 6, Paint()..color = AppColors.live);
    canvas.drawCircle(Offset(size.width - 20, 24), 6, Paint()..color = AppColors.danger);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
