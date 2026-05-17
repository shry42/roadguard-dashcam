import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final _pages = const [
    _OnboardPage(
      icon: Icons.videocam_rounded,
      title: 'Your Phone,\nYour Dashcam',
      subtitle: 'Turn your device into a smart dashcam with dual-view recording and live streaming.',
      color: AppColors.primary,
    ),
    _OnboardPage(
      icon: Icons.cloud_upload_rounded,
      title: 'Stream &\nStore Securely',
      subtitle: 'Watch live footage from the admin panel. Cloud backup keeps your trips safe.',
      color: AppColors.accent,
    ),
    _OnboardPage(
      icon: Icons.shield_rounded,
      title: 'Drive Safer\nEvery Trip',
      subtitle: 'AI alerts for harsh braking, speed, and incidents — peace of mind on every road.',
      color: AppColors.warning,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            SmoothPageIndicator(
              controller: _pageController,
              count: _pages.length,
              effect: const ExpandingDotsEffect(
                dotHeight: 8,
                dotWidth: 8,
                activeDotColor: AppColors.primary,
                dotColor: AppColors.border,
              ),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GradientButton(
                label: _currentPage == _pages.length - 1 ? 'Get Started' : 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: _next,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, size: 56, color: color),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, height: 1.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
