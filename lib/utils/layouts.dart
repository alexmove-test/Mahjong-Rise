import 'dart:math';

import 'tile_icons.dart';

/// Позиция плитки в раскладке: [x, y, layer].
typedef LayoutPos = (int x, int y, int layer);

/// Свободные плоские раскладки в духе Vita: живой силуэт, почти без пирамид.
///
/// Координаты — в половинах размера плитки:
/// сосед слева/справа отличается на ±2 по x, сверху/снизу — на ±2 по y.
/// Нечётные координаты дают кирпичную «живую» сетку и лёгкие наложения.
class Layouts {
  Layouts._();

  static LayoutPos _p(int x, int y, [int z = 0]) => (x, y, z);

  static void _row(List<LayoutPos> out, int y, List<int> xs, [int z = 0]) {
    for (final x in xs) {
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

  /// Сколько вертикальных слоёв добавить в раскладку (0 = только база, 2 = до L2…).
  static int _maxStackDepth(String name) {
    switch (name) {
      case 'petal':
      case 'seed':
      case 'bloom':
        return 2;
      case 'meadow':
      case 'grove':
      case 'wave':
      case 'garden':
      case 'pyramid':
      case 'fan':
      case 'fort':
        return 2;
      case 'lotus':
      case 'koi':
      case 'vine':
      case 'tower':
        return 3;
      case 'festival':
      case 'temple':
      case 'pavilion':
        return 3;
      case 'dragon':
      case 'turtle':
        return 4;
      default:
        return 2;
    }
  }

  /// Достраивает стопки вверх и подрезает край, чтобы число плиток оставалось чётным.
  static List<LayoutPos> _finalizeStacks(
    List<LayoutPos> positions,
    int targetMaxLayer,
    String name,
  ) {
    var out = List<LayoutPos>.from(positions);
    final tops = <String, int>{};
    for (final p in out) {
      final key = '${p.$1},${p.$2}';
      tops[key] = max(tops[key] ?? 0, p.$3);
    }

    for (final entry in tops.entries) {
      if (entry.value < 1) continue;
      final xy = entry.key.split(',');
      final x = int.parse(xy[0]);
      final y = int.parse(xy[1]);
      for (var z = entry.value + 1; z <= targetMaxLayer; z++) {
        out.add(_p(x, y, z));
      }
    }

    while (out.length.isOdd) {
      final idx = out.indexWhere((p) => p.$3 == 0);
      if (idx < 0) break;
      out.removeAt(idx);
    }

    return _done(out, name);
  }

  /// Крошечный бутон (16) — обучение.
  static List<LayoutPos> petal() {
    final p = <LayoutPos>[];
    _row(p, 0, [2, 4, 6]);
    _row(p, 2, [0, 2, 4, 6, 8]);
    _row(p, 4, [1, 3, 5, 7]);
    _row(p, 6, [2, 4, 6]);
    _row(p, 3, [4], 1);
    return _done(p, 'petal');
  }

  /// Цветок (20).
  static List<LayoutPos> bloom() {
    final p = <LayoutPos>[];
    _row(p, 0, [2, 4, 6]);
    _row(p, 2, [0, 2, 4, 6, 8]);
    _row(p, 4, [0, 2, 4, 6, 8]);
    _row(p, 6, [2, 4, 6]);
    _row(p, 1, [4], 1);
    _row(p, 3, [3, 5], 1);
    _row(p, 5, [4], 1);
    return _done(p, 'bloom');
  }

  /// Две живые кучки (24).
  static List<LayoutPos> meadow() {
    final p = <LayoutPos>[];
    _row(p, 1, [0, 2, 4]);
    _row(p, 3, [0, 2, 4, 6]);
    _row(p, 5, [1, 3, 5]);
    _row(p, 2, [2, 4], 1);

    _row(p, 0, [10, 12, 14]);
    _row(p, 2, [9, 11, 13, 15]);
    _row(p, 4, [10, 12, 14]);
    _row(p, 1, [12], 1);
    _row(p, 3, [12], 1);
    return _done(p, 'meadow');
  }

  /// Волна со сдвигом рядов (28).
  static List<LayoutPos> wave() {
    final p = <LayoutPos>[];
    _row(p, 0, [0, 2, 4, 6, 8, 10]);
    _row(p, 2, [1, 3, 5, 7, 9]);
    _row(p, 4, [0, 2, 4, 6, 8, 10]);
    _row(p, 6, [1, 3, 5, 7, 9]);
    _row(p, 8, [2, 4, 6, 8]);
    _row(p, 3, [5], 1);
    _row(p, 5, [5], 1);
    return _done(p, 'wave');
  }

  /// Сад с просветами (32).
  static List<LayoutPos> garden() {
    final p = <LayoutPos>[];
    _row(p, 0, [2, 4, 6, 8]);
    _row(p, 2, [0, 2, 4, 6, 8, 10]);
    _row(p, 4, [1, 3, 7, 9]);
    _row(p, 6, [0, 2, 4, 6, 8, 10]);
    _row(p, 8, [2, 4, 6, 8]);
    _row(p, 1, [5], 1);
    _row(p, 3, [3, 7], 1);
    _row(p, 5, [4, 5, 6], 1);
    _row(p, 7, [3, 7], 1);
    return _done(p, 'garden');
  }

  /// Веер, шире к низу (36).
  static List<LayoutPos> fan() {
    final p = <LayoutPos>[];
    _row(p, 0, [4, 6]);
    _row(p, 2, [2, 4, 6, 8]);
    _row(p, 4, [1, 3, 5, 7, 9]);
    _row(p, 6, [0, 2, 4, 6, 8, 10]);
    _row(p, 8, [0, 2, 4, 6, 8, 10]);
    _row(p, 10, [1, 3, 5, 7, 9]);
    _row(p, 3, [5], 1);
    _row(p, 5, [5], 1);
    _row(p, 6, [4, 6], 1);
    _row(p, 7, [3, 7], 1);
    _row(p, 8, [5], 1);
    _row(p, 9, [5], 1);
    return _done(p, 'fan');
  }

  /// Лотос (40).
  static List<LayoutPos> lotus() {
    final p = <LayoutPos>[];
    _row(p, 0, [3, 5, 7]);
    _row(p, 2, [1, 3, 5, 7, 9]);
    _row(p, 4, [0, 2, 4, 6, 8, 10]);
    _row(p, 6, [0, 2, 4, 6, 8, 10]);
    _row(p, 8, [1, 3, 5, 7, 9]);
    _row(p, 10, [3, 5, 7]);
    _row(p, 1, [5], 1);
    _row(p, 3, [5], 1);
    _row(p, 4, [4, 6], 1);
    _row(p, 5, [3, 5, 7], 1);
    _row(p, 6, [4, 6], 1);
    _row(p, 7, [5], 1);
    _row(p, 9, [5], 1);
    _row(p, 11, [5], 1);
    return _done(p, 'lotus');
  }

  /// Карпы / пруд (48).
  static List<LayoutPos> koi() {
    final p = <LayoutPos>[];
    _row(p, 0, [2, 4, 6, 8, 10]);
    _row(p, 2, [1, 3, 5, 7, 9, 11]);
    _row(p, 4, [0, 2, 4, 6, 8, 10, 12]);
    _row(p, 6, [1, 3, 5, 7, 9, 11]);
    _row(p, 8, [0, 2, 4, 6, 8, 10, 12]);
    _row(p, 10, [1, 3, 5, 7, 9, 11]);
    _row(p, 12, [3, 5, 7, 9]);
    _row(p, 1, [6], 1);
    _row(p, 3, [5], 1);
    _row(p, 5, [7], 1);
    _row(p, 7, [4, 8], 1);
    _row(p, 9, [6], 1);
    _row(p, 11, [5], 1);
    return _done(p, 'koi');
  }

  /// Вьющаяся лоза (56).
  static List<LayoutPos> vine() {
    final p = <LayoutPos>[];
    _row(p, 0, [0, 2, 4, 6, 8, 10, 12, 14]);
    _row(p, 2, [1, 3, 5, 7, 9, 11, 13, 15]);
    _row(p, 4, [0, 2, 4, 6, 8, 10, 12, 14]);
    _row(p, 6, [1, 3, 5, 7, 9, 11, 13, 15]);
    _row(p, 8, [0, 2, 4, 6, 8, 10, 12, 14]);
    _row(p, 10, [1, 3, 5, 7, 9, 11, 13, 15]);
    _row(p, 1, [7], 1);
    _row(p, 3, [5, 9], 1);
    _row(p, 5, [7], 1);
    _row(p, 7, [5, 9], 1);
    _row(p, 9, [7], 1);
    _row(p, 11, [7], 1);
    return _done(p, 'vine');
  }

  /// Праздничный ковёр (64).
  static List<LayoutPos> festival() {
    final p = <LayoutPos>[];
    for (var i = 0; i < 8; i++) {
      final y = i * 2;
      if (i.isEven) {
        _row(p, y, [0, 2, 4, 6, 8, 10, 12, 14]);
      } else {
        _row(p, y, [1, 3, 5, 7, 9, 11, 13]);
      }
    }
    _row(p, 3, [7], 1);
    _row(p, 7, [4, 10], 1);
    _row(p, 11, [7], 1);
    return _done(p, 'festival');
  }

  /// Павильон (72).
  static List<LayoutPos> pavilion() {
    final p = <LayoutPos>[];
    for (var i = 0; i < 8; i++) {
      final y = i * 2;
      if (i.isEven) {
        _row(p, y, [0, 2, 4, 6, 8, 10, 12, 14]);
      } else {
        _row(p, y, [1, 3, 5, 7, 9, 11, 13, 15]);
      }
    }
    _row(p, 1, [7], 1);
    _row(p, 3, [5, 9], 1);
    _row(p, 5, [7], 1);
    _row(p, 7, [5, 9], 1);
    _row(p, 9, [7], 1);
    _row(p, 11, [7], 1);
    return _done(p, 'pavilion');
  }

  /// Дракон — вытянутый живой силуэт (80).
  static List<LayoutPos> dragon() {
    final p = <LayoutPos>[];
    _row(p, 0, [2, 4, 6, 8, 10, 12]);
    _row(p, 2, [1, 3, 5, 7, 9, 11, 13, 15]);
    _row(p, 4, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]);
    _row(p, 6, [1, 3, 5, 7, 9, 11, 13, 15, 17]);
    _row(p, 8, [0, 2, 4, 6, 8, 10, 12, 14, 16, 18]);
    _row(p, 10, [1, 3, 5, 7, 9, 11, 13, 15, 17]);
    _row(p, 12, [1, 3, 5, 7, 9, 11, 13, 15]);
    _row(p, 14, [2, 4, 6, 8, 10, 12]);
    _row(p, 1, [8], 1);
    _row(p, 3, [7, 11], 1);
    _row(p, 5, [5, 9, 13], 1);
    _row(p, 7, [7, 11], 1);
    _row(p, 9, [5, 9, 13], 1);
    _row(p, 11, [8], 1);
    _row(p, 13, [6, 10], 1);
    return _done(p, 'dragon');
  }

  static List<LayoutPos> byName(String name) {
    final depth = _maxStackDepth(name);
    final List<LayoutPos> raw = switch (name) {
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
    return _finalizeStacks(raw, depth, name);
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
