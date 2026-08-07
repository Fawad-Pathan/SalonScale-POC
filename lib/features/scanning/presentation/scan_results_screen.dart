import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radius.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../catalogue/data/catalogue_providers.dart';
import '../../catalogue/models/salon_product.dart';
import '../data/scan_providers.dart';
import 'product_result_card.dart';

class ScanResultsScreen extends ConsumerWidget {
  const ScanResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scan = ref.watch(currentScanControllerProvider);
    final catalogue = ref.watch(productCatalogueProvider);
    final image = scan.image;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _startFreshScan(context, ref);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: catalogue.when(
            data: (products) {
              if (scan.products.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    children: [
                      _TopBar(
                        title: 'Review results',
                        onBack: () => _startFreshScan(context, ref),
                      ),
                      const Expanded(
                        child: EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No detected products',
                          message:
                              'Try re-running analysis or add products manually.',
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              label: 'Add product',
                              icon: Icons.add_rounded,
                              onPressed: () =>
                                  _showAddProductSheet(context, ref, products),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Scan again',
                              icon: Icons.refresh_rounded,
                              onPressed: () => _startFreshScan(context, ref),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }

              return Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 148),
                    children: [
                      _TopBar(
                        title: 'Review results',
                        onBack: () => _startFreshScan(context, ref),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Hero(
                        tag: 'scan-image-preview',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          child: AspectRatio(
                            aspectRatio: 16 / 10,
                            child: image != null && image.existsSync()
                                ? Image.file(image, fit: BoxFit.cover)
                                : const ColoredBox(
                                    color: AppColors.darkNav,
                                    child: Icon(Icons.center_focus_strong,
                                        color: Colors.white30, size: 64),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        gradient: AppColors.softGradient,
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: Colors.white),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${scan.products.length} products detected',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '${scan.totalUnits} total units. Review uncertain matches before saving.',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (scan.analysis?.warnings.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          scan.analysis!.warnings.join(' '),
                          style: const TextStyle(
                            color: AppColors.rose,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      ...scan.products.indexed.map(
                        (entry) => TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(
                              milliseconds: 240 + entry.$1.clamp(0, 6) * 45),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 18 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: ProductResultCard(
                              product: entry.$2,
                              catalogue: products,
                              onChanged: ref
                                  .read(currentScanControllerProvider.notifier)
                                  .updateProduct,
                              onDeleted: () => ref
                                  .read(currentScanControllerProvider.notifier)
                                  .deleteProduct(entry.$2.temporaryId),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SecondaryButton(
                              label: 'Add',
                              icon: Icons.add_rounded,
                              onPressed: () =>
                                  _showAddProductSheet(context, ref, products),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: SecondaryButton(
                              label: 'Scan',
                              icon: Icons.refresh_rounded,
                              onPressed: () => _startFreshScan(context, ref),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: PrimaryButton(
                              label: 'Save',
                              icon: Icons.check_rounded,
                              onPressed: () => _completeScan(context, ref),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(error.toString())),
          ),
        ),
      ),
    );
  }

  Future<void> _completeScan(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save inventory?'),
        content: const Text(
            'This saves the reviewed results and updates latest inventory counts.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final saved =
        await ref.read(currentScanControllerProvider.notifier).completeScan();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Scan saved.')));
    ref.read(currentScanControllerProvider.notifier).reset();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.scanDetails,
      ModalRoute.withName(AppRoutes.home),
      arguments: saved.id,
    );
  }

  void _startFreshScan(BuildContext context, WidgetRef ref) {
    ref.read(currentScanControllerProvider.notifier).reset();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (_) => false,
    );
  }

  Future<void> _showAddProductSheet(
      BuildContext context, WidgetRef ref, List<SalonProduct> products) async {
    var selected = products.isEmpty ? null : products.first;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Add missing product',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<SalonProduct>(
                    initialValue: selected,
                    decoration: const InputDecoration(labelText: 'Product'),
                    items: products
                        .map((product) => DropdownMenuItem(
                            value: product, child: Text(product.name)))
                        .toList(),
                    onChanged: (value) => setState(() => selected = value),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Add product',
                    icon: Icons.add_rounded,
                    onPressed: () {
                      ref
                          .read(currentScanControllerProvider.notifier)
                          .addManualProduct(selected);
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.onBack});

  final String title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton.filledTonal(
          tooltip: 'Back',
          onPressed: onBack ?? () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
