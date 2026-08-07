import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radius.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/widgets/app_buttons.dart';
import '../data/scan_providers.dart';

class ScanProcessingScreen extends ConsumerStatefulWidget {
  const ScanProcessingScreen({super.key});

  @override
  ConsumerState<ScanProcessingScreen> createState() =>
      _ScanProcessingScreenState();
}

class _ScanProcessingScreenState extends ConsumerState<ScanProcessingScreen> {
  var _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAnalysis());
  }

  Future<void> _runAnalysis() async {
    if (_started) {
      return;
    }
    _started = true;
    await ref.read(currentScanControllerProvider.notifier).analyzeImage();
    if (!mounted) {
      return;
    }
    final state = ref.read(currentScanControllerProvider);
    if (state.errorMessage == null) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.scanResults);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(currentScanControllerProvider);
    final image = scan.image;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _openFreshScanner(context);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        tooltip: 'Cancel',
                        onPressed: () => _openFreshScanner(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                      const Spacer(),
                      Text(
                        scan.errorMessage == null ? 'Analyzing' : 'Needs retry',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Hero(
                    tag: 'scan-image-preview',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      child: AspectRatio(
                        aspectRatio: 4 / 5,
                        child: image != null && image.existsSync()
                            ? Image.file(image, fit: BoxFit.cover)
                            : const ColoredBox(
                                color: AppColors.darkNav,
                                child: Icon(Icons.center_focus_strong,
                                    color: Colors.white30, size: 84),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ProcessingCard(
                    stage: scan.stage,
                    message: scan.errorMessage ??
                        'Identifying products, shade codes, packaging, and catalogue matches.',
                    isError: scan.errorMessage != null,
                    onRetry: scan.errorMessage == null
                        ? null
                        : () {
                            _started = false;
                            _runAnalysis();
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFreshScanner(BuildContext context) {
    ref.read(currentScanControllerProvider.notifier).reset();
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
      (_) => false,
    );
  }
}

class _ProcessingCard extends StatelessWidget {
  const _ProcessingCard({
    required this.stage,
    required this.message,
    required this.isError,
    this.onRetry,
  });

  final String stage;
  final String message;
  final bool isError;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isError)
            const Icon(Icons.error_outline, color: AppColors.rose, size: 56)
          else
            const _PulsingScannerIcon(),
          const SizedBox(height: AppSpacing.lg),
          Text(
            stage,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Retry analysis',
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

class _PulsingScannerIcon extends StatefulWidget {
  const _PulsingScannerIcon();

  @override
  State<_PulsingScannerIcon> createState() => _PulsingScannerIconState();
}

class _PulsingScannerIconState extends State<_PulsingScannerIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
      lowerBound: 0.92,
      upperBound: 1.08,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _controller,
      child: Container(
        width: 78,
        height: 78,
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.center_focus_strong,
            color: Colors.white, size: 38),
      ),
    );
  }
}
