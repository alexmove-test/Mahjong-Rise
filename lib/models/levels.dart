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

  String get difficultyLabel {
    if (id <= 5) return 'Легко';
    if (id <= 12) return 'Нормально';
    if (id <= 20) return 'Сложно';
    return 'Эксперт';
  }

  String get styleLabel {
    switch (style) {
      case 'fruit':
        return 'Фрукты';
      case 'nature':
        return 'Природа';
      case 'court':
        return 'Двор';
      case 'myth':
        return 'Миф';
      case 'classic':
        return 'Классика';
      case 'shape':
        return 'Фигуры';
      case 'number':
        return 'Цифры';
      case 'mixed':
        return 'Микс';
      default:
        return 'Микс';
    }
  }

  /// Сколько типов плиток из других тем добавить в колоду уровня.
  int get guestTileTypes {
    if (style == null || style == 'mixed') return 0;
    if (id <= 8) return 2;
    if (id <= 16) return 3;
    return 4;
  }
}

/// Каталог уровней с нарастающей сложностью.
abstract final class Levels {
  Levels._();

  static final List<LevelDef> all = List.unmodifiable(_build());

  static LevelDef byId(int id) =>
      all.firstWhere((l) => l.id == id, orElse: () => all.first);

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
            title: 'Росток',
            layout: 'petal',
            shuffles: 5,
            hints: 5,
            undos: 5,
            pairSize: 4,
            uniqueCap: 6,
            stars: (200, 350, 500),
          ),
          (
            title: 'Бутон',
            layout: 'ring',
            shuffles: 4,
            hints: 4,
            undos: 4,
            pairSize: 4,
            uniqueCap: 8,
            stars: (220, 380, 520),
          ),
          (
            title: 'Цветение',
            layout: 'bloom',
            shuffles: 4,
            hints: 4,
            undos: 4,
            pairSize: 4,
            uniqueCap: 10,
            stars: (280, 450, 650),
          ),
          (
            title: 'Поляна',
            layout: 'lantern',
            shuffles: 4,
            hints: 3,
            undos: 3,
            pairSize: 4,
            uniqueCap: 12,
            stars: (300, 480, 700),
          ),
          (
            title: 'Лужайка',
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
            title: 'Рощица',
            layout: 'crest',
            shuffles: 3,
            hints: 3,
            undos: 3,
            pairSize: 4,
            uniqueCap: 16,
            stars: (380, 600, 850),
          ),
          (
            title: 'Волна',
            layout: 'wave',
            shuffles: 3,
            hints: 2,
            undos: 3,
            pairSize: 2,
            uniqueCap: 18,
            stars: (400, 650, 900),
          ),
          (
            title: 'Ручей',
            layout: 'bridge',
            shuffles: 3,
            hints: 3,
            undos: 3,
            pairSize: 4,
            uniqueCap: 18,
            stars: (450, 700, 1000),
          ),
          (
            title: 'Сад',
            layout: 'garden',
            shuffles: 3,
            hints: 2,
            undos: 2,
            pairSize: 4,
            uniqueCap: 20,
            stars: (480, 750, 1050),
          ),
          (
            title: 'Беседка',
            layout: 'spiral',
            shuffles: 2,
            hints: 2,
            undos: 2,
            pairSize: 2,
            uniqueCap: 22,
            stars: (500, 800, 1100),
          ),
          (
            title: 'Веер',
            layout: 'fan',
            shuffles: 3,
            hints: 2,
            undos: 2,
            pairSize: 4,
            uniqueCap: 24,
            stars: (550, 850, 1200),
          ),
          (
            title: 'Павлиний веер',
            layout: 'twin',
            shuffles: 2,
            hints: 2,
            undos: 2,
            pairSize: 2,
            uniqueCap: 28,
            stars: (600, 900, 1300),
          ),
          // 13–20: сложно
          (
            title: 'Лотос',
            layout: 'lotus',
            shuffles: 2,
            hints: 1,
            undos: 2,
            pairSize: 2,
            uniqueCap: 32,
            stars: (650, 950, 1400),
          ),
          (
            title: 'Пруд',
            layout: 'arch',
            shuffles: 3,
            hints: 2,
            undos: 2,
            pairSize: 4,
            uniqueCap: 30,
            stars: (700, 1050, 1500),
          ),
          (
            title: 'Карпы',
            layout: 'koi',
            shuffles: 2,
            hints: 2,
            undos: 2,
            pairSize: 2,
            uniqueCap: 36,
            stars: (750, 1100, 1600),
          ),
          (
            title: 'Озеро',
            layout: 'cascade',
            shuffles: 2,
            hints: 1,
            undos: 1,
            pairSize: 2,
            uniqueCap: 40,
            stars: (800, 1200, 1700),
          ),
          (
            title: 'Лоза',
            layout: 'vine',
            shuffles: 1,
            hints: 1,
            undos: 1,
            pairSize: 2,
            uniqueCap: 42,
            stars: (850, 1250, 1800),
          ),
          (
            title: 'Плющ',
            layout: 'compass',
            shuffles: 3,
            hints: 2,
            undos: 2,
            pairSize: 4,
            uniqueCap: 40,
            stars: (900, 1400, 2000),
          ),
          (
            title: 'Праздник',
            layout: 'festival',
            shuffles: 2,
            hints: 2,
            undos: 2,
            pairSize: 2,
            uniqueCap: 42,
            stars: (1000, 1500, 2200),
          ),
          (
            title: 'Фонари',
            layout: 'nest',
            shuffles: 2,
            hints: 1,
            undos: 1,
            pairSize: 2,
            uniqueCap: 42,
            stars: (1100, 1600, 2400),
          ),
          // 21–24: эксперт
          (
            title: 'Павильон',
            layout: 'pavilion',
            shuffles: 1,
            hints: 1,
            undos: 1,
            pairSize: 2,
            uniqueCap: 48,
            stars: (1200, 1800, 2600),
          ),
          (
            title: 'Храм ветров',
            layout: 'ribbon',
            shuffles: 1,
            hints: 1,
            undos: 0,
            pairSize: 2,
            uniqueCap: 56,
            stars: (1300, 1900, 2800),
          ),
          (
            title: 'Дракон',
            layout: 'dragon',
            shuffles: 1,
            hints: 0,
            undos: 0,
            pairSize: 2,
            uniqueCap: 64,
            stars: (1400, 2000, 3000),
          ),
          (
            title: 'Небесный дракон',
            layout: 'gate',
            shuffles: 0,
            hints: 0,
            undos: 0,
            pairSize: 2,
            uniqueCap: null,
            stars: (1500, 2200, 3200),
          ),
        ];

    return [
      for (var i = 0; i < specs.length; i++)
        LevelDef(
          id: i + 1,
          title: specs[i].title,
          layout: specs[i].layout,
          shuffles: specs[i].shuffles,
          hints: specs[i].hints,
          undos: specs[i].undos,
          style: _styleFor(i + 1),
          pairSize: specs[i].pairSize,
          uniqueCap: specs[i].uniqueCap,
          starsThresholds: specs[i].stars,
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
