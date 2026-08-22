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
              return Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _ScannerPainter(
                      value: _controller.value,
                    ),
                    child: const SizedBox.expand(),
                  ),
                  _StatusPill(label: widget.progressLabel),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: const Alignment(0, -0.58),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
            ),
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
    final sweepTop = size.height * 0.12;
    final sweepBottom = size.height * 0.86;

    final shadePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x4A000000),
          Color(0x05000000),
          Color(0x3A000000),
        ],
        stops: [0, 0.52, 1],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(fullRect);
    canvas.drawRect(fullRect, shadePaint);

    final radialPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.07),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height * 0.52),
          radius: size.shortestSide * 0.7,
        ),
      );
    canvas.drawRect(fullRect, radialPaint);

    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.86)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const inset = 18.0;
    const corner = 34.0;
    final top = sweepTop;
    final bottom = sweepBottom;
    canvas.drawLine(const Offset(inset, 0).translate(0, top),
        const Offset(inset + corner, 0).translate(0, top), edgePaint);
    canvas.drawLine(Offset(size.width - inset - corner, top),
        Offset(size.width - inset, top), edgePaint);
    canvas.drawLine(Offset(inset, top), Offset(inset, top + corner), edgePaint);
    canvas.drawLine(Offset(size.width - inset, top),
        Offset(size.width - inset, top + corner), edgePaint);
    canvas.drawLine(
        Offset(inset, bottom), Offset(inset + corner, bottom), edgePaint);
    canvas.drawLine(Offset(size.width - inset - corner, bottom),
        Offset(size.width - inset, bottom), edgePaint);
    canvas.drawLine(
        Offset(inset, bottom), Offset(inset, bottom - corner), edgePaint);
    canvas.drawLine(Offset(size.width - inset, bottom),
        Offset(size.width - inset, bottom - corner), edgePaint);

    final scanY = sweepTop + (sweepBottom - sweepTop) * value;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.34),
          const Color(0xFF0A84FF).withValues(alpha: 0.42),
          Colors.white.withValues(alpha: 0.34),
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 1, size.width, 2))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(18, scanY),
      Offset(size.width - 18, scanY),
      scanPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScannerPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
