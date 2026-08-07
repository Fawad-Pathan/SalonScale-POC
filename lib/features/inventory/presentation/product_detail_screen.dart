import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';

import '../../../app/routes.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radius.dart';
import '../../../core/design/app_shadows.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../catalogue/data/catalogue_providers.dart';
import '../../catalogue/presentation/product_reference_image.dart';
import '../../inventory/models/inventory_record.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.record, super.key});

  final InventoryRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStock = record.quantity < 3;
    final catalogue =
        ref.watch(productCatalogueProvider).valueOrNull ?? const [];
    final matchedProduct = catalogue
        .where((product) => product.id == record.productId)
        .firstOrNull;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                Hero(
                  tag: 'inventory-${record.productId}',
                  child: SizedBox(
                    height: 280,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.softGradient,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Center(
                        child: ProductReferenceImage(
                          imagePath: matchedProduct?.displayImage ?? '',
                          size: 180,
                          borderRadius: AppRadius.xl,
                          icon: Icons.spa_rounded,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  record.brand.isEmpty ? 'Unknown brand' : record.brand,
                  style: const TextStyle(
                    color: AppColors.indigo,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  record.productName,
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
                    _DetailPill(label: record.category),
                    _DetailPill(label: record.packagingType),
                    if (record.shadeCode.isNotEmpty)
                      _DetailPill(label: record.shadeCode),
                    _DetailPill(label: lowStock ? 'Low stock' : 'In stock'),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Current quantity',
                        value: '${record.quantity} units',
                      ),
                      _DetailRow(
                        label: 'Last scanned',
                        value: DateFormat.yMMMd().format(record.latestScanDate),
                      ),
                      _DetailRow(
                        label: 'Stock status',
                        value: lowStock ? 'Needs review' : 'Healthy',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 14,
              left: 14,
              child: _FloatingIconButton(
                icon: Icons.close_rounded,
                label: 'Close',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'History',
                      icon: Icons.history_rounded,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Scan again',
                      icon: Icons.center_focus_strong,
                      onPressed: () =>
                          Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.home,
                        (_) => false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label.isEmpty ? 'Unspecified' : label,
        style: const TextStyle(fontWeight: FontWeight.w800),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingIconButton extends StatelessWidget {
  const _FloatingIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton.filled(
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.86),
          foregroundColor: AppColors.ink,
        ),
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}
