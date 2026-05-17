import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService extends ChangeNotifier {
  LocationService._();
  static final LocationService instance = LocationService._();

  Position? _position;
  String _label = 'GPS off';
  StreamSubscription<Position>? _sub;

  Position? get position => _position;
  String get label => _label;
  double? get speedKmh {
    final s = _position?.speed;
    if (s == null || s < 0) return null;
    return s * 3.6;
  }

  Future<bool> start() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _label = 'GPS disabled';
      notifyListeners();
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _label = 'No permission';
      notifyListeners();
      return false;
    }

    _sub?.cancel();
    _sub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      _position = pos;
      final speed = speedKmh;
      _label = speed != null ? '${speed.toStringAsFixed(0)} km/h' : 'GPS OK';
      notifyListeners();
    });

    return true;
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
