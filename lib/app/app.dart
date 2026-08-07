import 'package:flutter/material.dart';

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
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
