import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../models/tile.dart';
import 'tile_widget.dart';

/// Плитка летит с поля в слот ниши по дуге, уменьшаясь до размера лотка.
class TileFlightOverlay extends StatefulWidget {
  const TileFlightOverlay({
    super.key,
    required this.tile,
    required this.from,
    required this.to,
    required this.onArrived,
  });

  final Tile tile;
  final Rect from;
  final Rect to;
  final VoidCallback onArrived;

  static const duration = Duration(milliseconds: 420);

  @override
  State<TileFlightOverlay> createState() => _TileFlightOverlayState();
}

class _TileFlightOverlayState extends State<TileFlightOverlay>
    with SingleTickerProviderStateMixin {
  static const _ghostCount = 2;
  static const _ghostSpacing = 0.08;

  late final AnimationController _ctrl;
  late final Animation<double> _t;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(vsync: this, duration: TileFlightOverlay.duration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && !_notified) {
              _notified = true;
              widget.onArrived();
            }
          });
    _t = CurvedAnimation(
      parent: _ctrl,
      curve: const Cubic(0.2, 0.72, 0.16, 1.0),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Rect _rectAt(double t) {
    final clamped = t.clamp(0.0, 1.0);
    final sizeT = Curves.easeInOutCubic.transform(clamped);
    final w = lerpDouble(widget.from.width, widget.to.width, sizeT)!;
    final h = lerpDouble(widget.from.height, widget.to.height, sizeT)!;
    final cx = lerpDouble(widget.from.center.dx, widget.to.center.dx, clamped)!;
    final cy = lerpDouble(widget.from.center.dy, widget.to.center.dy, clamped)!;
    final distance = (widget.to.center - widget.from.center).distance;
    final arc =
        -math.min(64.0, 28.0 + distance * 0.14) * (4 * clamped * (1 - clamped));
    return Rect.fromCenter(center: Offset(cx, cy + arc), width: w, height: h);
  }

  double _rotation(double t) {
    final dx = widget.to.center.dx - widget.from.center.dx;
    if (dx.abs() < 4) return 0;
    final tilt = dx.sign * 0.16;
    return tilt * (1 - Curves.easeOutCubic.transform(t.clamp(0.0, 1.0)));
  }

  Widget _tileAt(
    Rect rect, {
    required double opacity,
    required double rotation,
    bool selected = false,
  }) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Transform.rotate(
            angle: rotation,
            child: TileWidget(
              tile: widget.tile,
              width: rect.width,
              height: rect.height,
              isSelected: selected,
              isFree: true,
              compact: true,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, _) {
        final t = _t.value;
        final children = <Widget>[];

        for (var i = _ghostCount; i >= 1; i--) {
          final ghostT = t - i * _ghostSpacing;
          if (ghostT <= 0) continue;
          final fade = (0.2 - i * 0.07).clamp(0.0, 1.0) * (1 - t * 0.55);
          if (fade <= 0.02) continue;
          children.add(
            _tileAt(
              _rectAt(ghostT),
              opacity: fade,
              rotation: _rotation(ghostT),
            ),
          );
        }

        children.add(
          _tileAt(
            _rectAt(t),
            opacity: 0.94 + 0.06 * t,
            rotation: _rotation(t),
          ),
        );

        return Stack(clipBehavior: Clip.none, children: children);
      },
    );
  }
}
