import 'dart:math';

import '../utils/layouts.dart';
import 'tile.dart';

enum MatchResult {
  /// Плитка ушла в лоток, пары не было.
  collected,

  /// Из лотка снята пара.
  matched,

  /// Поле и лоток пусты.
  win,

  /// Лоток заполнен без пары.
  lose,

  blocked,
  trayFull,
}

/// Логика поля + лоток на 4 плитки (пары снимаются из ниши).
class Board {
  Board({required this.tiles, this.layoutName = 'pyramid'});

  static const trayCapacity = 4;

  final List<Tile> tiles;
  final String layoutName;

  /// Плитки в верхней нише (порядок = порядок сбора).
  final List<Tile> tray = [];

  int get trayLiveCount => tray.where((t) => !t.removing).length;

  int get remaining => tiles.where((t) => !t.removed && !t.removing).length;
  int get total => tiles.length;
  bool get isWon => remaining == 0;
  bool isLost = false;

  ({int minX, int maxX, int minY, int maxY}) get bounds {
    final alive = tiles.where((t) => t.isOnBoard);
    if (alive.isEmpty) {
      // Пока все в лотке — держим прошлые границы через inTray/removed.
      final any = tiles.where((t) => !t.removed);
      if (any.isEmpty) {
        return (minX: 0, maxX: 0, minY: 0, maxY: 0);
      }
      return (
        minX: any.map((t) => t.x).reduce(min),
        maxX: any.map((t) => t.x).reduce(max),
        minY: any.map((t) => t.y).reduce(min),
        maxY: any.map((t) => t.y).reduce(max),
      );
    }
    return (
      minX: alive.map((t) => t.x).reduce(min),
      maxX: alive.map((t) => t.x).reduce(max),
      minY: alive.map((t) => t.y).reduce(min),
      maxY: alive.map((t) => t.y).reduce(max),
    );
  }

  factory Board.fromLayout(
    String layoutName, {
    Random? random,
    String? style,
    int pairSize = 4,
    int? uniqueCap,
    int? levelId,
    int guestTypes = 0,
  }) {
    final rng = random ?? Random();
    final positions = Layouts.byName(layoutName);
    final symbols = TileSymbols.deckFor(
      positions.length,
      random: rng,
      style: style,
      pairSize: pairSize,
      uniqueCap: uniqueCap,
      levelId: levelId,
      guestTypes: guestTypes,
    );

    final tiles = _dealSolvable(positions, symbols, rng);
    final board = Board(tiles: tiles, layoutName: layoutName);
    board._ensureVisiblePair(random: rng);
    return board;
  }

  /// Vita-стиль: плитка свободна, если её не накрывает слой выше.
  /// Соседи на том же слое не блокируют — раскладка плоская и «живая».
  bool isFree(Tile tile) {
    if (!tile.isOnBoard) return false;
    return _isFreeAmong(tile, tiles);
  }

  static bool _isFreeAmong(Tile tile, List<Tile> live) {
    for (final other in live) {
      if (other.id == tile.id) continue;
      if (!other.isOnBoard || other.layer <= tile.layer) continue;
      if (_overlaps(tile, other)) return false;
    }
    return true;
  }

  static bool _overlaps(Tile a, Tile b) {
    return a.x < b.x + 2 && a.x + 2 > b.x && a.y < b.y + 2 && a.y + 2 > b.y;
  }

  List<Tile> freeTiles() =>
      tiles.where((t) => t.isOnBoard && isFree(t)).toList();

  /// Можно ли ещё взять плитку с поля в лоток.
  bool hasMoves() {
    if (trayLiveCount >= trayCapacity) return trayHasPair();
    return freeTiles().isNotEmpty;
  }

  /// Есть видимый ход: пара наверху или совпадение с лотком.
  bool hasUsefulMove() {
    if (freeTiles().isEmpty) return false;
    return _hasMatchAmongFree();
  }

  bool _hasMatchAmongFree() {
    final free = freeTiles();
    final liveTray = tray.where((t) => !t.removing).toList();
    for (final boardTile in free) {
      for (final trayTile in liveTray) {
        if (TileSymbols.matches(boardTile.symbol, trayTile.symbol)) {
          return true;
        }
      }
    }
    for (var i = 0; i < free.length; i++) {
      for (var j = i + 1; j < free.length; j++) {
        if (TileSymbols.matches(free[i].symbol, free[j].symbol)) {
          return true;
        }
      }
    }
    return false;
  }

  bool trayHasPair() {
    final live = tray.where((t) => !t.removing).toList();
    for (var i = 0; i < live.length; i++) {
      for (var j = i + 1; j < live.length; j++) {
        if (TileSymbols.matches(live[i].symbol, live[j].symbol)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Подсказка: две плитки, которые сейчас можно снять парой.
  /// [match] — в лотке или вторая свободная на поле.
  ({Tile boardTile, Tile match})? findHint() {
    if (trayLiveCount >= trayCapacity && !trayHasPair()) return null;
    final free = freeTiles();
    if (free.isEmpty) return null;

    final liveTray = tray.where((t) => !t.removing).toList();
    for (final boardTile in free) {
      for (final trayTile in liveTray) {
        if (TileSymbols.matches(boardTile.symbol, trayTile.symbol)) {
          return (boardTile: boardTile, match: trayTile);
        }
      }
    }

    for (var i = 0; i < free.length; i++) {
      for (var j = i + 1; j < free.length; j++) {
        if (TileSymbols.matches(free[i].symbol, free[j].symbol)) {
          return (boardTile: free[i], match: free[j]);
        }
      }
    }
    return null;
  }

  /// Магнит: пара, которую можно снять сейчас, не переполняя лоток.
  ({Tile boardTile, Tile match})? findMagnetPair() {
    final hint = findHint();
    if (hint == null) return null;
    final needTwoSlots = hint.match.isOnBoard;
    final freeSlots = trayCapacity - trayLiveCount;
    if (needTwoSlots && freeSlots < 2) return null;
    if (!needTwoSlots && freeSlots < 1) return null;
    return hint;
  }

  /// Последняя снятая пара (для анимации / undo).
  List<Tile> lastMatched = [];

  /// Клик по плитке на поле → в лоток (пары — после [resolveTray], обычно после полёта).
  MatchResult pick(Tile tile) {
    lastMatched = [];
    if (!tile.isOnBoard) return MatchResult.blocked;
    if (!isFree(tile)) return MatchResult.blocked;
    if (trayLiveCount >= trayCapacity) return MatchResult.trayFull;

    tile.inTray = true;
    tray.add(tile);
    return MatchResult.collected;
  }

  /// Снять пары из ниши и проверить победу / переполнение.
  MatchResult resolveTray() {
    lastMatched = [];
    final cleared = _clearPairsFromTray();
    if (isWon) return MatchResult.win;
    if (cleared) {
      _ensureVisiblePair();
      return MatchResult.matched;
    }
    if (trayLiveCount >= trayCapacity && !trayHasPair()) {
      isLost = true;
      return MatchResult.lose;
    }
    _ensureVisiblePair();
    return MatchResult.collected;
  }

  /// Помечает пары в лотке на удаление (остаются до finishRemoval).
  bool _clearPairsFromTray() {
    var any = false;
    while (true) {
      final live = tray.where((t) => !t.removing).toList();
      var found = false;
      for (var i = 0; i < live.length; i++) {
        for (var j = i + 1; j < live.length; j++) {
          if (!TileSymbols.matches(live[i].symbol, live[j].symbol)) {
            continue;
          }
          final a = live[i];
          final b = live[j];
          a.removing = true;
          b.removing = true;
          lastMatched.add(a);
          lastMatched.add(b);
          found = true;
          any = true;
          break;
        }
        if (found) break;
      }
      if (!found) break;
    }
    return any;
  }

  void finishRemoval(Tile tile) {
    if (!tile.removing) return;
    tile.removing = false;
    tile.removed = true;
    tile.inTray = false;
    tray.removeWhere((t) => t.id == tile.id);
  }

  /// Вернуть плитку из лотка на поле (undo сбора).
  bool returnFromTray(Tile tile) {
    final idx = tray.indexWhere((t) => t.id == tile.id);
    if (idx < 0) return false;
    tray.removeAt(idx);
    tile.inTray = false;
    tile.removing = false;
    tile.removed = false;
    return true;
  }

  /// Снять проигрыш: вернуть последнюю собранную плитку на поле.
  bool reviveFromTray(Tile tile) {
    if (!isLost) return false;
    final ok = returnFromTray(tile);
    if (ok) isLost = false;
    return ok;
  }

  /// Вернуть сматченную пару обратно в лоток (undo матча).
  void restoreMatchedToTray(Tile a, Tile b) {
    a.removing = false;
    a.removed = false;
    a.inTray = true;
    b.removing = false;
    b.removed = false;
    b.inTray = true;
    if (!tray.any((t) => t.id == a.id)) tray.add(a);
    if (!tray.any((t) => t.id == b.id)) tray.add(b);
  }

  void clearSelection() {}

  /// Тасует лица, пока наверху есть полезная пара. `false` — свободных костей нет.
  bool shuffleRemaining({Random? random, int attempts = 40}) {
    if (freeTiles().isEmpty) return false;
    final rng = random ?? Random();
    for (var i = 0; i < attempts; i++) {
      _shuffleOnce(rng);
      if (_hasMatchAmongFree()) return true;
    }
    _shuffleOnce(rng);
    return _hasMatchAmongFree();
  }

  void _shuffleOnce(Random rng) {
    final alive = tiles.where((t) => t.isOnBoard).toList();
    final symbols = alive.map((t) => t.symbol).toList()..shuffle(rng);
    for (var i = 0; i < alive.length; i++) {
      alive[i].symbol = symbols[i];
    }
  }

  void _ensureVisiblePair({Random? random}) {
    if (isWon || isLost) return;
    if (_hasMatchAmongFree()) return;
    shuffleRemaining(random: random);
    if (_hasMatchAmongFree()) return;
    _forceVisiblePair();
  }

  /// Ставит совпадение на две свободные кости или под лоток.
  bool _forceVisiblePair() {
    final free = freeTiles();
    if (free.isEmpty) return false;

    final liveTray = tray.where((t) => !t.removing).toList();
    for (final trayTile in liveTray) {
      Tile? buried;
      for (final tile in tiles) {
        if (!tile.isOnBoard) continue;
        if (!TileSymbols.matches(tile.symbol, trayTile.symbol)) continue;
        if (isFree(tile)) return true;
        buried = tile;
        break;
      }
      if (buried == null) continue;
      final target = free.firstWhere(
        (tile) => !TileSymbols.matches(tile.symbol, trayTile.symbol),
        orElse: () => free.first,
      );
      _swapSymbols(target, buried);
      return _hasMatchAmongFree();
    }

    if (free.length < 2) return false;
    final groups = <String, List<Tile>>{};
    for (final tile in tiles) {
      if (!tile.isOnBoard) continue;
      groups.putIfAbsent(tile.symbol, () => []).add(tile);
    }
    for (final group in groups.values) {
      if (group.length < 2) continue;
      _swapSymbols(free[0], group[0]);
      _swapSymbols(free[1], group[1]);
      if (_hasMatchAmongFree()) return true;
    }
    return _hasMatchAmongFree();
  }

  static void _swapSymbols(Tile a, Tile b) {
    if (identical(a, b) || a.id == b.id) return;
    final tmp = a.symbol;
    a.symbol = b.symbol;
    b.symbol = tmp;
  }

  /// Раскладывает пары на свободные места с конца решения — наверху всегда есть ход.
  static List<Tile> _dealSolvable(
    List<LayoutPos> positions,
    List<String> symbols,
    Random rng,
  ) {
    final pairs = _pairQueue(symbols);
    for (var attempt = 0; attempt < 48; attempt++) {
      final shuffled = List<String>.from(pairs)..shuffle(rng);
      final tiles = _tryPairDeal(positions, shuffled, rng);
      if (tiles != null) return tiles;
    }
    final fallback = List<String>.from(symbols)..shuffle(rng);
    return [
      for (var i = 0; i < positions.length; i++)
        Tile(
          id: i,
          symbol: fallback[i],
          x: positions[i].$1,
          y: positions[i].$2,
          layer: positions[i].$3,
        ),
    ];
  }

  static List<String> _pairQueue(List<String> symbols) {
    final counts = <String, int>{};
    for (final symbol in symbols) {
      counts[symbol] = (counts[symbol] ?? 0) + 1;
    }
    final pairs = <String>[];
    for (final entry in counts.entries) {
      for (var i = 0; i < entry.value ~/ 2; i++) {
        pairs.add(entry.key);
      }
    }
    return pairs;
  }

  static List<Tile>? _tryPairDeal(
    List<LayoutPos> positions,
    List<String> pairs,
    Random rng,
  ) {
    final live = <Tile>[
      for (var i = 0; i < positions.length; i++)
        Tile(
          id: i,
          symbol: '',
          x: positions[i].$1,
          y: positions[i].$2,
          layer: positions[i].$3,
        ),
    ];
    final assigned = List<String?>.filled(positions.length, null);

    for (final symbol in pairs) {
      final free = [
        for (final tile in live)
          if (_isFreeAmong(tile, live)) tile,
      ];
      if (free.length < 2) return null;
      free.shuffle(rng);
      final a = free[0];
      final b = free[1];
      assigned[a.id] = symbol;
      assigned[b.id] = symbol;
      live.removeWhere((tile) => tile.id == a.id || tile.id == b.id);
    }

    return [
      for (var i = 0; i < positions.length; i++)
        Tile(
          id: i,
          symbol: assigned[i]!,
          x: positions[i].$1,
          y: positions[i].$2,
          layer: positions[i].$3,
        ),
    ];
  }
}
