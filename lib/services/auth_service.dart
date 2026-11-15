import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Authentication service handling Firebase Auth and Firestore operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Register new user with email and password
  /// Creates user in Firebase Auth and saves profile to Firestore with role='user'
  Future<UserModel?> register(
    String name,
    String email,
    String password,
  ) async {
    try {
      // Trim and lowercase email
      final cleanEmail = email.trim().toLowerCase();

      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) return null;

      // Create user profile with role='user'
      final userModel = UserModel(
        uid: user.uid,
        name: name,
        email: cleanEmail,
        role: 'user',
        address: null,
        photoUrl: null,
      );

      // Save profile to Firestore
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  /// Login with email and password
  Future<User?> login(String email, String password) async {
    try {
      // Trim and lowercase email
      final cleanEmail = email.trim().toLowerCase();

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in with Google
  /// Creates user document on first login if it doesn't exist
  Future<User?> signInWithGoogle() async {
    try {
      // Sign in with Google provider
      final userCredential =
          await _auth.signInWithProvider(GoogleAuthProvider());
      final user = userCredential.user;

      if (user != null) {
        // Check if user document exists, create if not
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          final userModel = UserModel(
            uid: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? '',
            role: 'user',
            photoUrl: user.photoURL,
          );
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(userModel.toMap());
        }
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign in anonymously as guest
  /// Does NOT create a users document
  Future<User?> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      rethrow;
    }
  }

  /// Send password reset email
  /// Always returns true with neutral message (don't reveal if account exists)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // Trim and lowercase email
      final cleanEmail = email.trim().toLowerCase();
      await _auth.sendPasswordResetEmail(email: cleanEmail);
    } catch (e) {
      rethrow;
    }
  }

  /// Logout current user
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Get user profile from Firestore
  /// If document doesn't exist and user is not anonymous, create it
  Future<UserModel?> getProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        // If document missing and user is not anonymous, create it
        final user = currentUser;
        if (user != null && !user.isAnonymous) {
          final userModel = UserModel(
            uid: user.uid,
            name: user.displayName ?? 'User',
            email: user.email ?? '',
            role: 'user',
            photoUrl: user.photoURL,
          );
          await _firestore
              .collection('users')
              .doc(user.uid)
              .set(userModel.toMap());
          return userModel;
        }
        return null;
      }

      return UserModel.fromMap(doc.data()!);
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile in Firestore
  Future<void> updateProfile(
    String uid, {
    String? name,
    String? address,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (address != null) updates['address'] = address;

      await _firestore.collection('users').doc(uid).update(updates);
    } catch (e) {
      rethrow;
    }
  }
}
