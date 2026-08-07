import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/app_exception.dart';
import '../models/salon_product.dart';

class CatalogueService {
  const CatalogueService({this.assetPath = 'assets/data/products.json'});

  final String assetPath;
  static const localProductsKey = 'salonscale_catalogue_products';

  Future<List<SalonProduct>> loadLocalCatalogue() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const CatalogueException(
            'Product catalogue must be a JSON list.');
      }
      return decoded
          .whereType<Map>()
          .map((item) => SalonProduct.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on CatalogueException {
      rethrow;
    } catch (error) {
      throw CatalogueException('Unable to load product catalogue.',
          cause: error);
    }
  }

  Future<List<SalonProduct>> loadCatalogue(
      SharedPreferences preferences) async {
    final bundled = await loadLocalCatalogue();
    final local = loadSavedProducts(preferences);
    final byId = {
      for (final product in bundled) product.id: product,
      for (final product in local) product.id: product,
    };
    return byId.values.toList()
      ..sort((left, right) => left.name.compareTo(right.name));
  }

  List<SalonProduct> loadSavedProducts(SharedPreferences preferences) {
    final raw = preferences.getString(localProductsKey);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map>()
        .map((item) => SalonProduct.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> saveProducts(
      SharedPreferences preferences, List<SalonProduct> products) async {
    await preferences.setString(
      localProductsKey,
      jsonEncode(products.map((product) => product.toJson()).toList()),
    );
  }

  Future<void> upsertSavedProduct(
      SharedPreferences preferences, SalonProduct product) async {
    final saved = loadSavedProducts(preferences);
    final next = [
      product,
      ...saved.where((existing) => existing.id != product.id),
    ]..sort((left, right) => left.name.compareTo(right.name));
    await saveProducts(preferences, next);
  }

  Future<void> archiveSavedProduct(
      SharedPreferences preferences, SalonProduct product) async {
    await upsertSavedProduct(
      preferences,
      product.copyWith(
        recognitionStatus: ProductRecognitionStatus.archived,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> uploadToFirestore({
    required FirebaseFirestore firestore,
    required String salonId,
    required List<SalonProduct> products,
  }) async {
    final batch = firestore.batch();
    final collection =
        firestore.collection('salons').doc(salonId).collection('products');
    for (final product in products) {
      batch.set(collection.doc(product.id), product.toJson());
    }
    await batch.commit();
  }
}
