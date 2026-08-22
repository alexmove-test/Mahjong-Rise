import 'board.dart';
import 'tile.dart';

/// Один слот незавершённой партии. [levelId] 0 — ежедневный стол.
class GameSnapshot {
  const GameSnapshot({
    required this.levelId,
    required this.layoutName,
    required this.score,
    required this.combo,
    required this.shuffles,
    required this.hints,
    required this.undos,
    required this.magnets,
    required this.tiles,
    required this.trayIds,
  });

  static const dailyLevelId = 0;

  final int levelId;
  final String layoutName;
  final int score;
  final int combo;
  final int shuffles;
  final int hints;
  final int undos;
  final int magnets;
  final List<TileSnapshot> tiles;
  final List<int> trayIds;

  factory GameSnapshot.fromBoard({
    required int levelId,
    required Board board,
    required int score,
    required int combo,
    required int shuffles,
    required int hints,
    required int undos,
    required int magnets,
  }) {
    final tiles = [
      for (final tile in board.tiles)
        TileSnapshot(
          id: tile.id,
          symbol: tile.symbol,
          x: tile.x,
          y: tile.y,
          layer: tile.layer,
          removed: tile.removed || tile.removing,
          inTray: tile.inTray && !tile.removing && !tile.removed,
        ),
    ];
    final trayIds = [
      for (final tile in board.tray)
        if (!tile.removing && !tile.removed) tile.id,
    ];
    return GameSnapshot(
      levelId: levelId,
      layoutName: board.layoutName,
      score: score,
      combo: combo,
      shuffles: shuffles,
      hints: hints,
      undos: undos,
      magnets: magnets,
      tiles: tiles,
      trayIds: trayIds,
    );
  }

  Board toBoard() {
    final restored = [
      for (final snap in tiles)
        Tile(
          id: snap.id,
          symbol: snap.symbol,
          x: snap.x,
          y: snap.y,
          layer: snap.layer,
          removed: snap.removed,
          inTray: snap.inTray && !snap.removed,
        ),
    ];
    final byId = {for (final tile in restored) tile.id: tile};
    final board = Board(tiles: restored, layoutName: layoutName);
    for (final id in trayIds) {
      final tile = byId[id];
      if (tile == null || !tile.inTray) continue;
      board.tray.add(tile);
    }
    return board;
  }

  Map<String, Object?> toJson() => {
    'levelId': levelId,
    'layoutName': layoutName,
    'score': score,
    'combo': combo,
    'shuffles': shuffles,
    'hints': hints,
    'undos': undos,
    'magnets': magnets,
    'tiles': [for (final tile in tiles) tile.toJson()],
    'trayIds': trayIds,
  };

  factory GameSnapshot.fromJson(Map<String, Object?> json) {
    final rawTiles = json['tiles'];
    final rawTray = json['trayIds'];
    return GameSnapshot(
      levelId: json['levelId'] as int? ?? 0,
      layoutName: json['layoutName'] as String? ?? 'petal',
      score: json['score'] as int? ?? 0,
      combo: json['combo'] as int? ?? 0,
      shuffles: json['shuffles'] as int? ?? 0,
      hints: json['hints'] as int? ?? 0,
      undos: json['undos'] as int? ?? 0,
      magnets: json['magnets'] as int? ?? 0,
      tiles: [
        if (rawTiles is List)
          for (final item in rawTiles)
            if (item is Map<String, Object?>) TileSnapshot.fromJson(item)
            else if (item is Map)
              TileSnapshot.fromJson(item.cast<String, Object?>()),
      ],
      trayIds: [
        if (rawTray is List)
          for (final id in rawTray)
            if (id is int) id,
      ],
    );
  }
}

class TileSnapshot {
  const TileSnapshot({
    required this.id,
    required this.symbol,
    required this.x,
    required this.y,
    required this.layer,
    required this.removed,
    required this.inTray,
  });

  final int id;
  final String symbol;
  final int x;
  final int y;
  final int layer;
  final bool removed;
  final bool inTray;

  Map<String, Object?> toJson() => {
    'id': id,
    'symbol': symbol,
    'x': x,
    'y': y,
    'layer': layer,
    'removed': removed,
    'inTray': inTray,
  };

  factory TileSnapshot.fromJson(Map<String, Object?> json) {
    return TileSnapshot(
      id: json['id'] as int? ?? 0,
      symbol: json['symbol'] as String? ?? '',
      x: json['x'] as int? ?? 0,
      y: json['y'] as int? ?? 0,
      layer: json['layer'] as int? ?? 0,
      removed: json['removed'] as bool? ?? false,
      inTray: json['inTray'] as bool? ?? false,
    );
  }
}
