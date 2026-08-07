import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const String _projectId =
      String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String _storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const String _iosBundleId =
      String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  static const String _androidClientId =
      String.fromEnvironment('FIREBASE_ANDROID_CLIENT_ID');
  static const String _iosClientId =
      String.fromEnvironment('FIREBASE_IOS_CLIENT_ID');

  static bool get isConfigured =>
      _apiKey.isNotEmpty && _appId.isNotEmpty && _projectId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw StateError(
          'Firebase options are not configured. Use mock mode or pass Firebase dart-defines.');
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return const FirebaseOptions(
        apiKey: _apiKey,
        appId: _appId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
        iosBundleId: _iosBundleId,
        iosClientId: _iosClientId,
      );
    }
    return const FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      storageBucket: _storageBucket,
      androidClientId: _androidClientId,
    );
  }
}
