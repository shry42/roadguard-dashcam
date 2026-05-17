import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/gradient_button.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: AppColors.accent, size: 32),
              ),
              const SizedBox(height: 24),
              const Text(
                'Reset password',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your email and we\'ll send you a link to reset your password.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 32),
              const AppTextField(
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 28),
              GradientButton(
                label: 'Send Reset Link',
                icon: Icons.send_rounded,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Reset link sent (UI demo)'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
