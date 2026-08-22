import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/board.dart';
import 'package:mahjong/models/game_snapshot.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/screens/game_screen.dart';
import 'package:mahjong/services/progress_store.dart';
import 'package:mahjong/utils/layouts.dart';
import 'package:mahjong/utils/tile_pyramid_position.dart';
import 'package:mahjong/widgets/game_board.dart';
import 'package:mahjong/widgets/tile_flight.dart';
import 'package:mahjong/widgets/tile_painter.dart';
import 'package:mahjong/widgets/tile_symbol_image.dart';
import 'package:mahjong/widgets/tile_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all named layouts produce a non-empty even tile count', () {
    const names = [
      'petal',
      'seed',
      'bloom',
      'meadow',
      'grove',
      'wave',
      'garden',
      'pyramid',
      'fan',
      'fort',
      'lotus',
      'koi',
      'vine',
      'tower',
      'festival',
      'temple',
      'pavilion',
      'dragon',
      'turtle',
    ];
    for (final name in names) {
      final positions = Layouts.byName(name);
      expect(positions, isNotEmpty, reason: name);
      expect(
        positions.length.isEven,
        isTrue,
        reason: '$name ${positions.length}',
      );

      final minX = positions.map((p) => p.$1).reduce(min);
      final maxX = positions.map((p) => p.$1).reduce(max);
      final minY = positions.map((p) => p.$2).reduce(min);
      final maxY = positions.map((p) => p.$2).reduce(max);
      final widthTiles = (maxX - minX + 2) / 2;
      final heightTiles = (maxY - minY + 2) / 2;
      expect(widthTiles, lessThanOrEqualTo(6), reason: '$name width');
      expect(heightTiles, lessThanOrEqualTo(5), reason: '$name height');
      expect(
        positions.map((p) => p.$3).reduce(max),
        greaterThanOrEqualTo(2),
        reason: '$name should stack in depth',
      );
    }
  });

  testWidgets('GameBoard shows tiles on the first frame', (tester) async {
    final board = Board.fromLayout('petal', random: Random(1));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 720,
            child: GameBoard(
              board: board,
              onTileTap: (_, _) {},
              onTileRemoveComplete: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(TileWidget), findsNWidgets(board.tiles.length));
    expect(find.byType(TileMappedSprite), findsWidgets);
    expect(find.byType(TilePyramidShadowLayer), findsWidgets);

    for (final tile in tester.widgetList<TileWidget>(find.byType(TileWidget))) {
      final box = tester.renderObject<RenderBox>(find.byWidget(tile));
      expect(box.size.width, greaterThan(20));
      expect(box.size.height, greaterThan(20));
    }
  });

  testWidgets('deep layouts keep late-game tiles readable', (tester) async {
    final board = Board.fromLayout('dragon', random: Random(1));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 720,
            child: GameBoard(
              board: board,
              onTileTap: (_, _) {},
              onTileRemoveComplete: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byType(TileWidget), findsWidgets);
    for (final tile in tester.widgetList<TileWidget>(find.byType(TileWidget))) {
      expect(tile.width, greaterThan(50));
    }
  });

  testWidgets('GameBoard scale stays fixed as tiles leave the board', (
    tester,
  ) async {
    final board = Board.fromLayout('petal', random: Random(1));

    Widget app() => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 720,
          child: GameBoard(
            board: board,
            onTileTap: (_, _) {},
            onTileRemoveComplete: (_) {},
          ),
        ),
      ),
    );

    await tester.pumpWidget(app());
    final firstTile = tester.widget<TileWidget>(find.byType(TileWidget).first);
    final firstLogical = Size(firstTile.width, firstTile.height);
    final keepId = firstTile.tile.id;
    final keepFinder = find.byWidgetPredicate(
      (w) => w is TileWidget && w.tile.id == keepId,
    );
    final keepRect = tester.getRect(keepFinder);

    for (final tile in board.tiles.where((t) => t.id != keepId)) {
      tile.inTray = true;
    }

    await tester.pumpWidget(app());
    expect(find.byType(TileWidget), findsOneWidget);

    final remaining = tester.widget<TileWidget>(find.byType(TileWidget));
    expect(remaining.width, firstLogical.width);
    expect(remaining.height, firstLogical.height);
    expect(tester.getRect(keepFinder), keepRect);
  });

  test('symbol sits on the ceramic face, not the ice rim', () {
    const size = Size(80, 92);
    final face = TileBaseLayout.faceRectOf(size);
    final symbol = TileBaseLayout.symbolRectOf(size);
    expect(face.right, lessThan(size.width));
    expect(face.bottom, lessThan(size.height));
    expect(symbol.left, greaterThanOrEqualTo(face.left));
    expect(symbol.top, greaterThanOrEqualTo(face.top));
    expect(symbol.right, lessThanOrEqualTo(face.right));
    expect(symbol.bottom, lessThanOrEqualTo(face.bottom));
  });

  testWidgets('TileWidget tints only the locked bone, not the icon', (
    tester,
  ) async {
    final free = Tile(id: 1, symbol: 'soft-01', layer: 1, x: 0, y: 0);
    final locked = Tile(id: 2, symbol: 'soft-01', layer: 0, x: 2, y: 0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              TileWidget(
                key: const Key('free'),
                tile: free,
                width: 64,
                height: 74,
                isSelected: false,
                isFree: true,
              ),
              TileWidget(
                key: const Key('locked'),
                tile: locked,
                width: 64,
                height: 74,
                isSelected: false,
                isFree: false,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(TileMappedSprite), findsWidgets);
    expect(find.byType(TilePyramidShadowLayer), findsNWidgets(2));
    expect(find.byType(TileSymbolImage), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byKey(const Key('locked')),
        matching: find.byType(ColorFiltered),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('free')),
        matching: find.byType(ColorFiltered),
      ),
      findsNothing,
    );
  });

  testWidgets('dark game backdrop uses felt.png under the vignette', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: MahjongScreenBackdrop(dark: true)),
    );

    final felt = tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).any(
      (box) {
        final decoration = box.decoration;
        if (decoration is! BoxDecoration) return false;
        final image = decoration.image?.image;
        return image is AssetImage && image.assetName == 'assets/felt.png';
      },
    );
    expect(felt, isTrue);
  });

  testWidgets('GameScreen hosts a visible board', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final progress = await ProgressStore.open();

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byType(GameBoard), findsOneWidget);
    expect(find.byType(TileWidget), findsWidgets);
    expect(find.text('0'), findsWidgets);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Take only a free top tile'), findsOneWidget);
    expect(find.text('0/16'), findsNothing);
    expect(find.text('1x'), findsNothing);
  });

  testWidgets('GameScreen restores a matching snapshot', (tester) async {
    SharedPreferences.setMockInitialValues({'progress.tableCoachDone': true});
    final progress = await ProgressStore.open();
    await progress.saveSnapshot(
      _boardSnapshot(levelId: 1, score: 777, symbol: 'keep-me'),
    );

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('777'), findsOneWidget);
    expect(find.text('keep-me'), findsNothing);
    expect(progress.savedSnapshot?.score, 777);
  });

  testWidgets('Retry clears the in-progress snapshot', (tester) async {
    SharedPreferences.setMockInitialValues({'progress.tableCoachDone': true});
    final progress = await ProgressStore.open();
    await progress.saveSnapshot(_boardSnapshot(levelId: 1, score: 777));

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byIcon(Icons.menu_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(progress.savedSnapshot, isNull);
    expect(find.text('777'), findsNothing);
  });

  testWidgets('another level does not restore a foreign snapshot', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 2,
      'progress.tableCoachDone': true,
    });
    final progress = await ProgressStore.open();
    await progress.saveSnapshot(_boardSnapshot(levelId: 1, score: 777));

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(level: Levels.byId(2), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('777'), findsNothing);
    expect(progress.hasSnapshotFor(1), isTrue);
    expect(progress.savedSnapshot?.score, 777);
    expect(progress.hasSnapshotFor(2), isFalse);
  });

  testWidgets('shuffle does not spend a boost when no tiles are free', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'progress.tableCoachDone': true});
    final progress = await ProgressStore.open();
    final tiles = [
      Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0, inTray: true),
      Tile(id: 1, symbol: 'B', layer: 0, x: 4, y: 0, inTray: true),
      Tile(id: 2, symbol: 'C', layer: 0, x: 8, y: 0, inTray: true),
    ];
    final board = Board(tiles: tiles, layoutName: 'petal');
    board.tray.addAll(tiles);
    await progress.saveSnapshot(
      GameSnapshot.fromBoard(
        levelId: 1,
        board: board,
        score: 40,
        combo: 0,
        shuffles: 2,
        hints: 1,
        undos: 1,
        magnets: 1,
      ),
    );

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Shuffle'));
    await tester.pump();

    expect(find.text('No free tiles'), findsOneWidget);
    expect(progress.savedSnapshot?.shuffles, 2);
  });

  testWidgets('hint highlights both tiles of a matching pair', (tester) async {
    SharedPreferences.setMockInitialValues({
      'progress.tableCoachDone': true,
      'tutorial.skipped': true,
      'tutorial.collect': true,
      'tutorial.match': true,
      'tutorial.layers': true,
      'tutorial.boosts': true,
    });
    final progress = await ProgressStore.open();
    final board = Board(
      tiles: [
        Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
        Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0),
        Tile(id: 2, symbol: 'B', layer: 0, x: 8, y: 0),
      ],
      layoutName: 'petal',
    );
    await progress.saveSnapshot(
      GameSnapshot.fromBoard(
        levelId: 1,
        board: board,
        score: 0,
        combo: 0,
        shuffles: 1,
        hints: 2,
        undos: 1,
        magnets: 1,
      ),
    );

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester
          .widgetList<TileWidget>(find.byType(TileWidget))
          .where((w) => w.isHinted),
      isEmpty,
    );

    await tester.tap(find.byTooltip('Hint'));
    await tester.pump();

    final hinted = tester
        .widgetList<TileWidget>(find.byType(TileWidget))
        .where((w) => w.isHinted)
        .map((w) => w.tile.id)
        .toSet();
    expect(hinted, {0, 1});
    expect(progress.savedSnapshot?.hints, 1);
  });

  testWidgets('magnet clears a matching pair from the board', (tester) async {
    SharedPreferences.setMockInitialValues({'progress.tableCoachDone': true});
    final progress = await ProgressStore.open();
    final board = Board(
      tiles: [
        Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
        Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0),
        Tile(id: 2, symbol: 'B', layer: 0, x: 8, y: 0),
      ],
      layoutName: 'petal',
    );
    await progress.saveSnapshot(
      GameSnapshot.fromBoard(
        levelId: 1,
        board: board,
        score: 0,
        combo: 0,
        shuffles: 1,
        hints: 1,
        undos: 1,
        magnets: 2,
      ),
    );

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Magnet'));
    await tester.pump();

    final onBoard = tester
        .widgetList<TileWidget>(find.byType(TileWidget))
        .where((w) => !w.compact && w.tile.isOnBoard)
        .map((w) => w.tile.id)
        .toSet();
    expect(onBoard, {2});
    expect(progress.savedSnapshot?.magnets, 1);
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('tapping a free tile flies it into the tray', (tester) async {
    SharedPreferences.setMockInitialValues({'progress.tableCoachDone': true});
    final progress = await ProgressStore.open();
    final board = Board(
      tiles: [
        Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
        Tile(id: 1, symbol: 'B', layer: 0, x: 4, y: 0),
        Tile(id: 2, symbol: 'C', layer: 0, x: 8, y: 0),
      ],
      layoutName: 'petal',
    );
    await progress.saveSnapshot(
      GameSnapshot.fromBoard(
        levelId: 1,
        board: board,
        score: 0,
        combo: 0,
        shuffles: 1,
        hints: 1,
        undos: 1,
        magnets: 1,
      ),
    );

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final onBoard = find.byWidgetPredicate(
      (w) => w is TileWidget && !w.compact && w.tile.id == 0,
    );
    expect(onBoard, findsOneWidget);
    await tester.tap(onBoard);
    await tester.pump();

    expect(find.byType(TileFlightOverlay), findsOneWidget);
    expect(onBoard, findsNothing);

    await tester.pump(TileFlightOverlay.duration);
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(TileFlightOverlay), findsNothing);
    expect(
      tester
          .widgetList<TileWidget>(find.byType(TileWidget))
          .where((w) => w.compact && w.tile.id == 0),
      isNotEmpty,
    );
  });

  testWidgets('watching a simulated ad grants a hint', (tester) async {
    SharedPreferences.setMockInitialValues({'progress.tableCoachDone': true});
    final progress = await ProgressStore.open();
    final board = Board(
      tiles: [
        Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
        Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0),
        Tile(id: 2, symbol: 'B', layer: 0, x: 8, y: 0),
      ],
      layoutName: 'petal',
    );
    await progress.saveSnapshot(
      GameSnapshot.fromBoard(
        levelId: 1,
        board: board,
        score: 0,
        combo: 0,
        shuffles: 1,
        hints: 0,
        undos: 1,
        magnets: 1,
      ),
    );

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Watch ad → Hint'));
    await tester.pump();
    expect(find.text('Simulated ad'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pump();

    expect(find.text('Simulated ad'), findsNothing);

    final hinted = tester
        .widgetList<TileWidget>(find.byType(TileWidget))
        .where((w) => w.isHinted)
        .map((w) => w.tile.id)
        .toSet();
    expect(hinted, {0, 1});
  });
}

GameSnapshot _boardSnapshot({
  required int levelId,
  required int score,
  String symbol = 'A',
}) {
  final board = Board(
    tiles: [
      Tile(id: 0, symbol: symbol, layer: 0, x: 0, y: 0),
      Tile(id: 1, symbol: 'B', layer: 0, x: 4, y: 0),
    ],
    layoutName: 'petal',
  );
  return GameSnapshot.fromBoard(
    levelId: levelId,
    board: board,
    score: score,
    combo: 0,
    shuffles: 1,
    hints: 1,
    undos: 1,
    magnets: 1,
  );
}
