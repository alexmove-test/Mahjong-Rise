import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'courtyard_progress.dart';

/// Живой двор: на хабе статичен (с лёгким idle), после победы — рост ~2 с.
class CourtyardScene extends StatefulWidget {
  const CourtyardScene({
    super.key,
    required this.to,
    this.from,
    this.animate = false,
    this.idle = true,
  });

  final CourtyardSnapshot to;
  final CourtyardSnapshot? from;
  final bool animate;
  final bool idle;

  static const growDuration = Duration(milliseconds: 2000);

  @override
  State<CourtyardScene> createState() => _CourtyardSceneState();
}

class _CourtyardSceneState extends State<CourtyardScene>
    with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _grow;

  static const _artAlign = Alignment(0, -0.12);

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final asset in CourtyardArtFade.assets) {
      precacheImage(AssetImage(asset), context);
    }
    precacheImage(const AssetImage(CourtyardArtFade.lifeAsset), context);
  }

  @override
  void didUpdateWidget(covariant CourtyardScene oldWidget) {
    super.didUpdateWidget(oldWidget);
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
          final breath = widget.idle
              ? 1.0 + 0.01 * (0.5 - 0.5 * math.cos(_idle.value * 2 * math.pi))
              : 1.0;
          final life = snapshot.lifeArt;

          return ClipRect(
            child: Transform.scale(
              scale: breath,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _plate(CourtyardArtFade.assets[fade.fromIndex]),
                  if (fade.blend > 0.01)
                    Opacity(
                      opacity: fade.blend,
                      child: _plate(CourtyardArtFade.assets[fade.toIndex]),
                    ),
                  if (life > 0.01)
                    Opacity(
                      opacity: life,
                      child: _plate(CourtyardArtFade.lifeAsset),
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
