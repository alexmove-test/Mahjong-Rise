import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/board.dart';
import 'package:mahjong/models/first_table_coach.dart';
import 'package:mahjong/models/tile.dart';

Board _boardWithCoveredTile() {
  return Board(
    tiles: [
      Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
      Tile(id: 1, symbol: 'A', layer: 1, x: 0, y: 0),
      Tile(id: 2, symbol: 'B', layer: 0, x: 4, y: 0),
      Tile(id: 3, symbol: 'B', layer: 0, x: 8, y: 0),
    ],
  );
}

void main() {
  test('inactive coach has no message surface', () {
    final coach = FirstTableCoach(active: false);
    expect(coach.active, isFalse);
    expect(coach.focusIds(_boardWithCoveredTile()), isEmpty);
  });

  test('three table steps follow collect then match', () {
    final coach = FirstTableCoach(active: true);
    final board = _boardWithCoveredTile();

    expect(coach.message, FirstTableCoach.tapFreeText);
    expect(coach.focusIds(board), {1});
    expect(coach.nearTray, isFalse);

    coach.onCollected();
    expect(coach.step, TableCoachStep.matchPair);
    expect(coach.message, FirstTableCoach.matchPairText);
    expect(coach.focusIds(board), {2, 3});

    coach.onMatched();
    expect(coach.step, TableCoachStep.trayLimit);
    expect(coach.message, FirstTableCoach.trayLimitText);
    expect(coach.nearTray, isTrue);

    coach.onCollected();
    expect(coach.active, isFalse);
    expect(coach.finished, isTrue);
  });

  test('win completes the lesson even mid-step', () {
    final coach = FirstTableCoach(active: true);
    coach.onCollected();
    coach.onWin();
    expect(coach.active, isFalse);
    expect(coach.finished, isTrue);
  });

  test('reset keeps an unfinished lesson on the first cue', () {
    final coach = FirstTableCoach(active: true);
    coach.onCollected();
    coach.resetIfActive();
    expect(coach.step, TableCoachStep.tapFree);
    expect(coach.active, isTrue);
  });
}
