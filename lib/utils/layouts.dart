import 'dart:math';

import 'tile_icons.dart';

/// Позиция плитки в раскладке: [x, y, layer].
typedef LayoutPos = (int x, int y, int layer);

/// Компактные пирамиды: плитки уходят в высоту, чтобы оставаться крупными на экране.
///
/// Координаты — в половинах размера плитки:
/// сосед слева/справа отличается на ±2 по x, сверху/снизу — на ±2 по y.
/// Нечётные координаты дают кирпичную сетку и наложения между стопками.
class Layouts {
  Layouts._();

  static LayoutPos _p(int x, int y, [int z = 0]) => (x, y, z);

  static void _row(List<LayoutPos> out, int y, List<int> xs, [int z = 0]) {
    for (final x in xs) {
      out.add(_p(x, y, z));
    }
  }

  /// Стопка в одной клетке: слои 0…[topZ].
  static void _pillar(List<LayoutPos> out, int x, int y, int topZ) {
    for (var z = 0; z <= topZ; z++) {
      out.add(_p(x, y, z));
    }
  }

  static List<LayoutPos> _done(List<LayoutPos> positions, String name) {
    assert(
      positions.length.isEven && positions.isNotEmpty,
      '$name must have even tile count, got ${positions.length}',
    );
    return positions;
  }

  /// Крошечный бутон (16) — обучение. 4×3 с двумя пиками.
  static List<LayoutPos> petal() {
    final p = <LayoutPos>[];
    _row(p, 0, [0, 2, 4, 6]);
    _row(p, 4, [0, 2, 4, 6]);
    _row(p, 2, [0, 6]);
    _pillar(p, 2, 2, 2);
    _pillar(p, 4, 2, 2);
    return _done(p, 'petal');
  }

  /// Цветок (24). 4×4 с центральным ромбом.
  static List<LayoutPos> bloom() {
    final p = <LayoutPos>[];
    _row(p, 0, [1, 3, 5]);
    _row(p, 6, [1, 3, 5]);
    _row(p, 2, [0, 6]);
    _row(p, 4, [0, 6]);
    _pillar(p, 2, 2, 2);
    _pillar(p, 4, 2, 2);
    _pillar(p, 2, 4, 2);
    _pillar(p, 4, 4, 2);
    _pillar(p, 3, 3, 1);
    return _done(p, 'bloom');
  }

  /// Одна кучка (28). 4×4, без разнесения на два острова.
  static List<LayoutPos> meadow() {
    final p = <LayoutPos>[];
    _row(p, 0, [0, 2, 4, 6]);
    _row(p, 6, [0, 2, 4, 6]);
    _row(p, 2, [0, 6]);
    _row(p, 4, [0, 6]);
    _pillar(p, 2, 2, 2);
    _pillar(p, 4, 2, 2);
    _pillar(p, 2, 4, 2);
    _pillar(p, 4, 4, 2);
    _pillar(p, 3, 3, 1);
    _pillar(p, 3, 1, 1);
    return _done(p, 'meadow');
  }

  /// Волна (30). 5×4, гребень по центру.
  static List<LayoutPos> wave() {
    final p = <LayoutPos>[];
    _row(p, 0, [0, 2, 4, 6, 8]);
    _row(p, 6, [0, 2, 4, 6, 8]);
    _row(p, 2, [0, 8]);
    _row(p, 4, [0, 8]);
    _pillar(p, 2, 2, 2);
    _pillar(p, 4, 2, 2);
    _pillar(p, 6, 2, 2);
    _pillar(p, 4, 4, 2);
    _pillar(p, 2, 4, 1);
    _pillar(p, 6, 4, 1);
    return _done(p, 'wave');
  }

  /// Сад (40). 5×4 с высокой серединой.
  static List<LayoutPos> garden() {
    final p = <LayoutPos>[];
    _row(p, 0, [0, 2, 4, 6, 8]);
    _row(p, 6, [0, 2, 4, 6, 8]);
    _row(p, 2, [0, 8]);
    _row(p, 4, [0, 8]);
    _pillar(p, 2, 2, 2);
    _pillar(p, 4, 2, 3);
    _pillar(p, 6, 2, 2);
    _pillar(p, 2, 4, 2);
    _pillar(p, 4, 4, 3);
    _pillar(p, 6, 4, 2);
    _pillar(p, 4, 1, 1);
    _pillar(p, 4, 5, 1);
    _pillar(p, 3, 3, 1);
    return _done(p, 'garden');
  }

  /// Веер (44). 5×5, пик в центре.
  static List<LayoutPos> fan() {
    final p = <LayoutPos>[];
    _row(p, 0, [0, 2, 4, 6, 8]);
    _row(p, 8, [0, 2, 4, 6, 8]);
    _row(p, 2, [0, 8]);
    _row(p, 4, [0, 8]);
    _row(p, 6, [0, 8]);
    _pillar(p, 2, 2, 2);
    _pillar(p, 4, 2, 2);
    _pillar(p, 6, 2, 2);
    _pillar(p, 2, 4, 2);
    _pillar(p, 4, 4, 3);
    _pillar(p, 6, 4, 2);
    _pillar(p, 2, 6, 2);
    _pillar(p, 4, 6, 2);
    _pillar(p, 6, 6, 2);
    return _done(p, 'fan');
  }

  /// Лотос (64). 5×5 пирамида.
  static List<LayoutPos> lotus() {
    final p = <LayoutPos>[];
    _row(p, 0, [0, 2, 4, 6, 8]);
    _row(p, 8, [0, 2, 4, 6, 8]);
    _row(p, 2, [0, 8]);
    _row(p, 4, [0, 8]);
    _row(p, 6, [0, 8]);
    _pillar(p, 4, 4, 4);
    _pillar(p, 4, 2, 3);
    _pillar(p, 2, 4, 3);
    _pillar(p, 6, 4, 3);
    _pillar(p, 4, 6, 3);
    _pillar(p, 2, 2, 2);
    _pillar(p, 6, 2, 2);
    _pillar(p, 2, 6, 2);
    _pillar(p, 6, 6, 2);
    _pillar(p, 3, 3, 2);
    _pillar(p, 5, 3, 2);
    _pillar(p, 3, 5, 2);
    _pillar(p, 5, 5, 2);
    _pillar(p, 4, 1, 2);
    return _done(p, 'lotus');
  }

  /// Карпы (62). 5×5, чуть ниже лотоса.
  static List<LayoutPos> koi() {
    final p = <LayoutPos>[];
    _row(p, 0, [0, 2, 4, 6, 8]);
    _row(p, 8, [0, 2, 4, 6, 8]);
    _row(p, 2, [0, 8]);
    _row(p, 4, [0, 8]);
    _row(p, 6, [0, 8]);
    _pillar(p, 4, 4, 4);
    _pillar(p, 4, 2, 3);
    _pillar(p, 2, 4, 3);
    _pillar(p, 6, 4, 3);
    _pillar(p, 4, 6, 3);
    _pillar(p, 2, 2, 2);
    _pillar(p, 6, 2, 2);
    _pillar(p, 2, 6, 2);
    _pillar(p, 6, 6, 2);
    _pillar(p, 3, 3, 2);
    _pillar(p, 5, 3, 2);
    _pillar(p, 3, 5, 2);
    _pillar(p, 5, 5, 2);
    p.add(_p(4, 1, 0));
    return _done(p, 'koi');
  }

  /// Лоза (72). 5×5, высокий крест.
  static List<LayoutPos> vine() {
    final p = <LayoutPos>[];
    _row(p, 0, [0, 2, 4, 6, 8]);
    _row(p, 8, [0, 2, 4, 6, 8]);
    _row(p, 2, [0, 8]);
    _row(p, 4, [0, 8]);
    _row(p, 6, [0, 8]);
    _pillar(p, 4, 4, 5);
    _pillar(p, 4, 2, 4);
    _pillar(p, 2, 4, 4);
    _pillar(p, 6, 4, 4);
    _pillar(p, 4, 6, 4);
    _pillar(p, 2, 2, 3);
    _pillar(p, 6, 2, 3);
    _pillar(p, 2, 6, 3);
    _pillar(p, 6, 6, 3);
    _pillar(p, 3, 3, 2);
    _pillar(p, 5, 3, 2);
    _pillar(p, 3, 5, 2);
    _pillar(p, 5, 5, 2);
    _pillar(p, 4, 1, 1);
    return _done(p, 'vine');
  }

  /// Праздничный ковёр (72). 5×5, широкие террасы.
  static List<LayoutPos> festival() {
    final p = <LayoutPos>[];
    for (final y in [0, 2, 4, 6, 8]) {
      _row(p, y, [0, 2, 4, 6, 8]);
    }
    for (final y in [0, 2, 4, 6, 8]) {
      for (final x in [0, 2, 4, 6, 8]) {
        final isCorner = (x == 0 || x == 8) && (y == 0 || y == 8);
        if (!isCorner) p.add(_p(x, y, 1));
      }
    }
    for (final y in [2, 4, 6]) {
      _row(p, y, [2, 4, 6], 2);
      _row(p, y, [2, 4, 6], 3);
    }
    _row(p, 2, [2, 4], 4);
    _row(p, 4, [2, 4, 6], 4);
    _row(p, 6, [4, 6], 4);
    _row(p, 4, [4], 5);
    return _done(p, 'festival');
  }

  /// Павильон (88). 6×5, глубокий двор.
  static List<LayoutPos> pavilion() {
    final p = <LayoutPos>[];
    _row(p, 0, [0, 2, 4, 6, 8, 10]);
    _row(p, 8, [0, 2, 4, 6, 8, 10]);
    _row(p, 2, [0, 10]);
    _row(p, 4, [0, 10]);
    _row(p, 6, [0, 10]);
    _pillar(p, 2, 2, 4);
    _pillar(p, 8, 2, 4);
    _pillar(p, 4, 2, 5);
    _pillar(p, 6, 2, 5);
    for (final y in [4, 6]) {
      for (final x in [2, 4, 6, 8]) {
        _pillar(p, x, y, 5);
      }
    }
    return _done(p, 'pavilion');
  }

  /// Дракон (122). 6×5, уходит в высоту.
  static List<LayoutPos> dragon() {
    final p = <LayoutPos>[];
    _row(p, 0, [0, 2, 4, 6, 8, 10]);
    _row(p, 8, [0, 2, 4, 6, 8, 10]);
    _row(p, 2, [0, 10]);
    _row(p, 4, [0, 10]);
    _row(p, 6, [0, 10]);
    for (final y in [2, 4, 6]) {
      _pillar(p, 4, y, 8);
      _pillar(p, 6, y, 8);
    }
    _pillar(p, 2, 4, 8);
    _pillar(p, 8, 4, 8);
    _pillar(p, 2, 2, 7);
    _pillar(p, 8, 2, 7);
    _pillar(p, 2, 6, 7);
    _pillar(p, 8, 6, 7);
    return _done(p, 'dragon');
  }

  static List<LayoutPos> byName(String name) {
    return switch (name) {
      'petal' || 'seed' => petal(),
      'bloom' => bloom(),
      'meadow' || 'grove' => meadow(),
      'wave' => wave(),
      'garden' || 'pyramid' => garden(),
      'fan' || 'fort' => fan(),
      'lotus' => lotus(),
      'koi' => koi(),
      'vine' || 'tower' => vine(),
      'festival' || 'temple' => festival(),
      'pavilion' => pavilion(),
      'dragon' || 'turtle' => dragon(),
      _ => bloom(),
    };
  }

  static int tileCount(String name) => byName(name).length;
}

/// Колода и матчинг символов (арт-пак `assets/titles`).
class TileSymbols {
  TileSymbols._();

  static List<String> get iconIds => TileIcons.ids;

  static const backgroundAsset = 'assets/pack/bg/background_green.png';
  static const leafBedAsset = 'assets/pack/bg/leaf_bed.png';
  static const shadowAsset = 'assets/pack/mixed/extra/shadow.png';

  static String assetFor(String symbol, {bool selected = false}) {
    return TileIcons.assetFor(symbol);
  }

  /// Собирает колоду ровно на [count] плиток (чётным числом, парами).
  ///
  /// [style] — тема иллюстраций на партию.
  /// [pairSize] — 2 (сложнее) или 4 (проще).
  /// [uniqueCap] — ограничить число разных лиц.
  /// [guestTypes] — сколько типов из других тем добавить в колоду.
  static List<String> deckFor(
    int count, {
    Random? random,
    String? style,
    int pairSize = 4,
    int? uniqueCap,
    int? levelId,
    int guestTypes = 0,
  }) {
    assert(count.isEven && count > 0);
    assert(pairSize == 2 || pairSize == 4);

    final rng = random ?? Random();
    final bonus = pickBonusTypes(
      levelId: levelId ?? rng.nextInt(1 << 30),
      random: rng,
    );
    final guests = pickGuestTypes(
      style: style,
      guestCount: guestTypes,
      levelId: levelId ?? rng.nextInt(1 << 30),
      random: rng,
    );
    final reserved = <String>{...bonus, ...guests}.toList();
    final primaryPool = TileIcons.idsForStyle(style ?? 'mixed');
    final primaryCandidates =
        primaryPool.where((id) => !reserved.contains(id)).toList()
          ..shuffle(rng);

    final typeLimit = uniqueCap ?? (reserved.length + primaryCandidates.length);
    final primarySlots = (typeLimit - reserved.length).clamp(
      0,
      primaryCandidates.length,
    );
    final types = <String>[
      ...reserved,
      ...primaryCandidates.take(primarySlots),
    ];

    if (types.isEmpty) {
      types.addAll(iconIds..shuffle(rng));
    }

    final deck = <String>[];
    var typeIndex = 0;
    while (deck.length < count) {
      final symbol = types[typeIndex % types.length];
      final remaining = count - deck.length;
      final add = remaining >= pairSize ? pairSize : 2;
      for (var i = 0; i < add; i++) {
        deck.add(symbol);
      }
      typeIndex++;
    }
    return deck;
  }

  /// На каждом уровне — одна крупная фигура и одна цифра.
  static List<String> pickBonusTypes({required int levelId, Random? random}) {
    final rng = random ?? Random(levelId * 5527);
    final shapes = List<String>.from(TileIcons.shapeIds)..shuffle(rng);
    final numbers = List<String>.from(TileIcons.numberIds)..shuffle(rng);
    return [shapes.first, numbers.first];
  }

  /// Несколько типов из других тем загруженного сета.
  static List<String> pickGuestTypes({
    required String? style,
    required int guestCount,
    required int levelId,
    Random? random,
  }) {
    if (guestCount <= 0 || style == null) return const [];

    final primary = TileIcons.idsForStyle(style).toSet();
    final candidates = TileIcons.softIds
        .where((id) => !primary.contains(id))
        .toList(growable: false);
    if (candidates.isEmpty) return const [];

    final guestRng = random ?? Random(levelId * 9973);
    final shuffled = List<String>.from(candidates)..shuffle(guestRng);
    return shuffled.take(guestCount.clamp(0, shuffled.length)).toList();
  }

  static bool matches(String a, String b) => a == b;
}
