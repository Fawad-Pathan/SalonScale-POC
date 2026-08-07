import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../../auth/data/auth_providers.dart';
import '../../inventory/models/inventory_record.dart';
import '../../inventory/services/firestore_inventory_repository.dart';
import '../../inventory/services/inventory_repository.dart';
import '../../inventory/services/local_inventory_repository.dart';
import '../../scanning/models/inventory_scan.dart';

final salonIdProvider = Provider<String>((ref) {
  final config = ref.watch(appConfigProvider);
  return ref.watch(authControllerProvider).valueOrNull?.salonId ??
      config.demoSalonId;
});

final inventoryRepositoryProvider =
    FutureProvider<InventoryRepository>((ref) async {
  final firebaseReady = await ref
      .watch(firebaseBootstrapProvider.future)
      .catchError((_) => false);
  if (firebaseReady) {
    return FirestoreInventoryRepository();
  }
  final preferences = await ref.watch(sharedPreferencesProvider.future);
  return LocalInventoryRepository(preferences);
});

final scanHistoryProvider = StreamProvider<List<InventoryScan>>((ref) async* {
  final repository = await ref.watch(inventoryRepositoryProvider.future);
  final salonId = ref.watch(salonIdProvider);
  yield* repository.watchScans(salonId);
});

final inventoryRecordsProvider =
    StreamProvider<List<InventoryRecord>>((ref) async* {
  final repository = await ref.watch(inventoryRepositoryProvider.future);
  final salonId = ref.watch(salonIdProvider);
  yield* repository.watchInventory(salonId);
});

final scanDetailProvider =
    FutureProvider.family<InventoryScan?, String>((ref, scanId) async {
  final repository = await ref.watch(inventoryRepositoryProvider.future);
  final salonId = ref.watch(salonIdProvider);
  return repository.getScan(salonId: salonId, scanId: scanId);
});
