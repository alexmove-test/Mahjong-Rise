import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../debug_agent_log.dart';
import '../l10n/l10n.dart';
import '../models/tile.dart';
import '../services/locked_tile_dim_controller.dart';
import '../services/table_look_controller.dart';
import '../utils/tile_pyramid_position.dart';
import 'match_particles.dart';
import 'tile_canvas.dart';
import 'tile_glyph.dart';
import 'tile_hit_target.dart';
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
    this.isBlocker = false,
    this.isTarget = false,
    this.isRemoving = false,
    this.onRemoveComplete,
    this.compact = false,
    this.showBack = false,
    this.shuffleToken = 0,
    this.shuffleGatherOffset = Offset.zero,
  });

  final Tile tile;
  final double width;
  final double height;
  final bool isSelected;
  final bool isFree;
  final bool isHinted;
  final bool isBlocker;
  final bool isTarget;
  final int shuffleToken;

  /// Вектор от центра этой плитки к центру поля — куда ссыпается колода.
  final Offset shuffleGatherOffset;

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
  static const shuffleDuration = Duration(milliseconds: 820);
  static const shuffleFlipDuration = shuffleDuration;
  static const shuffleMaxStagger = Duration.zero;
  static const shuffleGatherIn = 0.40;
  static const shuffleGatherOut = 0.60;

  /// Отказ по перекрытой кости: короткая тряска вместо немого тапа.
  static const shakeDuration = Duration(milliseconds: 200);
  static const _shakeAmplitudePx = 6.0;

  /// Свободная кость выступает над стопкой, под пальцем — bounce.
  static const _freeLiftPx = -1.6;
  static Duration get shufflePlayDuration => shuffleDuration;

  static Duration shuffleStaggerOf(Tile tile) {
    // Keep the old entry point; the pile meets in one beat.
    return Duration(milliseconds: 0 * tile.layer);
  }

  /// 0 на местах, 1 когда вся колода лежит одной костью в центре.
  static double shuffleGatherAmount(double t) {
    if (t <= 0 || t >= 1) return 0;
    if (t < shuffleGatherIn) {
      return Curves.easeInCubic.transform(t / shuffleGatherIn);
    }
    if (t <= shuffleGatherOut) return 1;
    return 1 -
        Curves.easeOutCubic.transform(
          (t - shuffleGatherOut) / (1 - shuffleGatherOut),
        );
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
  Timer? _shuffleFallback;
  bool _blockHits = false;

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
        AnimationController(vsync: this, duration: TileWidget.shuffleDuration)
          ..addStatusListener((status) {
            if (status != AnimationStatus.completed &&
                status != AnimationStatus.dismissed) {
              return;
            }
            _shownSymbol = widget.tile.symbol;
            // isAnimating ещё true в кадр смены статуса, а родитель может
            // больше не перестраиваться. Без своего флага плитки остаются
            // глухими после перемешивания.
            _blockHits = false;
            if (mounted) setState(() {});
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
    _blockHits = true;
    _shuffleFlip.duration = TileWidget.shuffleDuration;
    _shuffleFlip.forward(from: 0);
    _shuffleFallback?.cancel();
    _shuffleFallback = Timer(
      TileWidget.shuffleDuration + const Duration(milliseconds: 80),
      () {
        if (!mounted) return;
        if (_shuffleFlip.status == AnimationStatus.completed) return;
        _shuffleFlip.value = 1;
        _shownSymbol = widget.tile.symbol;
      },
    );
  }

  @override
  void dispose() {
    _shuffleFallback?.cancel();
    _tapGuard?.cancel();
    _shake.dispose();
    _pop.dispose();
    _shuffleFlip.dispose();
    _hintPulse.dispose();
    _burst.dispose();
    super.dispose();
  }

  double get _shuffleLocalT => _shuffleFlip.value.clamp(0.0, 1.0);

  String get _faceSymbol {
    final from = _shuffleFromSymbol;
    if (from == null || _shuffleLocalT >= 0.5) return widget.tile.symbol;
    return from;
  }

  double _shuffleFlightAmount(double t) {
    if (t <= 0 || t >= 1) return 0;
    if (t < TileWidget.shuffleGatherIn) {
      return math.sin((t / TileWidget.shuffleGatherIn) * math.pi);
    }
    if (t > TileWidget.shuffleGatherOut) {
      return math.sin(
        ((t - TileWidget.shuffleGatherOut) /
                (1 - TileWidget.shuffleGatherOut)) *
            math.pi,
      );
    }
    return 0;
  }

  Matrix4 _shuffleMatrix(double t, double tapPop) {
    final m = Matrix4.identity();
    if (t <= 0 || t >= 1) {
      return m..scaleByDouble(tapPop, tapPop, 1, 1);
    }

    final gather = TileWidget.shuffleGatherAmount(t);
    final flight = _shuffleFlightAmount(t);
    final mix = math.sin(
      widget.tile.id * 2.399 + widget.tile.x * 0.91 + widget.tile.y * 1.37,
    );
    final offset = widget.shuffleGatherOffset;
    final twist = mix * 0.26 * flight;
    final scale = (1.0 - 0.04 * gather + 0.05 * flight) * tapPop;

    return m
      ..translate(offset.dx * gather, offset.dy * gather)
      ..rotateZ(twist)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  void _playTapPop() {
    if (!widget.isFree || widget.compact || widget.isRemoving) return;
    _pop.forward(from: 0);
  }

  Timer? _tapGuard;

  /// Сразу на касании, без ожидания отпускания. На части экранов палец
  /// уезжает дальше стандартного порога, и обычный tap просто пропадает.
  void _emitTap() {
    if (_tapGuard != null) return;
    _tapGuard = Timer(const Duration(milliseconds: 280), () {
      _tapGuard = null;
    });
    if (!widget.isFree) {
      _shake.forward(from: 0);
    } else {
      _playTapPop();
    }
    final box = context.findRenderObject() as RenderBox?;
    final rect = (box != null && box.hasSize)
        ? box.localToGlobal(Offset.zero) & box.size
        : Rect.zero;
    widget.onTap?.call(rect);
  }

  double _highlightIntensity({required bool casual, bool premium = false}) {
    if (widget.isHinted) {
      return widget.compact ? 0.92 : 1.0;
    }
    if ((casual || premium) && widget.isSelected) return 1.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final tile = widget.tile;
    final width = widget.width;
    final height = widget.height;
    final isRemoving = widget.isRemoving;
    final showBack = widget.showBack;

    final covered = !widget.isFree && !widget.isSelected;
    final look = TableLookScope.lookOf(context);
    final casual = look.isCasual;
    final premium = look.isPremium;
    final dimCovered = LockedTileDimScope.maybeOf(context)?.enabled ?? false;
    final locked = (casual || dimCovered) && covered;
    final lifted = widget.isFree || widget.isSelected;

    final selectScale = (widget.isSelected || widget.isHinted) ? 1.05 : 1.0;
    // Свободная кость чуть выступает над стопкой даже без подсказки.
    final restLift = (lifted && !widget.compact) ? TileWidget._freeLiftPx : 0.0;
    final selectLift = (widget.isSelected || widget.isHinted) ? -2.0 : restLift;
    final tileSize = Size(width, height);
    final faceRect = premium
        ? PremiumTileLayout.faceRectOf(tileSize)
        : (casual
              ? CasualTileLayout.faceRectOf(tileSize)
              : TileBaseLayout.faceRectOf(tileSize));
    final symbolRect = premium
        ? PremiumTileLayout.symbolRectOf(tileSize)
        : (casual
              ? CasualTileLayout.symbolRectOf(tileSize)
              : TileBaseLayout.symbolRectOf(tileSize));
    final faceClipRadius = premium
        ? PremiumTileLayout.faceCornerRadius(tileSize)
        : (casual
              ? CasualTileLayout.cornerRadius(tileSize)
              : TileCanvas.faceCornerRadius(tileSize));
    final pyramid = TilePyramidPosition.visuals(
      z: tile.layer,
      tileWidth: width,
      tileHeight: height,
      lifted: lifted,
    );
    // Premium: контактная тень плотнее и резче, чтобы стопка читалась
    // объёмнее (см. разбор референса — тени были слишком мягкими/размытыми).
    final effectivePyramid = premium
        ? TilePyramidVisuals(
            baseOffset: pyramid.baseOffset,
            shadowOffset: pyramid.shadowOffset * 1.35,
            shadowOpacity: (pyramid.shadowOpacity * 1.30).clamp(0.0, 0.97),
            shadowBlur: pyramid.shadowBlur * 0.72,
          )
        : pyramid;
    final baseHighlight = _highlightIntensity(casual: casual, premium: premium);
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
          'assetW': TileBaseLayout.spriteWidthPx,
          'assetH': TileBaseLayout.spriteHeightPx,
          'engrave': 'raw-color',
          'kIsWeb': kIsWeb,
          'renderer': 'png-tile-base',
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
                  visuals: effectivePyramid,
                  tileSize: tileSize,
                  cornerRadius: premium
                      ? PremiumTileLayout.cornerRadius(tileSize)
                      : (casual
                            ? CasualTileLayout.cornerRadius(tileSize)
                            : TileCanvas.cornerRadius(tileSize)),
                ),
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _shuffleFlip,
                    builder: (context, _) {
                      final shown = _faceSymbol;
                      final special = TileCanvas.isSpecialSymbol(shown);
                      Widget layers = Stack(
                        fit: StackFit.expand,
                        clipBehavior: Clip.none,
                        children: [
                          TileBodySprite(
                            size: tileSize,
                            locked: locked,
                            lifted: lifted,
                            isSelected: widget.isSelected,
                            isSpecial: special,
                            specialSeed: shown.hashCode,
                            symbol: shown,
                          ),
                          if (special || TileGlyph.paints(shown))
                            CustomPaint(
                              size: tileSize,
                              painter: TileOverlayArtPainter(
                                locked: locked,
                                isSelected: widget.isSelected,
                                isSpecial: special,
                                casual: casual,
                                premium: premium,
                                specialSeed: shown.hashCode,
                                symbol: shown,
                              ),
                            )
                          else
                            Positioned(
                              left: faceRect.left,
                              top: faceRect.top,
                              width: faceRect.width,
                              height: faceRect.height,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  faceClipRadius,
                                ),
                                child: Stack(
                                  clipBehavior: Clip.hardEdge,
                                  children: [
                                    Positioned(
                                      left: symbolRect.left - faceRect.left,
                                      top: symbolRect.top - faceRect.top,
                                      width: symbolRect.width,
                                      height: symbolRect.height,
                                      child: ClipRect(
                                        child: Opacity(
                                          opacity: locked
                                              ? (premium ? 0.90 : 0.72)
                                              : 1.0,
                                          child: _EngravedFace(symbol: shown),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                      if (casual) {
                        layers = ClipRRect(
                          borderRadius: BorderRadius.circular(
                            CasualTileLayout.cornerRadius(tileSize),
                          ),
                          child: layers,
                        );
                      }
                      return layers;
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
                          casual: casual,
                          premium: premium,
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
          offset: Offset(0, isRemoving ? 0.22 : selectLift / height),
          duration: isRemoving
              ? TileWidget.removeSlideDuration
              : TileWidget.selectDuration,
          curve: Curves.easeOut,
          child: AnimatedBuilder(
            animation: Listenable.merge([_shuffleFlip, _pop]),
            builder: (context, child) {
              final tapPop =
                  1.0 +
                  (TileWidget.tapPopPeak - 1.0) *
                      math.sin(_pop.value * math.pi);
              return Transform(
                alignment: Alignment.center,
                transform: _shuffleMatrix(_shuffleLocalT, tapPop),
                key: const ValueKey('tile-shuffle-transform'),
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
          if (widget.isTarget)
            Positioned(
              left: faceRect.left + 2,
              top: faceRect.top + 2,
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF45276B),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.star_rounded,
                    color: const Color(0xFFFFD54F),
                    size: width * 0.23,
                  ),
                ),
              ),
            ),
          if (widget.isBlocker)
            Positioned.fromRect(
              rect: faceRect,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x33FFAB40),
                    borderRadius: BorderRadius.circular(faceClipRadius),
                    border: Border.all(
                      color: const Color(0xFFFFAB40),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
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

    final shuffling = _blockHits;
    final l10n = AppLocalizations.of(context);
    final semantic = Semantics(
      container: true,
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      onTap: widget.onTap == null ? null : _emitTap,
      selected: widget.isHinted || widget.isSelected,
      hint: widget.isTarget ? l10n.specialTile : null,
      label: l10n.tileSemanticLabel(
        symbol: tile.symbol,
        free: widget.isFree,
        hinted: widget.isHinted || widget.isSelected,
        inTray: widget.compact,
        removing: isRemoving,
      ),
      child: body,
    );
    if (widget.onTap == null) {
      return IgnorePointer(ignoring: isRemoving || shuffling, child: semantic);
    }

    final bool Function(Size, Offset) hitContains = casual
        ? CasualTileLayout.containsPoint
        : (premium
              ? PremiumTileLayout.containsPoint
              : TileCanvas.containsBodyPoint);
    Widget interactive = Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _emitTap(),
      child: semantic,
    );
    if (!widget.compact) {
      interactive = TileHitTarget(contains: hitContains, child: interactive);
    }
    return IgnorePointer(ignoring: isRemoving || shuffling, child: interactive);
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
