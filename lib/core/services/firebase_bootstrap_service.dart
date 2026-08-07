import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

class FirebaseBootstrapService {
  const FirebaseBootstrapService();

  Future<bool> initialize() async {
    if (Firebase.apps.isNotEmpty) {
      return true;
    }

    try {
      if (DefaultFirebaseOptions.isConfigured) {
        await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform);
      } else {
        await Firebase.initializeApp();
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
