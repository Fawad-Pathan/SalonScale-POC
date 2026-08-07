import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_providers.dart';
import '../models/salon_product.dart';
import '../services/catalogue_service.dart';

final catalogueServiceProvider =
    Provider<CatalogueService>((ref) => const CatalogueService());

final productCatalogueProvider =
    FutureProvider<List<SalonProduct>>((ref) async {
  final service = ref.watch(catalogueServiceProvider);
  final preferences = await ref.watch(sharedPreferencesProvider.future);
  return service.loadCatalogue(preferences);
});

final catalogueControllerProvider = Provider<CatalogueController>((ref) {
  return CatalogueController(ref);
});

class CatalogueController {
  const CatalogueController(this.ref);

  final Ref ref;

  Future<void> saveProduct(SalonProduct product) async {
    final preferences = await ref.read(sharedPreferencesProvider.future);
    await ref
        .read(catalogueServiceProvider)
        .upsertSavedProduct(preferences, product);
    ref.invalidate(productCatalogueProvider);
  }

  Future<void> archiveProduct(SalonProduct product) async {
    final preferences = await ref.read(sharedPreferencesProvider.future);
    await ref
        .read(catalogueServiceProvider)
        .archiveSavedProduct(preferences, product);
    ref.invalidate(productCatalogueProvider);
  }
}
