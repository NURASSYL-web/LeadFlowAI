import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../firebase_options.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();
  AuthStatus _status = AuthStatus.loading;
  UserModel? _user;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;

  AuthProvider() {
    unawaited(_repo.ensureSessionPersistence());
    _repo.authStateChanges.listen(_onAuthChanged);
  }

  Future<void> _onAuthChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = AuthStatus.unauthenticated;
      _user = null;
    } else {
      _user = await _repo.getUserFromFirestore(firebaseUser.uid);
      _status = AuthStatus.authenticated;
    }
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    if (!_ensureFirebaseConfigured()) {
      return false;
    }
    try {
      _error = null;
      _user = await _repo.signInWithGoogle();
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code, message: e.message);
      notifyListeners();
      return false;
    } on FirebaseException catch (e) {
      _error = _mapFirebaseServiceError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _error = _formatUnknownError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    if (!_ensureFirebaseConfigured()) {
      return false;
    }
    try {
      _error = null;
      _user = await _repo.signInWithEmail(email, password);
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code, message: e.message);
      notifyListeners();
      return false;
    } on FirebaseException catch (e) {
      _error = _mapFirebaseServiceError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _error = _formatUnknownError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithEmail(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    if (!_ensureFirebaseConfigured()) {
      return false;
    }
    try {
      _error = null;
      _user = await _repo.signUpWithEmail(name, email, password, phone);
      return _user != null;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code, message: e.message);
      notifyListeners();
      return false;
    } on FirebaseException catch (e) {
      _error = _mapFirebaseServiceError(e);
      notifyListeners();
      return false;
    } catch (e) {
      _error = _formatUnknownError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> updateProfile({required String name}) async {
    if (_user == null) return false;
    try {
      await _repo.updateUserProfile(uid: _user!.uid, name: name);
      _user = _user!.copyWith(name: name);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _formatUnknownError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    if (!_ensureFirebaseConfigured()) {
      return;
    }
    await _repo.sendPasswordResetEmail(email);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  bool _ensureFirebaseConfigured() {
    final configError =
        DefaultFirebaseOptions.currentPlatformConfigurationError;
    if (configError == null) {
      return true;
    }

    _error = configError;
    notifyListeners();
    return false;
  }

  String _mapFirebaseError(String code, {String? message}) {
    final normalizedMessage = message?.toLowerCase();
    if (normalizedMessage?.contains('api key not valid') == true) {
      return _firebaseSetupMessage();
    }

    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase Authentication.';
      case 'unauthorized-domain':
        return 'This domain is not authorized in Firebase Authentication.';
      case 'admin-restricted-operation':
        return 'This sign-in method is restricted in your Firebase project.';
      case 'popup-closed-by-user':
        return 'Google sign-in was cancelled before completion.';
      case 'popup-blocked':
      case 'popup-blocked-by-browser':
        return 'The browser blocked the sign-in popup. Allow popups and try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      default:
        return message?.trim().isNotEmpty == true
            ? message!.trim()
            : 'Something went wrong. Please try again.';
    }
  }

  String _mapFirebaseServiceError(FirebaseException e) {
    final normalizedMessage = e.message?.toLowerCase();
    if (normalizedMessage?.contains('api key not valid') == true) {
      return _firebaseSetupMessage();
    }

    if (e.plugin == 'cloud_firestore' && e.code == 'permission-denied') {
      return 'Firestore denied access. Check your Firestore rules for this signed-in user.';
    }
    if (e.message != null && e.message!.trim().isNotEmpty) {
      return e.message!.trim();
    }
    return 'Firebase error: ${e.code}';
  }

  String _formatUnknownError(Object error) {
    final text = error.toString().trim();
    if (text.toLowerCase().contains('api key not valid')) {
      return _firebaseSetupMessage();
    }
    if (text.isEmpty) {
      return 'Something went wrong. Please try again.';
    }
    return text;
  }

  String _firebaseSetupMessage() {
    return DefaultFirebaseOptions.currentPlatformConfigurationError ??
        'Firebase is configured incorrectly for this platform. Run `flutterfire configure` and add the platform config file before signing in.';
  }
}
