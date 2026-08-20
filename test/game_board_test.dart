import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/board.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/screens/game_screen.dart';
import 'package:mahjong/services/progress_store.dart';
import 'package:mahjong/utils/layouts.dart';
import 'package:mahjong/utils/tile_pyramid_position.dart';
import 'package:mahjong/widgets/game_board.dart';
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

    final felt = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .any((box) {
          final decoration = box.decoration;
          if (decoration is! BoxDecoration) return false;
          final image = decoration.image?.image;
          return image is AssetImage && image.assetName == 'assets/felt.png';
        });
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
    expect(find.text('Уровень 1'), findsOneWidget);
    expect(find.text('0/16'), findsOneWidget);
    expect(find.text('1x'), findsOneWidget);
  });
}
