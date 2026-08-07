import 'package:collection/collection.dart';

import '../../../core/utils/json_helpers.dart';

enum ProductRecognitionStatus {
  draft('Draft'),
  needsImages('Needs Images'),
  ready('Ready'),
  needsReview('Needs Review'),
  improving('Improving'),
  archived('Archived');

  const ProductRecognitionStatus(this.label);

  final String label;

  static ProductRecognitionStatus fromJson(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return switch (normalized) {
      'draft' => ProductRecognitionStatus.draft,
      'needs_images' => ProductRecognitionStatus.needsImages,
      'ready' => ProductRecognitionStatus.ready,
      'needs_review' => ProductRecognitionStatus.needsReview,
      'improving' => ProductRecognitionStatus.improving,
      'archived' => ProductRecognitionStatus.archived,
      _ => ProductRecognitionStatus.draft,
    };
  }

  String get jsonValue => name;
}

class SalonProduct {
  const SalonProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.packagingType,
    required this.shadeCode,
    required this.aliases,
    required this.imageUrl,
    this.sku = '',
    this.barcode,
    this.formFactor = '',
    this.sizeLabel = '',
    this.packageDimensions = '',
    this.primaryReferenceImage = '',
    this.referenceImages = const [],
    this.currentQuantity = 0,
    this.recognitionStatus = ProductRecognitionStatus.draft,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String brand;
  final String category;
  final String packagingType;
  final String shadeCode;
  final List<String> aliases;
  final String imageUrl;
  final String sku;
  final String? barcode;
  final String formFactor;
  final String sizeLabel;
  final String packageDimensions;
  final String primaryReferenceImage;
  final List<String> referenceImages;
  final int currentQuantity;
  final ProductRecognitionStatus recognitionStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayImage =>
      primaryReferenceImage.isNotEmpty ? primaryReferenceImage : imageUrl;

  String get displayFormFactor =>
      formFactor.isNotEmpty ? formFactor : packagingType;

  String get displaySku => sku.isNotEmpty ? sku : id;

  List<String> get allReferenceImages {
    final images = <String>[
      if (displayImage.isNotEmpty) displayImage,
      ...referenceImages,
    ];
    return images.toSet().toList();
  }

  bool get isRecognitionReady {
    return name.trim().isNotEmpty &&
        brand.trim().isNotEmpty &&
        category.trim().isNotEmpty &&
        displayFormFactor.trim().isNotEmpty &&
        allReferenceImages.isNotEmpty &&
        (sku.trim().isNotEmpty ||
            barcode?.trim().isNotEmpty == true ||
            id.trim().isNotEmpty);
  }

  factory SalonProduct.fromJson(Map<String, dynamic> json) {
    final imageUrl = readString(json, 'imageUrl',
        fallback: readString(json, 'primaryReferenceImage'));
    final primaryReferenceImage =
        readString(json, 'primaryReferenceImage', fallback: imageUrl);
    final status = ProductRecognitionStatus.fromJson(
      readString(json, 'recognitionStatus',
          fallback: readString(json, 'aiStatus')),
    );
    return SalonProduct(
      id: readString(json, 'id'),
      name: readString(json, 'name'),
      brand: readString(json, 'brand'),
      category: readString(json, 'category'),
      packagingType: readString(json, 'packagingType'),
      shadeCode: readString(json, 'shadeCode'),
      aliases: readStringList(json, 'aliases'),
      imageUrl: imageUrl,
      sku: readString(json, 'sku',
          fallback:
              readString(json, 'internalId', fallback: readString(json, 'id'))),
      barcode: readNullableString(json, 'barcode'),
      formFactor: readString(json, 'formFactor',
          fallback: readString(json, 'packagingType')),
      sizeLabel: readString(json, 'sizeLabel',
          fallback: [
            readString(json, 'size'),
            readString(json, 'unit'),
          ].where((item) => item.trim().isNotEmpty).join(' ')),
      packageDimensions: readString(json, 'packageDimensions'),
      primaryReferenceImage: primaryReferenceImage,
      referenceImages: readStringList(json, 'referenceImages'),
      currentQuantity:
          readInt(json, 'currentQuantity', fallback: readInt(json, 'quantity')),
      recognitionStatus: status == ProductRecognitionStatus.draft &&
              primaryReferenceImage.isEmpty &&
              imageUrl.isEmpty
          ? ProductRecognitionStatus.needsImages
          : status,
      createdAt: json.containsKey('createdAt')
          ? parseDateTime(json['createdAt'], fallback: DateTime.now())
          : null,
      updatedAt: json.containsKey('updatedAt')
          ? parseDateTime(json['updatedAt'], fallback: DateTime.now())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'category': category,
      'packagingType': packagingType,
      'shadeCode': shadeCode,
      'aliases': aliases,
      'imageUrl': imageUrl,
      'sku': sku,
      if (barcode != null) 'barcode': barcode,
      'formFactor': displayFormFactor,
      'sizeLabel': sizeLabel,
      'packageDimensions': packageDimensions,
      'primaryReferenceImage': primaryReferenceImage,
      'referenceImages': referenceImages,
      'currentQuantity': currentQuantity,
      'recognitionStatus': recognitionStatus.jsonValue,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  SalonProduct copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
    String? packagingType,
    String? shadeCode,
    List<String>? aliases,
    String? imageUrl,
    String? sku,
    String? barcode,
    String? formFactor,
    String? sizeLabel,
    String? packageDimensions,
    String? primaryReferenceImage,
    List<String>? referenceImages,
    int? currentQuantity,
    ProductRecognitionStatus? recognitionStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalonProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      packagingType: packagingType ?? this.packagingType,
      shadeCode: shadeCode ?? this.shadeCode,
      aliases: aliases ?? this.aliases,
      imageUrl: imageUrl ?? this.imageUrl,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      formFactor: formFactor ?? this.formFactor,
      sizeLabel: sizeLabel ?? this.sizeLabel,
      packageDimensions: packageDimensions ?? this.packageDimensions,
      primaryReferenceImage:
          primaryReferenceImage ?? this.primaryReferenceImage,
      referenceImages: referenceImages ?? this.referenceImages,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      recognitionStatus: recognitionStatus ?? this.recognitionStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is SalonProduct &&
            other.id == id &&
            other.name == name &&
            other.brand == brand &&
            other.category == category &&
            other.packagingType == packagingType &&
            other.shadeCode == shadeCode &&
            const ListEquality<String>().equals(other.aliases, aliases) &&
            other.imageUrl == imageUrl &&
            other.sku == sku &&
            other.barcode == barcode &&
            other.formFactor == formFactor &&
            other.sizeLabel == sizeLabel &&
            other.packageDimensions == packageDimensions &&
            other.primaryReferenceImage == primaryReferenceImage &&
            const ListEquality<String>()
                .equals(other.referenceImages, referenceImages) &&
            other.currentQuantity == currentQuantity &&
            other.recognitionStatus == recognitionStatus &&
            other.createdAt == createdAt &&
            other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      brand,
      category,
      packagingType,
      shadeCode,
      Object.hashAll(aliases),
      imageUrl,
      sku,
      barcode,
      formFactor,
      sizeLabel,
      packageDimensions,
      primaryReferenceImage,
      Object.hashAll(referenceImages),
      currentQuantity,
      recognitionStatus,
      createdAt,
      updatedAt,
    );
  }
}
