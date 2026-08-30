import 'dart:math';

import 'tile_icons.dart';

/// Позиция плитки в раскладке: [x, y, layer].
typedef LayoutPos = (int x, int y, int layer);

/// Раскладки на общей сцене 6×5 клеток. Сложность — в силуэте и в слоях,
/// не в сжатии плиток.
///
/// Координаты — в половинах размера плитки. Соседняя клетка сетки — ±2.
class Layouts {
  Layouts._();

  /// Правый край поля (клетка x = 10 → 6-я колонка).
  static const playfieldMaxX = 10;

  /// Нижний край поля (клетка y = 8 → 5-й ряд).
  static const playfieldMaxY = 8;

  static LayoutPos _p(int x, int y, [int z = 0]) => (x, y, z);

  /// Стопка из [count] плиток в одной клетке, слои 0…count-1.
  static void _stack(List<LayoutPos> out, int x, int y, int count) {
    for (var z = 0; z < count; z++) {
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

  /// 5 рядов × 6 столбцов. `.` — пусто, число — высота стопки.
  static List<LayoutPos> _grid(String name, List<String> rows) {
    assert(rows.length == 5, '$name must span the 5-row playfield');
    final p = <LayoutPos>[];
    for (var r = 0; r < rows.length; r++) {
      final cells = rows[r].trim().split(RegExp(r'\s+'));
      assert(cells.length == 6, '$name row $r must have 6 cells, got $cells');
      for (var c = 0; c < cells.length; c++) {
        final token = cells[c];
        if (token == '.' || token == '0') continue;
        final h = int.parse(token);
        _stack(p, c * 2, r * 2, h);
      }
    }
    return _done(p, name);
  }

  /// Уголки поля и сердцевина (16).
  static List<LayoutPos> petal() => _grid('petal', const [
    '2 . . . . 2',
    '. . . . . .',
    '. . 4 4 . .',
    '. . . . . .',
    '2 . . . . 2',
  ]);

  /// Пять бутонов (20).
  static List<LayoutPos> buds() => _grid('buds', const [
    '. 2 . . 2 .',
    '. . 4 . . .',
    '. 2 . 2 . .',
    '. . 4 . . .',
    '. 2 . . 2 .',
  ]);

  /// Крест (24).
  static List<LayoutPos> bloom() => _grid('bloom', const [
    '. . 2 . . .',
    '. . 3 . . .',
    '2 3 4 3 2 .',
    '. . 3 . . .',
    '. . 2 . . .',
  ]);

  /// Редкие поляны (28).
  static List<LayoutPos> glade() => _grid('glade', const [
    '2 . 2 . 2 .',
    '. 2 . . . 2',
    '2 . 4 . 2 .',
    '. 2 . 2 . .',
    '2 . 2 . 2 .',
  ]);

  /// Два холма (32).
  static List<LayoutPos> meadow() => _grid('meadow', const [
    '. . 2 2 . .',
    '2 . . . . 2',
    '4 4 . . 4 4',
    '2 . . . . 2',
    '. . 2 2 . .',
  ]);

  /// Роща колонн (36).
  static List<LayoutPos> grove() => _grid('grove', const [
    '2 . 2 . 2 .',
    '. 3 . 4 . 2',
    '2 . 4 . 3 .',
    '. 3 . 3 . .',
    '2 . 2 . 2 .',
  ]);

  /// Диагональный гребень (36).
  static List<LayoutPos> wave() => _grid('wave', const [
    '. . . . 3 4',
    '. . . 4 4 .',
    '. . 4 3 . .',
    '. 4 3 . . .',
    '3 4 . . . .',
  ]);

  /// Извилистый ручей (40).
  static List<LayoutPos> stream() => _grid('stream', const [
    '3 3 3 2 . .',
    '. . . 3 3 2',
    '. . 3 3 . .',
    '2 3 3 . . .',
    '2 2 3 . . .',
  ]);

  /// Кольцо с пустым двором (44).
  static List<LayoutPos> garden() => _grid('garden', const [
    '2 3 2 2 3 2',
    '3 . . . . 3',
    '2 . . . . 2',
    '3 . . . . 3',
    '2 3 2 2 3 2',
  ]);

  /// Беседка: стены и две башни (48).
  static List<LayoutPos> gazebo() => _grid('gazebo', const [
    '2 2 2 2 2 2',
    '2 . . . . 2',
    '2 . 6 6 . 2',
    '2 . . . . 2',
    '2 2 2 2 2 2',
  ]);

  /// Веер от низа (48).
  static List<LayoutPos> fan() => _grid('fan', const [
    '4 . . . . 4',
    '3 4 . . 4 3',
    '. 3 4 4 3 .',
    '. . 3 3 . .',
    '. . 3 3 . .',
  ]);

  /// Павлиний хвост с «глазами» (52).
  static List<LayoutPos> peacock() => _grid('peacock', const [
    '5 . . . . 5',
    '4 4 . . 4 4',
    '. 3 3 3 3 .',
    '. . 4 4 . .',
    '. . 3 3 . .',
  ]);

  /// Ромб лотоса (56).
  static List<LayoutPos> lotus() => _grid('lotus', const [
    '. . 3 3 . .',
    '. 3 4 4 3 .',
    '. 4 4 4 4 .',
    '. 3 4 4 3 .',
    '. . 3 3 . .',
  ]);

  /// Пруд: берег и остров (60).
  static List<LayoutPos> pond() => _grid('pond', const [
    '2 3 3 3 3 2',
    '3 . . . . 3',
    '3 . 5 5 . 3',
    '3 . . . . 3',
    '2 3 3 3 3 2',
  ]);

  /// Два карпа (64).
  static List<LayoutPos> koi() => _grid('koi', const [
    '4 5 3 . . .',
    '3 4 4 . . 2',
    '. 3 2 . 4 5',
    '2 . . 3 4 4',
    '. . . 3 5 4',
  ]);

  /// Широкая чаша озера (68).
  static List<LayoutPos> lake() => _grid('lake', const [
    '2 3 3 3 3 2',
    '3 4 . . 4 3',
    '4 . . . . 4',
    '3 4 . . 4 3',
    '2 3 3 3 3 2',
  ]);

  /// Зигзаг лозы (72).
  static List<LayoutPos> vine() => _grid('vine', const [
    '5 5 4 . . .',
    '. . 4 5 5 .',
    '6 6 4 . . .',
    '. . 4 5 5 .',
    '5 5 4 . . .',
  ]);

  /// Лестницы плюща (76).
  static List<LayoutPos> ivy() => _grid('ivy', const [
    '3 . . . . 7',
    '4 4 . . 6 5',
    '. 4 5 5 4 .',
    '5 6 . . 4 4',
    '7 . . . . 3',
  ]);

  /// Врата праздника (80).
  static List<LayoutPos> festival() => _grid('festival', const [
    '6 2 2 2 2 6',
    '6 . . . . 6',
    '6 . 2 2 . 6',
    '6 . . . . 6',
    '6 2 2 2 2 6',
  ]);

  /// Три фонарные башни (84).
  static List<LayoutPos> lanterns() => _grid('lanterns', const [
    '. 8 . 8 . 8',
    '. 6 . 6 . 6',
    '. 5 . 5 . 5',
    '. 4 . 4 . 4',
    '2 3 2 3 2 3',
  ]);

  /// Двор с высокой цитаделью (96).
  static List<LayoutPos> pavilion() => _grid('pavilion', const [
    '4 4 4 4 4 4',
    '4 . . . . 4',
    '4 . 12 12 . 4',
    '4 . . . . 4',
    '4 4 4 4 4 4',
  ]);

  /// Храм: широкое основание и пик (104).
  static List<LayoutPos> temple() => _grid('temple', const [
    '2 3 3 3 3 2',
    '3 4 4 4 4 3',
    '4 5 5 5 5 4',
    '3 4 4 4 4 3',
    '2 3 3 3 3 2',
  ]);

  /// Хребет дракона — поле целиком, пик уходит в слои (112).
  static List<LayoutPos> dragon() => _grid('dragon', const [
    '. 3 . 3 . 3',
    '2 5 4 6 4 2',
    '3 6 15 15 6 3',
    '2 5 4 6 4 2',
    '. 3 . 3 . 3',
  ]);

  /// Небесный дракон: две глубокие вершины (128).
  static List<LayoutPos> sky() => _grid('sky', const [
    '. 4 . 4 . 4',
    '3 6 5 6 5 3',
    '4 7 13 13 7 4',
    '3 6 5 6 5 3',
    '. 4 . 4 . 4',
  ]);

  /// Поле со скрина Vita: 16 плиток, координаты Rise (половины ширины/высоты).
  static List<LayoutPos> vita() {
    final p = <LayoutPos>[
      _p(0, 0),
      _p(2, 0),
      _p(4, 0),
      _p(6, 0),
      _p(4, 2),
      _p(6, 2),
      _p(0, 3),
      _p(4, 3),
      _p(6, 4),
      _p(8, 4),
      _p(0, 5),
      _p(2, 6),
      _p(4, 6),
      _p(6, 6),
      _p(8, 6),
      _p(10, 6),
    ];
    return _done(p, 'vita');
  }

  static const campaignBases = <String>[
    'petal',
    'buds',
    'bloom',
    'glade',
    'meadow',
    'grove',
    'wave',
    'stream',
    'garden',
    'gazebo',
    'fan',
    'peacock',
    'lotus',
    'pond',
    'koi',
    'lake',
    'vine',
    'ivy',
    'festival',
    'lanterns',
    'pavilion',
    'temple',
    'dragon',
    'sky',
  ];

  static int get campaignLayoutCount => campaignBases.length * 4;

  /// 0 = база, 1 = зеркало, 2 = выше стопки, 3 = зеркало + высота.
  static String variantName(String base, int variant) {
    return switch (variant % 4) {
      1 => '$base-m',
      2 => '$base-d',
      3 => '$base-md',
      _ => base,
    };
  }

  static List<LayoutPos> byName(String name) {
    var base = name;
    var mirror = false;
    var deep = false;
    if (name.endsWith('-md')) {
      base = name.substring(0, name.length - 3);
      mirror = true;
      deep = true;
    } else if (name.endsWith('-m')) {
      base = name.substring(0, name.length - 2);
      mirror = true;
    } else if (name.endsWith('-d')) {
      base = name.substring(0, name.length - 2);
      deep = true;
    }

    var positions = _baseByName(base);
    if (mirror) positions = _mirrorX(positions);
    if (deep) positions = _deeper(positions);
    return _done(positions, name);
  }

  static List<LayoutPos> _baseByName(String name) {
    return switch (name) {
      'petal' || 'seed' => petal(),
      'buds' => buds(),
      'bloom' => bloom(),
      'glade' => glade(),
      'meadow' => meadow(),
      'grove' => grove(),
      'wave' => wave(),
      'stream' => stream(),
      'garden' || 'pyramid' => garden(),
      'gazebo' => gazebo(),
      'fan' || 'fort' => fan(),
      'peacock' => peacock(),
      'lotus' => lotus(),
      'pond' => pond(),
      'koi' => koi(),
      'lake' => lake(),
      'vine' || 'tower' => vine(),
      'ivy' => ivy(),
      'festival' => festival(),
      'lanterns' => lanterns(),
      'pavilion' => pavilion(),
      'temple' => temple(),
      'dragon' || 'turtle' => dragon(),
      'sky' => sky(),
      'vita' => vita(),
      _ => bloom(),
    };
  }

  static List<LayoutPos> _mirrorX(List<LayoutPos> src) {
    return [for (final p in src) (playfieldMaxX - p.$1, p.$2, p.$3)];
  }

  /// +1 слой на каждую занятую клетку; при нечётном приросте — ещё один на пике.
  static List<LayoutPos> _deeper(List<LayoutPos> src) {
    final heights = <(int, int), int>{};
    for (final p in src) {
      final key = (p.$1, p.$2);
      final h = p.$3 + 1;
      final prev = heights[key] ?? 0;
      if (h > prev) heights[key] = h;
    }
    for (final key in heights.keys.toList()) {
      heights[key] = heights[key]! + 1;
    }
    if (heights.length.isOdd) {
      final tallest = heights.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      heights[tallest.key] = tallest.value + 1;
    }
    final out = <LayoutPos>[];
    for (final entry in heights.entries) {
      _stack(out, entry.key.$1, entry.key.$2, entry.value);
    }
    return out;
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
    double? cuteShare,
  }) {
    assert(count.isEven && count > 0);
    assert(pairSize == 2 || pairSize == 4);

    final rng = random ?? Random();
    final share = cuteShare ?? cuteSimpleShareFor(levelId, style: style);
    return _fruitMajorityDeck(
      count: count,
      fruitShare: share,
      pairSize: pairSize,
      uniqueCap: uniqueCap,
      random: rng,
      style: style,
      guestTypes: guestTypes,
      levelId: levelId,
    );
  }

  static const _storyLength = 24;
  static const fruitShare = 0.60;
  static const fruitWorldShare = 0.80;
  static const easyCuteShare = fruitShare;

  static double cuteSimpleShareFor(int? levelId, {String? style}) {
    if (style == 'fruit') return fruitWorldShare;
    if (levelId == null) return fruitShare;
    final story = ((levelId - 1) % _storyLength) + 1;
    final worldStyle = _styleForStory(story);
    if (worldStyle == 'fruit') return fruitWorldShare;
    return fruitShare;
  }

  static String? _styleForStory(int storyId) {
    const worlds = ['fruit', 'fruit', 'fruit', 'nature', 'myth'];
    final world = (storyId - 1) ~/ 4;
    if (world >= worlds.length) return 'mixed';
    return worlds[world];
  }

  static List<String> _fruitMajorityDeck({
    required int count,
    required double fruitShare,
    required int pairSize,
    int? uniqueCap,
    required Random random,
    String? style,
    int guestTypes = 0,
    int? levelId,
  }) {
    var fruitTiles = ((count * fruitShare) / 2).round() * 2;
    fruitTiles = fruitTiles.clamp(2, count);
    if (fruitTiles.isOdd) fruitTiles -= 1;
    final restTiles = count - fruitTiles;

    final fruitPool = List<String>.from(TileIcons.fruitIds)..shuffle(random);
    final bonus = pickBonusTypes(
      levelId: levelId ?? random.nextInt(1 << 30),
      random: random,
    );
    final guests = pickGuestTypes(
      style: style,
      guestCount: guestTypes,
      levelId: levelId ?? random.nextInt(1 << 30),
      random: random,
    );

    final restSeen = <String>{};
    final restPool = <String>[];
    void addRest(Iterable<String> ids) {
      for (final id in ids) {
        if (id.startsWith('fruit-')) continue;
        if (!restSeen.add(id)) continue;
        restPool.add(id);
      }
    }

    addRest([...bonus, ...guests]);
    addRest(
      List<String>.from(TileIcons.idsForStyle(style ?? 'mixed'))
        ..shuffle(random),
    );
    addRest(List<String>.from(TileIcons.softIds)..shuffle(random));
    addRest(List<String>.from(TileIcons.shapeIds)..shuffle(random));
    addRest(List<String>.from(TileIcons.numberIds)..shuffle(random));

    final typeLimit = uniqueCap ?? (fruitPool.length + restPool.length);
    var fruitSlots = (typeLimit * fruitShare).round().clamp(
      1,
      fruitPool.length,
    );
    var restSlots = restTiles == 0
        ? 0
        : (typeLimit - fruitSlots).clamp(0, restPool.length);
    if (restTiles > 0 && restPool.isNotEmpty) {
      restSlots = restSlots.clamp(1, restPool.length);
      if (restSlots < 2 && restPool.length >= 2 && typeLimit >= 4) {
        restSlots = 2;
      }
      restSlots = restSlots.clamp(1, restTiles ~/ 2);
      fruitSlots = (typeLimit - restSlots).clamp(1, fruitPool.length);
      fruitSlots = fruitSlots.clamp(1, fruitTiles ~/ 2);
    }

    final fruitTypes = fruitPool.take(fruitSlots).toList();
    final restTypes = restPool.take(restSlots).toList();
    return [
      ..._fillPairs(fruitTypes, fruitTiles, pairSize),
      ..._fillPairs(
        restTypes.isEmpty ? fruitTypes : restTypes,
        restTiles,
        pairSize,
      ),
    ];
  }

  static List<String> _fillPairs(List<String> types, int count, int pairSize) {
    if (count <= 0) return const [];
    final pool = types.isEmpty ? TileIcons.fruitIds : types;
    final maxTypes = (count ~/ 2).clamp(1, pool.length);
    final used = pool.take(maxTypes).toList();
    final per = List<int>.filled(used.length, 0);
    var leftover = count;
    for (var i = 0; i < used.length && leftover >= 2; i++) {
      per[i] += 2;
      leftover -= 2;
    }
    var i = 0;
    while (leftover >= 2) {
      final add = leftover >= pairSize ? pairSize : 2;
      per[i % used.length] += add;
      leftover -= add;
      i++;
    }
    return [
      for (var t = 0; t < used.length; t++) ...List.filled(per[t], used[t]),
    ];
  }

  /// На каждом уровне — фигура, цифра и одна сезонная (бонусная) кость.
  static List<String> pickBonusTypes({required int levelId, Random? random}) {
    final rng = random ?? Random(levelId * 5527);
    final shapes = List<String>.from(TileIcons.shapeIds)..shuffle(rng);
    final numbers = List<String>.from(TileIcons.numberIds)..shuffle(rng);
    final seasons = List<String>.from(const [
      'season-01',
      'season-02',
      'season-03',
      'season-04',
    ])..shuffle(rng);
    return [shapes.first, numbers.first, seasons.first];
  }

  /// Несколько типов из других тем — не фрукты, они уже занимают большую часть колоды.
  static List<String> pickGuestTypes({
    required String? style,
    required int guestCount,
    required int levelId,
    Random? random,
  }) {
    if (guestCount <= 0 || style == null) return const [];

    final primary = TileIcons.idsForStyle(style).toSet();
    final guestRng = random ?? Random(levelId * 9973);
    final pool =
        <String>[
            ...TileIcons.softIds,
            ...TileIcons.shapeIds,
            ...TileIcons.numberIds,
          ]
          ..removeWhere(primary.contains)
          ..removeWhere((id) => id.startsWith('fruit-'))
          ..shuffle(guestRng);

    if (pool.length < guestCount) {
      pool.addAll(
        List<String>.from(TileIcons.ids)
          ..removeWhere(primary.contains)
          ..removeWhere((id) => id.startsWith('fruit-'))
          ..removeWhere(pool.contains)
          ..shuffle(guestRng),
      );
    }
    return pool.take(guestCount).toList();
  }

  static bool matches(String a, String b) => a == b;
}
