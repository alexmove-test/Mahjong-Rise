import 'package:flutter/material.dart';

import '../services/table_look_controller.dart';
import 'premium_ui.dart';
import 'table_theme.dart';

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
      final premium = TableLookScope.lookOf(context).isPremium;
      if (premium) return _PremiumTableBackdrop(vignetteCenter: vignetteCenter);
      return Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF0B3D28)),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/felt.png'),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: vignetteCenter,
                  radius: 1.12,
                  colors: [
                    const Color(0xFFF8F1DE).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.62],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BoardVignetteOverlay(
              center: vignetteCenter,
              intensity: 0.48,
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
        const Positioned.fill(child: CustomPaint(painter: _MenuDamaskPainter())),
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

/// Тёплый деревянно-кожаный стол темы «Новая» — вместо зелёного сукна.
class _PremiumTableBackdrop extends StatelessWidget {
  const _PremiumTableBackdrop({required this.vignetteCenter});

  final Alignment vignetteCenter;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: TableUi.premiumTableDeep),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: vignetteCenter,
                radius: 1.25,
                colors: const [
                  TableUi.premiumTableHi,
                  TableUi.premiumTableMid,
                  TableUi.premiumTableDeep,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        const Positioned.fill(
          child: CustomPaint(painter: _LeatherGrainPainter()),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: vignetteCenter,
                radius: 1.05,
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.55],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: BoardVignetteOverlay(
            center: vignetteCenter,
            intensity: 0.60,
            dark: true,
            edgeColor: const Color(0xFF0F0803),
            midColor: const Color(0xFF1E1006),
          ),
        ),
      ],
    );
  }
}

/// Лёгкая диагональная фактура кожи/дерева — без внешних текстур.
class _LeatherGrainPainter extends CustomPainter {
  const _LeatherGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const step = 26.0;
    final light = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1.0;
    final dark = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 1.0;

    for (var i = -size.height.toInt(); i < size.width; i += step.toInt()) {
      final x = i.toDouble();
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        (i ~/ step).isEven ? light : dark,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MenuDamaskPainter extends CustomPainter {
  const _MenuDamaskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const step = 52.0;
    final stroke = Paint()
      ..color = const Color(0xFF2F6B4F).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final fill = Paint()
      ..color = const Color(0xFF4C9A6E).withValues(alpha: 0.06);

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
