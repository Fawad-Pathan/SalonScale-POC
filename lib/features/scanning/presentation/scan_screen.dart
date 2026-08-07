import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/routes.dart';
import '../../../core/config/app_providers.dart';
import '../../../core/design/app_colors.dart';
import '../../../core/design/app_radius.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/widgets/scanner_overlay.dart';
import '../../inventory/data/inventory_providers.dart';
import '../data/scan_providers.dart';
import '../models/scan_product_result.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({
    super.key,
    this.onMenu,
    this.resetOnOpen = false,
    this.isActive = true,
  });

  final VoidCallback? onMenu;
  final bool resetOnOpen;
  final bool isActive;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  Timer? _scanTimer;
  var _flashOn = false;
  var _cameraError = '';
  var _isInitializing = true;
  var _isCapturing = false;
  var _isAnalyzing = false;
  var _isPaused = false;
  var _statusLabel = 'Scanning live inventory';
  var _scanGeneration = 0;
  String? _lastSavedSignature;
  DateTime? _lastSavedAt;

  static const _scanInterval = Duration(seconds: 3);
  static const _duplicateCooldown = Duration(seconds: 30);
  static const _reviewWindow = Duration(milliseconds: 2400);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.resetOnOpen) {
        ref.read(currentScanControllerProvider.notifier).reset();
      }
      if (widget.isActive) {
        _initializeCamera();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) {
      return;
    }
    if (widget.isActive) {
      _scanGeneration++;
      ref.read(currentScanControllerProvider.notifier).reset();
      _isPaused = false;
      unawaited(_initializeCamera());
    } else {
      _pauseScanning();
      unawaited(_releaseCamera(refreshUi: true));
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _releaseCamera({bool refreshUi = false}) async {
    _scanTimer?.cancel();
    final controller = _cameraController;
    _cameraController = null;
    if (refreshUi && mounted) {
      setState(() {
        _flashOn = false;
        _isInitializing = false;
      });
    }
    await controller?.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (widget.isActive) {
        _isPaused = false;
        _initializeCamera();
      }
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _pauseScanning();
      unawaited(_releaseCamera(refreshUi: true));
      return;
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted || _isPaused || !widget.isActive) {
      return;
    }
    setState(() {
      _isInitializing = true;
      _cameraError = '';
      _statusLabel = 'Starting camera';
    });
    final status = await Permission.camera.request();
    if (!mounted || _isPaused || !widget.isActive) {
      return;
    }
    if (!status.isGranted && !status.isLimited) {
      setState(() {
        _cameraError = 'Camera permission is needed for automatic scanning.';
        _isInitializing = false;
      });
      return;
    }

    try {
      final cameras = await availableCameras();
      if (!mounted || _isPaused || !widget.isActive) {
        return;
      }
      if (cameras.isEmpty) {
        setState(() {
          _cameraError = 'No camera is available. Use gallery upload instead.';
          _isInitializing = false;
        });
        return;
      }
      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await _cameraController?.dispose();
      if (!mounted || _isPaused || !widget.isActive) {
        await controller.dispose();
        return;
      }
      _cameraController = controller;
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off).catchError((_) {});
      if (!mounted || _isPaused || !widget.isActive) {
        if (_cameraController == controller) {
          _cameraController = null;
        }
        await controller.dispose();
        return;
      }
      setState(() {
        _isInitializing = false;
        _statusLabel = 'Scanning live inventory';
      });
      _scheduleNextScan(const Duration(milliseconds: 800));
    } catch (error) {
      if (!mounted || !widget.isActive) {
        return;
      }
      setState(() {
        _cameraError =
            'Could not start the camera. Use gallery upload instead.';
        _isInitializing = false;
      });
    }
  }

  void _pauseScanning() {
    _scanGeneration++;
    _isPaused = true;
    _scanTimer?.cancel();
  }

  void _scheduleNextScan([Duration delay = _scanInterval]) {
    if (!mounted ||
        !widget.isActive ||
        _isPaused ||
        _isCapturing ||
        _isAnalyzing) {
      return;
    }
    _scanTimer?.cancel();
    _scanTimer = Timer(delay, () {
      if (!mounted) {
        return;
      }
      unawaited(_captureAndAutoLog());
    });
  }

  Future<void> _captureAndAutoLog() async {
    final controller = _cameraController;
    final generation = _scanGeneration;
    _scanTimer?.cancel();
    if (_isCapturing ||
        _isAnalyzing ||
        _isPaused ||
        !widget.isActive ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }
    setState(() {
      _isCapturing = true;
      _statusLabel = 'Capturing frame';
    });
    try {
      final capture = await controller.takePicture();
      if (!mounted ||
          !widget.isActive ||
          _isPaused ||
          generation != _scanGeneration) {
        return;
      }
      setState(() {
        _isCapturing = false;
        _isAnalyzing = true;
        _statusLabel = 'Identifying products';
      });
      ref
          .read(currentScanControllerProvider.notifier)
          .setImage(File(capture.path));
      await ref.read(currentScanControllerProvider.notifier).analyzeImage();
      if (!mounted ||
          !widget.isActive ||
          _isPaused ||
          generation != _scanGeneration) {
        ref.read(currentScanControllerProvider.notifier).reset();
        return;
      }
      await _autoSaveCurrentScan(generation);
    } catch (error) {
      if (mounted) {
        setState(() {
          _cameraError = '';
          _statusLabel = 'Scan failed - retrying';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isAnalyzing = false;
        });
        if (widget.isActive && !_isPaused) {
          _scheduleNextScan();
        }
      }
    }
  }

  Future<void> _autoSaveCurrentScan(int generation) async {
    final controller = ref.read(currentScanControllerProvider.notifier);
    final scan = ref.read(currentScanControllerProvider);
    if (scan.errorMessage != null) {
      controller.reset();
      setState(() => _statusLabel = 'AI issue - retrying');
      return;
    }
    if (scan.products.isEmpty) {
      controller.reset();
      setState(() => _statusLabel = 'Scanning live inventory');
      return;
    }
    if (_isMockAnalysis(scan)) {
      controller.reset();
      setState(() {
        _statusLabel = 'Connect OpenAI for live detection';
      });
      return;
    }

    setState(() {
      _statusLabel = 'Detected ${scan.totalUnits} units - logging inventory';
    });
    await Future<void>.delayed(_reviewWindow);
    if (!mounted ||
        _isPaused ||
        !widget.isActive ||
        generation != _scanGeneration) {
      return;
    }

    final latestScan = ref.read(currentScanControllerProvider);
    if (latestScan.products.isEmpty || latestScan.errorMessage != null) {
      controller.reset();
      return;
    }

    final signature = _scanSignature(latestScan.products);
    final now = DateTime.now();
    final isRecentDuplicate = signature == _lastSavedSignature &&
        _lastSavedAt != null &&
        now.difference(_lastSavedAt!) < _duplicateCooldown;
    if (isRecentDuplicate) {
      controller.reset();
      setState(() => _statusLabel = 'Already logged - scanning');
      return;
    }

    final saved = await controller.completeScan();
    controller.reset();
    _lastSavedSignature = signature;
    _lastSavedAt = now;
    ref.invalidate(scanHistoryProvider);
    ref.invalidate(inventoryRecordsProvider);
    if (!mounted) {
      return;
    }
    setState(() {
      _statusLabel = 'Added ${saved.totalUnits} units - still scanning';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Added ${saved.totalUnits} units across ${saved.totalUniqueProducts} products.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool _isMockAnalysis(CurrentScanState scan) {
    return ref.read(appConfigProvider).useMockAi ||
        scan.analysis?.warnings.any(
              (warning) => warning.toLowerCase().contains('mock analysis mode'),
            ) ==
            true;
  }

  String _scanSignature(List<ScanProductResult> products) {
    final parts = products.map((product) {
      final id = product.matchedProductId?.isNotEmpty == true
          ? product.matchedProductId!
          : product.confirmedName.toLowerCase().trim();
      return '$id:${product.confirmedQuantity}';
    }).toList()
      ..sort();
    return parts.join('|');
  }

  Future<void> _toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    final next = !_flashOn;
    await controller
        .setFlashMode(next ? FlashMode.torch : FlashMode.off)
        .catchError((_) {});
    if (mounted) {
      setState(() => _flashOn = next);
    }
  }

  void _restartScan() {
    if (!widget.isActive) {
      return;
    }
    _scanGeneration++;
    final wasBusy = _isCapturing || _isAnalyzing;
    ref.read(currentScanControllerProvider.notifier).reset();
    _scanTimer?.cancel();
    setState(() {
      _isPaused = false;
      _cameraError = '';
      _statusLabel = 'Scanning live inventory';
    });
    if (wasBusy) {
      return;
    }
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _initializeCamera();
    } else {
      _scheduleNextScan(const Duration(milliseconds: 500));
    }
  }

  Future<void> _openInventory() async {
    _pauseScanning();
    await _releaseCamera(refreshUi: true);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushNamed(AppRoutes.inventory);
    if (!mounted) {
      return;
    }
    if (widget.isActive) {
      _isPaused = false;
      await _initializeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressLabel = _cameraError.isNotEmpty
        ? _cameraError
        : _isInitializing
            ? 'Starting camera...'
            : _isCapturing
                ? 'Capturing...'
                : _isAnalyzing
                    ? 'Identifying products...'
                    : _statusLabel;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: 'scan-image-preview',
            child: _CameraLayer(
              controller: _cameraController,
              isInitializing: _isInitializing,
              hasError: _cameraError.isNotEmpty,
            ),
          ),
          ScannerOverlay(
            progressLabel: progressLabel,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _RoundIconButton(
                        icon: Icons.menu_rounded,
                        label: 'Open menu',
                        filled: true,
                        onPressed: widget.onMenu ??
                            () {
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            },
                      ),
                      const Spacer(),
                      _RoundIconButton(
                        icon: Icons.center_focus_strong,
                        label: 'Restart scan',
                        onPressed: _restartScan,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _RoundIconButton(
                        icon: _flashOn
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                        label: 'Toggle flash',
                        onPressed: _toggleFlash,
                      ),
                    ],
                  ),
                  const Spacer(),
                  _ScannerControls(
                    onCamera: _captureAndAutoLog,
                    onInventory: _openInventory,
                    onRestart: _restartScan,
                    canCapture:
                        !_isInitializing && !_isCapturing && !_isAnalyzing,
                  ),
                  const SizedBox(height: 26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraLayer extends StatelessWidget {
  const _CameraLayer({
    required this.controller,
    required this.isInitializing,
    required this.hasError,
  });

  final CameraController? controller;
  final bool isInitializing;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final camera = controller;
    if (camera != null && camera.value.isInitialized && !hasError) {
      return ClipRect(
        child: OverflowBox(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: camera.value.previewSize?.height ?? 1,
              height: camera.value.previewSize?.width ?? 1,
              child: CameraPreview(camera),
            ),
          ),
        ),
      );
    }
    return const _ScannerBackdrop();
  }
}

class _ScannerBackdrop extends StatelessWidget {
  const _ScannerBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Center(
        child: Container(
          width: 118,
          height: 118,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: const Icon(
            Icons.center_focus_strong,
            color: Colors.white70,
            size: 48,
          ),
        ),
      ),
    );
  }
}

class _ScannerControls extends StatelessWidget {
  const _ScannerControls({
    required this.onCamera,
    required this.onInventory,
    required this.onRestart,
    required this.canCapture,
  });

  final VoidCallback onCamera;
  final VoidCallback onInventory;
  final VoidCallback onRestart;
  final bool canCapture;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.darkNav.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.24),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BottomControl(
              icon: Icons.camera_alt_outlined,
              label: 'Scan',
              onTap: canCapture ? onCamera : null,
            ),
            const SizedBox(width: 24),
            GestureDetector(
              onTap: onRestart,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.indigo,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.indigo.withValues(alpha: 0.38),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.center_focus_strong,
                    color: Colors.white, size: 34),
              ),
            ),
            const SizedBox(width: 24),
            _BottomControl(
              icon: Icons.inventory_2_outlined,
              label: 'Inventory',
              onTap: onInventory,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton(
        style: IconButton.styleFrom(
          backgroundColor: filled
              ? AppColors.darkNav.withValues(alpha: 0.86)
              : Colors.white.withValues(alpha: 0.26),
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.20)),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

class _BottomControl extends StatelessWidget {
  const _BottomControl({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Opacity(
        opacity: onTap == null ? 0.42 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
