import 'package:geolocator/geolocator.dart';

class GeofenceHelper {
  /// Default Corporate Office Coordinates (can be received from backend config)
  static const double officeLatitude = 12.9716;
  static const double officeLongitude = 77.5946;
  static const double defaultRadiusMeters = 200.0;

  static Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

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

    return true;
  }

  static Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return null;
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static double calculateDistanceInMeters({
    required double userLat,
    required double userLng,
    double targetLat = officeLatitude,
    double targetLng = officeLongitude,
  }) {
    return Geolocator.distanceBetween(userLat, userLng, targetLat, targetLng);
  }

  static bool isWithinGeofence({
    required double userLat,
    required double userLng,
    double targetLat = officeLatitude,
    double targetLng = officeLongitude,
    double allowedRadius = defaultRadiusMeters,
  }) {
    final distance = calculateDistanceInMeters(
      userLat: userLat,
      userLng: userLng,
      targetLat: targetLat,
      targetLng: targetLng,
    );
    return distance <= allowedRadius;
  }
}
