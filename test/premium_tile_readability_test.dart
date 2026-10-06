import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/table_look.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/services/locked_tile_dim_controller.dart';
import 'package:mahjong/services/locked_tile_dim_store.dart';
import 'package:mahjong/services/table_look_controller.dart';
import 'package:mahjong/services/table_look_store.dart';
import 'package:mahjong/widgets/tile_symbol_image.dart';
import 'package:mahjong/widgets/tile_widget.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  testWidgets(
    'switching to New uses vector fruit and restores casual artwork',
    (tester) async {
      final look = TableLookController(TableLookStore.memory());
      addTearDown(look.dispose);
      await look.setLook(TableLook.casual);
      await tester.pumpWidget(
        MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: TableLookScope(
            controller: look,
            child: const SizedBox(
              width: 60,
              height: 72,
              child: TileSymbolImage(symbol: 'fruit-01'),
            ),
          ),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
      await look.setLook(TableLook.premium);
      await tester.pump();
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      await look.setLook(TableLook.casual);
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
    },
  );

  testWidgets('New tiles remain readable at board and tray sizes', (
    tester,
  ) async {
    final look = TableLookController(TableLookStore.memory());
    await look.setLook(TableLook.premium);
    addTearDown(look.dispose);
    final dim = LockedTileDimController(LockedTileDimStore.memory());
    await dim.setEnabled(true);
    addTearDown(dim.dispose);
    const symbols = [
      'fruit-01',
      'fruit-03',
      'bamboo-09',
      'dot-08',
      'character-07',
      'wind-north',
    ];
    const gallery = Key('premium-gallery');
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TableLookScope(
              controller: look,
              child: Center(
                child: RepaintBoundary(
                  key: gallery,
                  child: Container(
                    width: 540,
                    height: 400,
                    padding: const EdgeInsets.all(20),
                    color: const Color(0xFF95744F),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final row in [
                          (40.0, true),
                          (60.0, true),
                          (60.0, false),
                        ])
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              for (var i = 0; i < symbols.length; i++)
                                LockedTileDimScope(
                                  controller: dim,
                                  child: TileWidget(
                                    tile: Tile(
                                      id: i,
                                      symbol: symbols[i],
                                      layer: 0,
                                      x: 0,
                                      y: 0,
                                    ),
                                    width: row.$1,
                                    height: row.$1 * 1.2,
                                    isSelected: false,
                                    isFree: row.$2,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // Allow bundled SVG files to finish loading before capturing the frame.
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(gallery),
      matchesGoldenFile('goldens/premium_tile_readability.png'),
    );
  });
}
