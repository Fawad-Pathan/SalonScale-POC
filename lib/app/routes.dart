import 'package:flutter/material.dart';

import '../app/app_shell.dart';
import '../features/assistant/presentation/inventory_assistant_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/catalogue/models/salon_product.dart';
import '../features/catalogue/presentation/catalogue_product_detail_screen.dart';
import '../features/catalogue/presentation/catalogue_product_form_screen.dart';
import '../features/catalogue/presentation/catalogue_screen.dart';
import '../features/history/presentation/scan_details_screen.dart';
import '../features/history/presentation/scan_history_screen.dart';
import '../features/inventory/presentation/inventory_screen.dart';
import '../features/scanning/presentation/scan_processing_screen.dart';
import '../features/scanning/presentation/scan_results_screen.dart';
import '../features/scanning/presentation/scan_screen.dart';
import '../features/auth/presentation/splash_screen.dart';

class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const auth = '/auth';
  static const home = '/home';
  static const scan = '/scan';
  static const scanProcessing = '/scan/processing';
  static const scanResults = '/scan/results';
  static const history = '/history';
  static const scanDetails = '/history/details';
  static const inventory = '/inventory';
  static const catalogue = '/catalogue';
  static const catalogueProductDetails = '/catalogue/details';
  static const catalogueProductForm = '/catalogue/form';
  static const assistant = '/assistant';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (context, animation, secondaryAnimation) {
        return switch (settings.name) {
          splash => const SplashScreen(),
          auth => const AuthScreen(),
          home => const AppShell(initialIndex: 2),
          scan => const ScanScreen(resetOnOpen: true),
          scanProcessing => const ScanProcessingScreen(),
          scanResults => const ScanResultsScreen(),
          history => const ScanHistoryScreen(),
          inventory => const InventoryScreen(),
          catalogue => const CatalogueScreen(),
          catalogueProductDetails => CatalogueProductDetailScreen(
              productId: settings.arguments?.toString() ?? ''),
          catalogueProductForm => CatalogueProductFormScreen(
              product: settings.arguments is SalonProduct
                  ? settings.arguments as SalonProduct
                  : null),
          scanDetails =>
            ScanDetailsScreen(scanId: settings.arguments?.toString() ?? ''),
          assistant => const InventoryAssistantScreen(),
          _ => const SplashScreen(),
        };
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0.02),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
