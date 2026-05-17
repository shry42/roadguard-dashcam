import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  PermissionsService._();
  static final PermissionsService instance = PermissionsService._();

  Future<bool> requestDashcamPermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values.every((s) => s.isGranted);
  }

  Future<bool> hasAllPermissions() async {
    final camera = await Permission.camera.isGranted;
    final mic = await Permission.microphone.isGranted;
    final location = await Permission.locationWhenInUse.isGranted;
    return camera && mic && location;
  }

  Future<void> openSettings() => openAppSettings();
}
