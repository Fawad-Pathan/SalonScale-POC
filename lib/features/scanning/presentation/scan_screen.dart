import 'dart:async';
import 'dart:io';
import 'dart:ui';

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
import '../services/product_image_lookup_service.dart';

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
  var _scanNowAfterBusy = false;
  var _statusLabel = 'Scanning live inventory';
  var _scanGeneration = 0;
  String? _lastSavedSignature;
  DateTime? _lastSavedAt;
  _ScannedProductNotice? _lastScanNotice;
  Timer? _noticeDismissTimer;
  final _imageLookupCache = <String, Future<ProductWebImage?>>{};

  static const _scanInterval = Duration(seconds: 3);
  static const _configurationRetryInterval = Duration(seconds: 8);
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
        Future<void>.delayed(const Duration(milliseconds: 800), () {
          if (mounted && widget.isActive && !_isPaused) {
            _initializeCamera();
          }
        });
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
    _noticeDismissTimer?.cancel();
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
    if (!_hasLiveAiConfiguration) {
      setState(() => _statusLabel = _missingAiConfigurationMessage);
      _scanTimer?.cancel();
      _scanTimer = Timer(_configurationRetryInterval, () {
        if (mounted && widget.isActive && !_isPaused) {
          _scheduleNextScan(Duration.zero);
        }
      });
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
    if (!_hasLiveAiConfiguration) {
      if (mounted) {
        setState(() => _statusLabel = _missingAiConfigurationMessage);
      }
      _scheduleNextScan(_configurationRetryInterval);
      return;
    }
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
      debugPrint('SalonScale scan: captured ${capture.path}');
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
      final analyzedScan = ref.read(currentScanControllerProvider);
      debugPrint(
        'SalonScale scan: analysis finished, '
        'products=${analyzedScan.products.length}, '
        'units=${analyzedScan.totalUnits}, '
        'error=${analyzedScan.errorMessage ?? 'none'}, '
        'warnings=${analyzedScan.analysis?.warnings.join(' | ') ?? 'none'}',
      );
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
        debugPrint('SalonScale scan failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
          _isAnalyzing = false;
        });
        if (widget.isActive && !_isPaused) {
          final nextDelay = _scanNowAfterBusy
              ? const Duration(milliseconds: 250)
              : _scanInterval;
          _scanNowAfterBusy = false;
          _scheduleNextScan(nextDelay);
        }
      }
    }
  }

  Future<void> _autoSaveCurrentScan(int generation) async {
    final controller = ref.read(currentScanControllerProvider.notifier);
    final scan = ref.read(currentScanControllerProvider);
    if (scan.errorMessage != null) {
      controller.reset();
      setState(() => _statusLabel = _readableAnalysisError(scan.errorMessage!));
      return;
    }
    if (_isMockAnalysis(scan)) {
      controller.reset();
      setState(() {
        _statusLabel = _missingAiConfigurationMessage;
      });
      return;
    }
    if (scan.products.isEmpty) {
      final reason = _emptyScanReason(scan);
      controller.reset();
      setState(() => _statusLabel = reason);
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
    _showLastScannedNotice(
      saved.products,
      totalUnits: saved.totalUnits,
      totalUniqueProducts: saved.totalUniqueProducts,
      localImagePath: saved.localImagePath,
    );
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

  void _showLastScannedNotice(
    List<ScanProductResult> products, {
    required int totalUnits,
    required int totalUniqueProducts,
    required String localImagePath,
  }) {
    if (products.isEmpty) {
      return;
    }
    final featured = _featuredScannedProduct(products);
    final lookupKey = _imageLookupKey(featured);
    final imageFuture = _imageLookupCache.putIfAbsent(
      lookupKey,
      () => ref.read(productImageLookupServiceProvider).lookup(featured),
    );
    _noticeDismissTimer?.cancel();
    setState(() {
      _lastScanNotice = _ScannedProductNotice(
        product: featured,
        totalUnits: totalUnits,
        totalUniqueProducts: totalUniqueProducts,
        localImagePath: localImagePath,
        lookupKey: lookupKey,
        imageFuture: imageFuture,
      );
    });
    _noticeDismissTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() => _lastScanNotice = null);
      }
    });
  }

  ScanProductResult _featuredScannedProduct(List<ScanProductResult> products) {
    var featured = products.first;
    for (final product in products.skip(1)) {
      if (product.confirmedQuantity > featured.confirmedQuantity ||
          (product.confirmedQuantity == featured.confirmedQuantity &&
              product.recognitionConfidence > featured.recognitionConfidence)) {
        featured = product;
      }
    }
    return featured;
  }

  String _imageLookupKey(ScanProductResult product) {
    return '${product.brand}|${product.confirmedName}'
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  void _dismissLastScannedNotice() {
    _noticeDismissTimer?.cancel();
    setState(() => _lastScanNotice = null);
  }

  bool _isMockAnalysis(CurrentScanState scan) {
    return ref.read(appConfigProvider).useMockAi ||
        scan.analysis?.warnings.any(
              (warning) => warning.toLowerCase().contains('mock analysis mode'),
            ) ==
            true;
  }

  bool get _hasLiveAiConfiguration {
    final config = ref.read(appConfigProvider);
    return !config.useMockAi && config.hasAiCredentials;
  }

  String get _missingAiConfigurationMessage {
    final config = ref.read(appConfigProvider);
    if (config.useMockAi) {
      return 'Live AI is off. Run .\\tool\\run_openai.ps1';
    }
    if (!config.hasAiCredentials) {
      return 'OpenAI key missing. Run .\\tool\\run_openai.ps1';
    }
    return 'Live AI unavailable';
  }

  String _emptyScanReason(CurrentScanState scan) {
    final warnings = scan.analysis?.warnings ?? const [];
    for (final warning in warnings) {
      final usefulWarning = warning.trim();
      if (usefulWarning.isEmpty) {
        continue;
      }
      return usefulWarning.length > 52
          ? '${usefulWarning.substring(0, 49)}...'
          : usefulWarning;
    }
    return 'No label read yet - hold steady';
  }

  String _readableAnalysisError(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('timed out')) {
      return 'OpenAI timed out - retrying';
    }
    if (lower.contains('api key') || lower.contains('401')) {
      return _missingAiConfigurationMessage;
    }
    if (lower.contains('network') || lower.contains('socket')) {
      return 'Network issue - retrying';
    }
    return 'AI issue - retrying';
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
    if (_isCapturing || _isAnalyzing) {
      _scanGeneration++;
      _scanNowAfterBusy = true;
      ref.read(currentScanControllerProvider.notifier).reset();
      setState(() => _statusLabel = 'Scanning next clear frame');
      return;
    }
    ref.read(currentScanControllerProvider.notifier).reset();
    _scanTimer?.cancel();
    setState(() {
      _isPaused = false;
      _cameraError = '';
      _statusLabel = 'Scanning live inventory';
    });
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      _initializeCamera();
    } else {
      _scheduleNextScan(Duration.zero);
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
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _lastScanNotice == null
                        ? const SizedBox.shrink()
                        : _LastScannedProductCard(
                            key: ValueKey(_lastScanNotice!.lookupKey),
                            notice: _lastScanNotice!,
                            onDismiss: _dismissLastScannedNotice,
                          ),
                  ),
                  if (_lastScanNotice != null) const SizedBox(height: 14),
                  _ScannerControls(
                    onInventory: _openInventory,
                    onRestart: _restartScan,
                    isBusy: _isInitializing || _isCapturing || _isAnalyzing,
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

class _ScannedProductNotice {
  const _ScannedProductNotice({
    required this.product,
    required this.totalUnits,
    required this.totalUniqueProducts,
    required this.localImagePath,
    required this.lookupKey,
    required this.imageFuture,
  });

  final ScanProductResult product;
  final int totalUnits;
  final int totalUniqueProducts;
  final String localImagePath;
  final String lookupKey;
  final Future<ProductWebImage?> imageFuture;
}

class _LastScannedProductCard extends StatelessWidget {
  const _LastScannedProductCard({
    required this.notice,
    required this.onDismiss,
    super.key,
  });

  final _ScannedProductNotice notice;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final product = notice.product;
    final unitsText =
        notice.totalUnits == 1 ? '1 unit' : '${notice.totalUnits} units';
    final detailText = notice.totalUniqueProducts == 1
        ? 'Added $unitsText'
        : 'Added $unitsText across ${notice.totalUniqueProducts} products';

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _WebProductThumbnail(
                    imageFuture: notice.imageFuture,
                    localImagePath: notice.localImagePath,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.mint,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Scanned',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          product.confirmedName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          detailText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    tooltip: 'Dismiss',
                    onPressed: onDismiss,
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.muted,
                      minimumSize: const Size(36, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WebProductThumbnail extends StatelessWidget {
  const _WebProductThumbnail({
    required this.imageFuture,
    required this.localImagePath,
  });

  final Future<ProductWebImage?> imageFuture;
  final String localImagePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        width: 68,
        height: 68,
        child: FutureBuilder<ProductWebImage?>(
          future: imageFuture,
          builder: (context, snapshot) {
            final image = snapshot.data;
            if (image != null) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    image.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _ProductImageFallback(localImagePath: localImagePath),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) {
                        return child;
                      }
                      return const _ProductImageLoading();
                    },
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.58),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.public_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ],
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ProductImageLoading();
            }
            return _ProductImageFallback(localImagePath: localImagePath);
          },
        ),
      ),
    );
  }
}

class _ProductImageLoading extends StatelessWidget {
  const _ProductImageLoading();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.softGradient),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.indigo.withValues(alpha: 0.82),
          ),
        ),
      ),
    );
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback({this.localImagePath = ''});

  final String localImagePath;

  @override
  Widget build(BuildContext context) {
    final path = localImagePath.trim();
    if (path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.file(file, fit: BoxFit.cover),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.all(5),
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ],
        );
      }
    }
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.softGradient),
      child: Icon(
        Icons.inventory_2_outlined,
        color: AppColors.indigo,
        size: 26,
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
    required this.onInventory,
    required this.onRestart,
    required this.isBusy,
  });

  final VoidCallback onInventory;
  final VoidCallback onRestart;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.darkNav.withValues(alpha: 0.64),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.26),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BottomControl(
                  icon: Icons.inventory_2_outlined,
                  label: 'Inventory',
                  onTap: onInventory,
                ),
                const SizedBox(width: 26),
                _LiveScanButton(
                  isBusy: isBusy,
                  onTap: onRestart,
                ),
                const SizedBox(width: 26),
                _BottomControl(
                  icon: Icons.replay_rounded,
                  label: 'Retry',
                  onTap: onRestart,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveScanButton extends StatefulWidget {
  const _LiveScanButton({
    required this.isBusy,
    required this.onTap,
  });

  final bool isBusy;
  final VoidCallback onTap;

  @override
  State<_LiveScanButton> createState() => _LiveScanButtonState();
}

class _LiveScanButtonState extends State<_LiveScanButton> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: widget.isBusy ? Colors.white : AppColors.indigo,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.indigo.withValues(alpha: 0.38),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Icon(
            widget.isBusy
                ? Icons.auto_awesome_motion_rounded
                : Icons.center_focus_strong,
            color: widget.isBusy ? AppColors.indigo : Colors.white,
            size: 34,
          ),
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
