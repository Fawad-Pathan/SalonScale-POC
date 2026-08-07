import 'package:flutter/material.dart';

import '../../features/catalogue/presentation/product_reference_image.dart';
import '../../features/scanning/models/scan_product_result.dart';
import '../design/app_colors.dart';
import '../design/app_radius.dart';
import '../design/app_spacing.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    super.key,
    this.onTap,
    this.referenceImagePath = '',
  });

  final ScanProductResult product;
  final VoidCallback? onTap;
  final String referenceImagePath;

  @override
  Widget build(BuildContext context) {
    final confidence = (product.recognitionConfidence * 100).round();
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
                imagePath: referenceImagePath.isNotEmpty
                    ? referenceImagePath
                    : product.cameraCropPath ?? '',
                size: 68,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.brand.isEmpty ? 'Unknown brand' : product.brand,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: AppColors.indigo,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      product.confirmedName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '${product.packagingType} - ${product.shadeCode.isEmpty ? 'No shade' : product.shadeCode}',
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
                    'x${product.confirmedQuantity}',
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    '$confidence%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w800,
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
