import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_radius.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    required this.label,
    this.color,
    super.key,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.indigo;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
