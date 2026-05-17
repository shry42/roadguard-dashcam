import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../services/permissions_service.dart';
import '../../widgets/gradient_button.dart';

class DeviceSetupScreen extends StatefulWidget {
  const DeviceSetupScreen({super.key});

  @override
  State<DeviceSetupScreen> createState() => _DeviceSetupScreenState();
}

class _DeviceSetupScreenState extends State<DeviceSetupScreen> {
  int _step = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Dashcam'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.main),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _StepIndicator(current: _step, total: 3),
            const SizedBox(height: 32),
            Expanded(child: _buildStepContent()),
            GradientButton(
              label: _step < 2 ? 'Continue' : 'Finish Setup',
              onPressed: () async {
                if (_step == 0 || _step == 2) {
                  await PermissionsService.instance.requestDashcamPermissions();
                }
                if (_step < 2) {
                  setState(() => _step++);
                } else {
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, AppRoutes.main);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    return switch (_step) {
      0 => _StepContent(
          icon: Icons.smartphone_rounded,
          title: 'Use this phone',
          subtitle: 'Your device will act as the dashcam. Mount it on your windshield for the best road view.',
          child: _PermissionTile(icon: Icons.camera_alt_rounded, label: 'Camera access', granted: true),
        ),
      1 => _StepContent(
          icon: Icons.location_on_rounded,
          title: 'Enable location',
          subtitle: 'GPS tags every recording and trip for the admin panel map view.',
          child: _PermissionTile(icon: Icons.gps_fixed_rounded, label: 'Location access', granted: true),
        ),
      _ => _StepContent(
          icon: Icons.wifi_rounded,
          title: 'Connect to stream',
          subtitle: 'Choose how to send live video to your admin panel.',
          child: Column(
            children: [
              _ConnectionOption(
                icon: Icons.wifi_rounded,
                title: 'Wi-Fi',
                subtitle: 'Same network as admin',
                selected: true,
              ),
              const SizedBox(height: 12),
              _ConnectionOption(
                icon: Icons.signal_cellular_alt_rounded,
                title: 'Mobile data',
                subtitle: 'Stream anywhere with 4G',
                selected: false,
              ),
            ],
          ),
        ),
    };
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i <= current;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < total - 1 ? 8 : 0),
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _StepContent extends StatelessWidget {
  const _StepContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, size: 40, color: AppColors.primary),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        const SizedBox(height: 32),
        child,
      ],
    );
  }
}

class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.icon, required this.label, required this.granted});

  final IconData icon;
  final String label;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Icon(
            granted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            color: granted ? AppColors.live : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _ConnectionOption extends StatelessWidget {
  const _ConnectionOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 1.5 : 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: selected ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.primary : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
