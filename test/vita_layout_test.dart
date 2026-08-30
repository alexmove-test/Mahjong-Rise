import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/board.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/services/level_loader.dart';
import 'package:mahjong/utils/layouts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('vita layout has 16 tiles in Rise half-cell coords', () {
    final positions = Layouts.vita();
    expect(positions.length, 16);
    expect(positions.length.isEven, isTrue);
    expect(Layouts.byName('vita'), positions);

    expect(positions.map((p) => p.$1).reduce(min), 0);
    expect(positions.map((p) => p.$1).reduce(max), 10);
    expect(positions.map((p) => p.$2).reduce(max), 6);
  });

  test('Board.fromLayout(vita) deals a playable field', () {
    final board = Board.fromLayout('vita', random: Random(7), style: 'classic');
    expect(board.tiles.length, 16);
    expect(board.layoutName, 'vita');
    expect(board.freeTiles(), isNotEmpty);
    expect(board.hasUsefulMove(), isTrue);
  });

  testWidgets('vita JSON loads and matches Layouts.vita positions', (
    tester,
  ) async {
    final file = await LevelLoader.loadFile();
    expect(file.levelId, 'vita_screenshot');
    expect(file.boardTiles.length, 16);

    final fromJson = {
      for (final tile in file.boardTiles) (tile.x, tile.y, tile.layer),
    };
    expect(fromJson, Layouts.vita().toSet());

    final board = Board.fromLevelFile(file, random: Random(3), style: 'classic');
    expect(board.tiles.length, 16);
    expect(board.freeTiles(), isNotEmpty);
  });

  test('vita field can be cleared by visible pairs', () {
    final board = Board.fromLayout(
      'vita',
      random: Random(21),
      style: 'classic',
      pairSize: 4,
    );
    expect(_clearByVisiblePairs(board), isTrue);
    expect(board.isWon, isTrue);
  });
}

bool _clearByVisiblePairs(Board board) {
  for (var step = 0; step < 400; step++) {
    if (board.isWon) return true;
    if (!board.hasUsefulMove()) return false;

    final free = board.freeTiles();
    Tile? pick;
    for (final trayTile in board.tray.where((t) => !t.removing)) {
      for (final tile in free) {
        if (tile.symbol == trayTile.symbol) {
          pick = tile;
          break;
        }
      }
      if (pick != null) break;
    }
    if (pick == null) {
      for (var i = 0; i < free.length; i++) {
        for (var j = i + 1; j < free.length; j++) {
          if (free[i].symbol == free[j].symbol) {
            pick = free[i];
            break;
          }
        }
        if (pick != null) break;
      }
    }
    if (pick == null) return false;

    board.pick(pick);
    board.resolveTray();
    for (final tile in board.tiles.where((t) => t.removing).toList()) {
      board.finishRemoval(tile);
    }
  }
  return board.isWon;
}
