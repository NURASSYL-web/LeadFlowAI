import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static const String _setupMessage =
      'Firebase config is not bundled in this repository build yet.';

  static String? get currentPlatformConfigurationError => _setupMessage;

  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(_setupMessage);
  }

  static FirebaseOptions placeholderForPlatform(TargetPlatform platform) {
    return const FirebaseOptions(
      apiKey: 'placeholder',
      appId: 'placeholder',
      messagingSenderId: 'placeholder',
      projectId: 'placeholder',
    );
  }
}
