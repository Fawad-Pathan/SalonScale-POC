import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'routes.dart';
import 'theme.dart';

class SalonScalePocApp extends StatelessWidget {
  const SalonScalePocApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SalonScale PoC',
      debugShowCheckedModeBanner: false,
      theme: buildSalonTheme(),
      home: const AppShell(initialIndex: 2),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
