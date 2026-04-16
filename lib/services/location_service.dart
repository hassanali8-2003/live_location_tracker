import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Check and request location permissions
  Future<bool> handleLocationPermission() async {
    // 1. Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    // 2. Request normal location permissions (Foreground)
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // 3. Request Background Location Permission (Android 10+)
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final status = await Permission.locationAlways.request();
      if (!status.isGranted) {
        // You can choose to continue or fail here. 
        // For background tracking, we ideally want 'always'.
        print("Background location permission not granted");
      }
    }

    // 4. Request Notification Permission (Required for Android 13+)
    await Permission.notification.request();

    return true;
  }

  /// Get current position once
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await handleLocationPermission();
    if (!hasPermission) return null;

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  /// Get location stream for real-time updates
  Stream<Position> getLocationStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}
