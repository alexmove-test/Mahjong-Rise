import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/board.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/widgets/game_board.dart';
import 'package:mahjong/widgets/tile_widget.dart';
import 'package:mahjong/l10n/app_localizations.dart';

Tile tile(int id, int x, {int y = 0, int layer = 0}) =>
    Tile(id: id, symbol: 'bamboo-1', layer: layer, x: x, y: y);

void main() {
  test('reports covering tiles and only jointly blocking side neighbors', () {
    final center = tile(0, 2);
    final left = tile(1, 0);
    final right = tile(2, 4);
    final above = tile(3, 3, layer: 1);
    final distant = tile(4, 2, y: 2, layer: 1);
    final board = Board(tiles: [center, left, right, above, distant]);
    expect(board.blockersOf(center), unorderedEquals([left, right, above]));
    left.inTray = true;
    expect(board.blockersOf(center), [above]);
    above.removing = true;
    expect(board.blockersOf(center), isEmpty);
    expect(board.isFree(center), isTrue);
    center.inTray = true;
    expect(board.blockersOf(center), isEmpty);
  });

  testWidgets('blocked tap highlights neighbors temporarily without hints', (
    tester,
  ) async {
    final center = tile(0, 2);
    final board = Board(tiles: [center, tile(1, 0), tile(2, 4)]);
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 480,
            child: GameBoard(
              board: board,
              onTileTap: (t, _) => taps.add(t.id),
              onTileRemoveComplete: (_) {},
            ),
          ),
        ),
      ),
    );
    final centerFinder = find.byWidgetPredicate(
      (w) => w is TileWidget && w.tile.id == center.id,
    );
    Iterable<TileWidget> highlighted() => tester
        .widgetList<TileWidget>(find.byType(TileWidget))
        .where((w) => w.isBlocker);
    await tester.tap(centerFinder);
    await tester.pump();
    expect(taps, [0]);
    expect(highlighted().map((w) => w.tile.id), unorderedEquals([1, 2]));
    expect(highlighted().every((w) => !w.isHinted && !w.isSelected), isTrue);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(highlighted(), hasLength(2));
    await tester.tap(centerFinder);
    await tester.pump(const Duration(milliseconds: 500));
    expect(highlighted(), hasLength(2));
    await tester.pump(const Duration(milliseconds: 900));
    expect(highlighted(), isEmpty);
    await tester.tap(centerFinder);
    await tester.pump();
    await tester.tap(
      find.byWidgetPredicate((w) => w is TileWidget && w.tile.id == 1),
    );
    await tester.pump();
    expect(highlighted(), isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
