import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/config/app_providers.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radius.dart';
import '../../../core/design/app_shadows.dart';
import '../../../core/design/app_spacing.dart';
import '../data/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await ref.read(firebaseBootstrapProvider.future).catchError((_) => false);
    await ref.read(authControllerProvider.notifier).restoreSession();
    if (!mounted) {
      return;
    }
    var user = ref.read(authControllerProvider).valueOrNull;
    if (user == null) {
      await ref.read(authControllerProvider.notifier).signInAnonymously();
      if (!mounted) {
        return;
      }
      user = ref.read(authControllerProvider).valueOrNull;
    }
    Navigator.of(context)
        .pushReplacementNamed(user == null ? AppRoutes.auth : AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.94 + value * 0.06,
              child: child,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 94,
                height: 94,
                decoration: BoxDecoration(
                  color: AppColors.indigo,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppShadows.glow,
                ),
                child: const Icon(Icons.center_focus_strong,
                    color: Colors.white, size: 44),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'SalonScale',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text('Live AI inventory scanner'),
              const SizedBox(height: AppSpacing.lg),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
