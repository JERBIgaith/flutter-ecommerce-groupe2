import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Authentication controller managing auth state and user profile
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _profile;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get profile => _profile;

  /// Stream of Firebase Auth state changes
  Stream<User?> get authState => _authService.authStateChanges;

  /// Register new user
  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final userModel = await _authService.register(name, email, password);
      if (userModel != null) {
        _profile = userModel;
        _setLoading(false);
        return true;
      }
      _setError('Registration failed');
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  /// Login with email and password
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.login(email, password);
      if (user != null) {
        await loadProfile();
        _setLoading(false);
        return true;
      }
      _setError('Login failed');
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    await _authService.logout();
    _profile = null;
    _clearError();
    notifyListeners();
  }

  /// Load user profile from Firestore
  Future<void> loadProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      _profile = await _authService.getProfile(user.uid);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load profile');
    }
  }

  /// Update user profile
  Future<bool> updateProfile({String? name, String? address}) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    _setLoading(true);
    _clearError();

    try {
      await _authService.updateProfile(user.uid, name: name, address: address);
      await loadProfile();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Failed to update profile');
      _setLoading(false);
      return false;
    }
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Set error message
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
  }

  /// Convert Firebase Auth errors to user-friendly messages
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'user-disabled':
        return 'User account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return 'Authentication error: ${e.message ?? 'Unknown error'}';
    }
  }
}
