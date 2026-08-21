import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/game_snapshot.dart';
import 'package:mahjong/models/tile.dart';

void main() {
  test('round-trips tiles, undo stack and coach step', () {
    final tile = Tile(id: 3, symbol: 'soft-01', layer: 1, x: 2, y: 4, inTray: true);
    final snap = GameSnapshot(
      levelId: 2,
      layoutName: 'ring',
      score: 150,
      combo: 2,
      shuffles: 3,
      hints: 1,
      undos: 4,
      magnets: 1,
      tiles: [TileSnap.fromTile(tile)],
      trayIds: const [3],
      undoStack: [
        UndoEntry.collect(tileId: 3, scoreBefore: 100, comboBefore: 1),
        UndoEntry.match(
          tileId: 4,
          matchedIds: const [1, 2],
          scoreBefore: 0,
          comboBefore: 0,
        ),
      ],
      coachStep: 'matchPair',
      coachActive: true,
    );

    final restored = GameSnapshot.fromJson(snap.toJson());
    expect(restored.levelId, 2);
    expect(restored.layoutName, 'ring');
    expect(restored.score, 150);
    expect(restored.trayIds, [3]);
    expect(restored.tiles.single.symbol, 'soft-01');
    expect(restored.undoStack, hasLength(2));
    expect(restored.undoStack.first.kind, UndoKind.collect);
    expect(restored.undoStack.last.matchedIds, [1, 2]);
    expect(restored.coachStep, 'matchPair');
    expect(restored.coachActive, isTrue);
  });

  test('removing tiles snapshot as already removed', () {
    final tile = Tile(
      id: 1,
      symbol: 'A',
      layer: 0,
      x: 0,
      y: 0,
      removing: true,
      inTray: true,
    );
    final snap = TileSnap.fromTile(tile);
    expect(snap.removed, isTrue);
    expect(snap.inTray, isFalse);
  });
}
