import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/firebase_bootstrap_service.dart';
import 'app_config.dart';

final appConfigProvider =
    Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

final firebaseBootstrapProvider = FutureProvider<bool>((ref) {
  return const FirebaseBootstrapService().initialize();
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});
