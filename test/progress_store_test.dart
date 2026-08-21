import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/game_snapshot.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('saves and restores a mid-game snapshot', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.open();
    final tile = Tile(id: 1, symbol: 'A', layer: 0, x: 0, y: 0, inTray: true);
    final snap = GameSnapshot(
      levelId: 1,
      layoutName: 'petal',
      score: 40,
      combo: 1,
      shuffles: 2,
      hints: 3,
      undos: 4,
      magnets: 3,
      tiles: [TileSnap.fromTile(tile)],
      trayIds: const [1],
      undoStack: [
        UndoEntry.collect(tileId: 1, scoreBefore: 0, comboBefore: 0),
      ],
      coachStep: 'tapFree',
      coachActive: true,
    );

    await store.saveSnapshot(snap);
    expect(store.hasSnapshotFor(1), isTrue);
    expect(store.savedSnapshot?.undoStack, hasLength(1));
    expect(store.savedSnapshot?.coachStep, 'tapFree');

    await store.clearSnapshot();
    expect(store.savedSnapshot, isNull);
  });
}
