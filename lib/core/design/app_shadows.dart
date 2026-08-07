import 'package:flutter/material.dart';

class AppShadows {
  const AppShadows._();

  static const soft = [
    BoxShadow(
      color: Color(0x141C1C1E),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static const glow = [
    BoxShadow(
      color: Color(0x400A84FF),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];
}
