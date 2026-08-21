import '../models/tile.dart';

enum UndoKind { collect, match }

class UndoEntry {
  const UndoEntry.collect({
    required this.tileId,
    required this.scoreBefore,
    required this.comboBefore,
  }) : kind = UndoKind.collect,
       matchedIds = const [];

  const UndoEntry.match({
    required this.tileId,
    required this.matchedIds,
    required this.scoreBefore,
    required this.comboBefore,
  }) : kind = UndoKind.match;

  final UndoKind kind;
  final int? tileId;
  final List<int> matchedIds;
  final int scoreBefore;
  final int comboBefore;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'tileId': tileId,
    'matchedIds': matchedIds,
    'scoreBefore': scoreBefore,
    'comboBefore': comboBefore,
  };

  static UndoEntry fromJson(Map<String, Object?> json) {
    final kind = json['kind'] == 'match' ? UndoKind.match : UndoKind.collect;
    final matched = (json['matchedIds'] as List?)?.whereType<int>().toList() ??
        const <int>[];
    if (kind == UndoKind.match) {
      return UndoEntry.match(
        tileId: json['tileId'] as int?,
        matchedIds: matched,
        scoreBefore: (json['scoreBefore'] as num?)?.toInt() ?? 0,
        comboBefore: (json['comboBefore'] as num?)?.toInt() ?? 0,
      );
    }
    return UndoEntry.collect(
      tileId: json['tileId'] as int?,
      scoreBefore: (json['scoreBefore'] as num?)?.toInt() ?? 0,
      comboBefore: (json['comboBefore'] as num?)?.toInt() ?? 0,
    );
  }
}

class TileSnap {
  const TileSnap({
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

  factory TileSnap.fromTile(Tile tile) {
    return TileSnap(
      id: tile.id,
      symbol: tile.symbol,
      x: tile.x,
      y: tile.y,
      layer: tile.layer,
      removed: tile.removed || tile.removing,
      inTray: tile.inTray && !tile.removed && !tile.removing,
    );
  }

  Tile toTile() {
    return Tile(
      id: id,
      symbol: symbol,
      x: x,
      y: y,
      layer: layer,
      removed: removed && !inTray,
      inTray: inTray,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'symbol': symbol,
    'x': x,
    'y': y,
    'layer': layer,
    'removed': removed,
    'inTray': inTray,
  };

  static TileSnap fromJson(Map<String, Object?> json) {
    return TileSnap(
      id: (json['id'] as num).toInt(),
      symbol: json['symbol'] as String? ?? '',
      x: (json['x'] as num?)?.toInt() ?? 0,
      y: (json['y'] as num?)?.toInt() ?? 0,
      layer: (json['layer'] as num?)?.toInt() ?? 0,
      removed: json['removed'] == true,
      inTray: json['inTray'] == true,
    );
  }
}

/// Mid-game table: one snapshot for the current party.
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
    this.undoStack = const [],
    this.coachStep,
    this.coachActive = false,
  });

  final int levelId;
  final String layoutName;
  final int score;
  final int combo;
  final int shuffles;
  final int hints;
  final int undos;
  final int magnets;
  final List<TileSnap> tiles;
  final List<int> trayIds;
  final List<UndoEntry> undoStack;
  final String? coachStep;
  final bool coachActive;

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
    'undoStack': [for (final entry in undoStack) entry.toJson()],
    'coachStep': coachStep,
    'coachActive': coachActive,
  };

  static GameSnapshot fromJson(Map<String, Object?> json) {
    final tilesRaw = json['tiles'] as List? ?? const [];
    final trayRaw = json['trayIds'] as List? ?? const [];
    final undoRaw = json['undoStack'] as List? ?? const [];
    return GameSnapshot(
      levelId: (json['levelId'] as num?)?.toInt() ?? 1,
      layoutName: json['layoutName'] as String? ?? 'petal',
      score: (json['score'] as num?)?.toInt() ?? 0,
      combo: (json['combo'] as num?)?.toInt() ?? 0,
      shuffles: (json['shuffles'] as num?)?.toInt() ?? 0,
      hints: (json['hints'] as num?)?.toInt() ?? 0,
      undos: (json['undos'] as num?)?.toInt() ?? 0,
      magnets: (json['magnets'] as num?)?.toInt() ?? 0,
      tiles: [
        for (final item in tilesRaw)
          if (item is Map)
            TileSnap.fromJson(Map<String, Object?>.from(item)),
      ],
      trayIds: [for (final id in trayRaw) (id as num).toInt()],
      undoStack: [
        for (final item in undoRaw)
          if (item is Map)
            UndoEntry.fromJson(Map<String, Object?>.from(item)),
      ],
      coachStep: json['coachStep'] as String?,
      coachActive: json['coachActive'] == true,
    );
  }
}
