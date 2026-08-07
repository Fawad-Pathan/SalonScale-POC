import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../models/salon_user.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<SalonUser?>>((ref) {
  return AuthController(ref);
});

class AuthController extends StateNotifier<AsyncValue<SalonUser?>> {
  AuthController(this.ref) : super(const AsyncValue.data(null));

  final Ref ref;

  Future<void> restoreSession() async {
    final firebaseReady = await ref
        .read(firebaseBootstrapProvider.future)
        .catchError((_) => false);
    final config = ref.read(appConfigProvider);
    if (!firebaseReady) {
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      state = AsyncValue.data(
        SalonUser(
          id: user.uid,
          salonId: config.demoSalonId,
          displayName:
              user.isAnonymous ? 'Demo Stylist' : user.email ?? 'Salon User',
          isAnonymous: user.isAnonymous,
        ),
      );
    }
  }

  Future<void> signInAnonymously() async {
    state = const AsyncValue.loading();
    final firebaseReady = await ref
        .read(firebaseBootstrapProvider.future)
        .catchError((_) => false);
    final config = ref.read(appConfigProvider);
    if (!firebaseReady) {
      state = AsyncValue.data(
        SalonUser(
          id: 'local_demo_user',
          salonId: config.demoSalonId,
          displayName: 'Demo Stylist',
          isAnonymous: true,
        ),
      );
      return;
    }

    try {
      final credential = await FirebaseAuth.instance.signInAnonymously();
      final user = credential.user;
      state = AsyncValue.data(
        SalonUser(
          id: user?.uid ?? 'firebase_anonymous_user',
          salonId: config.demoSalonId,
          displayName: 'Demo Stylist',
          isAnonymous: true,
        ),
      );
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    final firebaseReady = await ref
        .read(firebaseBootstrapProvider.future)
        .catchError((_) => false);
    if (firebaseReady) {
      await FirebaseAuth.instance.signOut();
    }
    state = const AsyncValue.data(null);
  }
}
