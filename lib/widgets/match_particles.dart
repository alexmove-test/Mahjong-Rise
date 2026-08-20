import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 10–15 золотых искорок при совпадении плиток (0.5 с).
class MatchSparkBurst extends StatelessWidget {
  const MatchSparkBurst({
    super.key,
    required this.progress,
    required this.width,
    required this.height,
    this.particleCount = 12,
  });

  final double progress;
  final double width;
  final double height;
  final int particleCount;

  static const duration = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _SparkParticlePainter(
        progress: progress,
        particleCount: particleCount.clamp(10, 15),
      ),
    );
  }
}

class _SparkParticlePainter extends CustomPainter {
  _SparkParticlePainter({
    required this.progress,
    required this.particleCount,
  });

  final double progress;
  final int particleCount;

  static const _gold = Color(0xFFE8C96A);
  static const _goldDeep = Color(0xFFD4AF37);
  static const _white = Color(0xFFFFF8E8);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width * 0.5, size.height * 0.46);
    final travel = size.shortestSide * 0.62;
    final t = progress.clamp(0.0, 1.0);
    final fade = (1 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
    final spread = Curves.easeOutCubic.transform(t);

    for (var i = 0; i < particleCount; i++) {
      final rng = math.Random(i * 29 + 11);
      final angle = rng.nextDouble() * 2 * math.pi;
      final speed = 0.45 + rng.nextDouble() * 0.75;
      final drift = travel * speed * spread;

      final origin = Offset(
        (rng.nextDouble() - 0.5) * size.width * 0.14,
        (rng.nextDouble() - 0.5) * size.height * 0.10,
      );

      final pos = center +
          origin +
          Offset(
            math.cos(angle) * drift,
            math.sin(angle) * drift * 0.85 + t * travel * 0.06,
          );

      final alpha = (0.35 + rng.nextDouble() * 0.55) * fade;
      if (alpha <= 0.01) continue;

      final kind = i % 3;
      if (kind == 0) {
        _drawDot(canvas, pos, 1.6 + rng.nextDouble() * 2.2, alpha, rng);
      } else if (kind == 1) {
        _drawStreak(
          canvas,
          pos,
          angle + rng.nextDouble() * 0.4,
          4 + rng.nextDouble() * 5,
          alpha,
        );
      } else {
        _drawSpark(canvas, pos, angle, 3 + rng.nextDouble() * 3, alpha);
      }
    }
  }

  void _drawDot(
    Canvas canvas,
    Offset c,
    double r,
    double alpha,
    math.Random rng,
  ) {
    final color = Color.lerp(_goldDeep, _white, rng.nextDouble())!
        .withValues(alpha: alpha);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = color
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.2),
    );
  }

  void _drawStreak(
    Canvas canvas,
    Offset c,
    double angle,
    double len,
    double alpha,
  ) {
    final end = c + Offset(math.cos(angle) * len, math.sin(angle) * len);
    canvas.drawLine(
      c,
      end,
      Paint()
        ..color = _gold.withValues(alpha: alpha * 0.9)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 0.8),
    );
  }

  void _drawSpark(
    Canvas canvas,
    Offset c,
    double angle,
    double size,
    double alpha,
  ) {
    final paint = Paint()
      ..color = _white.withValues(alpha: alpha)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;

    for (var i = -1; i <= 1; i++) {
      final a = angle + i * 0.55;
      canvas.drawLine(
        c,
        c + Offset(math.cos(a) * size, math.sin(a) * size),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparkParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.particleCount != particleCount;
  }
}
