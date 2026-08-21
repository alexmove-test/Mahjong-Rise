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
    )..shuffle(rng);

    final tiles = <Tile>[
      for (var i = 0; i < positions.length; i++)
        Tile(
          id: i,
          symbol: symbols[i],
          x: positions[i].$1,
          y: positions[i].$2,
          layer: positions[i].$3,
        ),
    ];

    final board = Board(tiles: tiles, layoutName: layoutName);
    if (!board._dealReverse(symbols, rng)) {
      for (var i = 0; i < tiles.length; i++) {
        tiles[i].symbol = symbols[i];
      }
      board.shuffleRemaining(random: rng, attempts: 80);
    }
    return board;
  }

  /// Places matching pairs onto currently-free slots, working backwards.
  /// Guarantees a solution exists; the player can still fill the tray badly.
  bool _dealReverse(List<String> symbols, Random rng) {
    final remaining = <String, int>{};
    for (final symbol in symbols) {
      remaining[symbol] = (remaining[symbol] ?? 0) + 1;
    }
    final live = tiles.map((t) => t.id).toSet();

    while (live.isNotEmpty) {
      final free = tiles
          .where((t) => live.contains(t.id) && _isFreeAmong(t, live))
          .toList()
        ..shuffle(rng);
      if (free.length < 2) return false;

      final available = remaining.entries
          .where((e) => e.value >= 2)
          .map((e) => e.key)
          .toList()
        ..shuffle(rng);
      if (available.isEmpty) return false;

      final symbol = available.first;
      free[0].symbol = symbol;
      free[1].symbol = symbol;
      remaining[symbol] = remaining[symbol]! - 2;
      live.remove(free[0].id);
      live.remove(free[1].id);
    }
    return true;
  }

  bool _isFreeAmong(Tile tile, Set<int> liveIds) {
    if (!liveIds.contains(tile.id)) return false;
    for (final other in tiles) {
      if (!liveIds.contains(other.id) || other.layer <= tile.layer) continue;
      if (_overlaps(tile, other)) return false;
    }
    return true;
  }

  /// Vita-стиль: плитка свободна, если её не накрывает слой выше.
  /// Соседи на том же слое не блокируют — раскладка плоская и «живая».
  bool isFree(Tile tile) {
    if (!tile.isOnBoard) return false;
    return !_hasTileAbove(tile);
  }

  bool _hasTileAbove(Tile tile) {
    for (final other in tiles) {
      if (!other.isOnBoard || other.layer <= tile.layer) continue;
      if (_overlaps(tile, other)) return true;
    }
    return false;
  }

  bool _overlaps(Tile a, Tile b) {
    final ax0 = a.x;
    final ax1 = a.x + 2;
    final ay0 = a.y;
    final ay1 = a.y + 2;
    final bx0 = b.x;
    final bx1 = b.x + 2;
    final by0 = b.y;
    final by1 = b.y + 2;
    return ax0 < bx1 && ax1 > bx0 && ay0 < by1 && ay1 > by0;
  }

  List<Tile> freeTiles() =>
      tiles.where((t) => t.isOnBoard && isFree(t)).toList();

  /// Можно ли ещё взять плитку с поля в лоток.
  bool hasMoves() {
    if (trayLiveCount >= trayCapacity) return trayHasPair();
    return freeTiles().isNotEmpty;
  }

  /// Есть ход, который не заводит в тупик сразу: пара или свободная кость в лоток.
  bool hasUsefulMove() {
    if (freeTiles().isEmpty) return false;
    if (_hasMatchAmongFree()) return true;
    return trayLiveCount < trayCapacity;
  }

  bool _hasMatchAmongFree() {
    final free = freeTiles();
    final liveTray = tray.where((t) => !t.removing && !t.flying).toList();
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

  /// Следующий сбор этой кости сразу заполнит лоток без пары.
  bool wouldFillWithoutPair(Tile tile) {
    if (trayLiveCount != trayCapacity - 1) return false;
    if (!isFree(tile)) return false;
    final live = tray.where((t) => !t.removing && !t.flying).toList();
    return !live.any((t) => TileSymbols.matches(t.symbol, tile.symbol));
  }

  bool trayHasPair() {
    final live = tray.where((t) => !t.removing && !t.flying).toList();
    for (var i = 0; i < live.length; i++) {
      for (var j = i + 1; j < live.length; j++) {
        if (TileSymbols.matches(live[i].symbol, live[j].symbol)) {
          return true;
        }
      }
    }
    return false;
  }

  /// Подсказка: пара лоток+поле или две свободные одинаковые на поле.
  ({Tile boardTile, Tile? pairTile})? findHint() {
    if (trayLiveCount >= trayCapacity && !trayHasPair()) return null;
    final free = freeTiles();
    if (free.isEmpty) return null;

    final liveTray = tray.where((t) => !t.removing && !t.flying).toList();
    for (final boardTile in free) {
      for (final trayTile in liveTray) {
        if (TileSymbols.matches(boardTile.symbol, trayTile.symbol)) {
          return (boardTile: boardTile, pairTile: trayTile);
        }
      }
    }

    for (var i = 0; i < free.length; i++) {
      for (var j = i + 1; j < free.length; j++) {
        if (TileSymbols.matches(free[i].symbol, free[j].symbol)) {
          return (boardTile: free[i], pairTile: free[j]);
        }
      }
    }

    return null;
  }

  /// Магнит: свободная плитка, совпадающая с лотком, иначе часть пары на поле.
  Tile? findMagnetTarget() {
    if (trayLiveCount >= trayCapacity && !trayHasPair()) return null;
    final hint = findHint();
    return hint?.boardTile;
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
    if (cleared) return MatchResult.matched;
    if (trayLiveCount >= trayCapacity && !trayHasPair()) {
      isLost = true;
      return MatchResult.lose;
    }
    return MatchResult.collected;
  }

  /// Помечает пары в лотке на удаление (остаются до finishRemoval).
  bool _clearPairsFromTray() {
    var any = false;
    while (true) {
      final live = tray.where((t) => !t.removing && !t.flying).toList();
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
    tile.flying = false;
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

  /// Тасует лица, пока наверху есть полезная пара. `false` — пары нет.
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
}
