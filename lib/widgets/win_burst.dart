import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Форма заранее посчитанного кусочка праздника.
enum WinBurstShape { ribbon, diamond, tile, spark }

/// Кусочек дождя конфетти. Все нормализованные поля лежат в 0..1.
class WinBurstPiece {
  const WinBurstPiece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.spin,
    required this.wobble,
    required this.size,
    required this.alpha,
    required this.color,
    required this.shape,
  });

  final double x;
  final double delay;
  final double speed;
  final double spin;
  final double wobble;
  final double size;
  final double alpha;
  final Color color;
  final WinBurstShape shape;
}

/// Осколок взрыва из центра.
class WinBurstShard {
  const WinBurstShard({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.alpha,
    required this.color,
    required this.shape,
  });

  final double angle;
  final double speed;
  final double spin;
  final double size;
  final double alpha;
  final Color color;
  final WinBurstShape shape;
}

/// Луч вспышки из центра.
class WinBurstRay {
  const WinBurstRay({
    required this.angle,
    required this.length,
    required this.width,
  });

  final double angle;
  final double length;
  final double width;
}

/// Раскладка победы: считается один раз, художник только интерполирует t.
class WinBurstLayout {
  const WinBurstLayout({
    required this.pieces,
    required this.shards,
    required this.rays,
  });

  static const defaultSeed = 42;
  static const defaultCount = 96;
  static const defaultShardCount = 32;
  static const defaultRayCount = 16;

  static const colors = <Color>[
    Color(0xFFD4AF37),
    Color(0xFFE8C96A),
    Color(0xFFF8F1DE),
    Color(0xFFE84855),
    Color(0xFF4DA3FF),
    Color(0xFF3DDC97),
    Color(0xFFFF8A4C),
    Colors.white,
  ];

  final List<WinBurstPiece> pieces;
  final List<WinBurstShard> shards;
  final List<WinBurstRay> rays;

  factory WinBurstLayout.generate({
    int seed = defaultSeed,
    int count = defaultCount,
    int shardCount = defaultShardCount,
    int rayCount = defaultRayCount,
  }) {
    final rng = math.Random(seed);
    final shapes = WinBurstShape.values;

    final pieces = List<WinBurstPiece>.generate(count, (i) {
      return WinBurstPiece(
        x: rng.nextDouble(),
        delay: rng.nextDouble(),
        speed: 0.35 + rng.nextDouble() * 0.65,
        spin: rng.nextDouble(),
        wobble: rng.nextDouble(),
        size: 0.35 + rng.nextDouble() * 0.65,
        alpha: 0.55 + rng.nextDouble() * 0.45,
        color: colors[i % colors.length],
        shape: shapes[i % shapes.length],
      );
    });

    final shards = List<WinBurstShard>.generate(shardCount, (i) {
      return WinBurstShard(
        angle: rng.nextDouble(),
        speed: 0.35 + rng.nextDouble() * 0.65,
        spin: rng.nextDouble(),
        size: 0.35 + rng.nextDouble() * 0.65,
        alpha: 0.6 + rng.nextDouble() * 0.4,
        color: colors[(i + 3) % colors.length],
        shape: shapes[(i + 1) % shapes.length],
      );
    });

    final rays = List<WinBurstRay>.generate(rayCount, (i) {
      return WinBurstRay(
        angle: (i + rng.nextDouble() * 0.35) / rayCount,
        length: 0.45 + rng.nextDouble() * 0.55,
        width: 0.35 + rng.nextDouble() * 0.65,
      );
    });

    return WinBurstLayout(pieces: pieces, shards: shards, rays: rays);
  }
}

/// Полноэкранный праздник: вспышка из центра и циклический дождь.
class WinBurstPainter extends CustomPainter {
  const WinBurstPainter({
    required this.layout,
    required this.burstT,
    required this.rainT,
  });

  final WinBurstLayout layout;
  final double burstT;
  final double rainT;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final center = Offset(size.width * 0.5, size.height * 0.42);
    _paintRays(canvas, size, center);
    _paintShards(canvas, size, center);
    _paintRain(canvas, size);
  }

  void _paintRays(Canvas canvas, Size size, Offset center) {
    final t = burstT.clamp(0.0, 1.0);
    if (t <= 0) return;

    final spread = Curves.easeOutCubic.transform(t);
    final fade = (1 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
    if (fade <= 0.01) return;

    final reach = size.shortestSide * 0.55;

    for (final ray in layout.rays) {
      final angle = ray.angle * math.pi * 2;
      final dist = (40 + reach * ray.length) * spread;
      final tip =
          center +
          Offset(math.cos(angle) * dist, math.sin(angle) * dist * 0.78);
      canvas.drawLine(
        center,
        tip,
        Paint()
          ..color = const Color(0xFFE8C96A).withValues(alpha: 0.55 * fade)
          ..strokeWidth = 1.6 + ray.width * 3.4
          ..strokeCap = StrokeCap.round
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.4),
      );
    }
  }

  void _paintShards(Canvas canvas, Size size, Offset center) {
    final t = burstT.clamp(0.0, 1.0);
    if (t <= 0) return;

    final spread = Curves.easeOutCubic.transform(t);
    final fade = (1 - Curves.easeIn.transform(t)).clamp(0.0, 1.0);
    if (fade <= 0.01) return;

    final travel = size.shortestSide * 0.62;

    for (final shard in layout.shards) {
      final angle = shard.angle * math.pi * 2;
      final dist = (28 + travel * shard.speed) * spread;
      final pos =
          center +
          Offset(math.cos(angle) * dist, math.sin(angle) * dist * 0.82);
      final rotation = t * math.pi * 2 * (0.6 + shard.spin * 2.4);
      _drawShape(
        canvas,
        pos: pos,
        rotation: rotation,
        shape: shard.shape,
        color: shard.color.withValues(alpha: shard.alpha * fade),
        size: shard.size,
      );
    }
  }

  void _paintRain(Canvas canvas, Size size) {
    final t = rainT.clamp(0.0, 1.0);

    for (final piece in layout.pieces) {
      final span = (0.55 + piece.speed * 0.45).clamp(0.35, 1.0);
      var local = (t * span + piece.delay) % 1.0;
      if (local < 0) local += 1;

      var edgeFade = 1.0;
      if (local < 0.06) {
        edgeFade = local / 0.06;
      } else if (local > 0.9) {
        edgeFade = (1 - local) / 0.1;
      }
      final alpha = piece.alpha * edgeFade;
      if (alpha <= 0.02) continue;

      final wobble =
          math.sin((t + piece.wobble) * math.pi * 2 * (1.2 + piece.spin)) *
          (10 + piece.wobble * 18);
      final pos = Offset(
        piece.x * size.width + wobble,
        -24 + local * (size.height + 48),
      );
      final rotation = local * math.pi * 2 * (1 + piece.spin * 2.5);

      _drawShape(
        canvas,
        pos: pos,
        rotation: rotation,
        shape: piece.shape,
        color: piece.color.withValues(alpha: alpha),
        size: piece.size,
      );
    }
  }

  void _drawShape(
    Canvas canvas, {
    required Offset pos,
    required double rotation,
    required WinBurstShape shape,
    required Color color,
    required double size,
  }) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);

    switch (shape) {
      case WinBurstShape.ribbon:
        final w = 4.2 + size * 5.5;
        final h = 8.5 + size * 8;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: w, height: h),
            const Radius.circular(1.4),
          ),
          Paint()..color = color,
        );
      case WinBurstShape.diamond:
        final s = 4.2 + size * 6.2;
        final path = Path()
          ..moveTo(0, -s)
          ..lineTo(s * 0.72, 0)
          ..lineTo(0, s)
          ..lineTo(-s * 0.72, 0)
          ..close();
        canvas.drawPath(path, Paint()..color = color);
      case WinBurstShape.tile:
        final w = 6.5 + size * 6.5;
        final h = 8.5 + size * 8;
        final outer = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(1.8),
        );
        canvas.drawRRect(outer, Paint()..color = color);
        canvas.drawRRect(
          outer.deflate(1.15),
          Paint()..color = const Color(0xFFF8F1DE).withValues(alpha: 0.92),
        );
        canvas.drawCircle(
          Offset.zero,
          1.15 + size * 0.7,
          Paint()..color = color,
        );
      case WinBurstShape.spark:
        final r = 1.6 + size * 2.4;
        canvas.drawCircle(
          Offset.zero,
          r,
          Paint()
            ..color = color
            ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.3),
        );
        canvas.drawCircle(Offset.zero, r * 0.45, Paint()..color = Colors.white);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WinBurstPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.burstT != burstT ||
        oldDelegate.rainT != rainT;
  }
}

/// Медленно вращающиеся лучи за карточкой.
class WinSunburstPainter extends CustomPainter {
  const WinSunburstPainter({required this.rotation, required this.intensity});

  final double rotation;
  final double intensity;

  static const _rayCount = 20;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || intensity <= 0) return;

    final center = Offset(size.width * 0.5, size.height * 0.42);
    final radius = size.longestSide * 0.72;
    final turn = rotation * math.pi * 2;
    final wedge = math.pi / _rayCount;

    for (var i = 0; i < _rayCount; i++) {
      final angle = turn + i * math.pi * 2 / _rayCount;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + math.cos(angle - wedge * 0.42) * radius,
          center.dy + math.sin(angle - wedge * 0.42) * radius,
        )
        ..lineTo(
          center.dx + math.cos(angle + wedge * 0.42) * radius,
          center.dy + math.sin(angle + wedge * 0.42) * radius,
        )
        ..close();

      final gold = i.isEven;
      canvas.drawPath(
        path,
        Paint()
          ..color = (gold ? const Color(0xFFE8C96A) : const Color(0xFF3DDC97))
              .withValues(alpha: (gold ? 0.14 : 0.08) * intensity)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WinSunburstPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.intensity != intensity;
  }
}
