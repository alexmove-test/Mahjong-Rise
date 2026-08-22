import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../debug_agent_log.dart';
import '../models/tile.dart';
import '../utils/tile_pyramid_position.dart';
import 'match_particles.dart';
import 'tile_painter.dart';
import 'tile_symbol_image.dart';

/// Премиальный многослойный рендер: тень → база → гравировка → подсветка.
class TileWidget extends StatefulWidget {
  const TileWidget({
    super.key,
    required this.tile,
    required this.width,
    required this.height,
    required this.isSelected,
    required this.isFree,
    this.onTap,
    this.isHinted = false,
    this.isRemoving = false,
    this.onRemoveComplete,
    this.compact = false,
    this.showBack = false,
  });

  final Tile tile;
  final double width;
  final double height;
  final bool isSelected;
  final bool isFree;
  final bool isHinted;

  /// Тап с глобальным rect плитки (для полёта в лоток).
  final void Function(Rect globalRect)? onTap;
  final bool isRemoving;
  final VoidCallback? onRemoveComplete;

  /// Уменьшенный вид для лотка (Tray).
  final bool compact;

  /// Оборот плитки (нижний перекрытый слой).
  final bool showBack;

  static const removeDuration = Duration(milliseconds: 280);
  static const burstDuration = MatchSparkBurst.duration;
  static const selectDuration = Duration(milliseconds: 80);

  static Offset layerOffset(int zIndex, double tileW, double tileH) {
    return TilePyramidPosition.baseOffset(
      z: zIndex,
      tileWidth: tileW,
      tileHeight: tileH,
    );
  }

  @override
  State<TileWidget> createState() => _TileWidgetState();
}

class _TileWidgetState extends State<TileWidget>
    with TickerProviderStateMixin {
  static int _loggedTiles = 0;
  late final AnimationController _burst;
  late final AnimationController _hintPulse;

  @override
  void initState() {
    super.initState();
    _burst =
        AnimationController(vsync: this, duration: TileWidget.burstDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && widget.isRemoving) {
              widget.onRemoveComplete?.call();
            }
          });
    _hintPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );
    if (widget.isRemoving) {
      _burst.forward();
    }
    if (widget.isHinted) {
      _hintPulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant TileWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRemoving && !oldWidget.isRemoving) {
      _burst.forward(from: 0);
    }
    if (!widget.isRemoving && oldWidget.isRemoving) {
      _burst.reset();
    }
    if (widget.isHinted && !_hintPulse.isAnimating) {
      _hintPulse.repeat(reverse: true);
    } else if (!widget.isHinted && _hintPulse.isAnimating) {
      _hintPulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _hintPulse.dispose();
    _burst.dispose();
    super.dispose();
  }

  double _highlightIntensity() {
    if (widget.isSelected || widget.isHinted) {
      return widget.compact ? 0.92 : 1.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final tile = widget.tile;
    final width = widget.width;
    final height = widget.height;
    final isRemoving = widget.isRemoving;
    final showBack = widget.showBack;

    final selectScale = (widget.isSelected || widget.isHinted) ? 1.05 : 1.0;
    final selectLift = (widget.isSelected || widget.isHinted) ? -2.0 : 0.0;
    final tileSize = Size(width, height);
    final symbolRect = TileBaseLayout.symbolRectOf(tileSize);
    final pyramid = TilePyramidPosition.visuals(
      z: tile.layer,
      tileWidth: width,
      tileHeight: height,
    );
    final baseHighlight = _highlightIntensity();
    // #region agent log
    if (_loggedTiles < 3) {
      _loggedTiles++;
      agentDbg(
        location: 'tile_widget.dart:build',
        message: 'tile widget geometry',
        hypothesisId: 'A',
        data: {
          'id': tile.id,
          'symbol': tile.symbol,
          'layer': tile.layer,
          'w': width,
          'h': height,
          'compact': widget.compact,
          'showBack': showBack,
          'faceL': symbolRect.left,
          'faceT': TileBaseLayout.faceRectOf(tileSize).top,
          'faceW': TileBaseLayout.faceRectOf(tileSize).width,
          'faceH': TileBaseLayout.faceRectOf(tileSize).height,
          'symW': symbolRect.width,
          'symH': symbolRect.height,
          'shadowDx': pyramid.shadowOffset.dx,
          'shadowDy': pyramid.shadowOffset.dy,
          'shadowOp': pyramid.shadowOpacity,
          'shadowBlur': pyramid.shadowBlur,
          'highlight': baseHighlight,
          'spriteW': TileBaseLayout.spriteWidth,
          'spriteH': TileBaseLayout.spriteHeight,
          'faceFillsWidget':
              TileBaseLayout.faceRectOf(tileSize) == (Offset.zero & tileSize),
          'clipRadius': TileBaseLayout.cornerRadius(tileSize),
          'assetW': 514,
          'assetH': 709,
          'engrave': 'raw-color',
          'kIsWeb': kIsWeb,
          'renderer': 'mapped-sprite',
        },
      );
    }
    // #endregion

    final locked = !widget.isFree && !widget.isSelected;
    final lifted = widget.isFree || widget.isSelected;

    Widget tileBody = SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (!showBack)
            Stack(
              clipBehavior: Clip.none,
              children: [
                TilePyramidShadowLayer(
                  visuals: pyramid,
                  tileSize: tileSize,
                  asset: TileBaseLayout.shadowAsset,
                ),
                Positioned.fill(
                  child: _SpriteBone(
                    tileSize: tileSize,
                    locked: locked,
                    lifted: lifted,
                  ),
                ),
                Positioned(
                  left: symbolRect.left,
                  top: symbolRect.top,
                  width: symbolRect.width,
                  height: symbolRect.height,
                  child: Opacity(
                    opacity: lifted ? 1.0 : 0.78,
                    child: _EngravedFace(symbol: tile.symbol),
                  ),
                ),
                if (baseHighlight > 0)
                  AnimatedBuilder(
                    animation: _hintPulse,
                    builder: (context, _) {
                      final pulse = widget.isHinted
                          ? 0.72 + 0.28 * _hintPulse.value
                          : 1.0;
                      return CustomPaint(
                        size: tileSize,
                        painter: TileHighlightPainter(
                          intensity: baseHighlight * pulse,
                        ),
                      );
                    },
                  ),
              ],
            )
          else
            CustomPaint(
              size: tileSize,
              painter: TileVolumePainter(
                zIndex: tile.layer,
                drawBody: true,
                showBack: true,
              ),
            ),
        ],
      ),
    );

    tileBody = AnimatedOpacity(
      opacity: isRemoving ? 0.0 : 1.0,
      duration: TileWidget.removeDuration,
      curve: Curves.easeOut,
      child: AnimatedScale(
        scale: isRemoving ? 0.45 : selectScale,
        duration: isRemoving
            ? TileWidget.removeDuration
            : TileWidget.selectDuration,
        curve: isRemoving ? Curves.easeIn : Curves.easeOut,
        child: AnimatedSlide(
          offset: Offset(0, selectLift / height),
          duration: isRemoving
              ? TileWidget.removeDuration
              : TileWidget.selectDuration,
          curve: Curves.easeOut,
          child: tileBody,
        ),
      ),
    );

    Widget body = SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          tileBody,
          if (isRemoving)
            Positioned(
              left: -width * 0.12,
              top: -height * 0.06,
              width: width * 1.24,
              height: height * 1.28,
              child: AnimatedBuilder(
                animation: _burst,
                builder: (context, _) => MatchSparkBurst(
                  progress: Curves.easeOut.transform(_burst.value),
                  width: width * 1.24,
                  height: height * 1.28,
                  particleCount: 12 + tile.id % 4,
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.onTap == null) {
      return IgnorePointer(ignoring: isRemoving, child: body);
    }

    return IgnorePointer(
      ignoring: isRemoving,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final box = context.findRenderObject() as RenderBox?;
          final rect = (box != null && box.hasSize)
              ? box.localToGlobal(Offset.zero) & box.size
              : Rect.zero;
          widget.onTap?.call(rect);
        },
        child: body,
      ),
    );
  }
}

/// База кости: PNG спрайт, затемнение только тела, fallback на CustomPaint.
class _SpriteBone extends StatelessWidget {
  const _SpriteBone({
    required this.tileSize,
    required this.locked,
    required this.lifted,
  });

  final Size tileSize;
  final bool locked;
  final bool lifted;

  static const _lockedTint = ColorFilter.mode(
    Color(0x59304450),
    BlendMode.srcATop,
  );

  @override
  Widget build(BuildContext context) {
    Widget sprite = TileMappedSprite(
      asset: TileBaseLayout.baseAsset,
      tileSize: tileSize,
      errorBuilder: (context, error, stackTrace) {
        return TileFallbackFace(
          size: tileSize,
          locked: false,
          lifted: lifted,
        );
      },
    );
    if (locked) {
      sprite = ColorFiltered(colorFilter: _lockedTint, child: sprite);
    }
    return sprite;
  }
}

/// Символ поверх белой грани. Без ColorFilter: Multiply на тёмной базе
/// делает иконки почти невидимыми (особенно SVG в Chrome).
class _EngravedFace extends StatelessWidget {
  const _EngravedFace({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return TileSymbolImage(symbol: symbol, fit: BoxFit.contain);
  }
}
