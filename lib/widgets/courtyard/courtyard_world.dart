import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/courtyard_reward.dart';
import '../../models/garden.dart';
import '../../models/pet.dart';
import '../../models/pet_combat.dart';
import '../../models/pet_roster.dart';
import '../../models/plot_kind.dart';
import '../../models/seed_batch.dart';
import '../../services/fox_adventure_store.dart';
import '../../services/pet_story_store.dart';
import '../pets/pet_portrait.dart';
import '../pets/pet_story_section.dart';
import 'courtyard_estate.dart';
import 'courtyard_lot_build.dart';
import 'courtyard_reward_choice.dart';
import 'courtyard_world_layout.dart';
import '../garden/plant_art.dart';
import '../seeds/seed_plot_badge.dart';
import 'plot_stage_view.dart';

const courtyardHomeKey = ValueKey('courtyard-home');
const courtyardPondKey = ValueKey('courtyard-pond');
const courtyardPetAreaKey = ValueKey('courtyard-pet-area');
const courtyardPetStartAdventureKey = ValueKey('courtyard-pet-start-adventure');
const courtyardPetVisitKey = ValueKey('courtyard-pet-visit');

/// Изометрический двор: одна лужайка игрока, без соседних дворов.
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
    this.foxAdventure,
    this.onFoxTap,
    this.pets = const [],
    this.petStories,
    this.onPetTap,
    this.courtyardRewards = const {},
    this.showSeedProduction = false,
    this.seedBatch,
    this.showGarden = false,
    this.garden,
    this.onBedTap,
    this.onWarehouseTap,
    this.petRoster,
    this.ownedPetKinds = const [],
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
  final FoxAdventureStore? foxAdventure;
  final VoidCallback? onFoxTap;

  final List<PetCare> pets;
  final PetStoryStore? petStories;
  final VoidCallback? onPetTap;
  final Set<CourtyardReward> courtyardRewards;

  /// Знак партии только на своём дворе. Чужие и тестовые кадры его не рисуют.
  final bool showSeedProduction;
  final SeedBatch? seedBatch;

  /// Огород и склад только на своём дворе.
  final bool showGarden;
  final GardenSnapshot? garden;
  final ValueChanged<int>? onBedTap;
  final VoidCallback? onWarehouseTap;
  final PetRosterSnapshot? petRoster;
  final List<PetKind> ownedPetKinds;

  static const growDuration = Duration(milliseconds: 2400);

  @override
  State<CourtyardWorld> createState() => _CourtyardWorldState();
}

class _CourtyardWorldState extends State<CourtyardWorld>
    with TickerProviderStateMixin {
  late final AnimationController _grow;
  late final AnimationController _pulse;
  late final TransformationController _transform;
  int? _blendFrom;
  NeighborYard? _tappedNeighbor;
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
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    if (widget.animate) _grow.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(CourtyardWorldLayout.countryBase), context);
    for (final reward in CourtyardReward.values) {
      precacheImage(AssetImage(reward.asset), context);
    }
    for (var frame = 1; frame <= PlotStages.frameCount; frame++) {
      precacheImage(
        AssetImage(PlotStages.assetOf(PlotKind.house, frame)),
        context,
      );
    }
    for (var frame = 1; frame <= PlotStages.framesOf(PlotKind.pond); frame++) {
      precacheImage(
        AssetImage(PlotStages.assetOf(PlotKind.pond, frame)),
        context,
      );
    }
  }

  @override
  void didUpdateWidget(covariant CourtyardWorld oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate &&
        (oldWidget.from != widget.from || oldWidget.to != widget.to)) {
      _grow.forward(from: 0);
    }
    final prev = oldWidget.to.purchasedHome;
    final next = widget.to.purchasedHome;
    final stepped =
        !widget.animate && prev != null && next != null && next == prev + 1;
    if (!stepped || MediaQuery.disableAnimationsOf(context)) {
      _blendFrom = null;
      if (_pulse.isAnimating) _pulse.stop();
      return;
    }
    _blendFrom = prev;
    _pulse.forward(from: 0);
  }

  @override
  void dispose() {
    _grow.dispose();
    _pulse.dispose();
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

  double _visualHome(double stage) {
    final from = _blendFrom;
    if (from == null) return stage;
    final t = Curves.easeOutCubic.transform(_pulse.value);
    return from + (stage - from) * t;
  }

  void _fitIfNeeded(Size viewport) {
    if (viewport.width < 1 || viewport.height < 1) return;
    if (_viewport == viewport && _didFit) return;
    _viewport = viewport;
    _didFit = true;
    _applyCamera(viewport);
  }

  void _applyCamera(Size viewport) {
    _transform.value = _matrixFor(
      viewport,
      CourtyardWorldLayout.yardCover,
      0.72,
    );
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

  void _onHouseTap() {
    widget.onSelectLot?.call(PlotKind.house);
    final lot = _estate.lot(PlotKind.house);
    if (!lot.unlocked) widget.onLockedLot?.call(PlotKind.house);
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
          animation: Listenable.merge([_grow, _pulse]),
          builder: (context, _) {
            final estate = _estate;
            final homeStage = _visualHome(estate.homeStage);
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
                      alignment: Alignment.center,
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
                            _homeBuild(homeStage),
                            if (estate.pondStage > 0)
                              _pondBuild(estate.pondStage),
                            ..._rewardViews(hidePondGift: estate.pondStage > 0),
                            _petYard(),
                            if (estate.festival > 0.02 ||
                                estate.streakLife > 0.08)
                              Positioned.fromRect(
                                rect: CourtyardWorldLayout.mapRect(
                                  CourtyardWorldLayout.yardCover,
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
                            _homeHit(),
                            if (widget.showSeedProduction) _seedBadge(),
                            if (widget.showGarden) ..._gardenPlots(),
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

  Widget _homeBuild(double stage) {
    final pad = CourtyardWorldLayout.mapRect(CourtyardWorldLayout.homeYard);
    return Positioned.fromRect(
      key: courtyardHomeKey,
      rect: pad,
      child: IgnorePointer(
        child: PlotStageView(kind: PlotKind.house, stage: stage),
      ),
    );
  }

  Widget _pondBuild(double stage) {
    final pad = CourtyardWorldLayout.mapRect(CourtyardWorldLayout.pondYard);
    return Positioned.fromRect(
      key: courtyardPondKey,
      rect: pad,
      child: IgnorePointer(
        child: PlotStageView(kind: PlotKind.pond, stage: stage),
      ),
    );
  }

  Widget _homeHit() {
    final rect = CourtyardWorldLayout.mapRect(
      CourtyardWorldLayout.homeYard,
    ).inflate(8);
    return Positioned.fromRect(
      rect: rect,
      child: Semantics(
        button: true,
        label: AppLocalizations.of(context).homeSemantic,
        child: GestureDetector(
          key: const ValueKey('courtyard-lot-house'),
          onTap: widget.interactive ? _onHouseTap : null,
          behavior: HitTestBehavior.opaque,
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  List<Widget> _gardenPlots() {
    final garden = widget.garden ?? GardenSnapshot.empty;
    return [
      for (var index = 0; index < GardenCatalog.bedCount; index++)
        Positioned.fromRect(
          rect: CourtyardWorldLayout.mapRect(
            CourtyardWorldLayout.gardenBed(index),
          ),
          child: GardenBedView(
            index: index,
            planting: garden.bedAt(index),
            onTap: widget.interactive
                ? () => widget.onBedTap?.call(index)
                : null,
          ),
        ),
      Positioned.fromRect(
        rect: CourtyardWorldLayout.mapRect(CourtyardWorldLayout.warehouse),
        child: WarehouseBuilding(
          count: garden.plantCount,
          onTap: widget.interactive ? widget.onWarehouseTap : null,
        ),
      ),
      Positioned(
        key: const ValueKey('garden-guard'),
        left: CourtyardWorldLayout.mapRect(
          CourtyardWorldLayout.gardenBeds.first,
        ).left,
        top:
            CourtyardWorldLayout.mapRect(
              CourtyardWorldLayout.gardenBeds.first,
            ).bottom +
            4,
        width: 220,
        height: 34,
        child: _GardenGuardBadge(
          roster: widget.petRoster,
          owned: widget.ownedPetKinds,
        ),
      ),
    ];
  }

  Widget _seedBadge() {
    return Positioned.fromRect(
      rect: CourtyardWorldLayout.mapRect(CourtyardWorldLayout.seedBadge),
      child: SeedPlotBadge(
        batch: widget.seedBatch,
        onTap: widget.interactive ? _onHouseTap : () {},
      ),
    );
  }

  Widget _petYard() {
    return Positioned.fromRect(
      rect: CourtyardWorldLayout.mapRect(CourtyardWorldLayout.petYard),
      child: _PetYardArea(
        cares: widget.pets,
        stories: widget.petStories,
        roster: widget.petRoster,
        onTap: widget.onPetTap ?? widget.onFoxTap,
      ),
    );
  }

  List<Widget> _rewardViews({required bool hidePondGift}) {
    return [
      for (final reward in widget.courtyardRewards)
        if (!hidePondGift || reward != CourtyardReward.pond)
          Positioned.fromRect(
            rect: CourtyardWorldLayout.mapRect(
              CourtyardWorldLayout.rewardOf(reward),
            ),
            child: IgnorePointer(child: _GroundedProp(reward: reward)),
          ),
    ];
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
    final l10n = AppLocalizations.of(context);
    if (!yard.named) return l10n.neighboringCourtyard;
    if (yard.rating != null) {
      return l10n.neighborRating(yard.name!, yard.rating!);
    }
    return l10n.neighborYard(yard.name!);
  }
}

PetCare? _featuredYardCare(List<PetCare> cares, PetStoryStore? stories) {
  if (cares.isEmpty) return null;
  if (stories != null) {
    for (final care in cares) {
      final story = stories.currentFor(care.kind);
      if (story != null && !stories.isStarted(story)) return care;
    }
    for (final care in cares) {
      if (stories.currentFor(care.kind) != null) return care;
    }
  }
  var chosen = cares.first;
  for (final care in cares.skip(1)) {
    if (care.lowest < chosen.lowest) chosen = care;
  }
  return chosen;
}

class _PetYardSlot {
  const _PetYardSlot({
    required this.care,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final PetCare care;
  final double left;
  final double top;
  final double width;
  final double height;

  double get right => left + width;
}

List<_PetYardSlot> _yardSlots(List<PetCare> cares, double w, double h) {
  final n = cares.length;
  if (n == 0) return const [];
  final petWidth = n <= 1
      ? w * 0.58
      : n == 2
      ? w * 0.46
      : n == 3
      ? w * 0.36
      : w * 0.30;
  final petHeight = n <= 1
      ? h * 0.54
      : n == 2
      ? h * 0.48
      : n == 3
      ? h * 0.42
      : h * 0.38;
  final feet = h * 0.76;
  if (n == 1) {
    return [
      _PetYardSlot(
        care: cares.first,
        left: (w - petWidth) / 2,
        top: feet - petHeight,
        width: petWidth,
        height: petHeight,
      ),
    ];
  }
  final span = w * 0.94;
  final start = (w - span) / 2;
  final step = (span - petWidth) / (n - 1);
  return [
    for (var i = 0; i < n; i++)
      _PetYardSlot(
        care: cares[i],
        left: start + i * step,
        top: feet - petHeight + (i.isOdd ? h * 0.05 : -h * 0.015),
        width: petWidth,
        height: petHeight,
      ),
  ];
}

class _PetYardArea extends StatefulWidget {
  const _PetYardArea({
    required this.cares,
    required this.stories,
    this.roster,
    this.onTap,
  });

  final List<PetCare> cares;
  final PetStoryStore? stories;
  final PetRosterSnapshot? roster;
  final VoidCallback? onTap;

  @override
  State<_PetYardArea> createState() => _PetYardAreaState();
}

class _PetYardAreaState extends State<_PetYardArea>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float;

  @override
  void initState() {
    super.initState();
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.cares.isNotEmpty) _float.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PetYardArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cares.isEmpty) {
      _float.stop();
      _float.reset();
    } else if (!_float.isAnimating) {
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final cares = widget.cares;
    final stories = widget.stories;
    final featured = _featuredYardCare(cares, stories);
    final story = featured == null ? null : stories?.currentFor(featured.kind);
    final stage = story == null ? 0 : stories!.progress(story);
    final inviteLabel = l.petYardVisit;
    final status = cares.isEmpty
        ? l.chooseAPetStatus
        : cares.map((care) => l.petMoodLine(care.kind, care.mood)).join(' ');
    return Semantics(
      button: true,
      label: '$status $inviteLabel',
      child: GestureDetector(
        key: const ValueKey('courtyard-pets'),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final h = box.maxHeight;
            final slots = _yardSlots(cares, w, h);
            final item = w * 0.21;
            final petTop = slots.isEmpty
                ? h * 0.22
                : slots.map((slot) => slot.top).reduce(math.min);
            return SizedBox.expand(
              child: Stack(
                key: courtyardPetAreaKey,
                clipBehavior: Clip.none,
                children: [
                  if (cares.isEmpty)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.pets_rounded, color: accent, size: 36),
                          const SizedBox(height: 4),
                          Text(
                            l.chooseAPetYard,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFF8F1DE),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              shadows: [
                                Shadow(color: Color(0xAA000000), blurRadius: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    for (final slot in slots)
                      Positioned(
                        left: slot.left + slot.width * 0.07,
                        top: slot.top + slot.height * 0.88,
                        width: slot.width * 0.86,
                        height: h * 0.13,
                        child: const IgnorePointer(
                          child: CustomPaint(painter: ContactShadowPainter()),
                        ),
                      ),
                    for (final slot in [
                      ...slots,
                    ]..sort((a, b) => a.top.compareTo(b.top)))
                      Positioned(
                        key: ValueKey('courtyard-pet-${slot.care.kind.name}'),
                        left: slot.left,
                        top: slot.top,
                        width: slot.width,
                        height: slot.height,
                        child: PetPortrait(kind: slot.care.kind),
                      ),
                    if (widget.roster != null)
                      for (final slot in slots)
                        Positioned(
                          left: slot.left,
                          top: slot.top + slot.height * 0.7,
                          width: slot.width,
                          height: 18,
                          child: IgnorePointer(
                            child: _PetCombatBadge(
                              kind: slot.care.kind,
                              roster: widget.roster!,
                            ),
                          ),
                        ),
                    for (
                      var index = 0;
                      story != null && index < story.items.length;
                      index++
                    )
                      Positioned(
                        left: w * 0.03 + index * item * 1.12,
                        top: h - item,
                        width: item,
                        height: item,
                        child: Opacity(
                          opacity: index < stage
                              ? 1
                              : index == stage
                              ? 0.48
                              : 0.14,
                          child: PetStoryItemView(
                            item: story.items[index],
                            preview: index >= stage,
                          ),
                        ),
                      ),
                    Positioned(
                      left: -w * 0.28,
                      right: -w * 0.28,
                      bottom: h - petTop + 2,
                      child: AnimatedBuilder(
                        animation: _float,
                        builder: (context, child) {
                          final t = Curves.easeInOut.transform(_float.value);
                          const lift = -2.5;
                          return Transform.translate(
                            offset: Offset(0, lift * t),
                            child: child,
                          );
                        },
                        child: Center(
                          child: _PetInviteBubble(
                            label: inviteLabel,
                            startAdventure: false,
                          ),
                        ),
                      ),
                    ),
                    for (final slot in slots)
                      if (slot.care.mood != PetMood.content)
                        Positioned(
                          left: slot.right - w * 0.04,
                          top: slot.top + h * 0.04,
                          width: w * 0.20,
                          height: w * 0.20,
                          child: _PetMoodBubble(
                            mood: slot.care.mood,
                            accent: switch (slot.care.mood) {
                              PetMood.starving => const Color(0xFFE37A67),
                              PetMood.asking => const Color(0xFFF0B45A),
                              PetMood.content => const Color(0xFFFFD980),
                            },
                          ),
                        ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Реплика над фигуркой: начать историю или тихо пригласить в раздел питомца.
class _PetInviteBubble extends StatelessWidget {
  const _PetInviteBubble({required this.label, required this.startAdventure});

  final String label;
  final bool startAdventure;

  static const _gold = Color(0xFFD4AF37);
  static const _goldSoft = Color(0xFFE8C96A);
  static const _ivory = Color(0xFFF8F1DE);
  static const _cream = Color(0xF2FFF6E0);
  static const _wood = Color(0xE63A2012);

  @override
  Widget build(BuildContext context) {
    final fill = startAdventure ? _cream : _wood;
    final border = startAdventure ? _gold : _goldSoft.withValues(alpha: 0.62);
    final foreground = startAdventure ? const Color(0xFF3A2012) : _ivory;
    return Column(
      key: startAdventure
          ? courtyardPetStartAdventureKey
          : courtyardPetVisitKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(startAdventure ? 14 : 18),
            border: Border.all(
              color: border,
              width: startAdventure ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: startAdventure
                    ? const Color(0x66D4AF37)
                    : const Color(0x66000000),
                blurRadius: startAdventure ? 10 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              startAdventure ? 10 : 12,
              startAdventure ? 6 : 5,
              startAdventure ? 10 : 10,
              startAdventure ? 6 : 5,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    startAdventure
                        ? Icons.auto_stories_rounded
                        : Icons.spa_rounded,
                    size: startAdventure ? 14 : 12,
                    color: startAdventure ? const Color(0xFF8A5A18) : _goldSoft,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      color: foreground,
                      fontWeight: startAdventure
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: startAdventure ? 11 : 10,
                      height: 1.1,
                      letterSpacing: startAdventure ? 0.1 : 0.35,
                    ),
                  ),
                  if (!startAdventure) ...[
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: _goldSoft.withValues(alpha: 0.85),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        CustomPaint(
          size: const Size(14, 7),
          painter: _BubbleTailPainter(fill: fill, border: border),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  const _BubbleTailPainter({required this.fill, required this.border});

  final Color fill;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(1.2, 0)
      ..lineTo(size.width / 2, size.height - 0.6)
      ..lineTo(size.width - 1.2, 0);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close(),
      Paint()..color = fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BubbleTailPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.border != border;
}

class _GardenGuardBadge extends StatelessWidget {
  const _GardenGuardBadge({required this.roster, required this.owned});

  final PetRosterSnapshot? roster;
  final List<PetKind> owned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final guard = roster?.guarding(owned);
    final String label;
    if (guard == null) {
      label = roster != null && roster!.ownsDefenderSpecies(owned)
          ? l10n.gardenUnguarded
          : l10n.gardenNoDefender;
    } else {
      final record = roster!.recordOf(guard) ?? PetCombatRecord.fresh(guard);
      final power = PetStrength.of(
        level: record.level,
        main: roster!.defOf(record.mainItemId),
        accessory: roster!.defOf(record.accessoryItemId),
      ).total;
      label = l10n.gardenGuardLabel(l10n.petName(guard), power);
    }
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xE63A2012),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE8C96A)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFFF8F1DE),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PetCombatBadge extends StatelessWidget {
  const _PetCombatBadge({required this.kind, required this.roster});

  final PetKind kind;
  final PetRosterSnapshot roster;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final role = PetCombatRules.roleOf(kind);
    final record = roster.recordOf(kind) ?? PetCombatRecord.fresh(kind);
    final label = '${l10n.petRole(role)} ${l10n.petLevelShort(record.level)}';
    return Semantics(
      label: l10n.petBadgeLabel(role, record.level),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xE63A2012),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              key: ValueKey('pet-yard-badge-${kind.name}'),
              style: const TextStyle(
                color: Color(0xFFF8F1DE),
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Пузырь над питомцем — только когда он голоден или просит внимания.
class _PetMoodBubble extends StatelessWidget {
  const _PetMoodBubble({required this.mood, required this.accent});

  final PetMood mood;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xF2FFF6E0),
        border: Border.all(color: accent, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(
            mood == PetMood.starving
                ? Icons.restaurant_rounded
                : Icons.favorite_rounded,
            color: accent,
          ),
        ),
      ),
    );
  }
}

/// Декор вместе с тенью: спрайты нарисованы без неё, чтобы свет во дворе
/// шёл из одного места для дома, питомца и построек сразу.
class _GroundedProp extends StatelessWidget {
  const _GroundedProp({required this.reward});

  final CourtyardReward reward;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Смещена вправо: солнце на карте стоит слева сверху.
            Positioned(
              left: w * 0.16,
              width: w * 0.76,
              top: h * 0.87,
              height: h * 0.15,
              child: const CustomPaint(painter: ContactShadowPainter()),
            ),
            Positioned.fill(child: CourtyardRewardView(reward: reward)),
          ],
        );
      },
    );
  }
}

/// Мягкая тень под объектом: без неё спрайт висит над травой.
class ContactShadowPainter extends CustomPainter {
  const ContactShadowPainter({this.strength = 1});

  /// Насколько плотная тень: у мелкого декора она слабее, чем у дома.
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 2 || size.height < 2) return;
    final box = Offset.zero & size;
    // Ореол растекается по траве, ядро держит место касания — только с ним
    // спрайт перестаёт выглядеть наклейкой поверх лужайки.
    canvas.drawOval(
      box,
      Paint()
        ..color = const Color(0xFF12190D).withValues(alpha: 0.30 * strength)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * 0.25),
    );
    canvas.drawOval(
      box.deflate(size.height * 0.22),
      Paint()
        ..color = const Color(0xFF0D1409).withValues(alpha: 0.50 * strength)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.height * 0.1),
    );
  }

  @override
  bool shouldRepaint(covariant ContactShadowPainter oldDelegate) =>
      oldDelegate.strength != strength;
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
