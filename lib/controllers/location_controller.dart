import 'package:flutter/foundation.dart';
import '../services/location_service.dart';

/// Controller for managing delivery location selection and device GPS state
class LocationController extends ChangeNotifier {
  final LocationService _locationService = LocationService();

  double? _selectedLat;
  double? _selectedLng;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPermissionPermanentlyDenied = false;

  double? get selectedLat => _selectedLat;
  double? get selectedLng => _selectedLng;
  bool get hasSelection => _selectedLat != null && _selectedLng != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPermissionPermanentlyDenied => _isPermissionPermanentlyDenied;

  /// Fetch current GPS position and update selection
  Future<bool> useCurrentLocation() async {
    _isLoading = true;
    _errorMessage = null;
    _isPermissionPermanentlyDenied = false;
    notifyListeners();

    try {
      final coords = await _locationService.getCurrentPosition();
      _selectedLat = coords.latitude;
      _selectedLng = coords.longitude;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on LocationException catch (e) {
      _isLoading = false;
      _errorMessage = e.message;
      _isPermissionPermanentlyDenied = e.isPermanentlyDenied;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to get current location';
      notifyListeners();
      return false;
    }
  }

  /// Manually set latitude and longitude (e.g. from map picker)
  void setPosition(double lat, double lng) {
    _selectedLat = lat;
    _selectedLng = lng;
    _errorMessage = null;
    _isPermissionPermanentlyDenied = false;
    notifyListeners();
  }

  /// Clear the current location selection
  void clear() {
    _selectedLat = null;
    _selectedLng = null;
    _errorMessage = null;
    _isPermissionPermanentlyDenied = false;
    notifyListeners();
  }

  /// Open app settings for permission granted by user
  Future<void> openAppSettings() async {
    await _locationService.openAppSettings();
  }
}
