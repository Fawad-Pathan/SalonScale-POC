import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFFF5F5F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF2F2F7);
  static const ink = Color(0xFF111114);
  static const muted = Color(0xFF6E6E73);
  static const subtle = Color(0xFFE5E5EA);
  static const indigo = Color(0xFF007AFF);
  static const violet = Color(0xFF5856D6);
  static const lavender = Color(0xFFEAF2FF);
  static const mint = Color(0xFF34C759);
  static const amber = Color(0xFFFF9F0A);
  static const rose = Color(0xFFFF3B30);
  static const darkNav = Color(0xFF1C1C1E);

  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF0A84FF), violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const softGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF2F7FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
