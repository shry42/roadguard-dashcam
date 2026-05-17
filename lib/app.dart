import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'screens/alerts/alert_detail_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/onboarding_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/device/device_setup_screen.dart';
import 'screens/main/main_shell_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/recordings/recording_detail_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/trips/trip_detail_screen.dart';
import 'screens/live/live_stream_screen.dart';

class RoadGuardApp extends StatelessWidget {
  const RoadGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF141B26),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'RoadGuard Dashcam',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.onboarding: (_) => const OnboardingScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
        AppRoutes.main: (_) => const MainShellScreen(),
        AppRoutes.liveStream: (_) => const LiveStreamScreen(),
        AppRoutes.recordingDetail: (ctx) {
          final file = ModalRoute.of(ctx)?.settings.arguments;
          return RecordingDetailScreen(file: file is File ? file : null);
        },
        AppRoutes.tripDetail: (_) => const TripDetailScreen(),
        AppRoutes.deviceSetup: (_) => const DeviceSetupScreen(),
        AppRoutes.alertDetail: (_) => const AlertDetailScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
      },
    );
  }
}
