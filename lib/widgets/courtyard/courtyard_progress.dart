import 'dart:math' as math;

import '../../models/levels.dart';
import '../../services/progress_store.dart';

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
      Levels.cycleCount - 1,
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
    );
  }

  static CourtyardSnapshot fromCampaign({
    required int maxUnlocked,
    required bool lastCompleted,
    required int totalStars,
    int levelCount = 24,
    int streak = 0,
    bool festival = false,
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
    );
  }

  int get band => pathBand(step);

  /// Кроссфейд соседних иллюстраций участка.
  CourtyardArtFade get artFade => CourtyardArtFade.fromStep(step);

  /// Вечерний слой только на почти готовом доме, сила от звёзд.
  double get lifeArt {
    final ready = _rise(step, 20, maxStep);
    final stars = (0.25 * windowGlow + 0.75 * goldLight).clamp(0.0, 1.0);
    return ready * stars;
  }

  static double _rise(double value, double start, double end) {
    if (end <= start) return value >= start ? 1 : 0;
    return ((value - start) / (end - start)).clamp(0.0, 1.0);
  }

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
        other.streakLife == streakLife;
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
  ]);
}

/// Соседние пластины двора для кроссфейда.
class CourtyardArtFade {
  const CourtyardArtFade({
    required this.fromIndex,
    required this.toIndex,
    required this.blend,
  });

  static const plateSteps = <double>[
    0,
    2,
    4,
    6,
    8,
    10,
    12,
    14,
    16,
    18,
    20,
    22,
    24,
  ];

  static const assets = <String>[
    'assets/courtyard/courtyard_00_field.jpg',
    'assets/courtyard/courtyard_00b_trail.jpg',
    'assets/courtyard/courtyard_01_path.jpg',
    'assets/courtyard/courtyard_01b_gate.jpg',
    'assets/courtyard/courtyard_02_foundation.jpg',
    'assets/courtyard/courtyard_02b_walls_rise.jpg',
    'assets/courtyard/courtyard_03_walls.jpg',
    'assets/courtyard/courtyard_03b_roof_rise.jpg',
    'assets/courtyard/courtyard_04_roof.jpg',
    'assets/courtyard/courtyard_04b_windows_rise.jpg',
    'assets/courtyard/courtyard_05_windows.jpg',
    'assets/courtyard/courtyard_05b_garden.jpg',
    'assets/courtyard/courtyard_06_complete.jpg',
  ];

  static const lifeAsset = 'assets/courtyard/courtyard_07_life.jpg';

  /// Мультяшный дом второго участка.
  static const plot2Assets = <String>[
    'assets/courtyard/plot2/courtyard_00_field.jpg',
    'assets/courtyard/plot2/courtyard_00b_trail.jpg',
    'assets/courtyard/plot2/courtyard_01_path.jpg',
    'assets/courtyard/plot2/courtyard_01b_gate.jpg',
    'assets/courtyard/plot2/courtyard_02_foundation.jpg',
    'assets/courtyard/plot2/courtyard_02b_walls_rise.jpg',
    'assets/courtyard/plot2/courtyard_03_walls.jpg',
    'assets/courtyard/plot2/courtyard_03b_roof_rise.jpg',
    'assets/courtyard/plot2/courtyard_04_roof.jpg',
    'assets/courtyard/plot2/courtyard_04b_windows_rise.jpg',
    'assets/courtyard/plot2/courtyard_05_windows.jpg',
    'assets/courtyard/plot2/courtyard_05b_garden.jpg',
    'assets/courtyard/plot2/courtyard_06_complete.jpg',
  ];

  static const plot2LifeAsset = 'assets/courtyard/plot2/courtyard_07_life.jpg';

  static List<String> assetsFor(int cycle) => cycle == 1 ? plot2Assets : assets;

  static String lifeAssetFor(int cycle) =>
      cycle == 1 ? plot2LifeAsset : lifeAsset;

  /// Индекс нижней пластины (0–12).
  final int fromIndex;

  /// Индекс верхней пластины (0–12).
  final int toIndex;

  /// 0 = только [fromIndex], 1 = только [toIndex].
  final double blend;

  static CourtyardArtFade fromStep(double step) {
    final s = step.clamp(0.0, CourtyardSnapshot.maxStep);
    if (s <= plateSteps.first) {
      return const CourtyardArtFade(fromIndex: 0, toIndex: 0, blend: 0);
    }
    for (var i = 0; i < plateSteps.length - 1; i++) {
      final start = plateSteps[i];
      final end = plateSteps[i + 1];
      if (s <= end) {
        return CourtyardArtFade(
          fromIndex: i,
          toIndex: i + 1,
          blend: ((s - start) / (end - start)).clamp(0.0, 1.0),
        );
      }
    }
    final last = assets.length - 1;
    return CourtyardArtFade(fromIndex: last, toIndex: last, blend: 1);
  }
}

const pathStagePhrases = <String>[
  'A house will stand here.',
  'The fence holds the plot.',
  'The walls are yours.',
  'The roof is on.',
  'The windows are ready.',
  'The house rose from your wins.',
];

const pathWarmPhrases = <String>[
  'Another step along the path.',
  'The plot is yours now.',
  'The house is a little closer.',
];

const pathLifePhrase = 'The house feels warmer.';

/// Первая победа: двор в диалоге — не обои, а смысл кампании.
const firstHomePhrase = 'This house grows as you play.';

/// 0 = старт, 1–6 = этапы по 4 уровня.
int pathBand(double step) {
  if (step <= 0) return 0;
  if (step <= 4) return 1;
  if (step <= 8) return 2;
  if (step <= 12) return 3;
  if (step <= 16) return 4;
  if (step <= 20) return 5;
  return 6;
}

String pathPhraseForHome(CourtyardSnapshot snapshot) {
  final band = snapshot.band;
  if (band <= 0) return pathStagePhrases.first;
  return pathStagePhrases[band - 1];
}

String pathPhraseForWin({
  required CourtyardSnapshot from,
  required CourtyardSnapshot to,
}) {
  final fromBand = from.band;
  final toBand = to.band;
  if (toBand > fromBand && toBand > 0) {
    return pathStagePhrases[toBand - 1];
  }
  if (to.step > from.step + 0.01) {
    return pathWarmPhrases[to.step.floor() % pathWarmPhrases.length];
  }
  if (to.totalStars > from.totalStars) return pathLifePhrase;
  return pathWarmPhrases.first;
}
