import 'week_event.dart';
import 'week_id.dart';

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
}

/// Каталог уровней с нарастающей сложностью.
abstract final class Levels {
  Levels._();

  /// Уникальные раскладки сюжета; дальше кампания повторяет их циклами.
  static const storyLength = 24;

  /// Сотни карточек: 10 циклов первой двадцатичетырёх.
  static const campaignLength = 240;

  static final List<LevelDef> all = List.unmodifiable(_build());

  /// Сколько домов/участков в кампании.
  static const cycleCount = campaignLength ~/ storyLength;

  static LevelDef byId(int id) {
    final i = id - 1;
    if (i < 0 || i >= all.length) return all.first;
    return all[i];
  }

  /// 0-based номер участка для уровня.
  static int cycleOf(int id) =>
      ((id - 1) ~/ storyLength).clamp(0, cycleCount - 1);

  /// 1–24 внутри участка.
  static int localId(int id) => ((id - 1) % storyLength) + 1;

  static int cycleStartId(int cycle) => cycle * storyLength + 1;

  static int cycleEndId(int cycle) => (cycle + 1) * storyLength;

  static List<LevelDef> cycleLevels(int cycle) {
    final c = cycle.clamp(0, cycleCount - 1);
    return all.sublist(c * storyLength, (c + 1) * storyLength);
  }

  static String plotLabel(int cycle) => 'Plot ${cycle + 1}';

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

  static List<LevelDef> _build() {
    const specs =
        <
          ({
            String title,
            String layout,
            int shuffles,
            int hints,
            int undos,
            int pairSize,
            int? uniqueCap,
            (int, int, int) stars,
          })
        >[
          // 1–5: обучение, маленькие плоские поля
          (
            title: 'Sprout',
            layout: 'petal',
            shuffles: 5,
            hints: 5,
            undos: 5,
            pairSize: 4,
            uniqueCap: 6,
            stars: (200, 350, 500),
          ),
          (
            title: 'Bud',
            layout: 'petal',
            shuffles: 4,
            hints: 4,
            undos: 4,
            pairSize: 4,
            uniqueCap: 8,
            stars: (220, 380, 520),
          ),
          (
            title: 'Bloom',
            layout: 'bloom',
            shuffles: 4,
            hints: 4,
            undos: 4,
            pairSize: 4,
            uniqueCap: 10,
            stars: (280, 450, 650),
          ),
          (
            title: 'Glade',
            layout: 'bloom',
            shuffles: 4,
            hints: 3,
            undos: 3,
            pairSize: 4,
            uniqueCap: 12,
            stars: (300, 480, 700),
          ),
          (
            title: 'Lawn',
            layout: 'meadow',
            shuffles: 4,
            hints: 3,
            undos: 3,
            pairSize: 4,
            uniqueCap: 14,
            stars: (350, 550, 800),
          ),
          // 6–12: нормально
          (
            title: 'Grove',
            layout: 'meadow',
            shuffles: 3,
            hints: 3,
            undos: 3,
            pairSize: 4,
            uniqueCap: 16,
            stars: (380, 600, 850),
          ),
          (
            title: 'Wave',
            layout: 'wave',
            shuffles: 3,
            hints: 2,
            undos: 3,
            pairSize: 2,
            uniqueCap: 18,
            stars: (400, 650, 900),
          ),
          (
            title: 'Stream',
            layout: 'wave',
            shuffles: 3,
            hints: 3,
            undos: 3,
            pairSize: 4,
            uniqueCap: 18,
            stars: (450, 700, 1000),
          ),
          (
            title: 'Garden',
            layout: 'garden',
            shuffles: 3,
            hints: 2,
            undos: 2,
            pairSize: 4,
            uniqueCap: 20,
            stars: (480, 750, 1050),
          ),
          (
            title: 'Gazebo',
            layout: 'garden',
            shuffles: 2,
            hints: 2,
            undos: 2,
            pairSize: 2,
            uniqueCap: 22,
            stars: (500, 800, 1100),
          ),
          (
            title: 'Fan',
            layout: 'fan',
            shuffles: 3,
            hints: 2,
            undos: 2,
            pairSize: 4,
            uniqueCap: 24,
            stars: (550, 850, 1200),
          ),
          (
            title: 'Peacock Fan',
            layout: 'fan',
            shuffles: 2,
            hints: 2,
            undos: 2,
            pairSize: 2,
            uniqueCap: 28,
            stars: (600, 900, 1300),
          ),
          // 13–20: сложно
          (
            title: 'Lotus',
            layout: 'lotus',
            shuffles: 2,
            hints: 1,
            undos: 2,
            pairSize: 2,
            uniqueCap: 32,
            stars: (650, 950, 1400),
          ),
          (
            title: 'Pond',
            layout: 'lotus',
            shuffles: 3,
            hints: 2,
            undos: 2,
            pairSize: 4,
            uniqueCap: 30,
            stars: (700, 1050, 1500),
          ),
          (
            title: 'Carp',
            layout: 'koi',
            shuffles: 2,
            hints: 2,
            undos: 2,
            pairSize: 2,
            uniqueCap: 36,
            stars: (750, 1100, 1600),
          ),
          (
            title: 'Lake',
            layout: 'koi',
            shuffles: 2,
            hints: 1,
            undos: 1,
            pairSize: 2,
            uniqueCap: 40,
            stars: (800, 1200, 1700),
          ),
          (
            title: 'Vine',
            layout: 'vine',
            shuffles: 1,
            hints: 1,
            undos: 1,
            pairSize: 2,
            uniqueCap: 42,
            stars: (850, 1250, 1800),
          ),
          (
            title: 'Ivy',
            layout: 'vine',
            shuffles: 3,
            hints: 2,
            undos: 2,
            pairSize: 4,
            uniqueCap: 40,
            stars: (900, 1400, 2000),
          ),
          (
            title: 'Festival',
            layout: 'festival',
            shuffles: 2,
            hints: 2,
            undos: 2,
            pairSize: 2,
            uniqueCap: 42,
            stars: (1000, 1500, 2200),
          ),
          (
            title: 'Lanterns',
            layout: 'festival',
            shuffles: 2,
            hints: 1,
            undos: 1,
            pairSize: 2,
            uniqueCap: 42,
            stars: (1100, 1600, 2400),
          ),
          // 21–24: эксперт
          (
            title: 'Pavilion',
            layout: 'pavilion',
            shuffles: 1,
            hints: 1,
            undos: 1,
            pairSize: 2,
            uniqueCap: 48,
            stars: (1200, 1800, 2600),
          ),
          (
            title: 'Wind Temple',
            layout: 'pavilion',
            shuffles: 1,
            hints: 1,
            undos: 0,
            pairSize: 2,
            uniqueCap: 56,
            stars: (1300, 1900, 2800),
          ),
          (
            title: 'Dragon',
            layout: 'dragon',
            shuffles: 1,
            hints: 0,
            undos: 0,
            pairSize: 2,
            uniqueCap: 64,
            stars: (1400, 2000, 3000),
          ),
          (
            title: 'Sky Dragon',
            layout: 'dragon',
            shuffles: 0,
            hints: 0,
            undos: 0,
            pairSize: 2,
            uniqueCap: null,
            stars: (1500, 2200, 3200),
          ),
        ];

    assert(specs.length == storyLength);

    return [
      for (var i = 0; i < campaignLength; i++)
        LevelDef(
          id: i + 1,
          title: specs[i % specs.length].title,
          layout: specs[i % specs.length].layout,
          shuffles: specs[i % specs.length].shuffles,
          hints: specs[i % specs.length].hints,
          undos: specs[i % specs.length].undos,
          style: _styleFor((i % storyLength) + 1),
          pairSize: specs[i % specs.length].pairSize,
          uniqueCap: specs[i % specs.length].uniqueCap,
          starsThresholds: specs[i % specs.length].stars,
        ),
    ];
  }

  /// «Миры» по 4 уровня в одной теме; дальше — полный микс всех иконок.
  static String? _styleFor(int id) {
    const worlds = ['fruit', 'nature', 'court', 'myth', 'classic'];
    final world = (id - 1) ~/ 4;
    if (world >= worlds.length) return 'mixed';
    return worlds[world];
  }
}
