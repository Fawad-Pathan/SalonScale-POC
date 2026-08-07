import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radius.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../data/catalogue_providers.dart';
import '../models/salon_product.dart';
import 'product_reference_image.dart';

class CatalogueProductFormScreen extends ConsumerStatefulWidget {
  const CatalogueProductFormScreen({super.key, this.product});

  final SalonProduct? product;

  @override
  ConsumerState<CatalogueProductFormScreen> createState() =>
      _CatalogueProductFormScreenState();
}

class _CatalogueProductFormScreenState
    extends ConsumerState<CatalogueProductFormScreen> {
  static const categories = [
    'Shampoo',
    'Conditioner',
    'Hair Colour',
    'Developer',
    'Toner',
    'Treatment',
    'Styling Product',
    'Disinfectant',
    'Gloves',
    'Foil',
    'Towels',
    'Other Supplies',
  ];

  static const formFactors = [
    'Bottle',
    'Pump Bottle',
    'Spray Bottle',
    'Tube',
    'Jar',
    'Tub',
    'Box',
    'Pouch',
    'Can',
    'Packet',
  ];

  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _brand = TextEditingController(text: widget.product?.brand ?? '');
  late final _sku =
      TextEditingController(text: widget.product?.displaySku ?? '');
  late final _barcode =
      TextEditingController(text: widget.product?.barcode ?? '');
  late final _size =
      TextEditingController(text: widget.product?.sizeLabel ?? '');
  late final _dimensions =
      TextEditingController(text: widget.product?.packageDimensions ?? '');
  late final _quantity = TextEditingController(
      text: (widget.product?.currentQuantity ?? 0).toString());
  late var _category =
      _initialValue(categories, widget.product?.category, 'Other Supplies');
  late var _formFactor =
      _initialValue(formFactors, widget.product?.displayFormFactor, 'Bottle');
  late var _status =
      widget.product?.recognitionStatus ?? ProductRecognitionStatus.draft;
  late var _primaryImage = widget.product?.displayImage ?? '';
  late var _referenceImages = widget.product?.referenceImages.toList() ?? [];
  var _isSaving = false;

  String _initialValue(List<String> values, String? value, String fallback) {
    final candidate = value?.trim();
    if (candidate != null && values.contains(candidate)) {
      return candidate;
    }
    return fallback;
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _sku.dispose();
    _barcode.dispose();
    _size.dispose();
    _dimensions.dispose();
    _quantity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.product == null ? 'Add Product' : 'Edit Product';
    final imageWarnings = _imageWarnings;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProductReferenceImage(
                          imagePath: _primaryImage,
                          size: 92,
                          borderRadius: AppRadius.lg,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SecondaryButton(
                                label: 'Capture front',
                                icon: Icons.camera_alt_outlined,
                                onPressed: () => _pickImage(ImageSource.camera),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SecondaryButton(
                                label: 'Add angle',
                                icon: Icons.photo_library_outlined,
                                onPressed: () =>
                                    _pickImage(ImageSource.gallery),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (imageWarnings.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final warning in imageWarnings)
                            Chip(
                              label: Text(warning),
                              backgroundColor:
                                  AppColors.rose.withValues(alpha: 0.10),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _TextField(
                controller: _name,
                label: 'Product name',
                required: true,
              ),
              _TextField(
                controller: _brand,
                label: 'Brand',
                required: true,
              ),
              _DropdownField(
                label: 'Category',
                value: _category,
                values: categories,
                onChanged: (value) => setState(() => _category = value),
              ),
              _DropdownField(
                label: 'Form factor',
                value: _formFactor,
                values: formFactors,
                onChanged: (value) => setState(() => _formFactor = value),
              ),
              _TextField(controller: _size, label: 'Size and unit'),
              _TextField(controller: _sku, label: 'SKU or internal ID'),
              _TextField(controller: _barcode, label: 'Barcode or UPC'),
              _TextField(controller: _dimensions, label: 'Package dimensions'),
              _TextField(
                controller: _quantity,
                label: 'Current inventory quantity',
                keyboardType: TextInputType.number,
              ),
              _DropdownField(
                label: 'AI status',
                value: _status.label,
                values: ProductRecognitionStatus.values
                    .map((item) => item.label)
                    .toList(),
                onChanged: (value) => setState(
                  () => _status = ProductRecognitionStatus.values.firstWhere(
                    (item) => item.label == value,
                    orElse: () => ProductRecognitionStatus.draft,
                  ),
                ),
              ),
              if (_referenceImages.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Reference images',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 104,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _referenceImages.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final image = _referenceImages[index];
                      return InkWell(
                        onTap: () => setState(() => _primaryImage = image),
                        child: ProductReferenceImage(
                          imagePath: image,
                          size: 92,
                          borderRadius: AppRadius.lg,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: PrimaryButton(
          label: _isSaving ? 'Saving' : 'Save product',
          icon: Icons.check_rounded,
          onPressed: _isSaving ? null : _save,
        ),
      ),
    );
  }

  List<String> get _imageWarnings {
    final warnings = <String>[];
    if (_primaryImage.isEmpty) {
      warnings.add('Missing label image');
    }
    if (_referenceImages.length < 2) {
      warnings.add('Needs more angles');
    }
    return warnings;
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker()
        .pickImage(source: source, imageQuality: 88, maxWidth: 1800);
    if (picked == null) {
      return;
    }
    setState(() {
      _primaryImage = _primaryImage.isEmpty ? picked.path : _primaryImage;
      _referenceImages = {..._referenceImages, picked.path}.toList();
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    final now = DateTime.now();
    final id = widget.product?.id ?? 'catalogue_${const Uuid().v4()}';
    final status = _inferStatus();
    final product = SalonProduct(
      id: id,
      name: _name.text.trim(),
      brand: _brand.text.trim(),
      category: _category,
      packagingType: _formFactor,
      shadeCode: widget.product?.shadeCode ?? '',
      aliases: widget.product?.aliases ?? const [],
      imageUrl: widget.product?.imageUrl ?? '',
      sku: _sku.text.trim(),
      barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
      formFactor: _formFactor,
      sizeLabel: _size.text.trim(),
      packageDimensions: _dimensions.text.trim(),
      primaryReferenceImage: _primaryImage,
      referenceImages: _referenceImages,
      currentQuantity: int.tryParse(_quantity.text.trim()) ?? 0,
      recognitionStatus: status,
      createdAt: widget.product?.createdAt ?? now,
      updatedAt: now,
    );
    await ref.read(catalogueControllerProvider).saveProduct(product);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  ProductRecognitionStatus _inferStatus() {
    if (_status == ProductRecognitionStatus.archived) {
      return _status;
    }
    final hasIdentity =
        _sku.text.trim().isNotEmpty || _barcode.text.trim().isNotEmpty;
    if (_name.text.trim().isEmpty ||
        _brand.text.trim().isEmpty ||
        _category.trim().isEmpty ||
        _formFactor.trim().isEmpty ||
        !hasIdentity) {
      return ProductRecognitionStatus.draft;
    }
    if (_primaryImage.isEmpty) {
      return ProductRecognitionStatus.needsImages;
    }
    return _status == ProductRecognitionStatus.draft
        ? ProductRecognitionStatus.ready
        : _status;
  }
}

class _TextField extends StatelessWidget {
  const _TextField({
    required this.controller,
    required this.label,
    this.required = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final bool required;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label),
        validator: required
            ? (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null
            : null,
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          for (final item in values)
            DropdownMenuItem(value: item, child: Text(item)),
        ],
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}
