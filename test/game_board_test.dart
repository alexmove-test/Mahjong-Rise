import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/board.dart';
import 'package:mahjong/models/game_snapshot.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/screens/game_screen.dart';
import 'package:mahjong/models/table_look.dart';
import 'package:mahjong/services/locked_tile_dim_controller.dart';
import 'package:mahjong/services/locked_tile_dim_store.dart';
import 'package:mahjong/services/table_look_controller.dart';
import 'package:mahjong/services/table_look_store.dart';
import 'package:mahjong/services/progress_store.dart';
import 'package:mahjong/utils/layouts.dart';
import 'package:mahjong/utils/tile_pyramid_position.dart';
import 'package:mahjong/widgets/game_action_bar.dart';
import 'package:mahjong/widgets/game_board.dart';
import 'package:mahjong/widgets/game_hud.dart';
import 'package:mahjong/widgets/table_theme.dart';
import 'package:mahjong/widgets/tile_canvas.dart';
import 'package:mahjong/widgets/tile_glyph.dart';
import 'package:mahjong/widgets/tile_flight.dart';
import 'package:mahjong/widgets/tile_painter.dart';
import 'package:mahjong/widgets/tile_symbol_image.dart';
import 'package:mahjong/widgets/tile_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all named layouts produce a non-empty even tile count', () {
    const names = [
      'petal',
      'seed',
      'buds',
      'bloom',
      'glade',
      'meadow',
      'grove',
      'wave',
      'stream',
      'garden',
      'pyramid',
      'gazebo',
      'fan',
      'fort',
      'peacock',
      'lotus',
      'pond',
      'koi',
      'lake',
      'vine',
      'tower',
      'ivy',
      'festival',
      'lanterns',
      'pavilion',
      'temple',
      'dragon',
      'turtle',
      'sky',
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
      expect(minX, greaterThanOrEqualTo(0), reason: name);
      expect(minY, greaterThanOrEqualTo(0), reason: name);
      expect(maxX, lessThanOrEqualTo(Layouts.playfieldMaxX), reason: name);
      expect(maxY, lessThanOrEqualTo(Layouts.playfieldMaxY), reason: name);
    }
  });

  test('story layouts each have a distinct silhouette', () {
    final fingerprints = <String>{};
    for (final level in Levels.all.take(Levels.storyLength)) {
      final positions = Layouts.byName(level.layout);
      final cells = [for (final p in positions) '${p.$1},${p.$2},${p.$3}']
        ..sort();
      expect(
        fingerprints.add(cells.join(';')),
        isTrue,
        reason: 'level ${level.id} ${level.layout} repeats a silhouette',
      );
    }
    expect(fingerprints, hasLength(Levels.storyLength));
  });

  testWidgets('GameBoard shows tiles on the first frame', (tester) async {
    final board = Board.fromLayout('petal', random: Random(1));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
    expect(find.byType(TileBodySprite), findsWidgets);
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
      expect(tile.width, greaterThan(62));
    }
  });

  testWidgets('shallow and deep layouts keep the same tile scale', (
    tester,
  ) async {
    Future<double> widthOf(String layout) async {
      final board = Board.fromLayout(layout, random: Random(1));
      await tester.pumpWidget(
        MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
      return tester.widget<TileWidget>(find.byType(TileWidget).first).width;
    }

    final petal = await widthOf('petal');
    final dragon = await widthOf('dragon');
    expect(dragon, closeTo(petal, 0.5));
    expect(dragon, greaterThan(62));
  });

  testWidgets('GameBoard tiles fill the playfield width', (tester) async {
    final board = Board.fromLayout('garden', random: Random(1));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

    final tile = tester.widget<TileWidget>(find.byType(TileWidget).first);
    expect(tile.width, greaterThan(62));
    expect(tile.width, lessThan(72));
    expect(tile.height / tile.width, closeTo(GameBoard.tileAspect, 0.01));

    var minLeft = double.infinity;
    var maxRight = double.negativeInfinity;
    for (final widget in tester.widgetList<TileWidget>(
      find.byType(TileWidget),
    )) {
      final rect = tester.getRect(find.byWidget(widget));
      minLeft = min(minLeft, rect.left);
      maxRight = max(maxRight, rect.right);
    }
    expect(maxRight - minLeft, greaterThan(370));
    expect(maxRight - minLeft, lessThanOrEqualTo(402));
  });

  testWidgets('GameBoard scale stays fixed as tiles leave the board', (
    tester,
  ) async {
    final board = Board.fromLayout('petal', random: Random(1));

    Widget app() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

  test('tiles are rectangular like a standard mahjong bone', () {
    expect(GameBoard.tileAspect, closeTo(TileBaseLayout.spriteAspect, 0.001));
    expect(GameBoard.tileAspect, greaterThan(1.3));
    expect(
      GameBoard.traySlotH / GameBoard.traySlotW,
      closeTo(GameBoard.tileAspect, 0.01),
    );
    expect(GameBoard.trayBarH, greaterThan(GameBoard.traySlotH));
  });

  test('casual tiles are square squircles with a solid white face', () {
    expect(CasualTileLayout.aspect, 1.0);
    expect(GameBoard.tileAspectOf(true), 1.0);
    expect(GameBoard.tileGapFactorOf(false), GameBoard.tileGapFactor);
    expect(GameBoard.tileGapFactorOf(true), GameBoard.casualTileGapFactor);
    expect(GameBoard.casualTileGapFactor, lessThan(GameBoard.tileGapFactor));
    expect(GameBoard.casualTileScale, 1.3);
    expect(GameBoard.casualTileSpacingBoost, 1.2);
    expect(GameBoard.traySlotHeightOf(true), GameBoard.traySlotW);
    expect(
      CasualTileLayout.cornerRadius(const Size(80, 80)),
      closeTo(19.2, 0.05),
    );
    expect(TableUi.tileFace, const Color(0xFFFFFFFF));
    expect(TableUi.tileFaceLo, const Color(0xFFFFFFFF));
  });

  test('casual symbol window sits inside the squircle, classic stays 3:4', () {
    const casualSize = Size(80, 80);
    final casualSymbol = CasualTileLayout.symbolRectOf(casualSize);
    expect(casualSymbol.width / casualSymbol.height, closeTo(1.0, 0.001));
    expect(CasualTileLayout.symbolInsetX, 0.22);
    expect(CasualTileLayout.symbolInsetX, greaterThan(TileCanvas.symbolInset));
    expect(
      CasualTileLayout.containsPoint(casualSize, casualSymbol.topLeft),
      isTrue,
    );
    expect(
      CasualTileLayout.containsPoint(casualSize, casualSymbol.topRight),
      isTrue,
    );
    expect(
      CasualTileLayout.containsPoint(casualSize, casualSymbol.bottomLeft),
      isTrue,
    );
    expect(
      CasualTileLayout.containsPoint(casualSize, casualSymbol.bottomRight),
      isTrue,
    );

    final classicSize = Size(80, 80 * TileBaseLayout.spriteAspect);
    final classicSymbol = TileCanvas.symbolRectOf(classicSize);
    expect(
      classicSymbol.width / classicSymbol.height,
      closeTo(TileFaceArt.widthOverHeight, 0.01),
    );
    expect(TileCanvas.symbolInset, 0.14);
    expect(
      TileCanvas.containsFacePoint(classicSize, classicSymbol.topLeft),
      isTrue,
    );
    expect(
      TileCanvas.containsFacePoint(classicSize, classicSymbol.topRight),
      isTrue,
    );
    expect(
      TileCanvas.containsFacePoint(classicSize, classicSymbol.bottomLeft),
      isTrue,
    );
    expect(
      TileCanvas.containsFacePoint(classicSize, classicSymbol.bottomRight),
      isTrue,
    );
  });

  test('casual 512 fruit with 84% fill stays inside the squircle', () {
    const size = Size(80, 80);
    final window = CasualTileLayout.symbolRectOf(size);
    // fruit/02.png: ~14% side pad, 7% top, 9% bottom, 84% fill height.
    final content = Rect.fromLTRB(
      window.left + window.width * 0.14,
      window.top + window.height * 0.07,
      window.right - window.width * 0.14,
      window.bottom - window.height * 0.09,
    );
    expect(CasualTileLayout.containsPoint(size, content.topLeft), isTrue);
    expect(CasualTileLayout.containsPoint(size, content.topRight), isTrue);
    expect(CasualTileLayout.containsPoint(size, content.bottomLeft), isTrue);
    expect(CasualTileLayout.containsPoint(size, content.bottomRight), isTrue);
    expect(content.width / size.width, lessThan(0.52));
  });

  testWidgets('casual GameBoard tiles are square', (tester) async {
    final board = Board.fromLayout('garden', random: Random(1));
    final look = TableLookController(TableLookStore.memory());
    await look.setLook(TableLook.casual);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TableLookScope(
            controller: look,
            child: SizedBox(
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
      ),
    );

    final tile = tester.widget<TileWidget>(find.byType(TileWidget).first);
    expect(tile.height / tile.width, closeTo(1.0, 0.01));
    // 400×720: +30% давало ~91 px вплотную. Шаг +20% оставляет кость ~79 px.
    expect(tile.width, closeTo(79.0, 1.5));

    var minLeft = double.infinity;
    var maxRight = double.negativeInfinity;
    var minTop = double.infinity;
    var maxBottom = double.negativeInfinity;
    for (final widget in tester.widgetList<TileWidget>(
      find.byType(TileWidget),
    )) {
      final rect = tester.getRect(find.byWidget(widget));
      minLeft = min(minLeft, rect.left);
      maxRight = max(maxRight, rect.right);
      minTop = min(minTop, rect.top);
      maxBottom = max(maxBottom, rect.bottom);
    }
    expect(maxRight - minLeft, lessThanOrEqualTo(400.5));
    expect(maxBottom - minTop, lessThanOrEqualTo(720.5));
  });

  testWidgets('casual tiles overlap and grow on the same 6x5 field', (
    tester,
  ) async {
    final board = Board.fromLayout('garden', random: Random(1));

    Future<double> widthOf(TableLook look) async {
      final controller = TableLookController(TableLookStore.memory());
      await controller.setLook(look);
      await tester.pumpWidget(
        MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TableLookScope(
              controller: controller,
              child: SizedBox(
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
        ),
      );
      return tester.widget<TileWidget>(find.byType(TileWidget).first).width;
    }

    final classic = await widthOf(TableLook.classic);
    final casual = await widthOf(TableLook.casual);
    expect(casual, greaterThan(classic * 1.05));
  });

  testWidgets('casual faces stay inside the square tile', (tester) async {
    final look = TableLookController(TableLookStore.memory());
    await look.setLook(TableLook.casual);
    const symbols = [
      'fruit-01',
      'fruit-02',
      'fruit-09',
      'fruit-20',
      'soft-01',
      'shape-01',
      'number-01',
      'bamboo-09',
      'character-05',
    ];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TableLookScope(
            controller: look,
            child: Row(
              children: [
                for (var i = 0; i < symbols.length; i++)
                  TileWidget(
                    key: Key(symbols[i]),
                    tile: Tile(id: i, symbol: symbols[i], layer: 0, x: 0, y: 0),
                    width: 72,
                    height: 72,
                    isSelected: false,
                    isFree: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(ClipRRect), findsWidgets);
    expect(find.byType(ClipRect), findsWidgets);
    for (final symbol in symbols) {
      final tile = tester.widget<TileWidget>(find.byKey(Key(symbol)));
      expect(tile.width, 72);
      expect(tile.height, 72);
    }
  });

  testWidgets('classic image faces clip to the cream face', (tester) async {
    final look = TableLookController(TableLookStore.memory());
    await look.setLook(TableLook.classic);
    const symbols = ['fruit-01', 'shape-01', 'number-01'];
    final height = 72 * TileBaseLayout.spriteAspect;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TableLookScope(
            controller: look,
            child: Row(
              children: [
                for (var i = 0; i < symbols.length; i++)
                  TileWidget(
                    key: Key(symbols[i]),
                    tile: Tile(id: i, symbol: symbols[i], layer: 0, x: 0, y: 0),
                    width: 72,
                    height: height,
                    isSelected: false,
                    isFree: true,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(ClipRRect), findsWidgets);
    for (final symbol in symbols) {
      final tile = tester.widget<TileWidget>(find.byKey(Key(symbol)));
      expect(tile.width, 72);
      expect(
        tile.height / tile.width,
        closeTo(TileBaseLayout.spriteAspect, 0.01),
      );
      expect(
        find.descendant(
          of: find.byKey(Key(symbol)),
          matching: find.byType(ClipRRect),
        ),
        findsWidgets,
      );
    }
  });

  test('symbol sits on the ceramic face, not the ice rim', () {
    final size = Size(80, 80 * TileBaseLayout.spriteAspect);
    final face = TileBaseLayout.faceRectOf(size);
    final symbol = TileBaseLayout.symbolRectOf(size);
    expect(face.right, lessThan(size.width));
    expect(face.bottom, lessThan(size.height));
    expect(symbol.left, greaterThanOrEqualTo(face.left));
    expect(symbol.top, greaterThanOrEqualTo(face.top));
    expect(symbol.right, lessThanOrEqualTo(face.right));
    expect(symbol.bottom, lessThanOrEqualTo(face.bottom));
  });

  test('drawTile layout matches the screenshot proportions', () {
    final size = Size(80, 80 * TileBaseLayout.spriteAspect);
    expect(TileCanvas.cornerRadius(size), closeTo(9.6, 0.05));
    expect(TileCanvas.strokeWidthFactor * size.width, closeTo(1.12, 0.05));

    final face = TileCanvas.faceRectOf(size);
    expect(face.width / size.width, closeTo(0.93, 0.01));
    expect(face.height / size.height, closeTo(0.922, 0.01));

    final symbol = TileCanvas.symbolRectOf(size);
    expect(
      symbol.width / symbol.height,
      closeTo(TileFaceArt.widthOverHeight, 0.01),
    );
    expect(symbol.center.dx, closeTo(face.center.dx, 0.01));
    expect(symbol.center.dy, closeTo(face.center.dy, 0.5));
    expect((size.width * TileCanvas.shadowOffsetXFactor), closeTo(4.4, 0.1));
    expect(TileCanvas.shadowOpacity, closeTo(0.34, 0.001));
  });

  test('face art source is 3:4 and matches the symbol slot', () {
    expect(TileFaceArt.widthPx, 384);
    expect(TileFaceArt.heightPx, 512);
    expect(TileFaceArt.widthOverHeight, closeTo(3 / 4, 0.001));
    const bone = Size(
      TileBaseLayout.spriteWidthPx,
      TileBaseLayout.spriteHeightPx,
    );
    final symbol = TileBaseLayout.symbolRectOf(bone);
    expect(
      symbol.width / symbol.height,
      closeTo(TileFaceArt.widthOverHeight, 0.01),
    );
  });

  test('flower and season faces are special tiles', () {
    expect(TileCanvas.isSpecialSymbol('flower-01'), isFalse);
    expect(TileCanvas.isSpecialSymbol('season-03'), isTrue);
    expect(TileCanvas.isSpecialSymbol('set1-season-spring'), isTrue);
    expect(TileCanvas.isSpecialSymbol('soft-01'), isFalse);
  });

  test('canvas glyphs cover the screenshot suits', () {
    expect(TileGlyph.paints('flower-01'), isTrue);
    expect(TileGlyph.kindOf('flower-01')?.suit, TileSuit.plum);
    expect(TileGlyph.paints('bamboo-03'), isTrue);
    expect(TileGlyph.kindOf('bamboo-09')?.rank, 9);
    expect(TileGlyph.kindOf('character-05')?.suit, TileSuit.character);
    expect(TileGlyph.kindOf('character-05')?.rank, 5);
    expect(TileGlyph.paints('dot-08'), isTrue);
    expect(TileGlyph.kindOf('dragon-03')?.suit, TileSuit.dragon);
    expect(TileGlyph.paints('wind-01'), isTrue);
    expect(TileGlyph.paints('season-01'), isFalse);
    expect(TileGlyph.paints('soft-01'), isFalse);
    expect(TileGlyph.paints('number-05'), isFalse);
    expect(TileGlyph.paints('fruit-01'), isFalse);
    expect(TileGlyph.paints('shape-01'), isFalse);
    expect(TileGlyph.kindOf('set1-bamboo-03')?.rank, 3);
  });

  testWidgets('TileWidget does not gray covered tiles unless dimming is on', (
    tester,
  ) async {
    final free = Tile(id: 1, symbol: 'soft-01', layer: 1, x: 0, y: 0);
    final locked = Tile(id: 2, symbol: 'soft-01', layer: 0, x: 2, y: 0);
    final dim = LockedTileDimController(LockedTileDimStore.memory());

    Widget row() {
      return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: LockedTileDimScope(
            controller: dim,
            child: Row(
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
    }

    await tester.pumpWidget(row());

    TileBodySprite faceOf(Key key) {
      return tester.widget<TileBodySprite>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(TileBodySprite),
        ),
      );
    }

    expect(faceOf(const Key('free')).locked, isFalse);
    expect(faceOf(const Key('locked')).locked, isFalse);

    await dim.setEnabled(true);
    await tester.pumpWidget(row());

    expect(faceOf(const Key('free')).locked, isFalse);
    expect(faceOf(const Key('locked')).locked, isTrue);
  });

  testWidgets('casual look dims covered tiles even when dimming is off', (
    tester,
  ) async {
    final free = Tile(id: 1, symbol: 'soft-01', layer: 1, x: 0, y: 0);
    final locked = Tile(id: 2, symbol: 'soft-01', layer: 0, x: 2, y: 0);
    final dim = LockedTileDimController(LockedTileDimStore.memory());
    final look = TableLookController(TableLookStore.memory());
    await look.setLook(TableLook.casual);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TableLookScope(
            controller: look,
            child: LockedTileDimScope(
              controller: dim,
              child: Row(
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
        ),
      ),
    );

    TileBodySprite faceOf(Key key) {
      return tester.widget<TileBodySprite>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(TileBodySprite),
        ),
      );
    }

    expect(dim.enabled, isFalse);
    expect(faceOf(const Key('free')).locked, isFalse);
    expect(faceOf(const Key('locked')).locked, isTrue);
    expect(
      tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .where((paint) => paint.painter is TileCasualFacePainter)
          .length,
      2,
    );
  });

  testWidgets('selected and special tiles switch drawTile chrome', (
    tester,
  ) async {
    final selected = Tile(id: 1, symbol: 'soft-01', layer: 1, x: 0, y: 0);
    final flower = Tile(id: 2, symbol: 'flower-01', layer: 0, x: 2, y: 0);
    final season = Tile(id: 3, symbol: 'season-01', layer: 0, x: 4, y: 0);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Row(
            children: [
              TileWidget(
                key: const Key('selected'),
                tile: selected,
                width: 64,
                height: 74,
                isSelected: true,
                isFree: true,
              ),
              TileWidget(
                key: const Key('flower'),
                tile: flower,
                width: 64,
                height: 74,
                isSelected: false,
                isFree: true,
              ),
              TileWidget(
                key: const Key('season'),
                tile: season,
                width: 64,
                height: 74,
                isSelected: false,
                isFree: true,
              ),
            ],
          ),
        ),
      ),
    );

    TileBodySprite faceOf(Key key) {
      return tester.widget<TileBodySprite>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(TileBodySprite),
        ),
      );
    }

    expect(faceOf(const Key('selected')).isSelected, isTrue);
    expect(faceOf(const Key('flower')).isSpecial, isFalse);
    expect(faceOf(const Key('flower')).symbol, 'flower-01');
    expect(faceOf(const Key('season')).isSpecial, isTrue);
    expect(
      find.descendant(
        of: find.byKey(const Key('flower')),
        matching: find.byType(TileSymbolImage),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('season')),
        matching: find.byType(TileSymbolImage),
      ),
      findsNothing,
    );
  });

  testWidgets('tapping a locked tile shakes it, a free tile stays put', (
    tester,
  ) async {
    final free = Tile(id: 1, symbol: 'soft-01', layer: 1, x: 0, y: 0);
    final locked = Tile(id: 2, symbol: 'soft-01', layer: 0, x: 2, y: 0);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
                onTap: (_) {},
              ),
              TileWidget(
                key: const Key('locked'),
                tile: locked,
                width: 64,
                height: 74,
                isSelected: false,
                isFree: false,
                onTap: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    bool shiftedSideways(Key key) {
      return tester
          .widgetList<Transform>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(Transform),
            ),
          )
          .any((t) => t.transform.getTranslation().x.abs() > 0.5);
    }

    expect(shiftedSideways(const Key('locked')), isFalse);

    await tester.tap(find.byKey(const Key('locked')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(shiftedSideways(const Key('locked')), isTrue);

    await tester.tap(find.byKey(const Key('free')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(shiftedSideways(const Key('free')), isFalse);

    await tester.pumpAndSettle();
    expect(shiftedSideways(const Key('locked')), isFalse);
  });

  testWidgets('tapping a free tile pops 1.0 → 1.15 → 1.0', (tester) async {
    final free = Tile(id: 1, symbol: 'soft-01', layer: 1, x: 0, y: 0);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TileWidget(
            key: const Key('free'),
            tile: free,
            width: 64,
            height: 74,
            isSelected: false,
            isFree: true,
            onTap: (_) {},
          ),
        ),
      ),
    );

    double maxScaleX() {
      var peak = 1.0;
      for (final t in tester.widgetList<Transform>(
        find.descendant(
          of: find.byKey(const Key('free')),
          matching: find.byType(Transform),
        ),
      )) {
        peak = max(peak, t.transform.storage[0]);
      }
      return peak;
    }

    expect(maxScaleX(), closeTo(1.0, 0.02));
    await tester.tap(find.byKey(const Key('free')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(maxScaleX(), closeTo(TileWidget.tapPopPeak, 0.04));
    await tester.pump(TileWidget.tapPopDuration);
    expect(maxScaleX(), closeTo(1.0, 0.02));
  });

  testWidgets('removing a tile fades out and scales to 0.8', (tester) async {
    final tile = Tile(id: 1, symbol: 'soft-01', layer: 0, x: 0, y: 0);

    Widget app({required bool removing}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TileWidget(
          tile: tile,
          width: 64,
          height: 74,
          isSelected: false,
          isFree: true,
          isRemoving: removing,
          onRemoveComplete: () {},
        ),
      ),
    );

    await tester.pumpWidget(app(removing: false));
    await tester.pumpWidget(app(removing: true));

    final fade = tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(fade.opacity, 0);
    expect(fade.duration, TileWidget.removeDuration);

    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, TileWidget.removeScale);
    expect(scale.duration, TileWidget.removeDuration);

    final slide = tester.widget<AnimatedSlide>(find.byType(AnimatedSlide));
    expect(slide.offset.dy, greaterThan(0));
    expect(slide.duration, TileWidget.removeSlideDuration);
    expect(slide.curve, Curves.easeOut);
  });

  test('locked tiles cast a shorter, softer shadow than free ones', () {
    final free = TilePyramidPosition.visuals(
      z: 2,
      tileWidth: 80,
      tileHeight: 92,
    );
    final locked = TilePyramidPosition.visuals(
      z: 2,
      tileWidth: 80,
      tileHeight: 92,
      lifted: false,
    );

    expect(locked.shadowOffset.dx, lessThan(free.shadowOffset.dx));
    expect(locked.shadowOpacity, lessThan(free.shadowOpacity));
    expect(locked.shadowBlur, lessThan(free.shadowBlur));
    expect(locked.baseOffset, free.baseOffset);
  });

  test('shuffle gather peaks in the centre then returns', () {
    expect(TileWidget.shuffleGatherAmount(0), 0);
    expect(TileWidget.shuffleGatherAmount(1), 0);
    expect(TileWidget.shuffleGatherAmount(0.5), 1);
    expect(
      TileWidget.shuffleGatherAmount(0.2),
      greaterThan(TileWidget.shuffleGatherAmount(0.05)),
    );
    expect(
      TileWidget.shuffleGatherAmount(0.8),
      greaterThan(TileWidget.shuffleGatherAmount(0.95)),
    );
    for (var x = 0; x < 16; x++) {
      for (var y = 0; y < 16; y++) {
        for (var z = 0; z < 5; z++) {
          final delay = TileWidget.shuffleStaggerOf(
            Tile(id: z, symbol: 'A', layer: z, x: x, y: y),
          );
          expect(delay, lessThanOrEqualTo(TileWidget.shuffleMaxStagger));
        }
      }
    }
  });

  testWidgets('shuffle token keeps the old face until the gather midpoint', (
    tester,
  ) async {
    final tile = Tile(id: 1, symbol: 'soft-01', layer: 0, x: 0, y: 0);
    const gather = Offset(48, -36);

    Widget app({required int token}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TileWidget(
          tile: tile,
          width: 64,
          height: 74,
          isSelected: false,
          isFree: true,
          shuffleToken: token,
          shuffleGatherOffset: gather,
        ),
      ),
    );

    await tester.pumpWidget(app(token: 0));
    expect(
      tester.widget<TileSymbolImage>(find.byType(TileSymbolImage)).symbol,
      'soft-01',
    );

    tile.symbol = 'soft-02';
    await tester.pumpWidget(app(token: 1));
    await tester.pump();
    await tester.pump(TileWidget.shuffleDuration * 0.2);
    expect(
      tester.widget<TileSymbolImage>(find.byType(TileSymbolImage)).symbol,
      'soft-01',
    );

    Offset translationOf(Transform transform) {
      final m = transform.transform.storage;
      return Offset(m[12], m[13]);
    }

    await tester.pump(TileWidget.shuffleDuration * 0.3);
    expect(
      tester.widget<TileSymbolImage>(find.byType(TileSymbolImage)).symbol,
      'soft-02',
    );
    final stacked = tester.widget<Transform>(
      find.byKey(const ValueKey('tile-shuffle-transform')),
    );
    expect(translationOf(stacked).dx, closeTo(gather.dx, 0.6));
    expect(translationOf(stacked).dy, closeTo(gather.dy, 0.6));

    await tester.pumpAndSettle();
    for (final transform in tester.widgetList<Transform>(
      find.byKey(const ValueKey('tile-shuffle-transform')),
    )) {
      final m = transform.transform.storage;
      expect(translationOf(transform), Offset.zero);
      expect(m[0] * m[5] - m[1] * m[4], closeTo(1.0, 0.000001));
    }
  });

  testWidgets('shuffle gathers board tiles into one stack', (tester) async {
    final board = Board.fromLayout('petal', random: Random(1));
    var token = 0;

    Widget app() => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 720,
          child: GameBoard(
            board: board,
            onTileTap: (_, _) {},
            onTileRemoveComplete: (_) {},
            shuffleToken: token,
          ),
        ),
      ),
    );

    await tester.pumpWidget(app());
    token = 1;
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump(TileWidget.shuffleDuration * 0.5);

    final stacked = <Offset>[];
    for (final tile in board.tiles.where((t) => t.isOnBoard)) {
      final positioned = tester.widget<AnimatedPositioned>(
        find.byKey(ValueKey(tile.id)),
      );
      final transform = tester.widget<Transform>(
        find.descendant(
          of: find.byKey(ValueKey(tile.id)),
          matching: find.byKey(const ValueKey('tile-shuffle-transform')),
        ),
      );
      final m = transform.transform.storage;
      stacked.add(Offset(positioned.left! + m[12], positioned.top! + m[13]));
    }

    final xs = stacked.map((o) => o.dx);
    final ys = stacked.map((o) => o.dy);
    expect(xs.reduce(max) - xs.reduce(min), lessThan(2));
    expect(ys.reduce(max) - ys.reduce(min), lessThan(2));
  });

  testWidgets('dark game backdrop uses the New table by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: MahjongScreenBackdrop(dark: true)),
    );

    expect(_backdropUsesFelt(tester), isFalse);
    expect(
      tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .any((box) => box.color == TableUi.premiumTableDeep),
      isTrue,
    );
  });

  testWidgets('casual dark backdrop still uses felt.png', (tester) async {
    final look = TableLookController(TableLookStore.memory());
    await look.setLook(TableLook.casual);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TableLookScope(
          controller: look,
          child: const MahjongScreenBackdrop(dark: true),
        ),
      ),
    );

    expect(_backdropUsesFelt(tester), isTrue);
  });

  testWidgets('GameHud is a copper row of back and menu', (tester) async {
    var back = 0;
    var menu = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GameHud(
            onBack: () => back++,
            onMenu: () => menu++,
            backTooltip: 'Back',
            menuTooltip: 'Menu',
          ),
        ),
      ),
    );

    expect(find.byType(GameHudCircleButton), findsNWidgets(2));
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.text('40'), findsNothing);
    expect(find.text('90'), findsNothing);
    expect(find.text('180'), findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.tap(find.byIcon(Icons.menu_rounded));
    expect(back, 1);
    expect(menu, 1);
  });

  testWidgets('GameActionBar is a copper row of four badged buttons', (
    tester,
  ) async {
    var shuffle = 0;
    var magnet = 0;
    var hint = 0;
    var undo = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GameActionBar(
            shufflesLeft: 3,
            magnetsLeft: 5,
            hintsLeft: 0,
            undosLeft: 0,
            enabled: true,
            canUndo: true,
            canUndoViaAd: true,
            adsAvailable: true,
            onShuffle: () => shuffle++,
            onMagnet: () => magnet++,
            onHint: () => hint++,
            onUndo: () => undo++,
          ),
        ),
      ),
    );

    expect(find.byType(GameActionButton), findsNWidgets(4));
    expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
    expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('+'), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.shuffle_rounded));
    await tester.tap(find.byTooltip('Magnet'));
    await tester.tap(find.byIcon(Icons.lightbulb_outline_rounded));
    await tester.tap(find.byIcon(Icons.undo_rounded));
    expect(shuffle, 1);
    expect(magnet, 1);
    expect(hint, 1);
    expect(undo, 1);

    await tester.tap(find.byIcon(Icons.shuffle_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final pressed = tester
        .widgetList<Transform>(
          find.descendant(
            of: find.byType(GameActionButton),
            matching: find.byType(Transform),
          ),
        )
        .any((t) => t.transform.storage[0] < 0.98);
    expect(pressed, isTrue);
  });

  testWidgets('GameScreen hosts a visible board', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final progress = await ProgressStore.open();

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byType(GameBoard), findsOneWidget);
    expect(find.byType(TileWidget), findsWidgets);
    expect(find.byType(GameHud), findsOneWidget);
    expect(find.byType(GameActionBar), findsOneWidget);
    expect(find.text('200'), findsNothing);
    expect(find.text('350'), findsNothing);
    expect(find.text('500'), findsNothing);
    expect(find.text('Level 1'), findsNothing);
    expect(
      find.text('Take a free tile — open on top and one side'),
      findsOneWidget,
    );
    expect(find.text('0/16'), findsNothing);
    expect(find.text('1x'), findsNothing);

    final hud = tester.getRect(find.byType(GameHud));
    final board = tester.getRect(find.byType(GameBoard));
    final actions = tester.getRect(find.byType(GameActionBar));
    expect(hud.bottom, lessThanOrEqualTo(board.top + 1));
    expect(board.bottom, lessThanOrEqualTo(actions.top + 1));
    final screen = tester.getRect(find.byType(GameScreen));
    expect(board.center.dx, closeTo(screen.center.dx, 8));
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(GameHud), findsOneWidget);
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

  testWidgets('campaign leftover hints carry into a later level', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'progress.tableCoachDone': true,
      'tutorial.skipped': true,
      'tutorial.collect': true,
      'tutorial.match': true,
      'tutorial.layers': true,
      'tutorial.boosts': true,
      'progress.hintBalance': 4,
    });
    final progress = await ProgressStore.open();
    expect(Levels.byId(24).hints, 0);

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(level: Levels.byId(24), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      tester.widget<GameActionBar>(find.byType(GameActionBar)).hintsLeft,
      4,
    );
  });

  testWidgets('campaign leftover boosts carry into a later level', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'progress.tableCoachDone': true,
      'tutorial.skipped': true,
      'tutorial.collect': true,
      'tutorial.match': true,
      'tutorial.layers': true,
      'tutorial.boosts': true,
      'progress.hintBalance': 4,
      'progress.shuffleBalance': 3,
      'progress.magnetBalance': 2,
      'progress.undoBalance': 5,
    });
    final progress = await ProgressStore.open();
    final lateLevel = Levels.byId(24);
    expect(lateLevel.hints, 0);
    expect(lateLevel.shuffles, 0);
    expect(lateLevel.undos, 0);

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(level: lateLevel, progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final bar = tester.widget<GameActionBar>(find.byType(GameActionBar));
    expect(bar.hintsLeft, 4);
    expect(bar.shufflesLeft, 3);
    expect(bar.magnetsLeft, 2);
    expect(bar.undosLeft, 5);
  });

  testWidgets('hint highlights a free top pair instead of a covered pair', (
    tester,
  ) async {
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
        Tile(id: 1, symbol: 'C', layer: 1, x: 0, y: 0),
        Tile(id: 2, symbol: 'A', layer: 0, x: 4, y: 0),
        Tile(id: 3, symbol: 'D', layer: 1, x: 4, y: 0),
        Tile(id: 4, symbol: 'B', layer: 0, x: 8, y: 0),
        Tile(id: 5, symbol: 'B', layer: 0, x: 12, y: 0),
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Hint'));
    await tester.pump();

    final hinted = tester
        .widgetList<TileWidget>(find.byType(TileWidget))
        .where((w) => w.isHinted)
        .map((w) => w.tile.id)
        .toSet();
    expect(hinted, {4, 5});
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Magnet'));
    await tester.pump();
    await tester.pump(TileFlightOverlay.duration);
    await tester.pump(const Duration(milliseconds: 80));

    final onBoard = tester
        .widgetList<TileWidget>(find.byType(TileWidget))
        .where((w) => !w.compact && w.tile.isOnBoard)
        .map((w) => w.tile.id)
        .toSet();
    expect(onBoard, {2});
    expect(progress.savedSnapshot?.magnets, 1);
    expect(progress.savedSnapshot?.score, 100);
  });

  testWidgets('magnet pulls a covered tile that matches the tray', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'progress.tableCoachDone': true,
      'tutorial.skipped': true,
      'tutorial.collect': true,
      'tutorial.match': true,
      'tutorial.layers': true,
      'tutorial.boosts': true,
    });
    final progress = await ProgressStore.open();
    final tray = Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0, inTray: true);
    final buried = Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0);
    final cover = Tile(id: 2, symbol: 'B', layer: 1, x: 4, y: 0);
    final other = Tile(id: 3, symbol: 'C', layer: 0, x: 8, y: 0);
    final board = Board(
      tiles: [tray, buried, cover, other],
      layoutName: 'petal',
    );
    board.tray.add(tray);
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Magnet'));
    await tester.pump();
    await tester.pump(TileFlightOverlay.duration);
    await tester.pump(const Duration(milliseconds: 80));

    final onBoard = tester
        .widgetList<TileWidget>(find.byType(TileWidget))
        .where((w) => !w.compact && w.tile.isOnBoard)
        .map((w) => w.tile.id)
        .toSet();
    expect(onBoard, {2, 3});
    expect(progress.savedSnapshot?.magnets, 1);
    expect(progress.savedSnapshot?.score, 100);
  });

  testWidgets('tapping a free tile flies it into the tray', (tester) async {
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
        Tile(id: 0, symbol: 'A', layer: 0, x: 4, y: 4),
        Tile(id: 1, symbol: 'B', layer: 0, x: 6, y: 4),
        Tile(id: 2, symbol: 'C', layer: 0, x: 8, y: 4),
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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

  testWidgets('leaving mid-flight keeps the collected tile in the tray', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'progress.tableCoachDone': true,
      'tutorial.skipped': true,
      'tutorial.collect': true,
      'tutorial.match': true,
      'tutorial.layers': true,
      'tutorial.boosts': true,
    });
    final progress = await ProgressStore.open();
    await progress.saveSnapshot(
      GameSnapshot.fromBoard(
        levelId: 1,
        board: Board(
          tiles: [
            Tile(id: 0, symbol: 'A', layer: 0, x: 4, y: 4),
            Tile(id: 1, symbol: 'B', layer: 0, x: 6, y: 4),
            Tile(id: 2, symbol: 'C', layer: 0, x: 8, y: 4),
          ],
          layoutName: 'petal',
        ),
        score: 40,
        combo: 1,
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final lastTile = find.byWidgetPredicate(
      (w) => w is TileWidget && !w.compact && w.tile.id == 0,
    );
    expect(lastTile, findsOneWidget);
    await tester.tap(lastTile);
    await tester.pump();
    expect(find.byType(TileFlightOverlay), findsOneWidget);

    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: SizedBox()));
    await tester.pump();

    final snap = progress.savedSnapshot;
    expect(snap, isNotNull);
    final flown = snap!.tiles.firstWhere((tile) => tile.id == 0);
    expect(flown.removed, isFalse);
    expect(flown.inTray, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byWidgetPredicate(
        (w) => w is TileWidget && w.compact && w.tile.id == 0,
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is TileWidget && !w.compact && w.tile.id == 0 && w.tile.isOnBoard,
      ),
      findsNothing,
    );
  });

  testWidgets('last matching pair ends the table after flights', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'progress.tableCoachDone': true,
      'tutorial.skipped': true,
      'tutorial.collect': true,
      'tutorial.match': true,
      'tutorial.layers': true,
      'tutorial.boosts': true,
    });
    final progress = await ProgressStore.open();
    await progress.saveSnapshot(
      GameSnapshot.fromBoard(
        levelId: 1,
        board: Board(
          tiles: [
            Tile(id: 0, symbol: 'A', layer: 0, x: 4, y: 4),
            Tile(id: 1, symbol: 'A', layer: 0, x: 8, y: 4),
          ],
          layoutName: 'petal',
        ),
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      GameScreen(level: Levels.byId(1), progress: progress),
                ),
              );
            },
            child: const Text('play'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    Future<void> tapBoardTile(int id) async {
      final tile = find.byWidgetPredicate(
        (w) => w is TileWidget && !w.compact && w.tile.id == id,
      );
      expect(tile, findsOneWidget);
      await tester.tap(tile);
      await tester.pump();
      await tester.pump(TileFlightOverlay.duration);
      await tester.pump(const Duration(milliseconds: 80));
    }

    await tapBoardTile(0);
    await tapBoardTile(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(progress.isCompleted(1), isTrue);
    expect(progress.savedSnapshot, isNull);
  });

  testWidgets('last matching pair ends even if flight tickers stall', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'progress.tableCoachDone': true,
      'tutorial.skipped': true,
      'tutorial.collect': true,
      'tutorial.match': true,
      'tutorial.layers': true,
      'tutorial.boosts': true,
    });
    final progress = await ProgressStore.open();
    await progress.saveSnapshot(
      GameSnapshot.fromBoard(
        levelId: 1,
        board: Board(
          tiles: [
            Tile(id: 0, symbol: 'A', layer: 0, x: 4, y: 4),
            Tile(id: 1, symbol: 'A', layer: 0, x: 8, y: 4),
          ],
          layoutName: 'petal',
        ),
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TickerMode(
                    enabled: false,
                    child: GameScreen(
                      level: Levels.byId(1),
                      progress: progress,
                    ),
                  ),
                ),
              );
            },
            child: const Text('play'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    Future<void> tapBoardTile(int id) async {
      final tile = find.byWidgetPredicate(
        (w) => w is TileWidget && !w.compact && w.tile.id == id,
      );
      expect(tile, findsOneWidget);
      await tester.tap(tile);
      await tester.pump();
    }

    await tapBoardTile(0);
    await tapBoardTile(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(progress.isCompleted(1), isTrue);
    expect(progress.savedSnapshot, isNull);
  });

  testWidgets('last board tile matching the tray ends without a flight', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'progress.tableCoachDone': true,
      'tutorial.skipped': true,
      'tutorial.collect': true,
      'tutorial.match': true,
      'tutorial.layers': true,
      'tutorial.boosts': true,
    });
    final progress = await ProgressStore.open();
    final tray = Tile(id: 0, symbol: 'A', layer: 0, x: 4, y: 4, inTray: true);
    final last = Tile(id: 1, symbol: 'A', layer: 0, x: 8, y: 4);
    final board = Board(tiles: [tray, last], layoutName: 'petal')
      ..tray.add(tray);
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => TickerMode(
                    enabled: false,
                    child: GameScreen(
                      level: Levels.byId(1),
                      progress: progress,
                    ),
                  ),
                ),
              );
            },
            child: const Text('play'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('play'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final tile = find.byWidgetPredicate(
      (w) => w is TileWidget && !w.compact && w.tile.id == 1,
    );
    expect(tile, findsOneWidget);
    await tester.tap(tile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(progress.isCompleted(1), isTrue);
    expect(progress.savedSnapshot, isNull);
  });

  testWidgets('leaving after the last matching tap still credits the win', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'progress.tableCoachDone': true,
      'tutorial.skipped': true,
      'tutorial.collect': true,
      'tutorial.match': true,
      'tutorial.layers': true,
      'tutorial.boosts': true,
    });
    final progress = await ProgressStore.open();
    final tray = Tile(id: 0, symbol: 'A', layer: 0, x: 4, y: 4, inTray: true);
    final last = Tile(id: 1, symbol: 'A', layer: 0, x: 8, y: 4);
    final board = Board(tiles: [tray, last], layoutName: 'petal')
      ..tray.add(tray);
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final tile = find.byWidgetPredicate(
      (w) => w is TileWidget && !w.compact && w.tile.id == 1,
    );
    await tester.tap(tile);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(progress.isCompleted(1), isTrue);
  });

  testWidgets('watching a simulated ad grants a hint', (tester) async {
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(level: Levels.byId(1), progress: progress),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Watch ad → Hint'));
    await tester.pump();
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

bool _backdropUsesFelt(WidgetTester tester) {
  return tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).any((box) {
    final decoration = box.decoration;
    if (decoration is! BoxDecoration) return false;
    final image = decoration.image;
    if (image == null) return false;
    final provider = image.image;
    return provider is AssetImage &&
        provider.assetName == 'assets/felt.png' &&
        image.opacity == 1.0;
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
