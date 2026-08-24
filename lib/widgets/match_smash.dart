import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../models/tile.dart';
import 'tile_widget.dart';

/// Редкий матч: плитки расходятся, бьются и разлетаются осколками.
abstract final class MatchSmash {
  static const chance = 0.28;
  static const duration = Duration(milliseconds: 1080);
  static const impactAt = 0.46;
  static const pullPx = 20.0;

  static bool roll(math.Random rng) => rng.nextDouble() < chance;
}

class MatchSmashShard {
  const MatchSmashShard({
    required this.angle,
    required this.speed,
    required this.spin,
    required this.size,
    required this.delay,
    required this.lift,
    required this.gravity,
    required this.alpha,
    required this.shape,
    required this.color,
  });

  final double angle;
  final double speed;
  final double spin;
  final double size;
  final double delay;
  final double lift;
  final double gravity;
  final double alpha;
  final int shape;
  final Color color;
}

/// Раскладка осколков: считается один раз, художник только интерполирует t.
class MatchSmashLayout {
  const MatchSmashLayout({required this.shards});

  static const defaultSeed = 11;
  static const defaultCount = 52;

  static const stone = <Color>[
    Color(0xFFFAFAF5),
    Color(0xFFF5F0E8),
    Color(0xFFEDE8DE),
    Color(0xFFE4DDD2),
    Color(0xFFD8D0C4),
    Color(0xFFC9BBA8),
    Color(0xFFE8C96A),
  ];

  final List<MatchSmashShard> shards;

  factory MatchSmashLayout.generate({
    int seed = defaultSeed,
    int count = defaultCount,
  }) {
    final rng = math.Random(seed);
    return MatchSmashLayout(
      shards: List<MatchSmashShard>.generate(count, (i) {
        final large = i < 10;
        return MatchSmashShard(
          angle: rng.nextDouble(),
          speed: large
              ? 0.42 + rng.nextDouble() * 0.58
              : 0.28 + rng.nextDouble() * 0.72,
          spin: rng.nextDouble(),
          size: large
              ? 0.62 + rng.nextDouble() * 0.38
              : 0.18 + rng.nextDouble() * 0.55,
          delay: rng.nextDouble() * 0.12,
          lift: rng.nextDouble(),
          gravity: 0.35 + rng.nextDouble() * 0.65,
          alpha: 0.62 + rng.nextDouble() * 0.38,
          shape: large ? rng.nextInt(2) : rng.nextInt(4),
          color: stone[i % stone.length],
        );
      }),
    );
  }
}

/// Полноэкранный удар пары: расходятся → столкновение → разлёт.
class MatchSmashOverlay extends StatefulWidget {
  const MatchSmashOverlay({
    super.key,
    required this.left,
    required this.right,
    required this.leftRect,
    required this.rightRect,
    required this.onImpact,
    required this.onComplete,
    this.layout,
  });

  final Tile left;
  final Tile right;
  final Rect leftRect;
  final Rect rightRect;
  final VoidCallback onImpact;
  final VoidCallback onComplete;
  final MatchSmashLayout? layout;

  static const duration = MatchSmash.duration;

  @override
  State<MatchSmashOverlay> createState() => _MatchSmashOverlayState();
}

class _MatchSmashOverlayState extends State<MatchSmashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final MatchSmashLayout _layout;
  bool _didImpact = false;
  bool _didComplete = false;

  @override
  void initState() {
    super.initState();
    _layout =
        widget.layout ??
        MatchSmashLayout.generate(seed: widget.left.id * 17 + widget.right.id);
    _ctrl = AnimationController(vsync: this, duration: MatchSmash.duration)
      ..addListener(_onTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !_didComplete) {
          _didComplete = true;
          widget.onComplete();
        }
      });
    _ctrl.forward();
  }

  void _onTick() {
    if (!_didImpact && _ctrl.value >= MatchSmash.impactAt) {
      _didImpact = true;
      widget.onImpact();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final impact = t >= MatchSmash.impactAt;
        final burstT = impact
            ? ((t - MatchSmash.impactAt) / (1 - MatchSmash.impactAt)).clamp(
                0.0,
                1.0,
              )
            : 0.0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (!impact) ...[
              _flyingTile(
                tile: widget.left,
                start: widget.leftRect,
                other: widget.rightRect,
                t: t,
                isLeft: true,
              ),
              _flyingTile(
                tile: widget.right,
                start: widget.rightRect,
                other: widget.leftRect,
                t: t,
                isLeft: false,
              ),
            ],
            if (burstT > 0)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: MatchSmashPainter(
                      layout: _layout,
                      progress: burstT,
                      origin: Offset.lerp(
                        widget.leftRect.center,
                        widget.rightRect.center,
                        0.5,
                      )!,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _flyingTile({
    required Tile tile,
    required Rect start,
    required Rect other,
    required double t,
    required bool isLeft,
  }) {
    final center = matchSmashCenter(start: start, other: other, t: t);
    final rotation = matchSmashRotation(isLeft: isLeft, t: t);
    final scale = matchSmashScale(t);
    return Positioned(
      left: center.dx - start.width / 2,
      top: center.dy - start.height / 2,
      width: start.width,
      height: start.height,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: rotation,
          child: Transform.scale(
            scale: scale,
            child: TileWidget(
              tile: tile,
              width: start.width,
              height: start.height,
              isSelected: false,
              isFree: true,
              compact: true,
            ),
          ),
        ),
      ),
    );
  }
}

Offset matchSmashCenter({
  required Rect start,
  required Rect other,
  required double t,
}) {
  final mid = Offset.lerp(start.center, other.center, 0.5)!;
  var axis = start.center - other.center;
  if (axis.distanceSquared < 1) {
    axis = Offset(start.center.dx <= other.center.dx ? -1 : 1, 0);
  } else {
    axis = axis / axis.distance;
  }
  final pulled = start.center + axis * MatchSmash.pullPx;
  if (t >= MatchSmash.impactAt) return mid;
  if (t < 0.26) {
    final p = Curves.easeOutCubic.transform(t / 0.26);
    return Offset.lerp(start.center, pulled, p)!;
  }
  if (t < 0.34) return pulled;
  final slam = Curves.easeInCubic.transform(
    ((t - 0.34) / (MatchSmash.impactAt - 0.34)).clamp(0.0, 1.0),
  );
  return Offset.lerp(pulled, mid, slam)!;
}

double matchSmashRotation({required bool isLeft, required double t}) {
  final sign = isLeft ? -1.0 : 1.0;
  if (t >= MatchSmash.impactAt) return 0;
  if (t < 0.26) {
    return sign * 0.16 * Curves.easeOut.transform(t / 0.26);
  }
  if (t < 0.34) return sign * 0.16;
  final slam = ((t - 0.34) / (MatchSmash.impactAt - 0.34)).clamp(0.0, 1.0);
  return sign * (0.16 * (1 - slam) - 0.1 * slam);
}

double matchSmashScale(double t) {
  if (t >= MatchSmash.impactAt) return 0;
  if (t < 0.34) return 1.0;
  final slam = ((t - 0.34) / (MatchSmash.impactAt - 0.34)).clamp(0.0, 1.0);
  if (slam < 0.72) {
    return 1.0 + 0.08 * Curves.easeOut.transform(slam / 0.72);
  }
  final squash = (slam - 0.72) / 0.28;
  return 1.08 - 0.2 * squash;
}

class MatchSmashPainter extends CustomPainter {
  const MatchSmashPainter({
    required this.layout,
    required this.progress,
    required this.origin,
  });

  final MatchSmashLayout layout;
  final double progress;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || size.isEmpty) return;

    final t = progress.clamp(0.0, 1.0);
    _paintFlash(canvas, size, t);
    _paintShards(canvas, size, t);
  }

  void _paintFlash(Canvas canvas, Size size, double t) {
    final flash = (1 - Curves.easeIn.transform((t / 0.18).clamp(0.0, 1.0)))
        .clamp(0.0, 1.0);
    if (flash <= 0.02) return;

    final reach =
        size.shortestSide * (0.08 + 0.42 * Curves.easeOut.transform(t));
    canvas.drawCircle(
      origin,
      reach,
      Paint()
        ..color = const Color(0xFFFFF4D4).withValues(alpha: 0.42 * flash)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 18),
    );
    canvas.drawCircle(
      origin,
      reach * 0.38,
      Paint()..color = Colors.white.withValues(alpha: 0.55 * flash),
    );

    final ring = size.shortestSide * 0.12 * Curves.easeOutCubic.transform(t);
    canvas.drawCircle(
      origin,
      ring,
      Paint()
        ..color = const Color(0xFFE8C96A).withValues(alpha: 0.55 * flash)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 + 4 * (1 - t)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 1.6),
    );
  }

  void _paintShards(Canvas canvas, Size size, double t) {
    final travel = size.longestSide * 0.72;
    final gravity = size.height * 1.15;

    for (final shard in layout.shards) {
      final local = ((t - shard.delay) / (1 - shard.delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final spread = Curves.easeOutCubic.transform(local);
      var fade = 1.0;
      if (local > 0.62) {
        fade = (1 - Curves.easeIn.transform((local - 0.62) / 0.38)).clamp(
          0.0,
          1.0,
        );
      }
      final alpha = shard.alpha * fade;
      if (alpha <= 0.02) continue;

      final angle = shard.angle * math.pi * 2;
      final dist = (36 + travel * shard.speed) * spread;
      final lift = -size.height * 0.22 * shard.lift * math.sin(local * math.pi);
      final pos =
          origin +
          Offset(
            math.cos(angle) * dist,
            math.sin(angle) * dist * 0.78 +
                lift +
                0.5 * gravity * shard.gravity * local * local,
          );
      final rotation = (shard.spin - 0.5) * math.pi * 2 * (0.4 + local * 3.2);
      final piece = (6.5 + shard.size * 22) * (0.7 + fade * 0.3);

      _drawShard(
        canvas,
        pos: pos,
        rotation: rotation,
        size: piece,
        color: shard.color.withValues(alpha: alpha),
        shape: shard.shape,
      );
    }
  }

  void _drawShard(
    Canvas canvas, {
    required Offset pos,
    required double rotation,
    required double size,
    required Color color,
    required int shape,
  }) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(rotation);

    final fill = Paint()..color = color;
    switch (shape) {
      case 0:
        final w = size * 1.15;
        final h = size * 1.35;
        final outer = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          Radius.circular(size * 0.16),
        );
        canvas.drawRRect(outer, fill);
        canvas.drawRRect(
          outer.deflate(size * 0.12),
          Paint()..color = const Color(0xFFF8F1DE).withValues(alpha: color.a),
        );
      case 1:
        final path = Path()
          ..moveTo(-size * 0.9, -size * 0.25)
          ..lineTo(size * 0.55, -size * 0.8)
          ..lineTo(size * 0.85, size * 0.45)
          ..lineTo(-size * 0.4, size * 0.7)
          ..close();
        canvas.drawPath(path, fill);
      case 2:
        final path = Path()
          ..moveTo(-size * 0.65, -size * 0.85)
          ..lineTo(size * 0.8, -size * 0.2)
          ..lineTo(size * 0.25, size * 0.8)
          ..close();
        canvas.drawPath(path, fill);
      default:
        canvas.drawLine(
          Offset(-size * 0.9, 0),
          Offset(size * 0.9, 0),
          Paint()
            ..color = color
            ..strokeWidth = 1.4 + size * 0.08
            ..strokeCap = StrokeCap.round,
        );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MatchSmashPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.progress != progress ||
        oldDelegate.origin != origin;
  }
}
