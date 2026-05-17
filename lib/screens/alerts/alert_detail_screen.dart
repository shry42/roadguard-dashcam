import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alert Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 40),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Harsh braking', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('Severity: Medium', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_fill_rounded, size: 48, color: AppColors.primary),
                    SizedBox(height: 8),
                    Text('Event clip · 0:32', style: TextStyle(color: AppColors.textMuted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _InfoTile(label: 'Time', value: 'May 16, 2026 · 9:15 AM'),
            _InfoTile(label: 'Location', value: 'MG Road, Bangalore'),
            _InfoTile(label: 'Speed at event', value: '52 km/h'),
            _InfoTile(label: 'Trip', value: 'Morning commute'),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.map_outlined),
              label: const Text('View on map'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Mark as reviewed'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textPrimary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}
