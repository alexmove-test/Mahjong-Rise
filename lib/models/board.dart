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

    return Board(tiles: tiles, layoutName: layoutName);
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

  /// Подсказка: свободная плитка на поле + совпадающая в лотке (если есть).
  ({Tile boardTile, Tile? trayTile})? findHint() {
    if (trayLiveCount >= trayCapacity && !trayHasPair()) return null;
    final free = freeTiles();
    if (free.isEmpty) return null;

    final liveTray = tray.where((t) => !t.removing).toList();
    for (final boardTile in free) {
      for (final trayTile in liveTray) {
        if (TileSymbols.matches(boardTile.symbol, trayTile.symbol)) {
          return (boardTile: boardTile, trayTile: trayTile);
        }
      }
    }

    return (boardTile: free.first, trayTile: null);
  }

  /// Магнит: свободная плитка, совпадающая с лотком, иначе часть пары на поле.
  Tile? findMagnetTarget() {
    if (trayLiveCount >= trayCapacity && !trayHasPair()) return null;
    final free = freeTiles();
    if (free.isEmpty) return null;

    final liveTray = tray.where((t) => !t.removing).toList();
    for (final trayTile in liveTray) {
      for (final boardTile in free) {
        if (TileSymbols.matches(boardTile.symbol, trayTile.symbol)) {
          return boardTile;
        }
      }
    }

    for (var i = 0; i < free.length; i++) {
      for (var j = i + 1; j < free.length; j++) {
        if (TileSymbols.matches(free[i].symbol, free[j].symbol)) {
          return free[i];
        }
      }
    }

    return free.first;
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

  void shuffleRemaining({Random? random}) {
    final rng = random ?? Random();
    final alive = tiles.where((t) => t.isOnBoard).toList();
    final symbols = alive.map((t) => t.symbol).toList()..shuffle(rng);
    for (var i = 0; i < alive.length; i++) {
      alive[i].symbol = symbols[i];
    }
  }
}
