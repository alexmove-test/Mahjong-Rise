import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/board.dart';
import 'package:mahjong/models/first_table_coach.dart';
import 'package:mahjong/models/tile.dart';

void main() {
  test('starts on tapFree and advances to matchPair on collect', () {
    final coach = FirstTableCoach(active: true);
    expect(coach.step, TableCoachStep.tapFree);
    coach.onCollected();
    expect(coach.step, TableCoachStep.matchPair);
    expect(coach.active, isTrue);
  });

  test('match jumps to trayLimit then completes', () {
    final coach = FirstTableCoach(active: true);
    coach.onMatched();
    expect(coach.step, TableCoachStep.trayLimit);
    expect(coach.nearTray, isTrue);
    coach.onMatched();
    expect(coach.finished, isTrue);
    expect(coach.active, isFalse);
  });

  test('focuses a matching pair when one exists', () {
    final a = Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0);
    final b = Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0);
    final board = Board(tiles: [a, b]);
    final coach = FirstTableCoach(active: true);
    expect(coach.focusIds(board), {0, 1});
  });
}
