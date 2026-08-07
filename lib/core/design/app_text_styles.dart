import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTextStyles {
  const AppTextStyles._();

  static const headline = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
    height: 1.05,
    color: AppColors.ink,
  );

  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w900,
    letterSpacing: 0,
    height: 1.12,
    color: AppColors.ink,
  );

  static const cardTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    letterSpacing: 0,
    color: AppColors.ink,
  );

  static const body = TextStyle(
    fontSize: 14,
    height: 1.35,
    color: AppColors.muted,
  );

  static const caption = TextStyle(
    fontSize: 12,
    height: 1.25,
    color: AppColors.muted,
  );
}
