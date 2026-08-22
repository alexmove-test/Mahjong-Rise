import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../debug_agent_log.dart';
import '../debug_boot_timer.dart';
import '../models/board.dart';
import '../models/tile.dart';
import '../utils/tile_pyramid_position.dart';
import 'tile_widget.dart';

/// Поле: исходная раскладка вписывается в экран и не масштабируется по ходу игры.
class GameBoard extends StatefulWidget {
  const GameBoard({
    super.key,
    required this.board,
    required this.onTileTap,
    required this.onTileRemoveComplete,
    this.hintedIds = const {},
    this.introToken = 0,
  });

  final Board board;
  final void Function(Tile tile, Rect globalRect) onTileTap;
  final void Function(Tile tile) onTileRemoveComplete;
  final Set<int> hintedIds;

  /// Меняется при старте уровня — запускает intro-анимацию плиток.
  final int introToken;

  /// Почти квадратная кость референса.
  static const tileAspect = 1.15;
  static const moveDuration = Duration(milliseconds: 180);

  /// Зазор между соседними плитками (1.0 — вплотную).
  static const tileGapFactor = 1.0;

  /// Слот лотка — компактнее полевых плиток.
  static const traySlotW = 46.0;
  static const traySlotH = 54.0;
  static const trayBarH = 64.0;

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _BoardLayoutMetrics {
  const _BoardLayoutMetrics({
    required this.tileW,
    required this.tileH,
    required this.contentW,
    required this.contentH,
    required this.minX,
    required this.minY,
    required this.originX,
    required this.originY,
    required this.cellW,
    required this.cellH,
  });

  final double tileW;
  final double tileH;
  final double contentW;
  final double contentH;
  final int minX;
  final int minY;
  final double originX;
  final double originY;
  final double cellW;
  final double cellH;
}

class _GameBoardState extends State<GameBoard> {
  static const _refTileW = 80.0;
  static int _layoutLogs = 0;

  Offset _tileOrigin(_BoardLayoutMetrics metrics, Tile tile) {
    return TilePyramidPosition.boardOrigin(
      x: tile.x,
      y: tile.y,
      z: tile.layer,
      minX: metrics.minX,
      minY: metrics.minY,
      originX: metrics.originX,
      originY: metrics.originY,
      cellW: metrics.cellW,
      cellH: metrics.cellH,
      tileW: metrics.tileW,
      tileH: metrics.tileH,
    );
  }

  ({double minLeft, double minTop, double visualW, double visualH})
  _visualBounds(_BoardLayoutMetrics metrics, List<Tile> tiles) {
    var minLeft = double.infinity;
    var minTop = double.infinity;
    var maxRight = double.negativeInfinity;
    var maxBottom = double.negativeInfinity;

    for (final tile in tiles) {
      final origin = _tileOrigin(metrics, tile);
      final v = TilePyramidPosition.visuals(
        z: tile.layer,
        tileWidth: metrics.tileW,
        tileHeight: metrics.tileH,
      );
      final shadowPad = v.shadowOffset.dx + v.shadowBlur * 2.5;
      final shadowPadY = v.shadowOffset.dy + v.shadowBlur * 2.5;
      minLeft = math.min(minLeft, origin.dx);
      minTop = math.min(minTop, origin.dy);
      maxRight = math.max(maxRight, origin.dx + metrics.tileW + shadowPad);
      maxBottom = math.max(maxBottom, origin.dy + metrics.tileH + shadowPadY);
    }

    if (tiles.isEmpty) {
      return (
        minLeft: 0.0,
        minTop: 0.0,
        visualW: metrics.contentW,
        visualH: metrics.contentH,
      );
    }

    return (
      minLeft: minLeft,
      minTop: minTop,
      visualW: maxRight - minLeft,
      visualH: maxBottom - minTop,
    );
  }

  _BoardLayoutMetrics _metricsAt({
    required double tileW,
    required int minX,
    required int minY,
    required int maxX,
    required int maxY,
    required int maxLayer,
  }) {
    final tileH = tileW * GameBoard.tileAspect;
    const step = GameBoard.tileGapFactor;
    final cellW = tileW * step;
    final cellH = tileH * step;
    final gridW = (maxX - minX + 2).toDouble();
    final gridH = (maxY - minY + 2).toDouble();
    final scale = TilePyramidPosition.scaleFor(tileW);
    final originX = maxLayer * TilePyramidPosition.liftStepXPx * scale;
    final originY = maxLayer * TilePyramidPosition.liftStepYPx * scale;
    final boardW = (gridW / 2) * cellW;
    final boardH = (gridH / 2) * cellH;

    return _BoardLayoutMetrics(
      tileW: tileW,
      tileH: tileH,
      contentW: boardW + originX,
      contentH: boardH + originY,
      minX: minX,
      minY: minY,
      originX: originX,
      originY: originY,
      cellW: cellW,
      cellH: cellH,
    );
  }

  _BoardLayoutMetrics _computeMetrics(BoxConstraints constraints, Board board) {
    if (board.tiles.isEmpty) {
      return const _BoardLayoutMetrics(
        tileW: 48,
        tileH: 48 * GameBoard.tileAspect,
        contentW: 48,
        contentH: 48 * GameBoard.tileAspect,
        minX: 0,
        minY: 0,
        originX: 0,
        originY: 0,
        cellW: 48,
        cellH: 48 * GameBoard.tileAspect,
      );
    }

    final xs = board.tiles.map((t) => t.x);
    final ys = board.tiles.map((t) => t.y);
    final layers = board.tiles.map((t) => t.layer);
    final minX = xs.reduce(math.min);
    final maxX = xs.reduce(math.max);
    final minY = ys.reduce(math.min);
    final maxY = ys.reduce(math.max);
    final maxLayer = layers.reduce(math.max);

    final ref = _metricsAt(
      tileW: _refTileW,
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      maxLayer: maxLayer,
    );
    // Всегда по полной раскладке: иначе поле зумится, когда плиток становится меньше.
    final bounds = _visualBounds(ref, board.tiles);
    final usableW = math.max(constraints.maxWidth, 1.0);
    final usableH = math.max(constraints.maxHeight, 1.0);
    final fit = math.min(
      usableW / math.max(bounds.visualW, 1.0),
      usableH / math.max(bounds.visualH, 1.0),
    );
    final tileW = math.max(_refTileW * fit, 24.0);

    return _metricsAt(
      tileW: tileW,
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      maxLayer: maxLayer,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = widget.board.tiles.where((t) => t.isOnBoard).toList()
      ..sort((a, b) {
        final layer = a.layer.compareTo(b.layer);
        if (layer != 0) return layer;
        final y = a.y.compareTo(b.y);
        if (y != 0) return y;
        return a.x.compareTo(b.x);
      });

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _computeMetrics(constraints, widget.board);
        final bounds = _visualBounds(metrics, widget.board.tiles);
        // #region agent log
        if (_layoutLogs < 2) {
          _layoutLogs++;
          agentDbg(
            location: 'game_board.dart:LayoutBuilder',
            message: 'board layout metrics',
            hypothesisId: 'E',
            runId: 'post-fix',
            data: {
              'visible': visible.length,
              'tileW': metrics.tileW,
              'tileH': metrics.tileH,
              'maxW': constraints.maxWidth,
              'maxH': constraints.maxHeight,
              'kIsWeb': kIsWeb,
              'bootMs': agentBoot.elapsedMilliseconds,
              'intro': 'skipped',
            },
          );
        }
        // #endregion

        final stack = SizedBox(
          width: bounds.visualW,
          height: bounds.visualH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final tile in visible)
                Positioned(
                  key: ValueKey(tile.id),
                  left: _tileOrigin(metrics, tile).dx - bounds.minLeft,
                  top: _tileOrigin(metrics, tile).dy - bounds.minTop,
                  width: metrics.tileW,
                  height: metrics.tileH,
                  child: TileWidget(
                    tile: tile,
                    width: metrics.tileW,
                    height: metrics.tileH,
                    isSelected: false,
                    isFree: widget.board.isFree(tile),
                    showBack: false,
                    isHinted: widget.hintedIds.contains(tile.id),
                    isRemoving: false,
                    onTap: (rect) => widget.onTileTap(tile, rect),
                    onRemoveComplete: () => widget.onTileRemoveComplete(tile),
                  ),
                ),
            ],
          ),
        );

        return SizedBox(
          key: ValueKey(widget.board.layoutName),
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              child: stack,
            ),
          ),
        );
      },
    );
  }
}
