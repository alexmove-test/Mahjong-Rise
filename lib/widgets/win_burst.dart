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

    final center = Offset(size.width * 0.5, size.height * 0.5);
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

const _titleInk = Color(0xFF140E08);
const _titleGoldLo = Color(0xFFB07A18);
const _titleGold = Color(0xFFE8C96A);
const _titleIvory = Color(0xFFFFF6D8);

/// Тёмный ореол, лучи и искры вокруг победной надписи.
class WinTitleHaloPainter extends CustomPainter {
  const WinTitleHaloPainter({required this.spin, required this.glow});

  final double spin;
  final double glow;

  static const _rayCount = 12;
  static const _sparkCount = 9;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || glow <= 0) return;

    final center = Offset(size.width * 0.5, size.height * 0.48);
    _paintVeil(canvas, size, center);
    _paintBloom(canvas, size, center);
    _paintRays(canvas, size, center);
    _paintSparkles(canvas, size, center);
    _paintFlourish(canvas, size, center);
  }

  void _paintVeil(Canvas canvas, Size size, Offset center) {
    final veil = Rect.fromCenter(
      center: center,
      width: size.width * 1.08,
      height: size.height * 0.96,
    );
    canvas.drawOval(
      veil,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xF205120C).withValues(alpha: 0.82 * glow),
            const Color(0xCC05140F).withValues(alpha: 0.46 * glow),
            const Color(0x0003120C),
          ],
          stops: const [0.0, 0.48, 1.0],
        ).createShader(veil),
    );
  }

  void _paintBloom(Canvas canvas, Size size, Offset center) {
    final radius = size.shortestSide * 0.42;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = _titleGold.withValues(alpha: 0.28 * glow)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 22),
    );
    canvas.drawCircle(
      center,
      radius * 0.42,
      Paint()
        ..color = _titleIvory.withValues(alpha: 0.16 * glow)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12),
    );
  }

  void _paintRays(Canvas canvas, Size size, Offset center) {
    final radius = size.longestSide * 0.62;
    final turn = spin * math.pi * 2;
    final wedge = math.pi / _rayCount;

    for (var i = 0; i < _rayCount; i++) {
      final angle = turn + i * math.pi * 2 / _rayCount;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..lineTo(
          center.dx + math.cos(angle - wedge * 0.28) * radius,
          center.dy + math.sin(angle - wedge * 0.28) * radius,
        )
        ..lineTo(
          center.dx + math.cos(angle + wedge * 0.28) * radius,
          center.dy + math.sin(angle + wedge * 0.28) * radius,
        )
        ..close();
      canvas.drawPath(
        path,
        Paint()
          ..color = _titleGold.withValues(
            alpha: (i.isEven ? 0.18 : 0.08) * glow,
          )
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _paintSparkles(Canvas canvas, Size size, Offset center) {
    for (var i = 0; i < _sparkCount; i++) {
      final angle = spin * math.pi * 2 * 0.7 + i * 2.399963;
      final orbit = 0.74 + 0.08 * math.sin(spin * math.pi * 4 + i);
      final pos = Offset(
        center.dx + math.cos(angle) * size.width * 0.46 * orbit,
        center.dy + math.sin(angle) * size.height * 0.40 * orbit,
      );
      final twinkle =
          (0.35 + 0.65 * (0.5 + 0.5 * math.sin(spin * math.pi * 6 + i * 1.7))) *
          glow;
      if (twinkle <= 0.05) continue;

      final r = 1.6 + (i % 3) * 0.9;
      canvas.drawCircle(
        pos,
        r * 2.1,
        Paint()
          ..color = _titleGold.withValues(alpha: 0.42 * twinkle)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3.2),
      );
      _drawDiamond(canvas, pos, r * (0.85 + 0.35 * twinkle), twinkle);
    }
  }

  void _drawDiamond(Canvas canvas, Offset pos, double s, double alpha) {
    final path = Path()
      ..moveTo(pos.dx, pos.dy - s * 1.7)
      ..lineTo(pos.dx + s * 0.7, pos.dy)
      ..lineTo(pos.dx, pos.dy + s * 1.7)
      ..lineTo(pos.dx - s * 0.7, pos.dy)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = _titleIvory.withValues(alpha: 0.92 * alpha),
    );
  }

  void _paintFlourish(Canvas canvas, Size size, Offset center) {
    final y = center.dy + size.height * 0.28;
    final half = size.width * 0.22;
    final paint = Paint()
      ..color = _titleGold.withValues(alpha: 0.72 * glow)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(center.dx - half, y),
      Offset(center.dx + half, y),
      paint,
    );
    _drawDiamond(canvas, Offset(center.dx, y), 3.4, glow);
    _drawDiamond(canvas, Offset(center.dx - half, y), 2.2, glow * 0.85);
    _drawDiamond(canvas, Offset(center.dx + half, y), 2.2, glow * 0.85);
  }

  @override
  bool shouldRepaint(covariant WinTitleHaloPainter oldDelegate) {
    return oldDelegate.spin != spin || oldDelegate.glow != glow;
  }
}

/// Металлическая «Победа!» с контуром, свечением и бликом.
class WinTitleGlyphPainter extends CustomPainter {
  const WinTitleGlyphPainter({
    required this.text,
    required this.textDirection,
    required this.shimmer,
    required this.glow,
  });

  final String text;
  final TextDirection textDirection;
  final double shimmer;
  final double glow;

  static const style = TextStyle(
    fontWeight: FontWeight.w900,
    fontSize: 52,
    height: 1.05,
    letterSpacing: 2.2,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || text.isEmpty) return;

    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(color: Colors.white),
      ),
      textAlign: TextAlign.center,
      textDirection: textDirection,
    )..layout();
    final origin = Offset(
      (size.width - painter.width) / 2,
      (size.height - painter.height) / 2,
    );
    final rect = origin & Size(painter.width, painter.height);

    _paintGlow(canvas, painter, origin, rect);
    _paintStroke(canvas, origin, 8.8, _titleInk.withValues(alpha: 0.96));
    _paintStroke(canvas, origin, 3.8, _titleGoldLo);
    _paintFill(canvas, painter, origin, rect);
  }

  void _paintGlow(
    Canvas canvas,
    TextPainter painter,
    Offset origin,
    Rect rect,
  ) {
    final bounds = rect.inflate(36);
    canvas.saveLayer(
      bounds,
      Paint()
        ..color = _titleGold.withValues(alpha: 0.55 * glow)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 16),
    );
    painter.paint(canvas, origin);
    canvas.restore();

    canvas.saveLayer(
      bounds,
      Paint()
        ..color = const Color(0xCC000000).withValues(alpha: 0.55)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6),
    );
    painter.paint(canvas, origin + const Offset(0, 3.2));
    canvas.restore();
  }

  void _paintStroke(Canvas canvas, Offset origin, double width, Color color) {
    final stroke = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..strokeJoin = StrokeJoin.round
            ..color = color,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: textDirection,
    )..layout();
    stroke.paint(canvas, origin);
  }

  void _paintFill(
    Canvas canvas,
    TextPainter painter,
    Offset origin,
    Rect rect,
  ) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    final local = Offset.zero & Size(painter.width, painter.height);
    canvas.saveLayer(local, Paint());
    painter.paint(canvas, Offset.zero);
    canvas.drawRect(
      local,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF8E8),
            Color(0xFFFFE58A),
            Color(0xFFE4B84A),
            Color(0xFFC4922A),
          ],
          stops: [0.0, 0.36, 0.72, 1.0],
        ).createShader(local)
        ..blendMode = BlendMode.srcIn,
    );
    final x = -1.2 + 2.4 * shimmer;
    canvas.drawRect(
      local,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment(x - 0.22, -0.7),
          end: Alignment(x + 0.22, 0.7),
          colors: [
            const Color(0x00FFFFFF),
            Colors.white.withValues(alpha: 0.9 * glow),
            const Color(0x00FFFFFF),
          ],
        ).createShader(local)
        ..blendMode = BlendMode.srcATop,
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WinTitleGlyphPainter oldDelegate) {
    return oldDelegate.text != text ||
        oldDelegate.textDirection != textDirection ||
        oldDelegate.shimmer != shimmer ||
        oldDelegate.glow != glow;
  }
}
