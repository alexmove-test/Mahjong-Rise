import 'dart:math';

import '../utils/layouts.dart';
import 'level_tile.dart';
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
    return Board.fromPositions(
      Layouts.byName(layoutName),
      layoutName: layoutName,
      random: random,
      style: style,
      pairSize: pairSize,
      uniqueCap: uniqueCap,
      levelId: levelId,
      guestTypes: guestTypes,
    );
  }

  factory Board.fromPositions(
    List<LayoutPos> positions, {
    String layoutName = 'custom',
    Random? random,
    String? style,
    int pairSize = 4,
    int? uniqueCap,
    int? levelId,
    int guestTypes = 0,
  }) {
    final rng = random ?? Random();
    final symbols = TileSymbols.deckFor(
      positions.length,
      random: rng,
      style: style,
      pairSize: pairSize,
      uniqueCap: uniqueCap,
      levelId: levelId,
      guestTypes: guestTypes,
    );

    return Board(
      tiles: _dealSolvable(positions, symbols, rng),
      layoutName: layoutName,
    );
  }

  factory Board.fromLevelFile(
    LevelFile file, {
    Random? random,
    String? style,
    int pairSize = 4,
    int? uniqueCap,
    int? levelId,
    int guestTypes = 0,
  }) {
    final positions = [
      for (final tile in file.boardTiles) (tile.x, tile.y, tile.layer),
    ];
    return Board.fromPositions(
      positions,
      layoutName: file.layout,
      random: random,
      style: style,
      pairSize: pairSize,
      uniqueCap: uniqueCap,
      levelId: levelId,
      guestTypes: guestTypes,
    );
  }

  /// Свободна, если сверху ничего нет и открыт левый или правый край.
  /// Зажатая с двух сторон на том же слое — закрыта, даже если сверху пусто.
  bool isFree(Tile tile) {
    if (!tile.isOnBoard) return false;
    return _isFreeAmong(tile, tiles);
  }

  static bool _isFreeAmong(Tile tile, List<Tile> live) {
    if (_isCoveredAmong(tile, live)) return false;
    final left = _sideBlockedAmong(tile, live, left: true);
    final right = _sideBlockedAmong(tile, live, left: false);
    return !left || !right;
  }

  static bool _isCoveredAmong(Tile tile, List<Tile> live) {
    for (final other in live) {
      if (other.id == tile.id) continue;
      if (!other.isOnBoard || other.layer <= tile.layer) continue;
      if (_overlaps(tile, other)) return true;
    }
    return false;
  }

  /// Сосед слева/справа на том же слое с пересечением по Y (классический солитер).
  static bool _sideBlockedAmong(
    Tile tile,
    List<Tile> live, {
    required bool left,
  }) {
    for (final other in live) {
      if (other.id == tile.id) continue;
      if (!other.isOnBoard || other.layer != tile.layer) continue;
      if (!_yOverlaps(tile, other)) continue;
      if (left) {
        if (other.x < tile.x && other.x + 2 >= tile.x) return true;
      } else if (other.x > tile.x && other.x <= tile.x + 2) {
        return true;
      }
    }
    return false;
  }

  static bool _yOverlaps(Tile a, Tile b) {
    return a.y < b.y + 2 && a.y + 2 > b.y;
  }

  static bool _overlaps(Tile a, Tile b) {
    return a.x < b.x + 2 && a.x + 2 > b.x && _yOverlaps(a, b);
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

  /// Подсказка для кнопки: одинаковые плитки, лучше из закрытого слоя.
  /// Свободная пара наверху — только если закрытой нет.
  /// [match] — в лотке или вторая кость на поле.
  ({Tile boardTile, Tile match})? findHint() {
    if (trayLiveCount >= trayCapacity && !trayHasPair()) return null;

    ({Tile boardTile, Tile match})? best;
    var bestScore = -1;

    void consider(Tile boardTile, Tile match) {
      final score = _hintPairScore(boardTile, match);
      if (score <= bestScore) return;
      bestScore = score;
      best = (boardTile: boardTile, match: match);
    }

    final liveTray = tray.where((t) => !t.removing).toList();
    final onBoard = tiles.where((t) => t.isOnBoard).toList();
    if (onBoard.isEmpty) return null;

    for (final boardTile in onBoard) {
      for (final trayTile in liveTray) {
        if (TileSymbols.matches(boardTile.symbol, trayTile.symbol)) {
          consider(boardTile, trayTile);
        }
      }
    }

    for (var i = 0; i < onBoard.length; i++) {
      for (var j = i + 1; j < onBoard.length; j++) {
        if (TileSymbols.matches(onBoard[i].symbol, onBoard[j].symbol)) {
          consider(onBoard[i], onBoard[j]);
        }
      }
    }
    return best;
  }

  /// Сейчас доступная пара: свободные кости или совпадение с лотком.
  ({Tile boardTile, Tile match})? findPlayableHint() {
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

  /// Закрытая кость (под верхней) важнее свободной наверху;
  /// из закрытых — та, что ближе к поверхности.
  int _hintPairScore(Tile boardTile, Tile match) {
    final trayBonus = match.inTray ? 1000000 : 0;
    return trayBonus + _hintTileScore(boardTile) + _hintTileScore(match);
  }

  int _hintTileScore(Tile tile) {
    if (!tile.isOnBoard) return 0;
    if (_isCoveredAmong(tile, tiles)) {
      return 20000 + tile.layer * 100 - _coverCount(tile);
    }
    if (!isFree(tile)) {
      return 10000 + tile.layer * 100;
    }
    return tile.layer;
  }

  int _coverCount(Tile tile) {
    var n = 0;
    for (final other in tiles) {
      if (other.id == tile.id) continue;
      if (!other.isOnBoard || other.layer <= tile.layer) continue;
      if (_overlaps(tile, other)) n++;
    }
    return n;
  }

  /// Магнит: сначала пара к плитке в лотке (с любого слоя), иначе свободная пара на поле.
  ({Tile boardTile, Tile match})? findMagnetPair() {
    final freeSlots = trayCapacity - trayLiveCount;
    final liveTray = tray.where((t) => !t.removing).toList();
    if (freeSlots >= 1 && liveTray.isNotEmpty) {
      final pulled = _magnetMatchForTray(liveTray);
      if (pulled != null) return pulled;
    }

    final hint = findPlayableHint();
    if (hint == null) return null;
    final needTwoSlots = hint.match.isOnBoard;
    if (needTwoSlots && freeSlots < 2) return null;
    if (!needTwoSlots && freeSlots < 1) return null;
    return hint;
  }

  /// Пара к лотку: свободная плитка предпочтительнее, иначе самая верхняя из закрытых.
  ({Tile boardTile, Tile match})? _magnetMatchForTray(List<Tile> liveTray) {
    Tile? bestBoard;
    Tile? bestTray;
    var bestRank = -1;
    for (final trayTile in liveTray) {
      for (final boardTile in tiles) {
        if (!boardTile.isOnBoard) continue;
        if (!TileSymbols.matches(boardTile.symbol, trayTile.symbol)) continue;
        final rank = (isFree(boardTile) ? 1000 : 0) + boardTile.layer;
        if (rank <= bestRank) continue;
        bestRank = rank;
        bestBoard = boardTile;
        bestTray = trayTile;
      }
    }
    if (bestBoard == null || bestTray == null) return null;
    return (boardTile: bestBoard, match: bestTray);
  }

  /// Последняя снятая пара (для анимации / undo).
  List<Tile> lastMatched = [];

  /// Клик по плитке на поле → в лоток (пары — после [resolveTray], обычно после полёта).
  /// [force] — магнит: можно снять даже закрытую плитку с любого слоя.
  MatchResult pick(Tile tile, {bool force = false}) {
    lastMatched = [];
    if (!tile.isOnBoard) return MatchResult.blocked;
    if (!force && !isFree(tile)) return MatchResult.blocked;
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

  /// Раскладывает пары на свободные места с конца решения — наверху есть ход.
  static List<Tile> _dealSolvable(
    List<LayoutPos> positions,
    List<String> symbols,
    Random rng,
  ) {
    final pairs = _pairQueue(symbols);
    for (var attempt = 0; attempt < 96; attempt++) {
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
