import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/gradient_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.videocam_rounded, size: 36, color: AppColors.background),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Welcome back',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in to manage your dashcam',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 40),
              const AppTextField(
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),
              const AppTextField(
                label: 'Password',
                hint: 'Enter your password',
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 8),
              GradientButton(
                label: 'Sign In',
                icon: Icons.login_rounded,
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.main),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.8))),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.8))),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                    child: const Text(
                      'Sign up',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
