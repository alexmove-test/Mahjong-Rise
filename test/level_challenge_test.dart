import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/board.dart';
import 'package:mahjong/models/game_snapshot.dart';
import 'package:mahjong/models/game_table_session.dart';
import 'package:mahjong/models/level_challenge.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/utils/layouts.dart';
import 'package:mahjong/widgets/game_action_bar.dart';
import 'package:mahjong/screens/game_screen.dart';
import 'package:mahjong/services/progress_store.dart';
import 'package:mahjong/widgets/tile_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  testWidgets('challenge goals and target marks fit a mobile game screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'progress.tableCoachDone': true});
    final progress = await ProgressStore.open();
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    for (final id in [6, 12, 18]) {
      await tester.pumpWidget(
        MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: GameScreen(
            key: ValueKey(id),
            level: Levels.byId(id),
            progress: progress,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final goal = switch (id) {
        6 => 'Tower: clear every layer',
        12 => 'Remove the two starred tiles · 0/2',
        _ => 'Clear the board without shuffling',
      };
      expect(find.text(goal), findsOneWidget);
      if (id == 12) {
        expect(
          tester
              .widgetList<TileWidget>(find.byType(TileWidget))
              .where((tile) => tile.isTarget),
          hasLength(2),
        );
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    }
  });
  test('challenges start gradually and daily games keep ordinary rules', () {
    for (var i = 1; i <= 5; i++) {
      expect(Levels.byId(i).challenge, LevelChallenge.none);
    }
    for (final offset in [0, 24, 96]) {
      expect(Levels.byId(6 + offset).challenge, LevelChallenge.compactTower);
      expect(Levels.byId(12 + offset).challenge, LevelChallenge.specialPair);
      expect(Levels.byId(18 + offset).challenge, LevelChallenge.noShuffle);
    }
    for (var day = 1; day <= 24; day++) {
      expect(
        Levels.dailyFor(DateTime(2026, 9, day)).challenge,
        LevelChallenge.none,
      );
    }
  });

  test('all tower variants deal even boards with an opening pair', () {
    for (var variant = 0; variant < 4; variant++) {
      final name = Layouts.variantName('compact-tower', variant);
      for (var seed = 0; seed < 12; seed++) {
        final board = Board.fromLayout(name, random: Random(seed));
        expect(board.total.isEven, isTrue);
        expect(board.hasUsefulMove(), isTrue);
        expect(board.tiles.map((t) => t.layer).reduce(max), greaterThan(2));
      }
    }
  });

  test('special tiles retain faces through shuffle and snapshot', () {
    final session = GameTableSession()..resetFromLevel(Levels.byId(12));
    final ids = session.board.targetTileIds.toSet();
    expect(ids, hasLength(2));
    final faces = {for (final id in ids) id: session.tileById(id).symbol};
    expect(TileSymbols.matches(faces.values.first, faces.values.last), isTrue);
    session.shuffle();
    for (final id in ids) {
      expect(session.tileById(id).symbol, faces[id]);
    }
    session.tileById(ids.first).removed = true;
    final restored = GameTableSession()
      ..restore(GameSnapshot.fromJson(session.snapshotFor(12).toJson()));
    expect(restored.board.targetTileIds, ids);
    expect(restored.board.targetsCleared, 1);
    expect(restored.isWon, isFalse);
  });

  test('removing both targets wins while ordinary tiles remain', () {
    final tiles = List.generate(
      4,
      (i) => Tile(id: i, symbol: i < 2 ? 'A' : 'B', x: i * 3, y: 0, layer: 0),
    );
    final board = Board(tiles: tiles)
      ..configureChallenge(LevelChallenge.specialPair);
    final session = GameTableSession()..attachBoard(board);
    for (final id in board.targetTileIds) {
      session.pickTile(session.tileById(id));
      session.resolveCollect(
        tileId: id,
        scoreBefore: session.score,
        comboBefore: session.combo,
      );
    }
    expect(session.isWon, isTrue);
    expect(board.remaining, 2);
    expect(session.score, 600);
  });

  test(
    'no-shuffle rule survives granted boosts and resume; old saves stay ordinary',
    () {
      final session = GameTableSession()..resetFromLevel(Levels.byId(18));
      session.grantBoost(RewardedBoost.shuffle);
      final before = session.snapshotFor(18).toJson();
      expect(session.shuffle().fail, ShuffleFail.challenge);
      expect(session.snapshotFor(18).toJson(), before);
      expect(session.board.shuffleRemaining(), isFalse);
      final restored = GameTableSession()
        ..restore(GameSnapshot.fromJson(before));
      expect(restored.shuffleAllowed, isFalse);
      before.remove('challenge');
      before.remove('targetTileIds');
      restored.restore(GameSnapshot.fromJson(before));
      expect(restored.shuffleAllowed, isTrue);
      expect(restored.board.challenge, LevelChallenge.none);
    },
  );

  testWidgets('shuffle button cannot offer ads during no-shuffle challenge', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GameActionBar(
            shufflesLeft: 5,
            magnetsLeft: 1,
            hintsLeft: 1,
            undosLeft: 1,
            enabled: true,
            canUndo: false,
            canUndoViaAd: false,
            adsAvailable: true,
            shuffleAllowed: false,
            onShuffle: () => taps++,
            onMagnet: () {},
            onHint: () {},
            onUndo: () {},
          ),
        ),
      ),
    );
    final button = tester.widget<GameActionButton>(
      find.byType(GameActionButton).first,
    );
    expect(button.enabled, isFalse);
    expect(button.tooltip, 'Shuffling is disabled for this challenge');
    await tester.tap(find.byIcon(Icons.shuffle_rounded));
    expect(taps, 0);
  });
}
