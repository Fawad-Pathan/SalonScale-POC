import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_skeleton.dart';
import '../../../core/widgets/scan_history_tile.dart';
import '../../inventory/data/inventory_providers.dart';

class ScanHistoryScreen extends ConsumerStatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  ConsumerState<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends ConsumerState<ScanHistoryScreen> {
  var _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final scans = ref.watch(scanHistoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanning History'),
        actions: [
          IconButton(
            tooltip: 'Refresh history',
            onPressed: () {
              ref.invalidate(scanHistoryProvider);
              ref.invalidate(inventoryRecordsProvider);
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: scans.when(
          data: (items) {
            final filtered = _filterScans(items);
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Today', label: Text('Today')),
                          ButtonSegment(value: 'Week', label: Text('Week')),
                          ButtonSegment(value: 'Month', label: Text('Month')),
                          ButtonSegment(value: 'All', label: Text('All')),
                        ],
                        selected: {_filter},
                        onSelectionChanged: (value) =>
                            setState(() => _filter = value.first),
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            return states.contains(WidgetState.selected)
                                ? AppColors.indigo
                                : AppColors.surface;
                          }),
                          foregroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            return states.contains(WidgetState.selected)
                                ? Colors.white
                                : AppColors.ink;
                          }),
                          side: const WidgetStatePropertyAll(BorderSide.none),
                        ),
                      ),
                    ),
                  ),
                ),
                if (filtered.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.history_rounded,
                      title: 'No scans here',
                      message:
                          'Completed scans will appear after a stylist saves results.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 116),
                    sliver: SliverList.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final scan = filtered[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(
                              milliseconds: 220 + index.clamp(0, 6) * 40),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: ScanHistoryTile(
                            scan: scan,
                            onTap: () => Navigator.of(context).pushNamed(
                              AppRoutes.scanDetails,
                              arguments: scan.id,
                            ),
                            onDelete: () => _deleteScan(scan.id),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                LoadingSkeleton(height: 52, borderRadius: 28),
                SizedBox(height: AppSpacing.lg),
                LoadingSkeleton(height: 104),
                SizedBox(height: AppSpacing.md),
                LoadingSkeleton(height: 104),
              ],
            ),
          ),
          error: (error, _) => ErrorState(message: error.toString()),
        ),
      ),
    );
  }

  List<dynamic> _filterScans(List<dynamic> items) {
    final now = DateTime.now();
    return items.where((scan) {
      final createdAt = scan.createdAt as DateTime;
      return switch (_filter) {
        'Today' => createdAt.year == now.year &&
            createdAt.month == now.month &&
            createdAt.day == now.day,
        'Week' => createdAt.isAfter(now.subtract(const Duration(days: 7))),
        'Month' => createdAt.isAfter(now.subtract(const Duration(days: 31))),
        _ => true,
      };
    }).toList();
  }

  Future<void> _deleteScan(String scanId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete scan?'),
        content: const Text(
            'This removes the historical scan and recalculates latest inventory.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final repository = await ref.read(inventoryRepositoryProvider.future);
    final salonId = ref.read(salonIdProvider);
    await repository.deleteScan(salonId: salonId, scanId: scanId);
    ref.invalidate(scanHistoryProvider);
    ref.invalidate(inventoryRecordsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Scan deleted.')));
    }
  }
}
