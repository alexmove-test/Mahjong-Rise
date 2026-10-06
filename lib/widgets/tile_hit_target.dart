import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lets taps fall through the empty corners of a rounded tile.
///
/// Casual tiles overlap on the 6×5 grid, but only the squircle is visible.
/// A rectangular [GestureDetector] on the full box would steal taps from the
/// tile painted underneath — usually the one higher on the board.
class TileHitTarget extends SingleChildRenderObjectWidget {
  const TileHitTarget({
    super.key,
    required this.contains,
    required super.child,
  });

  final bool Function(Size size, Offset position) contains;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderTileHitTarget(contains: contains);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderTileHitTarget renderObject,
  ) {
    renderObject.contains = contains;
  }
}

class RenderTileHitTarget extends RenderProxyBox {
  RenderTileHitTarget({
    required bool Function(Size size, Offset position) contains,
  }) : _contains = contains;

  bool Function(Size size, Offset position) _contains;

  set contains(bool Function(Size size, Offset position) value) {
    _contains = value;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_contains(size, position)) return false;
    return super.hitTest(result, position: position);
  }
}
