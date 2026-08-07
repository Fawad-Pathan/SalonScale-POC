import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/config/app_providers.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radius.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/widgets/app_buttons.dart';
import '../../../core/widgets/app_card.dart';
import '../data/auth_providers.dart';

class AuthScreen extends ConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final firebaseReady = ref.watch(firebaseBootstrapProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              AppCard(
                padding: const EdgeInsets.all(28),
                gradient: AppColors.softGradient,
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: const Icon(Icons.verified_user_outlined,
                          color: Colors.white, size: 42),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Start a secure demo session',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      firebaseReady.valueOrNull == true
                          ? 'Anonymous Firebase Authentication is ready.'
                          : 'Firebase is not configured, so the PoC will use a local anonymous demo session.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    PrimaryButton(
                      label: auth.isLoading
                          ? 'Starting session...'
                          : 'Continue anonymously',
                      icon: Icons.login_rounded,
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .signInAnonymously();
                              if (context.mounted &&
                                  ref.read(authControllerProvider).hasValue) {
                                Navigator.of(context)
                                    .pushReplacementNamed(AppRoutes.home);
                              }
                            },
                    ),
                    if (auth.hasError) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        auth.error.toString(),
                        style: const TextStyle(color: AppColors.rose),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
