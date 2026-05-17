import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/gradient_button.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Join RoadGuard',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set up your dashcam profile in seconds',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              const AppTextField(label: 'Full Name', hint: 'John Doe', prefixIcon: Icons.person_outline_rounded),
              const SizedBox(height: 20),
              const AppTextField(
                label: 'Email',
                hint: 'you@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),
              const AppTextField(
                label: 'Phone',
                hint: '+91 98765 43210',
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 20),
              const AppTextField(
                label: 'Password',
                hint: 'Min. 8 characters',
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 20),
              const AppTextField(
                label: 'Confirm Password',
                hint: 'Re-enter password',
                obscureText: true,
                prefixIcon: Icons.lock_outline_rounded,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: true,
                      onChanged: (_) {},
                      activeColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      const TextSpan(
                        text: 'I agree to the ',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              GradientButton(
                label: 'Create Account',
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.deviceSetup),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(color: AppColors.textSecondary)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text('Sign in', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
