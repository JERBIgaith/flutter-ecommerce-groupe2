import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Authentication controller managing auth state and user profile
class AuthController extends ChangeNotifier {
  static const String _rememberedEmailKey = 'remembered_email';
  static const int _forgotPasswordCooldownSeconds = 60;

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _profile;
  DateTime? _lastPasswordResetTime;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get profile => _profile;

  /// Check if password reset can be sent (60 second cooldown)
  bool get canSendPasswordReset {
    if (_lastPasswordResetTime == null) return true;
    final elapsed = DateTime.now().difference(_lastPasswordResetTime!);
    return elapsed.inSeconds >= _forgotPasswordCooldownSeconds;
  }

  /// Get remaining cooldown seconds
  int get forgotPasswordCooldownSeconds {
    if (_lastPasswordResetTime == null) return 0;
    final elapsed = DateTime.now().difference(_lastPasswordResetTime!);
    final remaining = _forgotPasswordCooldownSeconds - elapsed.inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Stream of Firebase Auth state changes
  Stream<User?> get authState => _authService.authStateChanges;

  /// Check if current user is a guest (anonymous)
  bool get isGuest {
    final user = _authService.currentUser;
    return user != null && user.isAnonymous;
  }

  /// Check if current user is signed in (non-anonymous)
  bool get isSignedInUser {
    final user = _authService.currentUser;
    return user != null && !user.isAnonymous;
  }

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
      debugPrint('FirebaseAuthException during register: ${e.code}');
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('Error during register: $e');
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
      debugPrint('FirebaseAuthException during login: ${e.code}');
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('Error during login: $e');
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        await loadProfile();
        _setLoading(false);
        return true;
      }
      _setError('Google sign in cancelled');
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during Google sign in: ${e.code}');
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('Error during Google sign in: $e');
      _setError('Google sign in failed');
      _setLoading(false);
      return false;
    }
  }

  /// Sign in anonymously as guest
  Future<bool> signInAnonymously() async {
    _setLoading(true);
    _clearError();

    try {
      final user = await _authService.signInAnonymously();
      if (user != null) {
        _setLoading(false);
        return true;
      }
      _setError('Guest sign in failed');
      _setLoading(false);
      return false;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during anonymous sign in: ${e.code}');
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('Error during anonymous sign in: $e');
      _setError('An unexpected error occurred');
      _setLoading(false);
      return false;
    }
  }

  /// Send password reset email with cooldown
  Future<bool> sendPasswordResetEmail(String email) async {
    if (!canSendPasswordReset) {
      _setError(
          'Please wait $forgotPasswordCooldownSeconds seconds before trying again');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      await _authService.sendPasswordResetEmail(email);
      _lastPasswordResetTime = DateTime.now();
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during password reset: ${e.code}');
      _setError(_getAuthErrorMessage(e));
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('Error during password reset: $e');
      _setError('Failed to send reset email');
      _setLoading(false);
      return false;
    }
  }

  /// Save email for Remember Me
  Future<void> saveRememberedEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rememberedEmailKey, email.trim().toLowerCase());
    } catch (e) {
      // Failed to save, ignore
    }
  }

  /// Load remembered email
  Future<String?> loadRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_rememberedEmailKey);
    } catch (e) {
      return null;
    }
  }

  /// Clear remembered email
  Future<void> clearRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rememberedEmailKey);
    } catch (e) {
      // Failed to clear, ignore
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _authService.logout();
      _profile = null;
      _lastPasswordResetTime = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
      _setError('Logout failed');
    }
  }

  /// Load user profile from Firestore
  Future<void> loadProfile() async {
    final user = _authService.currentUser;
    if (user == null || user.isAnonymous) return;

    try {
      _profile = await _authService.getProfile(user.uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading profile: $e');
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
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters)';
      case 'user-disabled':
        return 'User account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Please try again later';
      case 'network-request-failed':
        return 'Network error. Please check your connection';
      default:
        return e.message ?? 'Authentication error occurred';
    }
  }
}
