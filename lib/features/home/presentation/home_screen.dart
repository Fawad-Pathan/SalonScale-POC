import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/scan_history_tile.dart';
import '../../../features/auth/data/auth_providers.dart';
import '../../../features/inventory/data/inventory_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final scans = ref.watch(scanHistoryProvider);
    final inventory = ref.watch(inventoryRecordsProvider);
    final completedScans = scans.valueOrNull ?? const [];
    final inventoryRecords = inventory.valueOrNull ?? const [];
    final totalUnits = inventoryRecords.fold<int>(
        0, (total, record) => total + record.quantity);
    final lowStock =
        inventoryRecords.where((record) => record.quantity < 3).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SalonScale'),
        actions: [
          IconButton.filledTonal(
            tooltip: 'Inventory assistant',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.assistant),
            icon: const Icon(Icons.auto_awesome_rounded),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome${user == null ? '' : ', ${user.displayName}'}',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Scan backbar products, confirm counts, and keep inventory fresh.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: const EdgeInsets.all(24),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.scan),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Inventory Scanner',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                        SizedBox(height: AppSpacing.sm),
                        Text(
                          'Point the camera at products and detected inventory is logged automatically.',
                          style: TextStyle(
                            color: AppColors.muted,
                            height: 1.35,
                          ),
                        ),
                        SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Icon(Icons.center_focus_strong,
                                color: AppColors.indigo, size: 20),
                            SizedBox(width: AppSpacing.sm),
                            Text(
                              'Full-screen detection',
                              style: TextStyle(
                                color: AppColors.indigo,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Container(
                    width: 74,
                    height: 74,
                    decoration: const BoxDecoration(
                      color: AppColors.lavender,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded,
                        color: AppColors.indigo, size: 34),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _AnimatedMetricCard(
                    index: 0,
                    label: 'Current units',
                    value: totalUnits.toString(),
                    icon: Icons.inventory_2_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _AnimatedMetricCard(
                    index: 1,
                    label: 'Low stock',
                    value: lowStock.toString(),
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _AnimatedMetricCard(
                    index: 2,
                    label: 'Completed scans',
                    value: completedScans.length.toString(),
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _AnimatedMetricCard(
                    index: 3,
                    label: 'Products',
                    value: inventoryRecords.length.toString(),
                    icon: Icons.spa_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _SectionHeader(
              title: 'Recent scans',
              action: 'View all',
              onAction: () =>
                  Navigator.of(context).pushNamed(AppRoutes.history),
            ),
            const SizedBox(height: AppSpacing.md),
            scans.when(
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.camera_alt_outlined,
                    title: 'No scans yet',
                    message:
                        'Start a scan to create the first inventory snapshot.',
                  );
                }
                return Column(
                  children: [
                    for (final scan in items.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ScanHistoryTile(
                          scan: scan,
                          onTap: () => Navigator.of(context).pushNamed(
                            AppRoutes.scanDetails,
                            arguments: scan.id,
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const LoadingSkeleton(height: 104),
              error: (error, _) => Text(error.toString()),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.assistant),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ask the inventory assistant',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.ink,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Summarize low stock, recent scans, and shades.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedMetricCard extends StatelessWidget {
  const _AnimatedMetricCard({
    required this.index,
    required this.label,
    required this.value,
    required this.icon,
  });

  final int index;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + index * 60),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - progress)),
          child: child,
        ),
      ),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.indigo),
            const SizedBox(height: AppSpacing.md),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: double.tryParse(value) ?? 0),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, animated, _) => Text(
                animated.round().toString(),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.action,
    required this.onAction,
  });

  final String title;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(action)),
      ],
    );
  }
}
