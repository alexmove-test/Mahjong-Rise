import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/board.dart';
import 'package:mahjong/models/game_snapshot.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('fresh save is a first session', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.open();
    expect(store.hasCompletedAny, isFalse);
    expect(store.tableCoachDone, isFalse);
    expect(store.maxUnlocked, 1);
  });

  test('a win on level 1 leaves the hub path', () async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 2,
      'progress.stars.1': 1,
      'progress.best.1': 400,
    });
    final store = await ProgressStore.open();
    expect(store.hasCompletedAny, isTrue);
  });

  test('table coach completion persists', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.open();
    await store.markTableCoachDone();
    expect(store.tableCoachDone, isTrue);
  });

  test('cycle helpers follow the current plot not the whole campaign', () async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 25,
      'progress.stars.1': 1,
      'progress.stars.24': 2,
      'progress.best.24': 900,
    });
    final store = await ProgressStore.open();
    expect(store.isCycleComplete(0), isTrue);
    expect(store.isCycleUnlocked(1), isTrue);
    expect(store.unlockedInCycle(0), 24);
    expect(store.unlockedInCycle(1), 1);
    expect(store.starsInCycle(0), 3);
    expect(store.starsInCycle(1), 0);
  });

  test('snapshot round-trips through prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.open();
    await store.saveSnapshot(_sampleSnap(levelId: 1, score: 50));

    expect(store.hasSnapshotFor(1), isTrue);
    expect(store.hasSnapshotFor(2), isFalse);
    expect(store.savedSnapshot!.score, 50);
    expect(store.savedSnapshot!.trayIds, [0]);

    await store.clearSnapshot();
    expect(store.savedSnapshot, isNull);
    expect(store.hasSnapshotFor(1), isFalse);
  });

  test('same-day daily win does not grow the streak', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.open();
    final day = DateTime(2026, 8, 20);
    final first = await store.recordDailyWin(now: day);
    expect(first.counted, isTrue);
    expect(first.streak, 1);

    final again = await store.recordDailyWin(now: day);
    expect(again.counted, isFalse);
    expect(again.streak, 1);
    expect(again.rewarded, isFalse);
  });

  test('next day after a win grows the streak', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.open();
    await store.recordDailyWin(now: DateTime(2026, 8, 20));
    final next = await store.recordDailyWin(now: DateTime(2026, 8, 21));
    expect(next.counted, isTrue);
    expect(next.streak, 2);
    expect(store.visibleStreak(DateTime(2026, 8, 21)), 2);
  });

  test('skipping a day resets the streak', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.open();
    await store.recordDailyWin(now: DateTime(2026, 8, 20));
    expect(store.dailyStreak, 1);
    expect(store.visibleStreak(DateTime(2026, 8, 22)), 0);

    await store.expireStreakIfNeeded(DateTime(2026, 8, 22));
    expect(store.dailyStreak, 0);

    final next = await store.recordDailyWin(now: DateTime(2026, 8, 22));
    expect(next.counted, isTrue);
    expect(next.streak, 1);
  });

  test('streak 3 and 7 bank a hint and a shuffle', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.open();
    var day = DateTime(2026, 8, 1);
    var lastRewarded = false;
    for (var i = 0; i < 7; i++) {
      final result = await store.recordDailyWin(now: day);
      lastRewarded = result.rewarded;
      expect(result.rewarded, i == 2 || i == 6);
      day = day.add(const Duration(days: 1));
    }
    expect(lastRewarded, isTrue);
    expect(store.dailyStreak, 7);
    expect(store.bankedHints, 2);
    expect(store.bankedShuffles, 2);

    final spent = await store.consumeBankedBoosts();
    expect(spent.hints, 2);
    expect(spent.shuffles, 2);
    expect(store.bankedHints, 0);
    expect(store.bankedShuffles, 0);
  });
}

GameSnapshot _sampleSnap({required int levelId, int score = 50}) {
  final tray = Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0, inTray: true);
  final board = Board(
    tiles: [
      tray,
      Tile(id: 1, symbol: 'B', layer: 0, x: 4, y: 0),
    ],
    layoutName: 'petal',
  );
  board.tray.add(tray);
  return GameSnapshot.fromBoard(
    levelId: levelId,
    board: board,
    score: score,
    combo: 2,
    shuffles: 3,
    hints: 1,
    undos: 2,
    magnets: 1,
  );
}
