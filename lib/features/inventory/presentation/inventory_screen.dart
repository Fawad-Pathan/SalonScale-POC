import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/inventory_list_tile.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../catalogue/data/catalogue_providers.dart';
import '../../catalogue/models/salon_product.dart';
import '../../inventory/data/inventory_providers.dart';
import '../../inventory/models/inventory_record.dart';
import 'product_detail_screen.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  var _query = '';
  var _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final inventory = ref.watch(inventoryRecordsProvider);
    final catalogue =
        ref.watch(productCatalogueProvider).valueOrNull ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Inventory'),
        actions: [
          IconButton(
            tooltip: 'Sort inventory',
            onPressed: () => setState(
                () => _filter = _filter == 'All' ? 'Low stock' : 'All'),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: inventory.when(
          data: (records) => _InventoryContent(
            records: _filtered(records),
            allRecords: records,
            catalogue: catalogue,
            query: _query,
            filter: _filter,
            onQueryChanged: (value) => setState(() => _query = value),
            onFilterChanged: (value) => setState(() => _filter = value),
          ),
          loading: () => const _InventoryLoading(),
          error: (error, _) => ErrorState(message: error.toString()),
        ),
      ),
    );
  }

  List<InventoryRecord> _filtered(List<InventoryRecord> records) {
    final query = _query.toLowerCase().trim();
    return records.where((record) {
      final matchesQuery = query.isEmpty ||
          record.productName.toLowerCase().contains(query) ||
          record.brand.toLowerCase().contains(query) ||
          record.shadeCode.toLowerCase().contains(query);
      final matchesFilter = _filter == 'All' ||
          (_filter == 'Low stock' && record.quantity < 3) ||
          (_filter == 'Tubes' &&
              record.packagingType.toLowerCase() == 'tube') ||
          (_filter == 'Colour' &&
              record.category.toLowerCase().contains('colour'));
      return matchesQuery && matchesFilter;
    }).toList()
      ..sort((left, right) => left.productName.compareTo(right.productName));
  }
}

class _InventoryContent extends StatelessWidget {
  const _InventoryContent({
    required this.records,
    required this.allRecords,
    required this.catalogue,
    required this.query,
    required this.filter,
    required this.onQueryChanged,
    required this.onFilterChanged,
  });

  final List<InventoryRecord> records;
  final List<InventoryRecord> allRecords;
  final List<SalonProduct> catalogue;
  final String query;
  final String filter;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final totalUnits =
        allRecords.fold<int>(0, (total, record) => total + record.quantity);
    final lowStock = allRecords.where((record) => record.quantity < 3).length;
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
                  hint: 'Search product, brand, or shade',
                  onChanged: onQueryChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: 'Total units',
                        value: totalUnits.toString(),
                        icon: Icons.inventory_2_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _SummaryCard(
                        label: 'Low stock',
                        value: lowStock.toString(),
                        icon: Icons.warning_amber_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final item in const [
                        'All',
                        'Low stock',
                        'Tubes',
                        'Colour'
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: ChoiceChip(
                            selected: filter == item,
                            label: Text(item),
                            onSelected: (_) => onFilterChanged(item),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
        if (records.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No inventory yet',
              message:
                  'Complete a scan to populate your latest product counts.',
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 116),
            sliver: SliverList.separated(
              itemCount: records.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final record = records[index];
                final matchedProduct = catalogue.where((product) {
                  return product.id == record.productId;
                }).firstOrNull;
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration:
                      Duration(milliseconds: 220 + index.clamp(0, 6) * 40),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 18 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: InventoryListTile(
                    record: record,
                    referenceImagePath: matchedProduct?.displayImage ?? '',
                    onTap: () => Navigator.of(context).push(
                      PageRouteBuilder<void>(
                        transitionDuration: const Duration(milliseconds: 320),
                        pageBuilder: (_, animation, __) => FadeTransition(
                          opacity: animation,
                          child: ProductDetailScreen(record: record),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      gradient: AppColors.softGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.indigo),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _InventoryLoading extends StatelessWidget {
  const _InventoryLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          LoadingSkeleton(height: 54, borderRadius: 28),
          SizedBox(height: AppSpacing.md),
          LoadingSkeleton(height: 116),
          SizedBox(height: AppSpacing.md),
          LoadingSkeleton(height: 94),
          SizedBox(height: AppSpacing.md),
          LoadingSkeleton(height: 94),
        ],
      ),
    );
  }
}
