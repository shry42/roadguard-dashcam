import 'package:flutter/material.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../alerts/alerts_screen.dart';
import '../home/home_screen.dart';
import '../live/live_stream_screen.dart';
import '../recordings/recordings_screen.dart';
import '../trips/trips_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _index = 0;

  final _screens = const [
    HomeScreen(),
    LiveStreamScreen(embedded: true),
    RecordingsScreen(embedded: true),
    TripsScreen(embedded: true),
    AlertsScreen(embedded: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.videocam_rounded), label: 'Live'),
            BottomNavigationBarItem(icon: Icon(Icons.video_library_rounded), label: 'Clips'),
            BottomNavigationBarItem(icon: Icon(Icons.route_rounded), label: 'Trips'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Alerts'),
          ],
        ),
      ),
      floatingActionButton: _index == 1
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.liveStream),
              backgroundColor: AppColors.recordRed,
              icon: const Icon(Icons.fiber_manual_record_rounded),
              label: const Text('Go Live'),
            ),
    );
  }
}
