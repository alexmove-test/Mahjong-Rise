import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Осколки каменной плитки при снятии пары (Vita-стиль).
class MatchBurst extends StatelessWidget {
  const MatchBurst({
    super.key,
    required this.progress,
    required this.width,
    required this.height,
  });

  /// 0 → 1
  final double progress;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _ShardBurstPainter(progress: progress),
    );
  }
}

class _ShardBurstPainter extends CustomPainter {
  _ShardBurstPainter({required this.progress});

  final double progress;

  static const _shardCount = 30;

  static const _stoneColors = <Color>[
    Color(0xFFFAFAF5),
    Color(0xFFF5F0E8),
    Color(0xFFEDE8DE),
    Color(0xFFE4DDD2),
    Color(0xFFD8D0C4),
  ];

  static const _gravity = 520.0;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final center = Offset(size.width / 2, size.height * 0.42);
    final travel = size.shortestSide * 1.15;
    final t = progress;
    final fade = (1 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);

    for (var i = 0; i < _shardCount; i++) {
      final seed = i * 17 + 3;
      final rng = math.Random(seed);

      // Разлёт вниз и в стороны: угол смещён к нижней полуплоскости.
      final spread = (rng.nextDouble() - 0.5) * 1.35;
      final angle = math.pi * 0.55 + spread;
      final speed = 0.55 + rng.nextDouble() * 0.65;

      final vx = math.cos(angle) * speed * travel;
      final vy = math.sin(angle) * speed * travel * 0.85 + travel * 0.08;

      final origin = Offset(
        (rng.nextDouble() - 0.5) * size.width * 0.18,
        (rng.nextDouble() - 0.5) * size.height * 0.12,
      );

      final x = center.dx + origin.dx + vx * t;
      final y =
          center.dy +
          origin.dy +
          vy * t +
          0.5 * _gravity * t * t * (travel / 280);

      final rotation =
          (rng.nextDouble() - 0.5) * math.pi + (rng.nextDouble() - 0.5) * 9 * t;

      final shardSize = (3.5 + rng.nextDouble() * 5.5) * (0.55 + fade * 0.45);
      final color = _stoneColors[i % _stoneColors.length].withValues(
        alpha: (0.55 + rng.nextDouble() * 0.4) * fade,
      );

      _drawShard(
        canvas,
        Offset(x, y),
        shardSize,
        rotation,
        color,
        rng.nextInt(3),
      );
    }
  }

  void _drawShard(
    Canvas canvas,
    Offset center,
    double size,
    double rotation,
    Color color,
    int shape,
  ) {
    final path = Path();
    switch (shape) {
      case 0:
        path.moveTo(-size * 0.9, -size * 0.3);
        path.lineTo(size * 0.5, -size * 0.7);
        path.lineTo(size * 0.8, size * 0.4);
        path.lineTo(-size * 0.4, size * 0.6);
        break;
      case 1:
        path.moveTo(-size * 0.6, -size * 0.8);
        path.lineTo(size * 0.7, -size * 0.2);
        path.lineTo(size * 0.3, size * 0.75);
        break;
      default:
        path.moveTo(-size * 0.75, size * 0.1);
        path.lineTo(size * 0.2, -size * 0.85);
        path.lineTo(size * 0.85, size * 0.15);
        path.lineTo(size * 0.1, size * 0.8);
        path.lineTo(-size * 0.55, size * 0.55);
    }
    path.close();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShardBurstPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
