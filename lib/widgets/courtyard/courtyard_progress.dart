import 'dart:math' as math;

import '../../models/levels.dart';
import '../../models/plot_kind.dart';
import '../../services/progress_store.dart';
import 'courtyard_lot_build.dart';

/// Визуальное состояние участка: чистая функция прогресса кампании.
class CourtyardSnapshot {
  const CourtyardSnapshot({
    required this.step,
    required this.totalStars,
    required this.dawn,
    required this.path,
    required this.fencePosts,
    required this.gate,
    required this.foundation,
    required this.walls,
    required this.roof,
    required this.chimney,
    required this.door,
    required this.windows,
    required this.shutters,
    required this.fence,
    required this.gardenBeds,
    required this.tree,
    required this.hedge,
    required this.yardProps,
    required this.climber,
    required this.windowGlow,
    required this.smoke,
    required this.birds,
    required this.laundry,
    required this.cat,
    required this.goldLight,
    this.festival = 0,
    this.streakLife = 0,
    this.plotKind = PlotKind.house,
  });

  /// 0 = пустое поле, 24 = дом собран.
  final double step;
  final int totalStars;

  final double dawn;
  final double path;
  final double fencePosts;
  final double gate;
  final double foundation;
  final double walls;
  final double roof;
  final double chimney;
  final double door;
  final double windows;
  final double shutters;
  final double fence;
  final double gardenBeds;
  final double tree;
  final double hedge;
  final double yardProps;
  final double climber;
  final double windowGlow;
  final double smoke;
  final double birds;
  final double laundry;
  final double cat;
  final double goldLight;
  final double festival;
  final double streakLife;
  final PlotKind plotKind;

  static const maxStep = 24.0;

  static CourtyardSnapshot fromStore(
    ProgressStore store, {
    int? cycle,
    int streak = 0,
    bool festival = false,
  }) {
    final story = Levels.storyLength;
    final c = (cycle ?? Levels.cycleOf(store.maxUnlocked)).clamp(
      0,
      Levels.maxCycle,
    );
    final localUnlocked = store.unlockedInCycle(c).clamp(1, story);
    final lastCompleted = store.isCycleComplete(c);
    return fromCampaign(
      maxUnlocked: lastCompleted ? story : localUnlocked,
      lastCompleted: lastCompleted,
      totalStars: store.starsInCycle(c),
      levelCount: story,
      streak: streak,
      festival: festival,
      plotKind: PlotKind.ofCycle(c),
    );
  }

  static CourtyardSnapshot fromCampaign({
    required int maxUnlocked,
    required bool lastCompleted,
    required int totalStars,
    int levelCount = 24,
    int streak = 0,
    bool festival = false,
    PlotKind plotKind = PlotKind.house,
  }) {
    final step = gardenStep(
      maxUnlocked: maxUnlocked,
      lastCompleted: lastCompleted,
      levelCount: levelCount,
    ).toDouble();
    return fromStep(
      step: step,
      totalStars: totalStars,
      streak: streak,
      festival: festival,
      plotKind: plotKind,
    );
  }

  static int gardenStep({
    required int maxUnlocked,
    required bool lastCompleted,
    int levelCount = 24,
  }) {
    if (maxUnlocked < levelCount) return (maxUnlocked - 1).clamp(0, levelCount);
    return lastCompleted ? levelCount : levelCount - 1;
  }

  static CourtyardSnapshot fromStep({
    required double step,
    required int totalStars,
    int streak = 0,
    bool festival = false,
    PlotKind plotKind = PlotKind.house,
  }) {
    final s = step.clamp(0.0, maxStep);
    final stars = totalStars.clamp(0, 72);
    final streakLife = _rise(streak.toDouble(), 1, 7);
    final festive = festival ? 1.0 : 0.0;
    return CourtyardSnapshot(
      step: s,
      totalStars: stars,
      dawn: _rise(s, 0, maxStep),
      path: _rise(s, 0.3, 4),
      fencePosts: _rise(s, 2, 5),
      gate: _rise(s, 5, 8),
      foundation: _rise(s, 6, 8.5),
      walls: _rise(s, 9, 12),
      roof: _rise(s, 12.5, 15),
      chimney: _rise(s, 14, 16),
      door: _rise(s, 15, 16.5),
      windows: _rise(s, 16.5, 18),
      shutters: _rise(s, 17, 19),
      fence: _rise(s, 18, 20),
      gardenBeds: _rise(s, 18.5, 20.5),
      tree: _rise(s, 20.5, 22.5),
      hedge: _rise(s, 21, 23),
      yardProps: _rise(s, 22, 23.5),
      climber: _rise(s, 23, 24),
      windowGlow: math.max(_rise(stars.toDouble(), 6, 14), streakLife * 0.55),
      smoke: math.max(_rise(stars.toDouble(), 16, 28), streakLife * 0.35),
      birds: math.max(_rise(stars.toDouble(), 32, 44), streakLife * 0.85),
      laundry: math.max(_rise(stars.toDouble(), 36, 48), streakLife * 0.4),
      cat: math.max(_rise(stars.toDouble(), 40, 54), streakLife * 0.45),
      goldLight: math.max(
        _rise(stars.toDouble(), 48, 62),
        festive * 0.28 + streakLife * 0.5,
      ),
      festival: festive,
      streakLife: streakLife,
      plotKind: plotKind,
    );
  }

  static CourtyardSnapshot lerp(
    CourtyardSnapshot a,
    CourtyardSnapshot b,
    double t,
  ) {
    final u = t.clamp(0.0, 1.0);
    double mix(double x, double y) => x + (y - x) * u;
    return CourtyardSnapshot(
      step: mix(a.step, b.step),
      totalStars: (a.totalStars + (b.totalStars - a.totalStars) * u).round(),
      dawn: mix(a.dawn, b.dawn),
      path: mix(a.path, b.path),
      fencePosts: mix(a.fencePosts, b.fencePosts),
      gate: mix(a.gate, b.gate),
      foundation: mix(a.foundation, b.foundation),
      walls: mix(a.walls, b.walls),
      roof: mix(a.roof, b.roof),
      chimney: mix(a.chimney, b.chimney),
      door: mix(a.door, b.door),
      windows: mix(a.windows, b.windows),
      shutters: mix(a.shutters, b.shutters),
      fence: mix(a.fence, b.fence),
      gardenBeds: mix(a.gardenBeds, b.gardenBeds),
      tree: mix(a.tree, b.tree),
      hedge: mix(a.hedge, b.hedge),
      yardProps: mix(a.yardProps, b.yardProps),
      climber: mix(a.climber, b.climber),
      windowGlow: mix(a.windowGlow, b.windowGlow),
      smoke: mix(a.smoke, b.smoke),
      birds: mix(a.birds, b.birds),
      laundry: mix(a.laundry, b.laundry),
      cat: mix(a.cat, b.cat),
      goldLight: mix(a.goldLight, b.goldLight),
      festival: mix(a.festival, b.festival),
      streakLife: mix(a.streakLife, b.streakLife),
      plotKind: u < 0.5 ? a.plotKind : b.plotKind,
    );
  }

  int get band => pathBand(step);

  /// Вечерний слой только на почти готовом доме, сила от звёзд.
  double get lifeArt {
    final ready = _rise(step, 20, maxStep);
    final stars = (0.25 * windowGlow + 0.75 * goldLight).clamp(0.0, 1.0);
    return ready * stars;
  }

  double get layerPond => plotKind == PlotKind.pond ? _rise(step, 4, 16) : 0;

  double get layerRoad => plotKind == PlotKind.pond ? 0 : path;

  double get layerHouse => switch (plotKind) {
    PlotKind.house => _rise(step, 6, 16),
    PlotKind.guest => _rise(step, 6, 12),
    PlotKind.pets => _rise(step, 6, 16),
    PlotKind.pond => 0,
  };

  double get layerInternet =>
      plotKind == PlotKind.guest ? _rise(step, 12, 20) : 0;

  double get layerFlowers => _rise(step, 17, 23);

  static double rise(double value, double start, double end) {
    if (end <= start) return value >= start ? 1 : 0;
    return ((value - start) / (end - start)).clamp(0.0, 1.0);
  }

  static double _rise(double value, double start, double end) =>
      rise(value, start, end);

  @override
  bool operator ==(Object other) {
    return other is CourtyardSnapshot &&
        other.step == step &&
        other.totalStars == totalStars &&
        other.dawn == dawn &&
        other.path == path &&
        other.fencePosts == fencePosts &&
        other.gate == gate &&
        other.foundation == foundation &&
        other.walls == walls &&
        other.roof == roof &&
        other.chimney == chimney &&
        other.door == door &&
        other.windows == windows &&
        other.shutters == shutters &&
        other.fence == fence &&
        other.gardenBeds == gardenBeds &&
        other.tree == tree &&
        other.hedge == hedge &&
        other.yardProps == yardProps &&
        other.climber == climber &&
        other.windowGlow == windowGlow &&
        other.smoke == smoke &&
        other.birds == birds &&
        other.laundry == laundry &&
        other.cat == cat &&
        other.goldLight == goldLight &&
        other.festival == festival &&
        other.streakLife == streakLife &&
        other.plotKind == plotKind;
  }

  @override
  int get hashCode => Object.hashAll([
    step,
    totalStars,
    dawn,
    path,
    fencePosts,
    gate,
    foundation,
    walls,
    roof,
    chimney,
    door,
    windows,
    shutters,
    fence,
    gardenBeds,
    tree,
    hedge,
    yardProps,
    climber,
    windowGlow,
    smoke,
    birds,
    laundry,
    cat,
    goldLight,
    festival,
    streakLife,
    plotKind,
  ]);
}

const pathStagePhrases = houseEraPhrasesEn;
const pondStagePhrases = pondEraPhrasesEn;
const petsStagePhrases = petsEraPhrasesEn;
const guestStagePhrases = guestEraPhrasesEn;

const pathWarmPhrases = <String>[
  'Another step along the path.',
  'The plot is yours now.',
  'The house is a little closer.',
];

const pondWarmPhrases = <String>[
  'The water rose a little.',
  'The pond is more yours now.',
  'The banks sit closer.',
];

const petsWarmPhrases = <String>[
  'The pet house grew a little.',
  'The yard is more theirs now.',
  'The kennel sits closer.',
];

const guestWarmPhrases = <String>[
  'The signal grew a little.',
  'The yard is more connected.',
  'The line sits closer.',
];

const pathLifePhrase = 'The house feels warmer.';
const pondLifePhrase = 'The pond feels alive.';
const petsLifePhrase = 'The pet house feels warmer.';
const guestLifePhrase = 'The yard hums a little.';

/// Первая победа: двор в диалоге — не обои, а смысл кампании.
const firstHomePhrase = 'This house grows as you play.';
const firstPondPhrase = 'This pond fills as you play.';
const firstPetsPhrase = 'This pet house grows as you play.';
const firstGuestPhrase = 'This yard comes online as you play.';

List<String> stagePhrasesFor(PlotKind kind) => eraPhrasesFor(kind, ru: false);

List<String> warmPhrasesFor(PlotKind kind) => switch (kind) {
  PlotKind.house => pathWarmPhrases,
  PlotKind.pond => pondWarmPhrases,
  PlotKind.pets => petsWarmPhrases,
  PlotKind.guest => guestWarmPhrases,
};

String lifePhraseFor(PlotKind kind) => switch (kind) {
  PlotKind.house => pathLifePhrase,
  PlotKind.pond => pondLifePhrase,
  PlotKind.pets => petsLifePhrase,
  PlotKind.guest => guestLifePhrase,
};

String firstPhraseFor(PlotKind kind) => switch (kind) {
  PlotKind.house => firstHomePhrase,
  PlotKind.pond => firstPondPhrase,
  PlotKind.pets => firstPetsPhrase,
  PlotKind.guest => firstGuestPhrase,
};

/// 0 = старт, 1–6 = этапы по 4 уровня внутри цикла из 24.
int pathBand(double step) {
  if (step <= 0) return 0;
  if (step <= 4) return 1;
  if (step <= 8) return 2;
  if (step <= 12) return 3;
  if (step <= 16) return 4;
  if (step <= 20) return 5;
  return 6;
}

String pathPhraseForHome(CourtyardSnapshot snapshot, {double? stage}) {
  final phrases = stagePhrasesFor(snapshot.plotKind);
  final era = CourtyardLotBuild.eraIndex(stage ?? snapshot.step);
  return phrases[era];
}

String pathPhraseForWin({
  required CourtyardSnapshot from,
  required CourtyardSnapshot to,
  double? fromStage,
  double? toStage,
}) {
  final phrases = stagePhrasesFor(to.plotKind);
  final warm = warmPhrasesFor(to.plotKind);
  final a = fromStage ?? from.step;
  final b = toStage ?? to.step;
  final fromEra = CourtyardLotBuild.eraIndex(a);
  final toEra = CourtyardLotBuild.eraIndex(b);
  if (toEra > fromEra) return phrases[toEra];
  if (b > a + 0.01) {
    return warm[b.floor() % warm.length];
  }
  if (to.totalStars > from.totalStars) return lifePhraseFor(to.plotKind);
  return warm.first;
}
