import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/config/app_providers.dart';
import '../../auth/data/auth_providers.dart';
import '../../catalogue/data/catalogue_providers.dart';
import '../../catalogue/models/salon_product.dart';
import '../../inventory/data/inventory_providers.dart';
import '../models/inventory_scan.dart';
import '../models/scan_analysis_result.dart';
import '../models/scan_product_result.dart';
import '../services/api_product_recognition_service.dart';
import '../services/mock_product_recognition_service.dart';
import '../services/openai_product_recognition_service.dart';
import '../services/product_recognition_service.dart';

final productRecognitionServiceProvider =
    Provider<ProductRecognitionService>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useMockAi || !config.hasAiCredentials) {
    return const MockProductRecognitionService();
  }
  if (config.usesOpenAi) {
    return OpenAIProductRecognitionService(
      apiKey: config.aiApiKey,
      model: config.aiModel,
    );
  }
  return APIProductRecognitionService(
      endpoint: config.aiEndpoint, apiKey: config.aiApiKey);
});

final currentScanControllerProvider =
    StateNotifierProvider<CurrentScanController, CurrentScanState>((ref) {
  return CurrentScanController(ref);
});

class CurrentScanState {
  const CurrentScanState({
    this.image,
    this.analysis,
    this.products = const [],
    this.stage = 'Ready',
    this.isProcessing = false,
    this.errorMessage,
  });

  final File? image;
  final ScanAnalysisResult? analysis;
  final List<ScanProductResult> products;
  final String stage;
  final bool isProcessing;
  final String? errorMessage;

  int get totalUnits => products.fold<int>(
      0, (total, product) => total + product.confirmedQuantity);

  CurrentScanState copyWith({
    File? image,
    bool clearImage = false,
    ScanAnalysisResult? analysis,
    bool clearAnalysis = false,
    List<ScanProductResult>? products,
    String? stage,
    bool? isProcessing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CurrentScanState(
      image: clearImage ? null : image ?? this.image,
      analysis: clearAnalysis ? null : analysis ?? this.analysis,
      products: products ?? this.products,
      stage: stage ?? this.stage,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class CurrentScanController extends StateNotifier<CurrentScanState> {
  CurrentScanController(this.ref) : super(const CurrentScanState());

  final Ref ref;
  final _uuid = const Uuid();

  void setImage(File image) {
    state = CurrentScanState(image: image, stage: 'Image ready');
  }

  void reset() {
    state = const CurrentScanState();
  }

  Future<void> analyzeImage() async {
    final image = state.image;
    if (image == null) {
      state = state.copyWith(
          errorMessage: 'Choose or capture an image before analysis.');
      return;
    }

    state = state.copyWith(
        isProcessing: true, stage: 'Loading catalogue', clearError: true);
    try {
      final catalogue = await ref.read(productCatalogueProvider.future);
      state = state.copyWith(stage: 'Identifying visible products');
      final service = ref.read(productRecognitionServiceProvider);
      final analysis =
          await service.analyzeImage(image: image, catalogue: catalogue);
      final products = analysis.detectedProducts
          .map(ScanProductResult.fromDetected)
          .toList();
      state = state.copyWith(
        analysis: analysis,
        products: products,
        stage: 'Review results',
        isProcessing: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isProcessing: false,
        stage: 'Analysis failed',
        errorMessage: error.toString(),
      );
    }
  }

  void updateProduct(ScanProductResult product) {
    state = state.copyWith(
      products: [
        for (final existing in state.products)
          if (existing.temporaryId == product.temporaryId)
            product
          else
            existing,
      ],
    );
  }

  void deleteProduct(String temporaryId) {
    state = state.copyWith(
        products: state.products
            .where((product) => product.temporaryId != temporaryId)
            .toList());
  }

  void addManualProduct(SalonProduct? product) {
    final selected = product;
    final result = ScanProductResult(
      temporaryId: 'manual_${_uuid.v4()}',
      detectedName: selected?.name ?? 'Manual product',
      confirmedName: selected?.name ?? 'Manual product',
      originalQuantity: 0,
      confirmedQuantity: 1,
      matchedProductId: selected?.id,
      brand: selected?.brand ?? '',
      category: selected?.category ?? '',
      packagingType: selected?.packagingType ?? '',
      shadeCode: selected?.shadeCode ?? '',
      recognitionConfidence: 0,
      catalogueMatchConfidence: selected == null ? 0 : 1,
      wasCorrected: true,
      notes: 'Added manually by stylist.',
      warnings: const ['Manual entry.'],
    );
    state = state.copyWith(products: [...state.products, result]);
  }

  Future<InventoryScan> completeScan() async {
    final image = state.image;
    final user = ref.read(authControllerProvider).valueOrNull;
    final config = ref.read(appConfigProvider);
    final analysis = state.analysis;
    final createdAt = DateTime.now();
    final scan = InventoryScan(
      id: 'scan_${_uuid.v4()}',
      userId: user?.id ?? 'local_demo_user',
      salonId: user?.salonId ?? config.demoSalonId,
      imageUrl: '',
      localImagePath: image?.path ?? '',
      createdAt: createdAt,
      status: 'completed',
      scanQuality: analysis?.scanQuality ?? 'unknown',
      totalUniqueProducts: state.products.length,
      totalUnits: state.totalUnits,
      warnings: analysis?.warnings ?? const [],
      products: state.products,
    );
    final repository = await ref.read(inventoryRepositoryProvider.future);
    await repository.saveScan(scan, image: image);
    ref.invalidate(scanHistoryProvider);
    ref.invalidate(inventoryRecordsProvider);
    return scan;
  }
}
