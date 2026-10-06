import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/fox_adventure_store.dart';
import 'package:mahjong/screens/level_select_screen.dart';
import 'package:mahjong/widgets/pets/fox_adventure.dart';
import 'package:mahjong/widgets/pets/pet_story_section.dart';
import 'package:mahjong/widgets/courtyard/courtyard_world.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'three victories persist with decoration choices and deduplicate replays',
    () async {
      final store = await FoxAdventureStore.open();
      await store.creditCampaignWin('before-start');
      expect(store.stage, 0);
      await store.start();
      await Future.wait([
        store.creditCampaignWin('attempt-1'),
        store.creditCampaignWin('attempt-1'),
      ]);
      expect(store.stage, 1);
      expect(store.pending, isTrue);
      final reopened = await FoxAdventureStore.open();
      expect(reopened.pending, isTrue);
      await reopened.finishScene();
      await reopened.creditCampaignWin('attempt-1');
      expect(reopened.stage, 1);
      await reopened.creditCampaignWin('attempt-2');
      await reopened.finishScene(blueBed: true);
      await reopened.creditCampaignWin('attempt-3');
      await reopened.finishScene(plushToy: true);
      await reopened.creditCampaignWin('attempt-4');
      final complete = await FoxAdventureStore.open();
      expect(complete.complete, isTrue);
      expect(complete.pending, isFalse);
      expect(complete.blueBed, isTrue);
      expect(complete.plushToy, isTrue);
      await complete.start();
      expect(complete.stage, 3);
    },
  );

  test(
    'pending scene survives leaving and cannot be overwritten by another win',
    () async {
      final store = await FoxAdventureStore.open();
      await store.start();
      await store.creditCampaignWin('one');
      await store.creditCampaignWin('two');
      expect(store.stage, 1);
      expect((await FoxAdventureStore.open()).pending, isTrue);
    },
  );

  testWidgets('story starts, preserves deferred scene and saves both choices', (
    tester,
  ) async {
    final store = await FoxAdventureStore.open();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showFoxAdventure(context, store),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    Future<void> open() async {
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    await open();
    await tester.tap(find.text('Help · 3 stages'));
    await tester.pumpAndSettle();
    expect(store.started, isTrue);
    await store.creditCampaignWin('one');
    await open();
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(store.pending, isTrue);
    await open();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await store.creditCampaignWin('two');
    await open();
    await tester.tap(find.text('Sky blue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(store.blueBed, isTrue);
    await store.creditCampaignWin('three');
    await open();
    await tester.tap(find.text('Plush toy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lovely!'));
    await tester.pumpAndSettle();
    expect(store.plushToy, isTrue);
    await open();
    expect(find.byKey(const ValueKey('fox-bed')), findsOneWidget);
    expect(find.byKey(const ValueKey('fox-toy')), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('story fits a narrow screen with large text', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = await FoxAdventureStore.open();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showFoxAdventure(context, store),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Help · 3 stages'), findsOneWidget);
  });

  testWidgets('courtyard migrates and restores a pending fox chapter', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 2,
      'progress.stars.1': 1,
      'progress.best.1': 400,
      'progress.lastPlayed': 1,
      'progress.courtyardPanHintDone': true,
    });
    final store = await FoxAdventureStore.open();
    await store.start();
    await store.creditCampaignWin('one');
    await store.finishScene();
    await store.creditCampaignWin('two');
    Future<void> pumpHub() async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: LevelSelectScreen()));
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await pumpHub();
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Continue'),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(petStoryMomentKey), findsNothing);
    expect(find.byKey(courtyardPetAreaKey), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpHub();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(FoxCorner), findsNothing);
    expect(find.byKey(courtyardPetAreaKey), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
