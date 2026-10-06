import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/widgets/tile_tray.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  testWidgets('warns at three unmatched tiles without moving the tray', (
    tester,
  ) async {
    final slots = List.generate(4, (_) => GlobalKey());
    final tiles = List.generate(
      4,
      (i) => Tile(
        id: i,
        symbol: 'bamboo-${i + 1}',
        layer: 0,
        x: 0,
        y: 0,
        inTray: true,
      ),
    );
    Future<void> show(List<Tile> tray) => tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: TileTray(
              tiles: tray,
              slotKeys: slots,
              hintedIds: const {},
              smashingIds: const {},
              onRemoveComplete: (_) {},
            ),
          ),
        ),
      ),
    );
    final warning = find.text('Осталось одно место — найдите пару').hitTestable();
    final semantics = tester.ensureSemantics();

    await show(tiles.take(2).toList());
    expect(warning, findsNothing);
    final initialSize = tester.getSize(find.byType(TileTray));
    final slotPosition = tester.getTopLeft(find.byKey(slots.last));

    await show(tiles.take(3).toList());
    expect(warning, findsOneWidget);
    expect(tester.getSize(find.byType(TileTray)), initialSize);
    expect(tester.getTopLeft(find.byKey(slots.last)), slotPosition);
    expect(
      find.bySemanticsLabel('Осталось одно место — найдите пару'),
      findsOneWidget,
    );

    await show(tiles);
    expect(warning, findsNothing);

    tiles[1].symbol = tiles[0].symbol;
    await show(tiles.take(3).toList());
    expect(warning, findsNothing);

    tiles[1].symbol = 'bamboo-2';
    tiles[0].removing = true;
    await show(tiles);
    expect(warning, findsNothing);

    await show([]);
    expect(warning, findsNothing);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
