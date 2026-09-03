import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/widgets/game_hud.dart';
import 'package:mahjong/widgets/tile_widget.dart';

void main() {
  testWidgets('free tile announces name and free state', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TileWidget(
            tile: Tile(id: 0, symbol: 'bamboo-3', layer: 0, x: 0, y: 0),
            width: 48,
            height: 66,
            isSelected: false,
            isFree: true,
            onTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Bamboo 3, free'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('locked tile announces locked state', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TileWidget(
            tile: Tile(id: 1, symbol: 'fruit-01', layer: 0, x: 0, y: 0),
            width: 48,
            height: 66,
            isSelected: false,
            isFree: false,
            onTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Fruit 1, locked'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('hud button uses explicit semantic label', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameHudCircleButton(
            icon: Icons.menu_rounded,
            tooltip: 'Menu',
            onPressed: () {},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Menu'), findsOneWidget);
    semantics.dispose();
  });
}
