import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: const Text(
                    'AD',
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt_rounded, size: 16, color: AppColors.background),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Alex Driver', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const Text('alex.driver@email.com', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Pro Plan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
            ),
            const SizedBox(height: 32),
            _ProfileField(label: 'Full name', value: 'Alex Driver'),
            _ProfileField(label: 'Email', value: 'alex.driver@email.com'),
            _ProfileField(label: 'Phone', value: '+91 98765 43210'),
            _ProfileField(label: 'Vehicle', value: 'Honda City · KA-01-AB-1234'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Edit profile'),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _ProfileStat(value: '127', label: 'Trips'),
                  _ProfileStat(value: '1.2k', label: 'Clips'),
                  _ProfileStat(value: '48', label: 'Alerts'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

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
