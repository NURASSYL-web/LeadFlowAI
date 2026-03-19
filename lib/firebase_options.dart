import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static const String _nonWebSetupMessage =
      'Firebase config is not bundled for this platform in the repository build yet.';

  static String? get currentPlatformConfigurationError {
    if (kIsWeb) {
      return null;
    }
    return _nonWebSetupMessage;
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    throw UnsupportedError(_nonWebSetupMessage);
  }

  static FirebaseOptions placeholderForPlatform(TargetPlatform platform) {
    return const FirebaseOptions(
      apiKey: 'placeholder',
      appId: 'placeholder',
      messagingSenderId: 'placeholder',
      projectId: 'placeholder',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBn7c3W_mZ3z3ztZdk4NNt0ZQd57Q2WGEM',
    appId: '1:279689050864:web:565ead8645c5786c882035',
    messagingSenderId: '279689050864',
    projectId: 'leadflow-9d3b0',
    authDomain: 'leadflow-9d3b0.firebaseapp.com',
    storageBucket: 'leadflow-9d3b0.firebasestorage.app',
    measurementId: 'G-F3CYPD8XZH',
  );
}
