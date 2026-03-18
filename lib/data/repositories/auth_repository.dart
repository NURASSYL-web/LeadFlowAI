import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../../core/utils/whatsapp_utils.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  GoogleSignIn? _googleSignIn;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> ensureSessionPersistence() async {
    if (!kIsWeb) {
      return;
    }
    await _auth.setPersistence(Persistence.LOCAL);
  }

  GoogleSignIn get _nativeGoogleSignIn => _googleSignIn ??= GoogleSignIn();

  Future<UserModel?> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = GoogleAuthProvider();
      provider.addScope('email');
      provider.setCustomParameters({'prompt': 'select_account'});

      final result = await _auth.signInWithPopup(provider);
      final user = result.user!;
      await _saveUserToFirestore(
        user.uid,
        user.displayName ?? 'User',
        user.email ?? '',
        null,
        user.photoURL,
      );
      return await _getOrCreateUserProfile(user);
    }

    final googleUser = await _nativeGoogleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final result = await _auth.signInWithCredential(credential);
    final user = result.user!;
    await _saveUserToFirestore(
      user.uid,
      user.displayName ?? 'User',
      user.email ?? '',
      null,
      user.photoURL,
    );
    return await _getOrCreateUserProfile(user);
  }

  Future<UserModel?> signInWithEmail(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    return await _getOrCreateUserProfile(result.user!);
  }

  Future<UserModel?> signUpWithEmail(
    String name,
    String email,
    String password,
    String phone,
  ) async {
    final result = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = result.user!;

    try {
      await user.updateDisplayName(name);
    } catch (_) {
      // Non-blocking for onboarding.
    }

    try {
      await user.sendEmailVerification();
    } catch (_) {
      // Account creation should still succeed even if verification email fails.
    }

    final normalizedPhone = normalizePhoneNumber(phone);
    await _saveUserToFirestore(user.uid, name, email, normalizedPhone, null);
    return await _getOrCreateUserProfile(
      user,
      fallbackName: name,
      fallbackPhone: normalizedPhone,
    );
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _nativeGoogleSignIn.signOut();
    }
    await _auth.signOut();
  }

  Future<void> _saveUserToFirestore(
    String uid,
    String name,
    String email,
    String? phone,
    String? avatarUrl,
  ) async {
    final doc = _db.collection('users').doc(uid);
    final snap = await doc.get();
    if (!snap.exists) {
      final user = UserModel(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        avatarUrl: avatarUrl,
        createdAt: DateTime.now(),
      );
      await doc.set(user.toMap());
    } else {
      await doc.update({
        'name': name,
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      });
    }
  }

  Future<UserModel?> getUserFromFirestore(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return UserModel.fromMap(snap.data()!);
  }

  Future<void> updateUserProfile({
    required String uid,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    final data = <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
    if (data.isEmpty) return;
    final doc = _db.collection('users').doc(uid);
    await doc.set(data, SetOptions(merge: true));

    if (name != null && _auth.currentUser?.uid == uid) {
      await _auth.currentUser?.updateDisplayName(name);
    }
  }

  Future<UserModel> _getOrCreateUserProfile(
    User user, {
    String? fallbackName,
    String? fallbackPhone,
  }) async {
    final existing = await getUserFromFirestore(user.uid);
    if (existing != null) {
      return existing;
    }

    final created = UserModel(
      uid: user.uid,
      name: fallbackName ?? user.displayName ?? 'User',
      email: user.email ?? '',
      phone: fallbackPhone,
      avatarUrl: user.photoURL,
      createdAt: DateTime.now(),
    );

    await _db
        .collection('users')
        .doc(user.uid)
        .set(created.toMap(), SetOptions(merge: true));
    return created;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
