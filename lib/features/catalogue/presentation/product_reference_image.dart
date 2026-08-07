import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radius.dart';

class ProductReferenceImage extends StatelessWidget {
  const ProductReferenceImage({
    required this.imagePath,
    super.key,
    this.size = 64,
    this.borderRadius = AppRadius.md,
    this.icon = Icons.inventory_2_outlined,
  });

  final String imagePath;
  final double size;
  final double borderRadius;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final image = _buildImage();
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: image ??
            DecoratedBox(
              decoration: const BoxDecoration(gradient: AppColors.softGradient),
              child: Icon(icon, color: AppColors.indigo),
            ),
      ),
    );
  }

  Widget? _buildImage() {
    final path = imagePath.trim();
    if (path.isEmpty) {
      return null;
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(path, fit: BoxFit.cover);
    }
    if (path.startsWith('assets/')) {
      return Image.asset(path, fit: BoxFit.cover);
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return null;
  }
}
