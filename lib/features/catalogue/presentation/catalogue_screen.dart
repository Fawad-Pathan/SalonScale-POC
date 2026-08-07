import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../../../app/routes.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radius.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/status_chip.dart';
import '../data/catalogue_providers.dart';
import '../models/salon_product.dart';
import '../../inventory/data/inventory_providers.dart';
import 'product_reference_image.dart';

class CatalogueScreen extends ConsumerStatefulWidget {
  const CatalogueScreen({super.key});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  var _query = '';
  var _brand = 'All';
  var _category = 'All';
  var _status = 'All';
  var _sort = 'Name';

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productCatalogueProvider);
    final inventory =
        ref.watch(inventoryRecordsProvider).valueOrNull ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Catalogue'),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Add product',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.catalogueProductForm),
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: products.when(
          data: (items) {
            final enriched = items.map((product) {
              final record = inventory.where((item) {
                return item.productId == product.id;
              }).firstOrNull;
              return record == null
                  ? product
                  : product.copyWith(currentQuantity: record.quantity);
            }).toList();
            return _CatalogueContent(
              products: _filtered(enriched),
              allProducts: enriched,
              query: _query,
              brand: _brand,
              category: _category,
              status: _status,
              sort: _sort,
              onQueryChanged: (value) => setState(() => _query = value),
              onBrandChanged: (value) => setState(() => _brand = value),
              onCategoryChanged: (value) => setState(() => _category = value),
              onStatusChanged: (value) => setState(() => _status = value),
              onSortChanged: (value) => setState(() => _sort = value),
              onArchive: _archiveProduct,
            );
          },
          loading: () => const _CatalogueLoading(),
          error: (error, _) => ErrorState(message: error.toString()),
        ),
      ),
    );
  }

  List<SalonProduct> _filtered(List<SalonProduct> products) {
    final query = _query.toLowerCase().trim();
    final filtered = products.where((product) {
      final matchesQuery = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          product.displaySku.toLowerCase().contains(query) ||
          (product.barcode ?? '').toLowerCase().contains(query);
      final matchesBrand = _brand == 'All' || product.brand == _brand;
      final matchesCategory =
          _category == 'All' || product.category == _category;
      final matchesStatus =
          _status == 'All' || product.recognitionStatus.label == _status;
      return matchesQuery && matchesBrand && matchesCategory && matchesStatus;
    }).toList();

    filtered.sort((left, right) {
      return switch (_sort) {
        'Quantity' => right.currentQuantity.compareTo(left.currentQuantity),
        'Recently added' => (right.createdAt ?? DateTime(0))
            .compareTo(left.createdAt ?? DateTime(0)),
        'Recently scanned' => (right.updatedAt ?? DateTime(0))
            .compareTo(left.updatedAt ?? DateTime(0)),
        _ => left.name.compareTo(right.name),
      };
    });
    return filtered;
  }

  Future<void> _archiveProduct(SalonProduct product) async {
    await ref.read(catalogueControllerProvider).archiveProduct(product);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} archived.')),
    );
  }
}

class _CatalogueContent extends StatelessWidget {
  const _CatalogueContent({
    required this.products,
    required this.allProducts,
    required this.query,
    required this.brand,
    required this.category,
    required this.status,
    required this.sort,
    required this.onQueryChanged,
    required this.onBrandChanged,
    required this.onCategoryChanged,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onArchive,
  });

  final List<SalonProduct> products;
  final List<SalonProduct> allProducts;
  final String query;
  final String brand;
  final String category;
  final String status;
  final String sort;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onBrandChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<SalonProduct> onArchive;

  @override
  Widget build(BuildContext context) {
    final brands = ['All', ...allProducts.map((item) => item.brand).toSet()]
      ..removeWhere((item) => item.trim().isEmpty);
    final categories = [
      'All',
      ...allProducts.map((item) => item.category).toSet(),
    ]..removeWhere((item) => item.trim().isEmpty);
    final statuses = [
      'All',
      ...ProductRecognitionStatus.values.map((item) => item.label),
    ];

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSearchField(
                  hint: 'Search product, brand, SKU, barcode',
                  onChanged: onQueryChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                _FilterRow(
                  value: brand,
                  values: brands,
                  label: 'Brand',
                  onChanged: onBrandChanged,
                ),
                _FilterRow(
                  value: category,
                  values: categories,
                  label: 'Category',
                  onChanged: onCategoryChanged,
                ),
                _FilterRow(
                  value: status,
                  values: statuses,
                  label: 'AI Status',
                  onChanged: onStatusChanged,
                ),
                _FilterRow(
                  value: sort,
                  values: const [
                    'Name',
                    'Quantity',
                    'Recently added',
                    'Recently scanned',
                  ],
                  label: 'Sort',
                  onChanged: onSortChanged,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        if (products.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No catalogue products',
              message: 'Add products to train scanner recognition.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList.separated(
              itemCount: products.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final product = products[index];
                return _CatalogueTile(
                  product: product,
                  onArchive: () => onArchive(product),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _CatalogueTile extends StatelessWidget {
  const _CatalogueTile({required this.product, required this.onArchive});

  final SalonProduct product;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.of(context).pushNamed(
        AppRoutes.catalogueProductDetails,
        arguments: product.id,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            ProductReferenceImage(
              imagePath: product.displayImage,
              size: 70,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    [
                      product.brand,
                      product.category,
                      product.displayFormFactor,
                    ].where((item) => item.trim().isNotEmpty).join(' - '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'SKU: ${product.displaySku}   Size: ${product.sizeLabel.isEmpty ? 'Unspecified' : product.sizeLabel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      StatusChip(label: product.recognitionStatus.label),
                      StatusChip(label: 'Inventory ${product.currentQuantity}'),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.of(context).pushNamed(
                    AppRoutes.catalogueProductForm,
                    arguments: product,
                  );
                }
                if (value == 'archive') {
                  onArchive();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit product')),
                PopupMenuItem(value: 'archive', child: Text('Archive product')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });

  final String value;
  final List<String> values;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(item),
                        selected: value == item,
                        onSelected: (_) => onChanged(item),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogueLoading extends StatelessWidget {
  const _CatalogueLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          LoadingSkeleton(height: 54, borderRadius: AppRadius.pill),
          SizedBox(height: AppSpacing.md),
          LoadingSkeleton(height: 112),
          SizedBox(height: AppSpacing.md),
          LoadingSkeleton(height: 112),
        ],
      ),
    );
  }
}
