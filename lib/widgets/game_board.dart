import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../debug_agent_log.dart';
import '../debug_boot_timer.dart';
import '../models/board.dart';
import '../models/tile.dart';
import '../utils/layouts.dart';
import '../utils/tile_pyramid_position.dart';
import 'tile_painter.dart';
import 'tile_widget.dart';

/// Поле: общая сцена 6×5, масштаб плитки не зависит от числа слоёв.
class GameBoard extends StatefulWidget {
  const GameBoard({
    super.key,
    required this.board,
    required this.onTileTap,
    required this.onTileRemoveComplete,
    this.hintedIds = const {},
    this.introToken = 0,
    this.shuffleToken = 0,
  });

  final Board board;
  final void Function(Tile tile, Rect globalRect) onTileTap;
  final void Function(Tile tile) onTileRemoveComplete;
  final Set<int> hintedIds;

  /// Меняется при старте уровня — запускает intro-анимацию плиток.
  final int introToken;

  /// Меняется при перемешивании — плитки переворачиваются волной.
  final int shuffleToken;

  /// Стандартная кость: выше, чем шире (как физическая плитка / спрайт 709×514).
  static const tileAspect = TileBaseLayout.spriteAspect;
  static const moveDuration = Duration(milliseconds: 400);

  /// Соседние стопки вплотную: дыры даёт силуэт раскладки, не пустой зазор.
  static const tileGapFactor = 1.0;

  /// Слот лотка — компактнее полевых плиток, то же соотношение сторон.
  static const traySlotW = 46.0;
  static const traySlotH = traySlotW * tileAspect;
  static const trayBarH = traySlotH + 10.0;

  @override
  State<GameBoard> createState() => GameBoardState();
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

class GameBoardState extends State<GameBoard> {
  static const _refTileW = 80.0;

  /// Запас под подъём стопок. Не растёт с maxLayer — иначе поле сжимается.
  static const _liftPadLayers = 4;
  static int _layoutLogs = 0;
  final GlobalKey _stackKey = GlobalKey();
  _BoardLayoutMetrics? _lastMetrics;
  ({double minLeft, double minTop, double visualW, double visualH})?
  _lastBounds;

  Rect? globalBoardRectOf(Tile tile) {
    final metrics = _lastMetrics;
    final bounds = _lastBounds;
    final box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (metrics == null || bounds == null || box == null || !box.hasSize) {
      return null;
    }
    final origin = _tileOrigin(metrics, tile);
    final topLeft = box.localToGlobal(
      Offset(origin.dx - bounds.minLeft, origin.dy - bounds.minTop),
    );
    final bottomRight = box.localToGlobal(
      Offset(
        origin.dx - bounds.minLeft + metrics.tileW,
        origin.dy - bounds.minTop + metrics.tileH,
      ),
    );
    return Rect.fromPoints(topLeft, bottomRight);
  }

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
    final scale = TilePyramidPosition.scaleFor(tileW);
    final originX = maxLayer * TilePyramidPosition.liftStepXPx * scale;
    final originY = maxLayer * TilePyramidPosition.liftStepYPx * scale;
    // Крайняя плитка занимает tileW/tileH, а не ещё одну ячейку с зазором.
    final boardW = ((maxX - minX) / 2) * cellW + tileW;
    final boardH = ((maxY - minY) / 2) * cellH + tileH;

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

    const minX = 0;
    const minY = 0;
    const maxX = Layouts.playfieldMaxX;
    const maxY = Layouts.playfieldMaxY;

    final ref = _metricsAt(
      tileW: _refTileW,
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      maxLayer: _liftPadLayers,
    );
    final usableW = math.max(constraints.maxWidth, 1.0);
    final usableH = math.max(constraints.maxHeight, 1.0);
    final fit = math.min(
      usableW / math.max(ref.contentW, 1.0),
      usableH / math.max(ref.contentH, 1.0),
    );
    final tileW = math.max(_refTileW * fit, 36.0);

    return _metricsAt(
      tileW: tileW,
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      maxLayer: _liftPadLayers,
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
        final bounds = (
          minLeft: 0.0,
          minTop: 0.0,
          visualW: metrics.contentW,
          visualH: metrics.contentH,
        );
        _lastMetrics = metrics;
        _lastBounds = bounds;
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
          key: _stackKey,
          width: bounds.visualW,
          height: bounds.visualH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final tile in visible)
                AnimatedPositioned(
                  key: ValueKey(tile.id),
                  duration: GameBoard.moveDuration,
                  curve: Curves.easeOut,
                  left: _tileOrigin(metrics, tile).dx - bounds.minLeft,
                  top: _tileOrigin(metrics, tile).dy - bounds.minTop,
                  width: metrics.tileW,
                  height: metrics.tileH,
                  child: TileWidget(
                    tile: tile,
                    width: metrics.tileW,
                    height: metrics.tileH,
                    isSelected: widget.hintedIds.contains(tile.id),
                    isFree: widget.board.isFree(tile),
                    showBack: false,
                    isHinted: widget.hintedIds.contains(tile.id),
                    isRemoving: false,
                    shuffleToken: widget.shuffleToken,
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
          child: FittedBox(
            fit: BoxFit.contain,
            child: stack,
          ),
        );
      },
    );
  }
}
