import 'package:flutter/material.dart';

class ScannerOverlay extends StatefulWidget {
  const ScannerOverlay({
    super.key,
    this.progressLabel = 'Ready',
  });

  final String progressLabel;

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Semantics(
        label: widget.progressLabel,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _ScannerPainter(
                  value: _controller.value,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ScannerPainter extends CustomPainter {
  _ScannerPainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final scanRect = Rect.fromLTRB(
      8,
      58,
      size.width - 8,
      size.height - 94,
    );

    final shadePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x33000000),
          Color(0x05000000),
          Color(0x22000000),
        ],
        stops: [0, 0.48, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(fullRect);
    canvas.drawRect(fullRect, shadePaint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(24)),
      borderPaint,
    );

    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const corner = 52.0;
    for (final top in [scanRect.top, scanRect.bottom]) {
      final isTop = top == scanRect.top;
      canvas.drawLine(Offset(scanRect.left, top),
          Offset(scanRect.left + corner, top), cornerPaint);
      canvas.drawLine(Offset(scanRect.right - corner, top),
          Offset(scanRect.right, top), cornerPaint);
      canvas.drawLine(Offset(scanRect.left, top),
          Offset(scanRect.left, top + (isTop ? corner : -corner)), cornerPaint);
      canvas.drawLine(
          Offset(scanRect.right, top),
          Offset(scanRect.right, top + (isTop ? corner : -corner)),
          cornerPaint);
    }

    final scanY = scanRect.top + scanRect.height * value;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.26),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(scanRect.left, scanY - 1, scanRect.width, 2))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(scanRect.left + 28, scanY),
      Offset(scanRect.right - 28, scanY),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
