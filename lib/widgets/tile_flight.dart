import 'package:flutter/material.dart';

import '../models/tile.dart';
import 'tile_widget.dart';

/// Плитка летит с поля в слот ниши.
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

  static const duration = Duration(milliseconds: 340);

  @override
  State<TileFlightOverlay> createState() => _TileFlightOverlayState();
}

class _TileFlightOverlayState extends State<TileFlightOverlay>
    with SingleTickerProviderStateMixin {
  static const _ghostCount = 3;
  static const _ghostSpacing = 0.1;

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
    _t = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Rect _rectAt(double t) {
    final clamped = t.clamp(0.0, 1.0);
    final rect = Rect.lerp(widget.from, widget.to, clamped)!;
    // Лёгкая дуга вверх.
    final arc = -28.0 * (4 * clamped * (1 - clamped));
    return rect.shift(Offset(0, arc));
  }

  Widget _tileAt(Rect rect, {required double opacity, bool selected = false}) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
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
          final fade = (0.28 - i * 0.07).clamp(0.0, 1.0) * (1 - t * 0.35);
          if (fade <= 0) continue;
          children.add(_tileAt(_rectAt(ghostT), opacity: fade));
        }

        children.add(
          _tileAt(_rectAt(t), opacity: 0.92 + 0.08 * t, selected: true),
        );

        return Stack(clipBehavior: Clip.none, children: children);
      },
    );
  }
}
