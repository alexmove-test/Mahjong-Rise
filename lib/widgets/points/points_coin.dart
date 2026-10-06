import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Символ баллов: золотая монета с квадратным отверстием.
class PointsCoin extends StatelessWidget {
  const PointsCoin({super.key, this.size = 22, this.shine = 0, this.glow = 0});

  final double size;

  /// Положение блика по монете, 0 — блика нет.
  final double shine;

  /// Сила золотого ореола вокруг монеты.
  final double glow;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: PointsCoinPainter(shine: shine, glow: glow),
    );
  }
}

class PointsCoinPainter extends CustomPainter {
  const PointsCoinPainter({this.shine = 0, this.glow = 0});

  final double shine;
  final double glow;

  static const _rim = Color(0xFF6E4A10);
  static const _hole = Color(0xFF2A1708);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = s * 0.46;

    if (glow > 0) {
      canvas.drawCircle(
        center,
        radius * 1.24,
        Paint()
          ..color = const Color(0xFFFFD86B).withValues(alpha: 0.42 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.14),
      );
    }

    canvas.drawCircle(
      center.translate(0, s * 0.05),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.34),
    );

    final face = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.34, -0.42),
          radius: 1.05,
          colors: [
            Color(0xFFFFF6D2),
            Color(0xFFF2D179),
            Color(0xFFC08F2E),
            Color(0xFF8A6014),
          ],
          stops: [0.0, 0.42, 0.78, 1.0],
        ).createShader(face),
    );

    canvas.drawCircle(
      center,
      radius - s * 0.02,
      Paint()
        ..color = _rim
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.045,
    );
    canvas.drawCircle(
      center,
      radius * 0.74,
      Paint()
        ..color = const Color(0xFF8A6014).withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03,
    );

    if (shine > 0) {
      canvas.save();
      canvas.clipPath(Path()..addOval(face));
      final travel = (shine * 2 - 1) * radius * 2.4;
      canvas.translate(center.dx + travel, center.dy);
      canvas.rotate(-math.pi / 7);
      final band = Rect.fromCenter(
        center: Offset.zero,
        width: s * 0.3,
        height: s * 2.4,
      );
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: 0.62),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(band),
      );
      canvas.restore();
    }

    final hole = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: radius * 0.52,
        height: radius * 0.52,
      ),
      Radius.circular(s * 0.025),
    );
    canvas.drawRRect(hole, Paint()..color = _hole);
    canvas.drawRRect(
      hole,
      Paint()
        ..color = const Color(0xFFFFE9A8).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.028,
    );
  }

  @override
  bool shouldRepaint(covariant PointsCoinPainter oldDelegate) =>
      oldDelegate.shine != shine || oldDelegate.glow != glow;
}
