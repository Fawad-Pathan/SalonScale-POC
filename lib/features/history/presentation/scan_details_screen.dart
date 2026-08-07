import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radius.dart';
import '../../../core/design/app_shadows.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../catalogue/data/catalogue_providers.dart';
import '../../inventory/data/inventory_providers.dart';

class ScanDetailsScreen extends ConsumerWidget {
  const ScanDetailsScreen({required this.scanId, super.key});

  final String scanId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(scanDetailProvider(scanId));
    final catalogue =
        ref.watch(productCatalogueProvider).valueOrNull ?? const [];

    return Scaffold(
      body: SafeArea(
        child: scan.when(
          data: (scan) {
            if (scan == null) {
              return const EmptyState(
                icon: Icons.search_off,
                title: 'Scan not found',
                message: 'The selected scan could not be loaded.',
              );
            }
            final imageExists = scan.localImagePath.isNotEmpty &&
                File(scan.localImagePath).existsSync();
            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: imageExists
                            ? Image.file(File(scan.localImagePath),
                                fit: BoxFit.cover)
                            : const ColoredBox(
                                color: AppColors.darkNav,
                                child: Icon(Icons.image_outlined,
                                    color: Colors.white30, size: 64),
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormat.yMMMd()
                                      .add_jm()
                                      .format(scan.createdAt),
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ),
                              StatusChip(label: scan.status),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              _ScanMetric(
                                  label: 'Products',
                                  value: scan.totalUniqueProducts.toString()),
                              _ScanMetric(
                                  label: 'Units',
                                  value: scan.totalUnits.toString()),
                              _ScanMetric(
                                  label: 'Quality', value: scan.scanQuality),
                            ],
                          ),
                          if (scan.warnings.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              scan.warnings.join(' '),
                              style: const TextStyle(
                                color: AppColors.rose,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Identified products',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...scan.products.map((product) {
                      final match = catalogue
                          .where((item) => item.id == product.matchedProductId)
                          .firstOrNull;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: AppCard(
                          padding: EdgeInsets.zero,
                          child: Column(
                            children: [
                              ProductCard(
                                product: product,
                                referenceImagePath: match?.displayImage ?? '',
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.md,
                                    0,
                                    AppSpacing.md,
                                    AppSpacing.md),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Match: ${match?.name ?? product.matchedProductId ?? 'None'}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                    if (product.wasCorrected)
                                      const StatusChip(label: 'Corrected'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.86),
                      foregroundColor: AppColors.ink,
                    ),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ErrorState(message: error.toString()),
        ),
      ),
    );
  }
}

class _ScanMetric extends StatelessWidget {
  const _ScanMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
