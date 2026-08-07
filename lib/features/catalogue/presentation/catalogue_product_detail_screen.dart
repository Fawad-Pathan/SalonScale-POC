import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../app/routes.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radius.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_chip.dart';
import '../data/catalogue_providers.dart';
import '../models/salon_product.dart';
import 'product_reference_image.dart';

class CatalogueProductDetailScreen extends ConsumerWidget {
  const CatalogueProductDetailScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productCatalogueProvider);
    return Scaffold(
      body: SafeArea(
        child: products.when(
          data: (items) {
            final matches = items.where((item) => item.id == productId);
            if (matches.isEmpty) {
              return const EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Product not found',
                message: 'The selected catalogue product could not be loaded.',
              );
            }
            return _ProductDetail(product: matches.first);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(error.toString())),
        ),
      ),
    );
  }
}

class _ProductDetail extends ConsumerWidget {
  const _ProductDetail({required this.product});

  final SalonProduct product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = product.allReferenceImages;
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 128),
          children: [
            Row(
              children: [
                IconButton.filledTonal(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.of(context).pushNamed(
                        AppRoutes.catalogueProductForm,
                        arguments: product,
                      );
                    }
                    if (value == 'archive') {
                      ref
                          .read(catalogueControllerProvider)
                          .archiveProduct(product);
                      Navigator.of(context).pop();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit product')),
                    PopupMenuItem(
                        value: 'archive', child: Text('Archive product')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ProductReferenceImage(
              imagePath: product.displayImage,
              size: 220,
              borderRadius: AppRadius.xl,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              product.brand.isEmpty ? 'Unknown brand' : product.brand,
              style: const TextStyle(
                color: AppColors.indigo,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              product.name,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                StatusChip(label: product.recognitionStatus.label),
                StatusChip(label: product.category),
                StatusChip(label: product.displayFormFactor),
                StatusChip(label: 'Qty ${product.currentQuantity}'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                children: [
                  _DetailRow(label: 'SKU / ID', value: product.displaySku),
                  _DetailRow(
                      label: 'Barcode', value: product.barcode ?? 'Not set'),
                  _DetailRow(
                      label: 'Size',
                      value: product.sizeLabel.isEmpty
                          ? 'Unspecified'
                          : product.sizeLabel),
                  _DetailRow(
                      label: 'Dimensions',
                      value: product.packageDimensions.isEmpty
                          ? 'Unspecified'
                          : product.packageDimensions),
                  _DetailRow(
                    label: 'Date added',
                    value: product.createdAt == null
                        ? 'Bundled'
                        : DateFormat.yMMMd().format(product.createdAt!),
                  ),
                  _DetailRow(
                    label: 'Date updated',
                    value: product.updatedAt == null
                        ? 'Bundled'
                        : DateFormat.yMMMd()
                            .add_jm()
                            .format(product.updatedAt!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Reference images',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 112,
              child: images.isEmpty
                  ? const AppCard(
                      child: Center(child: Text('No reference images yet.')),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final image = images[index];
                        return Column(
                          children: [
                            ProductReferenceImage(
                              imagePath: image,
                              size: 84,
                              borderRadius: AppRadius.lg,
                            ),
                            if (image != product.displayImage)
                              TextButton(
                                onPressed: () =>
                                    _setPrimaryImage(ref, product, image),
                                child: const Text('Primary'),
                              ),
                          ],
                        );
                      },
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.md),
                      itemCount: images.length,
                    ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _WarningChip(
                    visible: product.name.trim().isEmpty,
                    label: 'Missing name'),
                _WarningChip(
                    visible: product.brand.trim().isEmpty,
                    label: 'Missing brand'),
                _WarningChip(
                    visible: product.category.trim().isEmpty,
                    label: 'Missing category'),
                _WarningChip(
                    visible: images.isEmpty, label: 'Needs clear image'),
                _WarningChip(
                    visible: product.sku.trim().isEmpty &&
                        product.barcode?.trim().isNotEmpty != true,
                    label: 'Needs SKU or barcode'),
              ],
            ),
          ],
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Add image',
                  icon: Icons.add_a_photo_outlined,
                  onPressed: () => _captureReferenceImage(context, ref),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PrimaryButton(
                  label: 'Edit',
                  icon: Icons.edit_rounded,
                  onPressed: () => Navigator.of(context).pushNamed(
                    AppRoutes.catalogueProductForm,
                    arguments: product,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _captureReferenceImage(
      BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) {
      return;
    }
    final picked = await ImagePicker()
        .pickImage(source: source, imageQuality: 88, maxWidth: 1800);
    if (picked == null) {
      return;
    }
    final nextImages = {...product.referenceImages, picked.path}.toList();
    final updated = product.copyWith(
      primaryReferenceImage: product.displayImage.isEmpty
          ? picked.path
          : product.primaryReferenceImage,
      referenceImages: nextImages,
      recognitionStatus: ProductRecognitionStatus.ready,
      updatedAt: DateTime.now(),
    );
    await ref.read(catalogueControllerProvider).saveProduct(updated);
  }

  Future<void> _setPrimaryImage(
      WidgetRef ref, SalonProduct product, String image) async {
    await ref.read(catalogueControllerProvider).saveProduct(
          product.copyWith(
            primaryReferenceImage: image,
            referenceImages:
                product.referenceImages.where((item) => item != image).toList(),
            updatedAt: DateTime.now(),
          ),
        );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningChip extends StatelessWidget {
  const _WarningChip({required this.visible, required this.label});

  final bool visible;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    return Chip(
      avatar: const Icon(Icons.warning_amber_rounded, size: 18),
      label: Text(label),
      backgroundColor: AppColors.rose.withValues(alpha: 0.10),
      side: BorderSide(color: AppColors.rose.withValues(alpha: 0.20)),
    );
  }
}
