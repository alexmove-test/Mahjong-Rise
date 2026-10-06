import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/l10n/l10n.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/models/table_look.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/screens/game_screen.dart';
import 'package:mahjong/services/courtyard_reward_store.dart';
import 'package:mahjong/services/progress_store.dart';
import 'package:mahjong/services/table_look_controller.dart';
import 'package:mahjong/services/table_look_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahjong/widgets/app_settings.dart';
import 'package:mahjong/widgets/tile_canvas.dart';
import 'package:mahjong/widgets/tile_glyph.dart';
import 'package:mahjong/widgets/tile_widget.dart';

void main() {
  group('TableLook.premium model', () {
    test('parses from stored id', () {
      expect(TableLook.parse('premium'), TableLook.premium);
      expect(TableLook.premium.id, 'premium');
      expect(TableLook.premium.isPremium, isTrue);
      expect(TableLook.premium.isCasual, isFalse);
    });

    test('classic and casual are not premium', () {
      expect(TableLook.classic.isPremium, isFalse);
      expect(TableLook.casual.isPremium, isFalse);
    });

    test('New is the default look', () {
      expect(TableLook.defaultLook, TableLook.premium);
      expect(TableLook.parse(null), TableLook.premium);
    });
  });

  testWidgets('settings shows the new theme and selects it', (tester) async {
    final controller = TableLookController(TableLookStore.memory());
    final l10n = lookupAppLocalizations(const Locale('en'));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TableLookSection(controller: controller, l10n: l10n),
        ),
      ),
    );

    expect(find.text(l10n.tableLookPremium), findsOneWidget);

    await tester.tap(find.text(l10n.tableLookPremium));
    await tester.pump();

    expect(controller.look, TableLook.premium);
  });

  testWidgets('settings offer classic and casual from the first launch', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final rewards = await CourtyardRewardStore.open();
    final controller = TableLookController(TableLookStore.memory());
    await controller.attachRewards(rewards);
    final l10n = lookupAppLocalizations(const Locale('en'));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TableLookSection(controller: controller, l10n: l10n),
        ),
      ),
    );

    expect(find.text(l10n.tableLookLockedHint), findsNothing);
    expect(find.text(l10n.tableLookClassicHint), findsOneWidget);
    expect(find.text(l10n.tableLookCasualHint), findsOneWidget);

    await tester.tap(find.text(l10n.tableLookCasual));
    await tester.pump();
    expect(controller.look, TableLook.casual);

    await tester.tap(find.text(l10n.tableLookClassic));
    await tester.pump();
    expect(controller.look, TableLook.classic);
  });

  testWidgets('a gift look switch shows a settings hint on the table', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'progress.tableCoachDone': true});
    final progress = await ProgressStore.open();
    final look = TableLookController(TableLookStore.memory());
    await look.setLook(TableLook.casual, fromGift: true);

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TableLookScope(
          controller: look,
          child: GameScreen(level: Levels.byId(2), progress: progress),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(tableLookSettingsHintKey), findsOneWidget);
    expect(look.settingsHintPending, isFalse);
  });

  testWidgets('an early level says themes can be chosen in the menu', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'progress.tableCoachDone': true});
    final progress = await ProgressStore.open();
    final look = TableLookController(await TableLookStore.open());
    final l10n = lookupAppLocalizations(const Locale('en'));

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TableLookScope(
          controller: look,
          child: GameScreen(level: Levels.byId(2), progress: progress),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(tableLookSettingsHintKey), findsOneWidget);
    expect(find.text(l10n.tableLookSettingsHint), findsOneWidget);
    expect(look.settingsHintPending, isFalse);
  });

  testWidgets('level 1 shows the theme hint above the coach', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final progress = await ProgressStore.open();
    final look = TableLookController(await TableLookStore.open());
    final l10n = lookupAppLocalizations(const Locale('en'));

    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: TableLookScope(
          controller: look,
          child: GameScreen(level: Levels.byId(1), progress: progress),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(tableLookSettingsHintKey), findsOneWidget);
    expect(find.text(l10n.coachTapFree), findsOneWidget);
  });

  testWidgets('premium tiles render without a system-font fallback', (
    tester,
  ) async {
    final look = TableLookController(TableLookStore.memory());
    await look.setLook(TableLook.premium);
    const symbols = [
      'fruit-01',
      'soft-01',
      'character-01',
      'character-07',
      'bamboo-05',
      'dot-08',
      'dragon-02',
      'wind-north',
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
                    width: 60,
                    height: 60 * 1.2,
                    isSelected: i == 0,
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
    for (final symbol in symbols) {
      expect(find.byKey(Key(symbol)), findsOneWidget);
    }
  });

  test('premium tile body is a thicker plate than the classic sprite', () {
    const size = Size(80, 96);
    final classicFace = TileCanvas.faceRectOf(size);
    final premiumFace = PremiumTileLayout.faceRectOf(size);

    expect(premiumFace.width, lessThan(classicFace.width));
    expect(premiumFace.height, lessThan(classicFace.height));
  });

  test('PremiumTileCanvas.drawBody paints every state without throwing', () {
    const size = Size(80, 96);
    for (final locked in [false, true]) {
      for (final lifted in [false, true]) {
        for (final selected in [false, true]) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          PremiumTileCanvas.drawBody(
            canvas,
            size,
            isSelected: selected,
            locked: locked,
            lifted: lifted,
          );
          recorder.endRecording().dispose();
        }
      }
    }
  });

  test('TileGlyph draws hand-made premium glyphs for 4-9 and winds', () {
    const rect = Rect.fromLTWH(0, 0, 60, 80);
    final symbols = [
      for (var i = 4; i <= 9; i++) 'character-0$i',
      'wind-east',
      'wind-south',
      'wind-west',
      'wind-north',
    ];
    for (final symbol in symbols) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () => TileGlyph.draw(canvas, rect, symbol: symbol, premium: true),
        returnsNormally,
      );
      recorder.endRecording().dispose();
    }
  });
}
