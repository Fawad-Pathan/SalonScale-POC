import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../features/scanning/models/inventory_scan.dart';
import '../design/app_colors.dart';
import '../design/app_radius.dart';
import '../design/app_spacing.dart';
import 'status_chip.dart';

class ScanHistoryTile extends StatelessWidget {
  const ScanHistoryTile({
    required this.scan,
    super.key,
    this.onTap,
    this.onDelete,
  });

  final InventoryScan scan;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final imageExists = scan.localImagePath.isNotEmpty &&
        File(scan.localImagePath).existsSync();
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: AppColors.subtle.withValues(alpha: 0.72)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: imageExists
                      ? Image.file(File(scan.localImagePath), fit: BoxFit.cover)
                      : const ColoredBox(
                          color: AppColors.lavender,
                          child: Icon(Icons.center_focus_strong,
                              color: AppColors.indigo),
                        ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat.MMMd().add_jm().format(scan.createdAt),
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${scan.totalUniqueProducts} products - ${scan.totalUnits} units',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    StatusChip(label: scan.status),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Delete scan',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                )
              else
                const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
