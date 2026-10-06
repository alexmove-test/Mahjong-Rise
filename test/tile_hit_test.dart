import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/board.dart';
import 'package:mahjong/models/table_look.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/services/table_look_controller.dart';
import 'package:mahjong/services/table_look_store.dart';
import 'package:mahjong/widgets/game_board.dart';
import 'package:mahjong/widgets/tile_canvas.dart';
import 'package:mahjong/widgets/tile_widget.dart';
import 'package:mahjong/l10n/app_localizations.dart';

Finder _tile(int id) => find.byWidgetPredicate(
  (widget) => widget is TileWidget && widget.tile.id == id,
);

Rect _rectOf(WidgetTester tester, Finder finder) {
  final box = tester.renderObject<RenderBox>(finder);
  return box.localToGlobal(Offset.zero) & box.size;
}

Offset? _exposedUpperPoint(WidgetTester tester) {
  final topBox = tester.renderObject<RenderBox>(_tile(1));
  final neighborBox = tester.renderObject<RenderBox>(_tile(2));
  final topRect = _rectOf(tester, _tile(1));
  final neighborRect = _rectOf(tester, _tile(2));
  final overlap = topRect.intersect(neighborRect);
  if (overlap.isEmpty) return null;

  for (var y = overlap.top + 0.5; y < overlap.bottom; y += 1) {
    for (var x = overlap.left + 0.5; x < overlap.right; x += 1) {
      final global = Offset(x, y);
      final inTop = CasualTileLayout.containsPoint(
        topBox.size,
        topBox.globalToLocal(global),
      );
      final inNeighbor = CasualTileLayout.containsPoint(
        neighborBox.size,
        neighborBox.globalToLocal(global),
      );
      if (inTop && !inNeighbor) return global;
    }
  }
  return null;
}

void main() {
  test('casual neighbor square covers a corner the squircle leaves open', () {
    const size = Size(80, 80);
    const gap = GameBoard.casualTileGapFactor;
    final neighborOrigin = Offset(size.width * gap, size.height * gap);
    final overlap = (Offset.zero & size).intersect(neighborOrigin & size);
    expect(overlap.isEmpty, isFalse);

    final corner = Offset(overlap.right - 1, overlap.bottom - 1);
    expect(CasualTileLayout.containsPoint(size, corner), isFalse);
    expect(
      CasualTileLayout.containsPoint(size, corner - neighborOrigin),
      isFalse,
    );
  });

  testWidgets(
    'casual tap on an upper tile is not stolen by a lower neighbor corner',
    (tester) async {
      final look = TableLookController(TableLookStore.memory());
      await look.setLook(TableLook.casual);

      final top = Tile(id: 1, symbol: 'fruit-01', layer: 0, x: 2, y: 0);
      final neighbor = Tile(id: 2, symbol: 'fruit-02', layer: 1, x: 4, y: 2);
      final taps = <int>[];

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
                  board: Board(tiles: [top, neighbor]),
                  onTileTap: (tile, _) => taps.add(tile.id),
                  onTileRemoveComplete: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        _rectOf(tester, _tile(1)).overlaps(_rectOf(tester, _tile(2))),
        isTrue,
      );

      final exposed = _exposedUpperPoint(tester);
      expect(
        exposed,
        isNotNull,
        reason: 'upper squircle should peek through the neighbor box',
      );

      await tester.tapAt(exposed!);
      await tester.pump();
      expect(taps, [1]);
    },
  );

  testWidgets('casual tile centers still receive their own taps', (
    tester,
  ) async {
    final look = TableLookController(TableLookStore.memory());
    await look.setLook(TableLook.casual);

    final top = Tile(id: 1, symbol: 'fruit-01', layer: 0, x: 2, y: 0);
    final neighbor = Tile(id: 2, symbol: 'fruit-02', layer: 1, x: 4, y: 2);
    final taps = <int>[];

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
                board: Board(tiles: [top, neighbor]),
                onTileTap: (tile, _) => taps.add(tile.id),
                onTileRemoveComplete: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(_tile(1));
    await tester.tap(_tile(2));
    await tester.pump();
    expect(taps, [1, 2]);
  });

  testWidgets('tile still accepts a tap after shuffle finishes', (
    tester,
  ) async {
    final tile = Tile(id: 7, symbol: 'bamboo-1', layer: 0, x: 0, y: 0);
    final taps = <int>[];
    var token = 0;

    Future<void> show() {
      return tester.pumpWidget(
        MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: GameBoard(
                board: Board(tiles: [tile]),
                shuffleToken: token,
                onTileTap: (t, _) => taps.add(t.id),
                onTileRemoveComplete: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    await show();
    token = 1;
    await show();
    await tester.pump(
      TileWidget.shufflePlayDuration + const Duration(milliseconds: 100),
    );
    await tester.pump();
    await tester.tap(_tile(7));
    await tester.pump();
    expect(taps, [7]);
  });

  testWidgets('free tile center is not stolen by a locked tile above it', (
    tester,
  ) async {
    final free = Tile(id: 1, symbol: 'bamboo-1', layer: 0, x: 2, y: 0);
    final locked = Tile(id: 2, symbol: 'bamboo-2', layer: 10, x: 2, y: 2);
    final left = Tile(id: 3, symbol: 'bamboo-3', layer: 10, x: 0, y: 2);
    final right = Tile(id: 4, symbol: 'bamboo-4', layer: 10, x: 4, y: 2);
    final taps = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 480,
            child: GameBoard(
              board: Board(tiles: [free, locked, left, right]),
              onTileTap: (tile, _) => taps.add(tile.id),
              onTileRemoveComplete: (_) {},
            ),
          ),
        ),
      ),
    );

    final freeRect = _rectOf(tester, _tile(1));
    final lockedRect = _rectOf(tester, _tile(2));
    expect(lockedRect.contains(freeRect.center), isTrue);
    expect(Board(tiles: [free, locked, left, right]).isFree(free), isTrue);
    expect(Board(tiles: [free, locked, left, right]).isFree(locked), isFalse);

    await tester.tapAt(freeRect.center);
    await tester.pump();
    expect(taps, [1]);
  });
}
