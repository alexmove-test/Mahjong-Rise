import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/plot_kind.dart';
import 'courtyard_estate.dart';
import 'courtyard_lot_build.dart';
import 'courtyard_world_layout.dart';
import 'plot_stage_view.dart';

/// Широкая изометрическая страна: 4 своих лота + дворы соседей.
class CourtyardWorld extends StatefulWidget {
  const CourtyardWorld({
    super.key,
    required this.to,
    this.from,
    this.animate = false,
    this.neighbors = const [],
    this.onSelectLot,
    this.onLockedLot,
    this.onNeighborTap,
    this.onPanHint,
    this.inspectKind,
    this.interactive = true,
  });

  final CourtyardEstate to;
  final CourtyardEstate? from;
  final bool animate;
  final List<NeighborYard> neighbors;
  final ValueChanged<PlotKind>? onSelectLot;
  final ValueChanged<PlotKind>? onLockedLot;
  final ValueChanged<NeighborYard>? onNeighborTap;
  final VoidCallback? onPanHint;
  final PlotKind? inspectKind;
  final bool interactive;

  static const growDuration = Duration(milliseconds: 2400);

  @override
  State<CourtyardWorld> createState() => _CourtyardWorldState();
}

class _CourtyardWorldState extends State<CourtyardWorld>
    with SingleTickerProviderStateMixin {
  late final AnimationController _grow;
  late final TransformationController _transform;
  NeighborYard? _tappedNeighbor;
  PlotKind? _inspected;
  var _didFit = false;
  Size? _viewport;

  static const _gold = Color(0xFFE8C96A);
  static const _ivory = Color(0xFFF8F1DE);
  static const _wood = Color(0xFF3A2012);

  @override
  void initState() {
    super.initState();
    _transform = TransformationController();
    _grow = AnimationController(
      vsync: this,
      duration: CourtyardWorld.growDuration,
    );
    if (widget.animate) _grow.forward();
    _inspected = widget.inspectKind;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final asset in CourtyardWorldLayout.allAssets) {
      precacheImage(AssetImage(asset), context);
    }
  }

  @override
  void didUpdateWidget(covariant CourtyardWorld oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate &&
        (oldWidget.from != widget.from || oldWidget.to != widget.to)) {
      _grow.forward(from: 0);
    }
    if (widget.inspectKind != null && widget.inspectKind != _inspected) {
      _inspected = widget.inspectKind;
    }
  }

  @override
  void dispose() {
    _grow.dispose();
    _transform.dispose();
    super.dispose();
  }

  CourtyardEstate get _estate {
    final from = widget.from;
    if (!widget.animate || from == null) return widget.to;
    return CourtyardEstate.lerp(
      from,
      widget.to,
      Curves.easeInOutCubic.transform(_grow.value),
    );
  }

  void _fitIfNeeded(Size viewport) {
    if (viewport.width < 1 || viewport.height < 1) return;
    if (_viewport == viewport && _didFit) return;
    _viewport = viewport;
    _didFit = true;
    _applyCamera(viewport);
  }

  void _applyCamera(Size viewport) {
    _transform.value = _matrixFor(viewport, CourtyardWorldLayout.plateau, 0.78);
  }

  Matrix4 _matrixFor(Size viewport, Rect focusNorm, double coverage) {
    final cam = CourtyardWorldLayout.camera(
      viewport: viewport,
      focusNorm: focusNorm,
      coverage: coverage,
    );
    return Matrix4.identity()
      ..translate(cam.tx, cam.ty)
      ..scale(cam.scale);
  }

  void _onLotTap(PlotKind kind) {
    final lot = _estate.lot(kind);
    setState(() => _inspected = kind);
    widget.onSelectLot?.call(kind);
    if (!lot.unlocked) widget.onLockedLot?.call(kind);
  }

  void _onNeighborTap(NeighborYard yard) {
    setState(() => _tappedNeighbor = yard);
    widget.onNeighborTap?.call(yard);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _fitIfNeeded(viewport);
        });
        final cover = CourtyardWorldLayout.coverScale(viewport);
        return AnimatedBuilder(
          animation: _grow,
          builder: (context, _) {
            final estate = _estate;
            return SizedBox(
              width: viewport.width,
              height: viewport.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const IgnorePointer(
                    child: Image(
                      image: AssetImage(CourtyardWorldLayout.countryBase),
                      fit: BoxFit.cover,
                      alignment: Alignment(0, 0.18),
                      filterQuality: FilterQuality.high,
                      gaplessPlayback: true,
                    ),
                  ),
                  ClipRect(
                    child: InteractiveViewer(
                      transformationController: _transform,
                      constrained: false,
                      minScale: cover,
                      maxScale: math.max(2.8, cover),
                      boundaryMargin: EdgeInsets.zero,
                      panEnabled: widget.interactive,
                      scaleEnabled: widget.interactive,
                      onInteractionStart: widget.interactive
                          ? (_) => widget.onPanHint?.call()
                          : null,
                      child: SizedBox(
                        width: CourtyardWorldLayout.mapWidth,
                        height: CourtyardWorldLayout.mapHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Positioned.fill(
                              child: Image(
                                image: AssetImage(
                                  CourtyardWorldLayout.countryBase,
                                ),
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.high,
                                gaplessPlayback: true,
                              ),
                            ),
                            for (final kind in PlotKind.order)
                              _lotBuild(kind, estate.lot(kind)),
                            for (final kind in PlotKind.order)
                              _lotProgress(kind, estate.lot(kind)),
                            if (_inspected != null)
                              _lotInspect(_inspected!, estate.lot(_inspected!)),
                            if (estate.festival > 0.02 ||
                                estate.streakLife > 0.08)
                              Positioned.fromRect(
                                rect: CourtyardWorldLayout.mapRect(
                                  CourtyardWorldLayout.plateau,
                                ),
                                child: IgnorePointer(
                                  child: CustomPaint(
                                    painter: FestivalLanternsPainter(
                                      strength:
                                          (estate.festival * 0.7 +
                                                  estate.streakLife * 0.5)
                                              .clamp(0.0, 1.0),
                                      t: widget.animate ? _grow.value : 0.35,
                                    ),
                                  ),
                                ),
                              ),
                            for (final kind in PlotKind.order) _lotHit(kind),
                            for (final yard in widget.neighbors)
                              _neighborHit(yard),
                            if (_tappedNeighbor != null)
                              _neighborLabel(_tappedNeighbor!),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _lotBuild(PlotKind kind, CourtyardLotView lot) {
    if (!lot.unlocked && lot.stage < 0.05) return const SizedBox.shrink();
    final pad = CourtyardWorldLayout.mapRect(CourtyardWorldLayout.lotOf(kind));
    final rect = Rect.fromLTWH(
      pad.left - pad.width * 0.06,
      pad.top - pad.height * 0.72,
      pad.width * 1.12,
      pad.height * 1.72,
    );
    return Positioned.fromRect(
      rect: rect,
      child: IgnorePointer(
        child: PlotStageView(kind: kind, stage: lot.stage),
      ),
    );
  }

  Widget _lotProgress(PlotKind kind, CourtyardLotView lot) {
    if (!lot.unlocked) return const SizedBox.shrink();
    final lotRect = CourtyardWorldLayout.mapRect(
      CourtyardWorldLayout.lotOf(kind),
    );
    final width = lotRect.width * 0.72;
    const height = 22.0;
    return Positioned(
      left: lotRect.center.dx - width / 2,
      top: lotRect.bottom - lotRect.height * 0.28,
      width: width,
      height: height,
      child: IgnorePointer(
        child: PlotProgressMeter(
          key: ValueKey('plot-progress-${kind.name}'),
          kind: kind,
          stage: lot.stage,
        ),
      ),
    );
  }

  Widget _lotInspect(PlotKind kind, CourtyardLotView lot) {
    final pad = CourtyardWorldLayout.mapRect(CourtyardWorldLayout.lotOf(kind));
    final width = math.max(pad.width * 1.05, 96.0);
    return Positioned(
      left: pad.center.dx - width / 2,
      top: pad.top - 28,
      width: width,
      child: IgnorePointer(
        child: _LotInspectCard(kind: kind, lot: lot),
      ),
    );
  }

  Widget _lotHit(PlotKind kind) {
    final rect = CourtyardWorldLayout.mapRect(
      CourtyardWorldLayout.lotOf(kind),
    ).inflate(8);
    return Positioned.fromRect(
      rect: rect,
      child: Semantics(
        button: true,
        enabled: true,
        label: L10n.of(context).plotTitle(kind),
        child: GestureDetector(
          key: ValueKey('courtyard-lot-${kind.name}'),
          onTap: () => _onLotTap(kind),
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  Widget _neighborHit(NeighborYard yard) {
    final rect = CourtyardWorldLayout.mapRect(
      CourtyardWorldLayout.neighborOf(yard.slot),
    );
    return Positioned.fromRect(
      rect: rect,
      child: GestureDetector(
        key: ValueKey('courtyard-neighbor-${yard.slot}'),
        onTap: () => _onNeighborTap(yard),
        behavior: HitTestBehavior.opaque,
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _neighborLabel(NeighborYard yard) {
    final rect = CourtyardWorldLayout.mapRect(
      CourtyardWorldLayout.neighborOf(yard.slot),
    );
    return Positioned(
      left: rect.left - 20,
      top: rect.top - 36,
      width: rect.width + 40,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _wood.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _gold.withValues(alpha: 0.7)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Text(
              _neighborCaption(context, yard),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _ivory,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _neighborCaption(BuildContext context, NeighborYard yard) {
    final l10n = L10n.of(context);
    if (!yard.named) return l10n.neighboringCourtyard;
    if (yard.rating != null) {
      return l10n.neighborRating(yard.name!, yard.rating!);
    }
    return l10n.neighborYard(yard.name!);
  }
}

class _LotInspectCard extends StatelessWidget {
  const _LotInspectCard({required this.kind, required this.lot});

  final PlotKind kind;
  final CourtyardLotView lot;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final subtitle = lot.unlocked
        ? '${l10n.plotEra(kind, lot.era)} · ${l10n.openedProgress(lot.stage.floor().clamp(0, CourtyardLotBuild.maxStage), CourtyardLotBuild.maxStage)}'
        : l10n.plotLockedHint;
    return DecoratedBox(
      key: ValueKey('plot-inspect-${kind.name}'),
      decoration: BoxDecoration(
        color: const Color(0xE63A2012),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE8C96A).withValues(alpha: 0.75),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.plotTitle(kind),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFF8F1DE),
                fontWeight: FontWeight.w800,
                fontSize: 10,
                height: 1.1,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFE8C96A),
                fontWeight: FontWeight.w600,
                fontSize: 8,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Гирлянда фонарей поверх двора на неделю события и за серию.
class FestivalLanternsPainter extends CustomPainter {
  const FestivalLanternsPainter({required this.strength, required this.t});

  final double strength;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (strength <= 0) return;
    final sway = 6 * math.sin(t * 2 * math.pi);
    final line = Paint()
      ..color = const Color(0xFFE8C96A).withValues(alpha: 0.55 * strength)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final glow = Paint()
      ..color = const Color(0xFFFFD54F).withValues(alpha: 0.42 * strength)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final core = Paint()
      ..color = const Color(0xFFFFF3C4).withValues(alpha: 0.9 * strength);

    final y = size.height * 0.18;
    final points = <Offset>[
      Offset(size.width * 0.12 + sway * 0.15, y + 10),
      Offset(size.width * 0.28, y - 4),
      Offset(size.width * 0.46 + sway * 0.08, y + 6),
      Offset(size.width * 0.64, y - 2),
      Offset(size.width * 0.82 - sway * 0.12, y + 8),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy - 14);
    for (final p in points) {
      path.lineTo(p.dx, p.dy - 14);
    }
    canvas.drawPath(path, line);
    for (final p in points) {
      canvas.drawCircle(p, 9, glow);
      canvas.drawCircle(p, 4.2, core);
    }
  }

  @override
  bool shouldRepaint(covariant FestivalLanternsPainter oldDelegate) {
    return oldDelegate.strength != strength || oldDelegate.t != t;
  }
}
