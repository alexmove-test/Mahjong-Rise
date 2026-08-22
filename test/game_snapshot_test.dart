import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/board.dart';
import 'package:mahjong/models/game_snapshot.dart';
import 'package:mahjong/models/tile.dart';

void main() {
  test('snapshot json round-trips board, tray and boosts', () {
    final tray = Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0, inTray: true);
    final board = Board(
      tiles: [
        tray,
        Tile(id: 1, symbol: 'B', layer: 1, x: 2, y: 4),
        Tile(id: 2, symbol: 'C', layer: 0, x: 6, y: 0, removed: true),
      ],
      layoutName: 'petal',
    );
    board.tray.add(tray);

    final snap = GameSnapshot.fromBoard(
      levelId: 4,
      board: board,
      score: 275,
      combo: 3,
      shuffles: 2,
      hints: 1,
      undos: 4,
      magnets: 1,
    );
    final encoded = jsonEncode(snap.toJson());
    final decoded = jsonDecode(encoded);
    expect(decoded, isA<Map>());
    final again = GameSnapshot.fromJson(
      Map<String, Object?>.from(decoded as Map),
    );

    expect(again.levelId, 4);
    expect(again.layoutName, 'petal');
    expect(again.score, 275);
    expect(again.combo, 3);
    expect(again.shuffles, 2);
    expect(again.hints, 1);
    expect(again.undos, 4);
    expect(again.magnets, 1);
    expect(again.trayIds, [0]);
    expect(again.tiles, hasLength(3));
    expect(again.tiles[1].symbol, 'B');
    expect(again.tiles[2].removed, isTrue);

    final restored = again.toBoard();
    expect(restored.layoutName, 'petal');
    expect(restored.tray, hasLength(1));
    expect(restored.tray.single.id, 0);
    expect(restored.tiles[0].inTray, isTrue);
    expect(restored.tiles[1].isOnBoard, isTrue);
    expect(restored.tiles[2].removed, isTrue);
  });

  test('removing tiles are stored as already taken off', () {
    final a = Tile(
      id: 0,
      symbol: 'A',
      layer: 0,
      x: 0,
      y: 0,
      inTray: true,
      removing: true,
    );
    final b = Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0);
    final board = Board(tiles: [a, b], layoutName: 'petal');
    board.tray.add(a);

    final snap = GameSnapshot.fromBoard(
      levelId: 1,
      board: board,
      score: 100,
      combo: 1,
      shuffles: 1,
      hints: 1,
      undos: 1,
      magnets: 1,
    );
    expect(snap.tiles[0].removed, isTrue);
    expect(snap.tiles[0].inTray, isFalse);
    expect(snap.trayIds, isEmpty);

    final restored = snap.toBoard();
    expect(restored.tiles[0].removed, isTrue);
    expect(restored.tray, isEmpty);
  });
}
