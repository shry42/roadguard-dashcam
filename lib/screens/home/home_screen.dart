import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_badge.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildLivePreview(context)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                delegate: SliverChildListDelegate([
                  StatCard(
                    icon: Icons.route_rounded,
                    label: 'Trips today',
                    value: '3',
                    color: AppColors.accent,
                    onTap: () {},
                  ),
                  StatCard(
                    icon: Icons.timer_rounded,
                    label: 'Drive time',
                    value: '2h 14m',
                    color: AppColors.primary,
                    onTap: () {},
                  ),
                  StatCard(
                    icon: Icons.speed_rounded,
                    label: 'Max speed',
                    value: '78 km/h',
                    color: AppColors.warning,
                    onTap: () {},
                  ),
                  StatCard(
                    icon: Icons.warning_amber_rounded,
                    label: 'Alerts',
                    value: '2',
                    color: AppColors.danger,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.alertDetail),
                  ),
                ]),
              ),
            ),
            const SliverToBoxAdapter(child: SectionHeader(title: 'Recent activity')),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _ActivityTile(
                  title: ['Morning commute', 'Office run', 'Evening return'][i],
                  time: ['8:42 AM', '1:15 PM', '6:30 PM'][i],
                  distance: ['12.4 km', '8.2 km', '15.1 km'][i],
                  onTap: () => Navigator.pushNamed(context, AppRoutes.tripDetail),
                ),
                childCount: 3,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Good evening,', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                const Text(
                  'Alex Driver',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceLight,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: const Text('AD', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLivePreview(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.liveStream),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surfaceLight,
                AppColors.surfaceLight.withValues(alpha: 0.6),
              ],
            ),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: const Color(0xFF1a2535),
                  child: CustomPaint(painter: _RoadPainter()),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: const StatusBadge(label: 'LIVE', type: BadgeType.live, pulse: true),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.overlay,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fiber_manual_record, color: AppColors.recordRed, size: 10),
                      SizedBox(width: 6),
                      Text('REC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Front camera',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        Text('Tap to open live view', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                    Icon(Icons.fullscreen_rounded, color: AppColors.textPrimary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.time,
    required this.distance,
    required this.onTap,
  });

  final String title;
  final String time;
  final String distance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_car_rounded, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('$time · $distance', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.15)
      ..strokeWidth = 2;
    for (var i = 0; i < 8; i++) {
      final y = size.height * (0.3 + i * 0.1);
      canvas.drawLine(Offset(size.width * 0.35, y), Offset(size.width * 0.65, y + 20), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
