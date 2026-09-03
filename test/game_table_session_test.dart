import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/board.dart';
import 'package:mahjong/models/game_snapshot.dart';
import 'package:mahjong/models/game_table_session.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/models/tile.dart';

Tile _tile(int id, String symbol, {int x = 0, int y = 0}) {
  return Tile(id: id, symbol: symbol, x: x, y: y, layer: 0);
}

GameTableSession _session(Board board) {
  final session = GameTableSession();
  session.attachBoard(board);
  session.shufflesLeft = 2;
  session.hintsLeft = 2;
  session.undosLeft = 2;
  session.magnetsLeft = 2;
  return session;
}

void main() {
  test('collect then match awards combo points', () {
    final a = _tile(0, 'A');
    final a2 = _tile(1, 'A', x: 4);
    final b = _tile(2, 'B', y: 2);
    final b2 = _tile(3, 'B', x: 4, y: 2);
    final session = _session(Board(tiles: [a, a2, b, b2], layoutName: 'test'));

    expect(session.pickTile(a), MatchResult.collected);
    expect(
      session.resolveCollect(tileId: 0, scoreBefore: 0, comboBefore: 0).result,
      MatchResult.collected,
    );
    expect(session.score, 0);
    expect(session.combo, 0);

    expect(session.pickTile(a2), MatchResult.collected);
    final matched = session.resolveCollect(
      tileId: 1,
      scoreBefore: 0,
      comboBefore: 0,
    );
    expect(matched.result, MatchResult.matched);
    expect(session.combo, 1);
    expect(session.score, GameTableSession.pairPoints(comboAfter: 1));
  });

  test('second match grows combo and score', () {
    final tiles = [
      _tile(0, 'A'),
      _tile(1, 'A', x: 4),
      _tile(2, 'B', y: 2),
      _tile(3, 'B', x: 4, y: 2),
    ];
    final session = _session(Board(tiles: tiles, layoutName: 'test'));

    session.pickTile(tiles[0]);
    session.resolveCollect(tileId: 0, scoreBefore: 0, comboBefore: 0);
    session.pickTile(tiles[1]);
    session.resolveCollect(tileId: 1, scoreBefore: 0, comboBefore: 0);

    final scoreAfterFirst = session.score;
    session.pickTile(tiles[2]);
    session.resolveCollect(
      tileId: 2,
      scoreBefore: session.score,
      comboBefore: session.combo,
    );
    session.pickTile(tiles[3]);
    final win = session.resolveCollect(
      tileId: 3,
      scoreBefore: session.score,
      comboBefore: session.combo,
    );

    expect(win.result, MatchResult.win);
    expect(session.combo, 2);
    expect(
      session.score,
      scoreAfterFirst +
          GameTableSession.pairPoints(comboAfter: 2) +
          GameTableSession.winBonus,
    );
  });

  test('lose resets combo and keeps undo', () {
    final a = _tile(0, 'A');
    final b = _tile(1, 'B', x: 4);
    final c = _tile(2, 'C', y: 2);
    final d = _tile(3, 'D', x: 4, y: 2);
    final session = _session(Board(tiles: [a, b, c, d], layoutName: 'test'));
    session.combo = 3;

    for (final tile in [a, b, c, d]) {
      session.pickTile(tile);
    }
    final lose = session.resolveCollect(
      tileId: 3,
      scoreBefore: 0,
      comboBefore: 3,
    );
    expect(lose.result, MatchResult.lose);
    expect(session.combo, 0);
    expect(session.undoStack, isNotEmpty);
  });

  test('undo collect restores tile, score and charge', () {
    final a = _tile(0, 'A');
    final b = _tile(1, 'B', x: 4);
    final session = _session(Board(tiles: [a, b], layoutName: 'test'));
    session.undosLeft = 1;

    session.pickTile(a);
    session.resolveCollect(tileId: 0, scoreBefore: 0, comboBefore: 0);
    expect(session.board.tray, hasLength(1));

    final entry = session.takeUndo(fromLose: false);
    expect(entry, isNotNull);
    session.applyInstantUndo(entry!, fromLose: false);

    expect(a.isOnBoard, isTrue);
    expect(session.board.tray, isEmpty);
    expect(session.score, 0);
    expect(session.undosLeft, 0);
  });

  test('hint spends a charge only when a pair exists', () {
    final a = _tile(0, 'A');
    final a2 = _tile(1, 'A', x: 4);
    final session = _session(Board(tiles: [a, a2], layoutName: 'test'));
    session.hintsLeft = 1;

    final hint = session.consumeHint();
    expect(hint, isNotNull);
    expect(session.hintsLeft, 0);

    expect(session.consumeHint(), isNull);
    expect(session.hintsLeft, 0);
  });

  test('shuffle spends a charge and clears combo', () {
    final a = _tile(0, 'A');
    final a2 = _tile(1, 'A', x: 4);
    final session = _session(Board(tiles: [a, a2], layoutName: 'test'));
    session.shufflesLeft = 1;
    session.combo = 4;

    final outcome = session.shuffle();
    expect(outcome.applied, isTrue);
    expect(session.shufflesLeft, 0);
    expect(session.combo, 0);
  });

  test('grantBoost adds one charge', () {
    final session = GameTableSession()..resetFromLevel(Levels.byId(1));
    final hints = session.hintsLeft;
    session.grantBoost(RewardedBoost.hint);
    expect(session.hintsLeft, hints + 1);
  });

  test('grantBoost can add fifty magnet charges', () {
    final session = GameTableSession()..resetFromLevel(Levels.byId(1));
    final magnets = session.magnetsLeft;
    session.grantBoost(RewardedBoost.magnet, count: 50);
    expect(session.magnetsLeft, magnets + 50);
  });

  test('snapshot round-trips score and boosts', () {
    final a = _tile(0, 'A');
    final b = _tile(1, 'B', x: 4);
    final session = _session(Board(tiles: [a, b], layoutName: 'petal'));
    session.score = 275;
    session.combo = 3;
    session.shufflesLeft = 2;
    session.hintsLeft = 1;
    session.undosLeft = 4;
    session.magnetsLeft = 1;
    session.pickTile(a);

    final snap = session.snapshotFor(4);
    expect(snap.levelId, 4);
    expect(snap.score, 275);

    final restored = GameTableSession()..restore(snap);
    expect(restored.score, 275);
    expect(restored.combo, 3);
    expect(restored.shufflesLeft, 2);
    expect(restored.board.tray, hasLength(1));
    expect(GameSnapshot.fromJson(snap.toJson()).levelId, 4);
  });

  test('resetFromLevel copies magnet count from hints', () {
    final session = GameTableSession()..resetFromLevel(Levels.byId(1));
    expect(session.magnetsLeft, Levels.byId(1).hints);
    expect(session.shufflesLeft, Levels.byId(1).shuffles);
    expect(session.hasProgressToSave, isFalse);
  });

  test('resetFromLevel can keep a leftover hint count', () {
    final session = GameTableSession()
      ..resetFromLevel(Levels.byId(1), hintsLeft: 3);
    expect(session.hintsLeft, 3);
    expect(session.startHints, 3);
    expect(session.magnetsLeft, Levels.byId(1).hints);
  });
}
