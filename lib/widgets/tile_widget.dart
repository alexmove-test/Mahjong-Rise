import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../debug_agent_log.dart';
import '../models/tile.dart';
import '../utils/tile_pyramid_position.dart';
import 'match_particles.dart';
import 'tile_canvas.dart';
import 'tile_glyph.dart';
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
    this.shuffleToken = 0,
  });

  final Tile tile;
  final double width;
  final double height;
  final bool isSelected;
  final bool isFree;
  final bool isHinted;
  final int shuffleToken;

  /// Тап с глобальным rect плитки (для полёта в лоток).
  final void Function(Rect globalRect)? onTap;
  final bool isRemoving;
  final VoidCallback? onRemoveComplete;

  /// Уменьшенный вид для лотка (Tray).
  final bool compact;

  /// Оборот плитки (нижний перекрытый слой).
  final bool showBack;

  static const removeDuration = Duration(milliseconds: 300);
  static const removeScale = 0.8;
  static const removeSlideDuration = Duration(milliseconds: 400);
  static const burstDuration = MatchSparkBurst.duration;
  static const selectDuration = Duration(milliseconds: 80);
  static const tapPopDuration = Duration(milliseconds: 200);
  static const tapPopPeak = 1.15;
  static const shuffleFlipDuration = Duration(milliseconds: 480);
  static const shuffleMaxStagger = Duration(milliseconds: 216);

  /// Отказ по перекрытой кости: короткая тряска вместо немого тапа.
  static const shakeDuration = Duration(milliseconds: 200);
  static const _shakeAmplitudePx = 6.0;

  /// Свободная кость выступает над стопкой, под пальцем — bounce.
  static const _freeLiftPx = -1.6;
  static Duration get shufflePlayDuration =>
      shuffleFlipDuration + shuffleMaxStagger;

  static Duration shuffleStaggerOf(Tile tile) {
    final wave = (tile.x * 3 + tile.y * 5 + tile.layer * 11).abs() % 12;
    return Duration(milliseconds: wave * 18);
  }

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

class _TileWidgetState extends State<TileWidget> with TickerProviderStateMixin {
  static int _loggedTiles = 0;
  late final AnimationController _burst;
  late final AnimationController _hintPulse;
  late final AnimationController _shuffleFlip;
  late final AnimationController _shake;
  late final AnimationController _pop;
  late String _shownSymbol;
  String? _shuffleFromSymbol;
  int _shuffleDelayMs = 0;

  @override
  void initState() {
    super.initState();
    _shownSymbol = widget.tile.symbol;
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
    _shuffleFlip =
        AnimationController(
          vsync: this,
          duration: TileWidget.shuffleFlipDuration,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _shownSymbol = widget.tile.symbol;
          }
        });
    _shake = AnimationController(
      vsync: this,
      duration: TileWidget.shakeDuration,
    );
    _pop = AnimationController(
      vsync: this,
      duration: TileWidget.tapPopDuration,
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
    final shuffled = widget.shuffleToken != oldWidget.shuffleToken;
    final symbolChanged = widget.tile.symbol != _shownSymbol;
    if (!widget.compact && (shuffled || symbolChanged)) {
      final from = _shuffleFlip.isAnimating ? _faceSymbol : _shownSymbol;
      _playShuffle(fromSymbol: from);
    }
  }

  void _playShuffle({required String fromSymbol}) {
    _shuffleFromSymbol = fromSymbol;
    _shuffleDelayMs = TileWidget.shuffleStaggerOf(widget.tile).inMilliseconds;
    _shuffleFlip.duration =
        TileWidget.shuffleFlipDuration +
        Duration(milliseconds: _shuffleDelayMs);
    _shuffleFlip.forward(from: 0);
  }

  @override
  void dispose() {
    _shake.dispose();
    _pop.dispose();
    _shuffleFlip.dispose();
    _hintPulse.dispose();
    _burst.dispose();
    super.dispose();
  }

  double get _shuffleLocalT {
    final duration = _shuffleFlip.duration;
    if (duration == null || duration.inMilliseconds <= 0) {
      return _shuffleFlip.value;
    }
    final elapsed = _shuffleFlip.value * duration.inMilliseconds;
    return ((elapsed - _shuffleDelayMs) /
            TileWidget.shuffleFlipDuration.inMilliseconds)
        .clamp(0.0, 1.0);
  }

  String get _faceSymbol {
    final from = _shuffleFromSymbol;
    if (from == null || _shuffleLocalT >= 0.5) return widget.tile.symbol;
    return from;
  }

  void _playTapPop() {
    if (!widget.isFree || widget.compact || widget.isRemoving) return;
    _pop.forward(from: 0);
  }

  double _highlightIntensity() {
    if (widget.isHinted) {
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

    final locked = !widget.isFree && !widget.isSelected;
    final lifted = widget.isFree || widget.isSelected;

    final selectScale = (widget.isSelected || widget.isHinted) ? 1.05 : 1.0;
    // Свободная кость чуть выступает над стопкой даже без подсказки.
    final restLift = (lifted && !widget.compact) ? TileWidget._freeLiftPx : 0.0;
    final selectLift = (widget.isSelected || widget.isHinted) ? -2.0 : restLift;
    final tileSize = Size(width, height);
    final symbolRect = TileBaseLayout.symbolRectOf(tileSize);
    final pyramid = TilePyramidPosition.visuals(
      z: tile.layer,
      tileWidth: width,
      tileHeight: height,
      lifted: lifted,
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
          'renderer': 'canvas-drawTile',
        },
      );
    }
    // #endregion

    Widget tileBody = SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (!showBack)
            Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                TilePyramidShadowLayer(
                  visuals: pyramid,
                  tileSize: tileSize,
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _shuffleFlip,
                    builder: (context, _) {
                      final shown = _faceSymbol;
                      final special = TileCanvas.isSpecialSymbol(shown);
                      return Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            size: tileSize,
                            painter: TileFacePainter(
                              locked: locked,
                              lifted: lifted,
                              isSelected: widget.isSelected,
                              isSpecial: special,
                              specialSeed: shown.hashCode,
                              symbol: shown,
                            ),
                          ),
                          if (!special && !TileGlyph.paints(shown))
                            Positioned(
                              left: symbolRect.left,
                              top: symbolRect.top,
                              width: symbolRect.width,
                              height: symbolRect.height,
                              child: Opacity(
                                opacity: lifted ? 1.0 : 0.72,
                                child: _EngravedFace(symbol: shown),
                              ),
                            ),
                        ],
                      );
                    },
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
        scale: isRemoving ? TileWidget.removeScale : selectScale,
        duration: isRemoving
            ? TileWidget.removeDuration
            : TileWidget.selectDuration,
        curve: isRemoving ? Curves.easeOut : Curves.easeOut,
        child: AnimatedSlide(
          offset: Offset(
            0,
            isRemoving ? 0.22 : selectLift / height,
          ),
          duration: isRemoving
              ? TileWidget.removeSlideDuration
              : TileWidget.selectDuration,
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: Listenable.merge([_shuffleFlip, _pop]),
            builder: (context, child) {
              final t = _shuffleLocalT;
              final scaleX = (t == 0 || t == 1)
                  ? 1.0
                  : (t < 0.5 ? (1 - t * 2) : (t - 0.5) * 2).clamp(0.08, 1.0);
              final bounce = math.sin(t * math.pi);
              final lift = -12.0 * bounce;
              final tilt = bounce * 0.14 * (widget.tile.id.isEven ? 1.0 : -1.0);
              final pop = 1.0 + 0.07 * bounce;
              final tapPop = 1.0 +
                  (TileWidget.tapPopPeak - 1.0) *
                      math.sin(_pop.value * math.pi);
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..translate(0.0, lift)
                  ..rotateZ(tilt)
                  ..scale(scaleX * pop * tapPop, pop * tapPop),
                child: child,
              );
            },
            child: tileBody,
          ),
        ),
      ),
    );

    tileBody = AnimatedBuilder(
      animation: _shake,
      builder: (context, child) {
        final t = _shake.value;
        if (t == 0 || t == 1) return child!;
        final dx =
            math.sin(t * math.pi * 3) * TileWidget._shakeAmplitudePx * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: tileBody,
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

    final shuffling = _shuffleFlip.isAnimating;
    if (widget.onTap == null) {
      return IgnorePointer(ignoring: isRemoving || shuffling, child: body);
    }

    return IgnorePointer(
      ignoring: isRemoving || shuffling,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (widget.isFree) _playTapPop();
        },
        onTap: () {
          if (!widget.isFree) _shake.forward(from: 0);
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
