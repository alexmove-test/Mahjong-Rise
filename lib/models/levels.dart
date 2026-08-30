import 'plot_kind.dart';
import 'week_event.dart';
import 'week_id.dart';
import '../utils/layouts.dart';

/// Определение уровня: раскладка, бусты и «жёсткость» колоды.
class LevelDef {
  const LevelDef({
    required this.id,
    required this.title,
    required this.layout,
    required this.shuffles,
    required this.hints,
    required this.undos,
    this.style,
    this.pairSize = 4,
    this.uniqueCap,
    this.starsThresholds = const (400, 700, 1000),
  });

  /// 1-based id.
  final int id;
  final String title;
  final String layout;
  final int shuffles;
  final int hints;
  final int undos;

  /// Художественный стиль партии; null — смешанные стили (сложнее читать).
  final String? style;

  /// 4 — проще (квартеты), 2 — сложнее (только пары).
  final int pairSize;

  /// Сколько разных лиц максимум (меньше = проще).
  final int? uniqueCap;

  /// Пороги звёзд по очкам: (1★, 2★, 3★).
  final (int, int, int) starsThresholds;

  int starsForScore(int score) {
    if (score >= starsThresholds.$3) return 3;
    if (score >= starsThresholds.$2) return 2;
    if (score >= starsThresholds.$1) return 1;
    return 0;
  }

  /// Номер в первой сюжетной двадцатичетырёх (раскладка, сложность, тема).
  int get storyId => ((id - 1) % Levels.storyLength) + 1;

  PlotKind get plotKind => Levels.plotKindOf(id);

  String get difficultyLabel {
    final n = storyId;
    if (n <= 5) return 'Easy';
    if (n <= 12) return 'Normal';
    if (n <= 20) return 'Hard';
    return 'Expert';
  }

  String get styleLabel {
    switch (style) {
      case 'fruit':
        return 'Fruit';
      case 'nature':
        return 'Nature';
      case 'court':
        return 'Court';
      case 'myth':
        return 'Myth';
      case 'classic':
        return 'Classic';
      case 'shape':
        return 'Shapes';
      case 'number':
        return 'Numbers';
      case 'mixed':
        return 'Mix';
      default:
        return 'Mix';
    }
  }

  /// Сколько типов плиток из других тем добавить в колоду уровня.
  int get guestTileTypes {
    if (style == null || style == 'mixed') return 0;
    final n = storyId;
    if (n <= 1) return 0;
    if (n <= 8) return 2;
    if (n <= 16) return 3;
    return 4;
  }

  /// Доля фруктов в колоде: фруктовые миры гуще, остальные всё равно с большинством фруктов.
  static const fruitShare = 0.60;
  static const fruitWorldShare = 0.80;

  double get cuteSimpleShare => style == 'fruit' ? fruitWorldShare : fruitShare;
}

/// Кривая бустов и плотности внутри участка из 24.
typedef _LevelSpec = ({
  String layout,
  int shuffles,
  int hints,
  int undos,
  int pairSize,
  int? uniqueCap,
  (int, int, int) stars,
});

/// Каталог уровней: формула участка × круга, без фиксированных 240 карточек.
abstract final class Levels {
  Levels._();

  /// Уникальные шаги внутри участка.
  static const storyLength = 24;

  /// Практический потолок бесконечной кампании.
  static const maxLevelId = 10000;

  static const campaignLength = maxLevelId;

  static int get cycleCount => maxLevelId ~/ storyLength;

  static Iterable<LevelDef> get all sync* {
    for (var i = 1; i <= maxLevelId; i++) {
      yield byId(i);
    }
  }

  static int get maxCycle => cycleCount - 1;

  static LevelDef byId(int id) {
    if (id < 1) return _at(1);
    if (id > maxLevelId) return _at(maxLevelId);
    return _at(id);
  }

  /// 0-based номер участка для уровня.
  static int cycleOf(int id) => ((id.clamp(1, maxLevelId) - 1) ~/ storyLength);

  static PlotKind plotKindOf(int id) => PlotKind.ofCycle(cycleOf(id));

  static PlotKind plotKindOfCycle(int cycle) => PlotKind.ofCycle(cycle);

  /// Круг из четырёх участков (0 = первый дом–интернет).
  static int loopOf(int id) => cycleOf(id) ~/ PlotKind.order.length;

  /// 1–24 внутри участка.
  static int localId(int id) => ((id - 1) % storyLength) + 1;

  static int cycleStartId(int cycle) => cycle * storyLength + 1;

  static int cycleEndId(int cycle) => (cycle + 1) * storyLength;

  static List<LevelDef> cycleLevels(int cycle) {
    final start = cycleStartId(cycle);
    return [for (var i = 0; i < storyLength; i++) byId(start + i)];
  }

  static String plotLabel(int cycle) => PlotKind.ofCycle(cycle).titleEn;

  /// Ежедневный стол: сюжетная раскладка по календарному дню, без прогресса кампании.
  static LevelDef dailyFor(DateTime date, {WeekEvent? event}) {
    final day = DateTime(date.year, date.month, date.day);
    final index =
        day.difference(DateTime(2024, 1, 1)).inDays.abs() % storyLength;
    final base = byId(index + 1);
    final weekEvent = event ?? WeekEvent.forWeek(WeekId.fromDate(day));
    return LevelDef(
      id: base.id,
      title: 'Today',
      layout: base.layout,
      shuffles: base.shuffles + weekEvent.extraBoosts,
      hints: base.hints + weekEvent.extraBoosts,
      undos: base.undos,
      style: weekEvent.style,
      pairSize: base.pairSize,
      uniqueCap: base.uniqueCap,
      starsThresholds: base.starsThresholds,
    );
  }

  static LevelDef _at(int id) {
    final local = localId(id);
    final spec = _specs[local - 1];
    final cycle = cycleOf(id);
    final loop = cycle ~/ PlotKind.order.length;
    final variant = (loop + cycle) % 4;
    final kind = PlotKind.ofCycle(cycle);
    return LevelDef(
      id: id,
      title: kind.titleEn,
      layout: Layouts.variantName(spec.layout, variant),
      shuffles: _scaleDown(spec.shuffles, loop),
      hints: _scaleDown(spec.hints, loop),
      undos: _scaleDown(spec.undos, loop ~/ 2 + (loop > 0 ? 1 : 0)),
      style: _styleFor(local),
      pairSize: loop >= 2 ? 2 : spec.pairSize,
      uniqueCap: spec.uniqueCap == null ? null : spec.uniqueCap! + loop * 6,
      starsThresholds: (
        spec.stars.$1 + loop * 50,
        spec.stars.$2 + loop * 80,
        spec.stars.$3 + loop * 100,
      ),
    );
  }

  static int _scaleDown(int value, int cut) => (value - cut).clamp(0, value);

  static const _specs = <_LevelSpec>[
    (
      layout: 'petal',
      shuffles: 5,
      hints: 5,
      undos: 5,
      pairSize: 4,
      uniqueCap: 6,
      stars: (200, 350, 500),
    ),
    (
      layout: 'buds',
      shuffles: 4,
      hints: 4,
      undos: 4,
      pairSize: 4,
      uniqueCap: 8,
      stars: (220, 380, 520),
    ),
    (
      layout: 'bloom',
      shuffles: 4,
      hints: 4,
      undos: 4,
      pairSize: 4,
      uniqueCap: 10,
      stars: (280, 450, 650),
    ),
    (
      layout: 'glade',
      shuffles: 4,
      hints: 3,
      undos: 3,
      pairSize: 4,
      uniqueCap: 12,
      stars: (300, 480, 700),
    ),
    (
      layout: 'meadow',
      shuffles: 4,
      hints: 3,
      undos: 3,
      pairSize: 4,
      uniqueCap: 14,
      stars: (350, 550, 800),
    ),
    (
      layout: 'grove',
      shuffles: 3,
      hints: 3,
      undos: 3,
      pairSize: 4,
      uniqueCap: 16,
      stars: (380, 600, 850),
    ),
    (
      layout: 'wave',
      shuffles: 3,
      hints: 2,
      undos: 3,
      pairSize: 2,
      uniqueCap: 18,
      stars: (400, 650, 900),
    ),
    (
      layout: 'stream',
      shuffles: 3,
      hints: 3,
      undos: 3,
      pairSize: 4,
      uniqueCap: 18,
      stars: (450, 700, 1000),
    ),
    (
      layout: 'garden',
      shuffles: 3,
      hints: 2,
      undos: 2,
      pairSize: 4,
      uniqueCap: 20,
      stars: (480, 750, 1050),
    ),
    (
      layout: 'gazebo',
      shuffles: 2,
      hints: 2,
      undos: 2,
      pairSize: 2,
      uniqueCap: 22,
      stars: (500, 800, 1100),
    ),
    (
      layout: 'fan',
      shuffles: 3,
      hints: 2,
      undos: 2,
      pairSize: 4,
      uniqueCap: 24,
      stars: (550, 850, 1200),
    ),
    (
      layout: 'peacock',
      shuffles: 2,
      hints: 2,
      undos: 2,
      pairSize: 2,
      uniqueCap: 28,
      stars: (600, 900, 1300),
    ),
    (
      layout: 'lotus',
      shuffles: 2,
      hints: 1,
      undos: 2,
      pairSize: 2,
      uniqueCap: 32,
      stars: (650, 950, 1400),
    ),
    (
      layout: 'pond',
      shuffles: 3,
      hints: 2,
      undos: 2,
      pairSize: 4,
      uniqueCap: 30,
      stars: (700, 1050, 1500),
    ),
    (
      layout: 'koi',
      shuffles: 2,
      hints: 2,
      undos: 2,
      pairSize: 2,
      uniqueCap: 36,
      stars: (750, 1100, 1600),
    ),
    (
      layout: 'lake',
      shuffles: 2,
      hints: 1,
      undos: 1,
      pairSize: 2,
      uniqueCap: 40,
      stars: (800, 1200, 1700),
    ),
    (
      layout: 'vine',
      shuffles: 1,
      hints: 1,
      undos: 1,
      pairSize: 2,
      uniqueCap: 42,
      stars: (850, 1250, 1800),
    ),
    (
      layout: 'ivy',
      shuffles: 3,
      hints: 2,
      undos: 2,
      pairSize: 4,
      uniqueCap: 40,
      stars: (900, 1400, 2000),
    ),
    (
      layout: 'festival',
      shuffles: 2,
      hints: 2,
      undos: 2,
      pairSize: 2,
      uniqueCap: 42,
      stars: (1000, 1500, 2200),
    ),
    (
      layout: 'lanterns',
      shuffles: 2,
      hints: 1,
      undos: 1,
      pairSize: 2,
      uniqueCap: 42,
      stars: (1100, 1600, 2400),
    ),
    (
      layout: 'pavilion',
      shuffles: 1,
      hints: 1,
      undos: 1,
      pairSize: 2,
      uniqueCap: 48,
      stars: (1200, 1800, 2600),
    ),
    (
      layout: 'temple',
      shuffles: 1,
      hints: 1,
      undos: 0,
      pairSize: 2,
      uniqueCap: 56,
      stars: (1300, 1900, 2800),
    ),
    (
      layout: 'dragon',
      shuffles: 1,
      hints: 0,
      undos: 0,
      pairSize: 2,
      uniqueCap: 64,
      stars: (1400, 2000, 3000),
    ),
    (
      layout: 'sky',
      shuffles: 0,
      hints: 0,
      undos: 0,
      pairSize: 2,
      uniqueCap: null,
      stars: (1500, 2200, 3200),
    ),
  ];

  /// «Миры»: фрукты занимают три четвёрки, китайская тема не вытесняет фрукты.
  static String? _styleFor(int storyId) {
    const worlds = ['fruit', 'fruit', 'fruit', 'nature', 'myth'];
    final world = (storyId - 1) ~/ 4;
    if (world >= worlds.length) return 'mixed';
    return worlds[world];
  }
}
