import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/board.dart';
import '../models/level_tile.dart';

/// Грузит JSON-раскладку из `assets/levels/` в [Board] Mahjong Rise.
class LevelLoader {
  LevelLoader._();

  static const vitaAsset = 'assets/levels/vita_screenshot.json';

  static Future<LevelFile> loadFile([String assetPath = vitaAsset]) async {
    final raw = await rootBundle.loadString(assetPath);
    return LevelFile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  /// Позиции из JSON, лица — как в обычном уровне (пары, решаемость).
  static Future<Board> loadBoard({
    String assetPath = vitaAsset,
    String? style,
    int pairSize = 4,
    int? uniqueCap,
    int? levelId,
  }) async {
    final file = await loadFile(assetPath);
    return Board.fromLevelFile(
      file,
      style: style,
      pairSize: pairSize,
      uniqueCap: uniqueCap,
      levelId: levelId,
    );
  }
}
