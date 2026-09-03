import 'package:flutter/material.dart';

import 'premium_ui.dart';

/// Фон экранов: светлый damask для меню или сукно игрового стола.
class MahjongScreenBackdrop extends StatelessWidget {
  const MahjongScreenBackdrop({
    super.key,
    this.fieldGreen = const Color(0xFFD7EEDC),
    this.vignetteCenter = const Alignment(0, -0.08),
    this.dark = false,
  });

  final Color fieldGreen;
  final Alignment vignetteCenter;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (dark) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF052418),
                  Color(0xFF0B5C40),
                  Color(0xFF12855A),
                  Color(0xFF0B5C40),
                  Color(0xFF041C14),
                ],
                stops: [0.0, 0.18, 0.48, 0.78, 1.0],
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/felt.png'),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  opacity: 0.42,
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(painter: _DamaskPainter(dark: true)),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: vignetteCenter,
                  radius: 1.12,
                  colors: [
                    const Color(0xFFF8F1DE).withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.65],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BoardVignetteOverlay(
              center: vignetteCenter,
              intensity: 0.68,
              dark: true,
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: fieldGreen),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF5FBF6),
                  Color(0xFFD7EEDC),
                  Color(0xFFB5D9C2),
                ],
                stops: [0.0, 0.46, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: vignetteCenter,
                radius: 1.08,
                colors: [
                  Colors.white.withValues(alpha: 0.55),
                  Colors.transparent,
                  const Color(0xFF7CB392).withValues(alpha: 0.28),
                ],
                stops: const [0.0, 0.52, 1.0],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: CustomPaint(painter: _DamaskPainter())),
        Positioned.fill(
          child: BoardVignetteOverlay(
            center: vignetteCenter,
            intensity: 0.72,
            dark: false,
          ),
        ),
      ],
    );
  }
}

class _DamaskPainter extends CustomPainter {
  const _DamaskPainter({this.dark = false});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 52.0;
    final stroke = Paint()
      ..color = (dark ? const Color(0xFF1A4A34) : const Color(0xFF2F6B4F))
          .withValues(alpha: dark ? 0.34 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final fill = Paint()
      ..color = (dark ? const Color(0xFF0E3A28) : const Color(0xFF4C9A6E))
          .withValues(alpha: dark ? 0.22 : 0.06);

    for (var row = 0; row < size.height / step + 2; row++) {
      for (var col = 0; col < size.width / step + 2; col++) {
        final stagger = row.isOdd ? step * 0.5 : 0.0;
        final center = Offset(col * step + stagger, row * step);
        _rosette(canvas, center, step * 0.28, stroke, fill);
      }
    }
  }

  void _rosette(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.38, c.dy - r * 0.38)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + r * 0.38, c.dy + r * 0.38)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r * 0.38, c.dy + r * 0.38)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - r * 0.38, c.dy - r * 0.38)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    canvas.drawCircle(c, r * 0.16, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
