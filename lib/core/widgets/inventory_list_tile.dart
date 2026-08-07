import 'package:flutter/material.dart';

import '../../features/catalogue/presentation/product_reference_image.dart';
import '../../features/inventory/models/inventory_record.dart';
import '../design/app_colors.dart';
import '../design/app_radius.dart';
import '../design/app_spacing.dart';

class InventoryListTile extends StatelessWidget {
  const InventoryListTile({
    required this.record,
    super.key,
    this.onTap,
    this.referenceImagePath = '',
  });

  final InventoryRecord record;
  final VoidCallback? onTap;
  final String referenceImagePath;

  @override
  Widget build(BuildContext context) {
    final lowStock = record.quantity < 3;
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
              ProductReferenceImage(
                imagePath: referenceImagePath,
                size: 62,
                icon: Icons.spa_outlined,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.ink,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      [
                        record.brand,
                        record.shadeCode.isEmpty ? null : record.shadeCode,
                        record.packagingType,
                      ]
                          .whereType<String>()
                          .where((item) => item.isNotEmpty)
                          .join(' - '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    record.quantity.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    lowStock ? 'Low' : 'In stock',
                    style: TextStyle(
                      color: lowStock ? AppColors.rose : AppColors.mint,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
