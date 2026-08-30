/// Плитка из JSON-уровня (`assets/levels/*.json`).
class LevelTileDef {
  const LevelTileDef({
    required this.id,
    required this.type,
    required this.kind,
    required this.x,
    required this.y,
    required this.layer,
    this.symbol,
    this.zone = 'board',
  });

  final String id;

  /// flower | bamboo | hieroglyph | special
  final String type;
  final String kind;
  final int x;
  final int y;
  final int layer;
  final String? symbol;
  final String zone;

  bool get isOnBoard => zone == 'board';

  factory LevelTileDef.fromJson(Map<String, dynamic> json) {
    return LevelTileDef(
      id: json['id'] as String,
      type: json['type'] as String,
      kind: json['kind'] as String,
      x: json['x'] as int,
      y: json['y'] as int,
      layer: json['layer'] as int? ?? 0,
      symbol: json['symbol'] as String?,
      zone: json['zone'] as String? ?? 'board',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'kind': kind,
    'x': x,
    'y': y,
    'layer': layer,
    if (symbol != null) 'symbol': symbol,
    'zone': zone,
  };
}

class LevelFile {
  const LevelFile({
    required this.levelId,
    required this.layout,
    required this.tiles,
  });

  final String levelId;
  final String layout;
  final List<LevelTileDef> tiles;

  List<LevelTileDef> get boardTiles =>
      tiles.where((t) => t.isOnBoard).toList(growable: false);

  factory LevelFile.fromJson(Map<String, dynamic> json) {
    final raw = json['tiles'] as List<dynamic>;
    return LevelFile(
      levelId: json['levelId'] as String? ?? 'unknown',
      layout: json['layout'] as String? ?? 'vita',
      tiles: [
        for (final item in raw)
          LevelTileDef.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
    );
  }
}
