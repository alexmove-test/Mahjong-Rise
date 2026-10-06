import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../debug_agent_log.dart';
import '../debug_boot_timer.dart';
import '../l10n/l10n.dart';
import '../models/board.dart';
import '../models/tile.dart';
import '../services/table_look_controller.dart';
import '../utils/layouts.dart';
import '../utils/tile_pyramid_position.dart';
import 'tile_canvas.dart';
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

  /// Меняется при перемешивании — плитки ссыпаются в центр и снова раскладываются.
  final int shuffleToken;

  /// Классическая кость: выше, чем шире (спрайт 709×514). Casual — квадрат.
  static const tileAspect = TileBaseLayout.spriteAspect;
  static const moveDuration = Duration(milliseconds: 400);

  static double tileAspectOf(bool casual) =>
      casual ? CasualTileLayout.aspect : tileAspect;

  /// Соседние стопки вплотную: дыры даёт силуэт раскладки, не пустой зазор.
  static const tileGapFactor = 1.0;

  /// Яркий матч: базовый шаг. От него считается размер, затем кость растёт.
  static const casualTileGapFactor = 0.92;

  /// Кость яркого матча на 30% крупнее базы. Шаг сжимается, чтобы стол
  /// остался внутри экрана, затем раздвигается на [casualTileSpacingBoost].
  static const casualTileScale = 1.3;

  /// Шаг между центрами на 20% свободнее плотной укладки увеличенной кости.
  static const casualTileSpacingBoost = 1.2;

  static double tileGapFactorOf(bool casual) =>
      casual ? casualTileGapFactor : tileGapFactor;

  /// Слот лотка — компактнее полевых плиток, то же соотношение сторон.
  static const traySlotW = 46.0;
  static const traySlotH = traySlotW * tileAspect;
  static const trayBarH = traySlotH + 10.0;

  static double traySlotHeightOf(bool casual) =>
      traySlotW * tileAspectOf(casual);

  static double trayBarHeightOf(bool casual) => traySlotHeightOf(casual) + 10.0;

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
  Timer? _blockerTimer;
  Tile? _blockedTile;

  @override
  void dispose() {
    _blockerTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(GameBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.board != widget.board ||
        oldWidget.introToken != widget.introToken ||
        oldWidget.shuffleToken != widget.shuffleToken) {
      _blockerTimer?.cancel();
      _blockedTile = null;
    }
  }

  void _onTileTap(Tile tile, Rect rect) {
    _blockerTimer?.cancel();
    final blockers = widget.board.blockersOf(tile);
    setState(() => _blockedTile = blockers.isEmpty ? null : tile);
    if (blockers.isNotEmpty) {
      _blockerTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => _blockedTile = null);
      });
    }
    widget.onTileTap(tile, rect);
  }

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

  Offset _shuffleGatherOffset(
    _BoardLayoutMetrics metrics,
    ({double minLeft, double minTop, double visualW, double visualH}) bounds,
    Tile tile,
  ) {
    final origin = _tileOrigin(metrics, tile);
    return Offset(
      bounds.visualW / 2 - (origin.dx - bounds.minLeft + metrics.tileW / 2),
      bounds.visualH / 2 - (origin.dy - bounds.minTop + metrics.tileH / 2),
    );
  }

  _BoardLayoutMetrics _metricsAt({
    required double tileW,
    required double tileAspect,
    required double gapFactor,
    required int minX,
    required int minY,
    required int maxX,
    required int maxY,
    required int maxLayer,
  }) {
    final tileH = tileW * tileAspect;
    final cellW = tileW * gapFactor;
    final cellH = tileH * gapFactor;
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

  _BoardLayoutMetrics _computeMetrics(
    BoxConstraints constraints,
    Board board, {
    required double tileAspect,
    required double gapFactor,
    double tileScale = 1,
  }) {
    if (board.tiles.isEmpty) {
      return _BoardLayoutMetrics(
        tileW: 48,
        tileH: 48 * tileAspect,
        contentW: 48,
        contentH: 48 * tileAspect,
        minX: 0,
        minY: 0,
        originX: 0,
        originY: 0,
        cellW: 48,
        cellH: 48 * tileAspect,
      );
    }

    const minX = 0;
    const minY = 0;
    const maxX = Layouts.playfieldMaxX;
    const maxY = Layouts.playfieldMaxY;

    final ref = _metricsAt(
      tileW: _refTileW,
      tileAspect: tileAspect,
      gapFactor: gapFactor,
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
    final fittedW = math.max(_refTileW * fit, 36.0);
    final scaledW = fittedW * math.max(tileScale, 1);
    final gap = tileScale <= 1
        ? gapFactor
        : _gapThatFits(
            tileW: scaledW,
            tileAspect: tileAspect,
            usableW: usableW,
            usableH: usableH,
            minX: minX,
            minY: minY,
            maxX: maxX,
            maxY: maxY,
          );

    if (tileScale > 1 && gap > 0) {
      final opened = gap * GameBoard.casualTileSpacingBoost;
      final loosened = _tileWForGap(
        gapFactor: opened,
        tileAspect: tileAspect,
        usableW: usableW,
        usableH: usableH,
        minX: minX,
        minY: minY,
        maxX: maxX,
        maxY: maxY,
      );
      return _metricsAt(
        tileW: loosened,
        tileAspect: tileAspect,
        gapFactor: opened,
        minX: minX,
        minY: minY,
        maxX: maxX,
        maxY: maxY,
        maxLayer: _liftPadLayers,
      );
    }

    return _metricsAt(
      tileW: gap < 0 ? fittedW : scaledW,
      tileAspect: tileAspect,
      gapFactor: gap < 0 ? gapFactor : gap,
      minX: minX,
      minY: minY,
      maxX: maxX,
      maxY: maxY,
      maxLayer: _liftPadLayers,
    );
  }

  /// Крупнейшая кость, у которой шаг [gapFactor] ещё помещается в экран.
  static double _tileWForGap({
    required double gapFactor,
    required double tileAspect,
    required double usableW,
    required double usableH,
    required int minX,
    required int minY,
    required int maxX,
    required int maxY,
  }) {
    var lo = 1.0;
    var hi = math.max(usableW, usableH);
    for (var i = 0; i < 40; i++) {
      final mid = (lo + hi) / 2;
      final room = _gapThatFits(
        tileW: mid,
        tileAspect: tileAspect,
        usableW: usableW,
        usableH: usableH,
        minX: minX,
        minY: minY,
        maxX: maxX,
        maxY: maxY,
      );
      if (room >= gapFactor) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Шаг, при котором кость [tileW] вместе с подъёмом стопок влезает в экран.
  /// Отрицательный — даже полное наложение не помещается.
  static double _gapThatFits({
    required double tileW,
    required double tileAspect,
    required double usableW,
    required double usableH,
    required int minX,
    required int minY,
    required int maxX,
    required int maxY,
  }) {
    final tileH = tileW * tileAspect;
    final scale = TilePyramidPosition.scaleFor(tileW);
    final originX = _liftPadLayers * TilePyramidPosition.liftStepXPx * scale;
    final originY = _liftPadLayers * TilePyramidPosition.liftStepYPx * scale;
    final spanX = (maxX - minX) / 2;
    final spanY = (maxY - minY) / 2;

    double axisGap(double usable, double tile, double origin, double span) {
      if (span <= 0 || tile <= 0) return 1;
      return (usable - origin - tile) / (span * tile);
    }

    return math.min(
      axisGap(usableW, tileW, originX, spanX),
      axisGap(usableH, tileH, originY, spanY),
    );
  }

  @override
  Widget build(BuildContext context) {
    final blockerIds = _blockedTile == null
        ? <int>{}
        : widget.board.blockersOf(_blockedTile!).map((t) => t.id).toSet();
    final visible = widget.board.tiles.where((t) => t.isOnBoard).toList()
      ..sort((a, b) {
        final hintedA = widget.hintedIds.contains(a.id);
        final hintedB = widget.hintedIds.contains(b.id);
        if (hintedA != hintedB) return hintedA ? 1 : -1;
        // Свободная кость выше закрытой: прямоугольник соседа иначе
        // съедает центр и на узком экране в неё невозможно попасть.
        final freeA = widget.board.isFree(a);
        final freeB = widget.board.isFree(b);
        if (freeA != freeB) return freeA ? 1 : -1;
        final layer = a.layer.compareTo(b.layer);
        if (layer != 0) return layer;
        final y = a.y.compareTo(b.y);
        if (y != 0) return y;
        return a.x.compareTo(b.x);
      });

    return LayoutBuilder(
      builder: (context, constraints) {
        final casual = TableLookScope.lookOf(context).isCasual;
        final metrics = _computeMetrics(
          constraints,
          widget.board,
          tileAspect: GameBoard.tileAspectOf(casual),
          gapFactor: GameBoard.tileGapFactorOf(casual),
          tileScale: casual ? GameBoard.casualTileScale : 1,
        );
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
                    isBlocker: blockerIds.contains(tile.id),
                    isTarget: widget.board.targetTileIds.contains(tile.id),
                    isRemoving: false,
                    shuffleToken: widget.shuffleToken,
                    shuffleGatherOffset: _shuffleGatherOffset(
                      metrics,
                      bounds,
                      tile,
                    ),
                    onTap: (rect) => _onTileTap(tile, rect),
                    onRemoveComplete: () => widget.onTileRemoveComplete(tile),
                  ),
                ),
            ],
          ),
        );

        return Semantics(
          container: true,
          label: AppLocalizations.of(context).boardSemantic,
          child: SizedBox(
            key: ValueKey(widget.board.layoutName),
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: FittedBox(
              fit: BoxFit.contain,
              clipBehavior: Clip.none,
              child: stack,
            ),
          ),
        );
      },
    );
  }
}
