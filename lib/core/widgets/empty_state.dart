import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_radius.dart';
import '../design/app_shadows.dart';
import '../design/app_spacing.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                gradient: AppColors.softGradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.subtle),
                boxShadow: AppShadows.soft,
              ),
              child: Icon(icon, size: 38, color: AppColors.indigo),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
