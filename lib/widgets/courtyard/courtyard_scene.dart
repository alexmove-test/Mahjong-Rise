import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'courtyard_progress.dart';

/// Живой двор: на хабе статичен (с лёгким idle), после победы — рост ~2.4 с
/// с лёгким Ken Burns к дому.
class CourtyardScene extends StatefulWidget {
  const CourtyardScene({
    super.key,
    required this.to,
    this.from,
    this.animate = false,
    this.idle = true,
    this.cycle = 0,
  });

  final CourtyardSnapshot to;
  final CourtyardSnapshot? from;
  final bool animate;
  final bool idle;

  /// 0-based номер участка: 1 = мультяшный двор.
  final int cycle;

  static const growDuration = Duration(milliseconds: 2400);

  @override
  State<CourtyardScene> createState() => _CourtyardSceneState();
}

class _CourtyardSceneState extends State<CourtyardScene>
    with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _grow;

  static const _artAlign = Alignment(0, -0.28);
  static const _growZoom = 0.05;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _grow = AnimationController(
      vsync: this,
      duration: CourtyardScene.growDuration,
    );
    if (widget.idle) _idle.repeat();
    if (widget.animate) _grow.forward();
  }

  void _precacheArt() {
    for (final asset in CourtyardArtFade.assetsFor(widget.cycle)) {
      precacheImage(AssetImage(asset), context);
    }
    precacheImage(
      AssetImage(CourtyardArtFade.lifeAssetFor(widget.cycle)),
      context,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _precacheArt();
  }

  @override
  void didUpdateWidget(covariant CourtyardScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cycle != oldWidget.cycle) {
      _precacheArt();
    }
    if (widget.idle && !_idle.isAnimating) {
      _idle.repeat();
    } else if (!widget.idle && _idle.isAnimating) {
      _idle.stop();
    }
    if (widget.animate &&
        (oldWidget.from != widget.from || oldWidget.to != widget.to)) {
      _grow.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    _grow.dispose();
    super.dispose();
  }

  CourtyardSnapshot get _snapshot {
    final from = widget.from;
    if (!widget.animate || from == null) return widget.to;
    return CourtyardSnapshot.lerp(
      from,
      widget.to,
      Curves.easeInOutCubic.transform(_grow.value),
    );
  }

  Widget _plate(String asset) {
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      alignment: _artAlign,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_idle, _grow]),
        builder: (context, _) {
          final snapshot = _snapshot;
          final fade = snapshot.artFade;
          final plates = CourtyardArtFade.assetsFor(widget.cycle);
          final breath = widget.idle
              ? 1.0 + 0.01 * (0.5 - 0.5 * math.cos(_idle.value * 2 * math.pi))
              : 1.0;
          final kenBurns = widget.animate
              ? 1.0 + _growZoom * Curves.easeOutCubic.transform(_grow.value)
              : 1.0;
          final life = snapshot.lifeArt;

          return ClipRect(
            child: Transform.scale(
              scale: breath * kenBurns,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _plate(plates[fade.fromIndex]),
                  if (fade.blend > 0.01)
                    Opacity(
                      opacity: fade.blend,
                      child: _plate(plates[fade.toIndex]),
                    ),
                  if (life > 0.01)
                    Opacity(
                      opacity: life,
                      child: _plate(
                        CourtyardArtFade.lifeAssetFor(widget.cycle),
                      ),
                    ),
                  if (snapshot.festival > 0.02 || snapshot.streakLife > 0.08)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: FestivalLanternsPainter(
                          strength: (snapshot.festival * 0.7 +
                                  snapshot.streakLife * 0.5)
                              .clamp(0.0, 1.0),
                          t: widget.idle ? _idle.value : 0.35,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Рамка дерева/золота вокруг двора на главном экране.
class CourtyardFrame extends StatelessWidget {
  const CourtyardFrame({super.key, required this.height, required this.child});

  final double height;
  final Widget child;

  static const _gold = Color(0xFFD4AF37);
  static const _woodTop = Color(0xFF6B3E24);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _gold.withValues(alpha: 0.72), width: 1.6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
            BoxShadow(color: _woodTop.withValues(alpha: 0.18), blurRadius: 18),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.4),
          child: SizedBox(height: height, width: double.infinity, child: child),
        ),
      ),
    );
  }
}

/// Гирлянда фонарей поверх двора на неделю события и за серию.
class FestivalLanternsPainter extends CustomPainter {
  const FestivalLanternsPainter({required this.strength, required this.t});

  final double strength;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    final sway = 6 * math.sin(t * 2 * math.pi);
    final line = Paint()
      ..color = const Color(0xFFE8C96A).withValues(alpha: 0.55 * strength)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final glow = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.42 * strength)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final core = Paint()
      ..color = const Color(0xFFFFF3C4).withValues(alpha: 0.9 * strength);

    final y = size.height * 0.18;
    final points = <Offset>[
      Offset(size.width * 0.12 + sway * 0.15, y + 10),
      Offset(size.width * 0.28, y - 4),
      Offset(size.width * 0.46 + sway * 0.08, y + 6),
      Offset(size.width * 0.64, y - 2),
      Offset(size.width * 0.82 - sway * 0.12, y + 8),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy - 14);
    for (final p in points) {
      path.lineTo(p.dx, p.dy - 14);
    }
    canvas.drawPath(path, line);
    for (final p in points) {
      canvas.drawCircle(p, 9, glow);
      canvas.drawCircle(p, 4.2, core);
    }
  }

  @override
  bool shouldRepaint(covariant FestivalLanternsPainter oldDelegate) {
    return oldDelegate.strength != strength || oldDelegate.t != t;
  }
}
