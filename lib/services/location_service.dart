import 'package:geolocator/geolocator.dart';

/// Exception thrown when location operations fail
class LocationException implements Exception {
  final String message;
  final bool isPermanentlyDenied;

  LocationException(this.message, {this.isPermanentlyDenied = false});

  @override
  String toString() => message;
}

/// Domain object representing geographical coordinates
class AppCoordinates {
  final double latitude;
  final double longitude;

  const AppCoordinates(this.latitude, this.longitude);
}

/// Service for device location using Geolocator
class LocationService {
  /// Get current device coordinates with permission handling
  Future<AppCoordinates> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permissions are permanently denied. Please enable them in app settings.',
        isPermanentlyDenied: true,
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    return AppCoordinates(position.latitude, position.longitude);
  }

  /// Open app settings for permission management
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open device location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
