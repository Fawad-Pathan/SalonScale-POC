import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radius.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../catalogue/models/salon_product.dart';
import '../../catalogue/presentation/product_reference_image.dart';
import '../models/scan_product_result.dart';

class ProductResultCard extends StatelessWidget {
  const ProductResultCard({
    required this.product,
    required this.catalogue,
    required this.onChanged,
    required this.onDeleted,
    super.key,
  });

  final ScanProductResult product;
  final List<SalonProduct> catalogue;
  final ValueChanged<ScanProductResult> onChanged;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final confidence = (product.recognitionConfidence * 100).round();
    final matchedProduct = catalogue
        .where((item) => item.id == product.matchedProductId)
        .firstOrNull;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'product-${product.temporaryId}',
                child: ProductReferenceImage(
                  imagePath: matchedProduct?.displayImage ??
                      product.cameraCropPath ??
                      '',
                  size: 76,
                  borderRadius: AppRadius.md,
                  icon: Icons.spa_rounded,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand.isEmpty ? 'Unknown brand' : product.brand,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.indigo,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      product.confirmedName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      matchedProduct == null
                          ? 'Catalogue match needs review'
                          : 'Matched: ${matchedProduct.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: () => _showEditDialog(context),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDeleted,
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: product.recognitionConfidence.clamp(0, 1),
              backgroundColor: AppColors.subtle,
              valueColor: AlwaysStoppedAnimation<Color>(
                confidence >= 80
                    ? AppColors.indigo
                    : confidence >= 60
                        ? AppColors.amber
                        : AppColors.rose,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    _Pill(
                        label: product.packagingType.isEmpty
                            ? 'Packaging?'
                            : product.packagingType),
                    _Pill(
                        label: product.shadeCode.isEmpty
                            ? 'No shade'
                            : product.shadeCode),
                    _Pill(label: '$confidence% confidence'),
                  ],
                ),
              ),
              _QuantityStepper(
                value: product.confirmedQuantity,
                onChanged: (value) => onChanged(
                  product.copyWith(
                    confirmedQuantity: value,
                    wasCorrected: true,
                  ),
                ),
              ),
            ],
          ),
          if (product.warnings.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              product.warnings.join(' '),
              style: const TextStyle(
                color: AppColors.rose,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final nameController = TextEditingController(text: product.confirmedName);
    final quantityController =
        TextEditingController(text: product.confirmedQuantity.toString());
    var selectedProductId =
        catalogue.any((item) => item.id == product.matchedProductId)
            ? product.matchedProductId!
            : 'none';

    final updated = await showDialog<ScanProductResult>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final selected = catalogue
                .where((item) => item.id == selectedProductId)
                .firstOrNull;
            return AlertDialog(
              title: const Text('Edit product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const Key('edit-product-name'),
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'Product name'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      key: const Key('edit-product-quantity'),
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<String>(
                      initialValue: selectedProductId,
                      decoration:
                          const InputDecoration(labelText: 'Catalogue match'),
                      items: [
                        const DropdownMenuItem(
                            value: 'none', child: Text('No match')),
                        ...catalogue.map((item) => DropdownMenuItem(
                            value: item.id, child: Text(item.name))),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedProductId = value ?? 'none';
                          final selected = catalogue
                              .where((item) => item.id == selectedProductId)
                              .firstOrNull;
                          if (selected != null) {
                            nameController.text = selected.name;
                          }
                        });
                      },
                    ),
                    if (selected != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                            '${selected.brand} - ${selected.packagingType} - ${selected.shadeCode}'),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel')),
                ElevatedButton(
                  key: const Key('save-product-edit'),
                  onPressed: () {
                    final quantity =
                        int.tryParse(quantityController.text.trim()) ??
                            product.confirmedQuantity;
                    final selected = catalogue
                        .where((item) => item.id == selectedProductId)
                        .firstOrNull;
                    Navigator.of(context).pop(
                      product.copyWith(
                        confirmedName: nameController.text.trim().isEmpty
                            ? product.confirmedName
                            : nameController.text.trim(),
                        confirmedQuantity: quantity < 0 ? 0 : quantity,
                        matchedProductId: selected?.id,
                        clearMatchedProductId: selected == null,
                        brand: selected?.brand ?? product.brand,
                        category: selected?.category ?? product.category,
                        packagingType:
                            selected?.packagingType ?? product.packagingType,
                        shadeCode: selected?.shadeCode ?? product.shadeCode,
                        catalogueMatchConfidence: selected == null ? 0 : 1,
                        wasCorrected: true,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated != null) {
      onChanged(updated);
    }
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.lavender,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decrease quantity',
            onPressed: value <= 0 ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove_rounded),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              value.toString(),
              key: ValueKey(value),
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Increase quantity',
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}
