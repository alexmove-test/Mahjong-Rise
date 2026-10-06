import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/pet.dart';
import 'package:mahjong/screens/level_select_screen.dart';
import 'package:mahjong/services/courtyard_reward_store.dart';
import 'package:mahjong/services/fox_adventure_store.dart';
import 'package:mahjong/services/pet_store.dart';
import 'package:mahjong/widgets/courtyard/courtyard_world.dart';
import 'package:mahjong/widgets/pets/courtyard_pet_invite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  setUp(
    () => SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 2,
      'progress.stars.1': 1,
      'progress.best.1': 400,
      'progress.lastPlayed': 1,
      'progress.courtyardPanHintDone': true,
      'pet.remindersPrompted': true,
    }),
  );

  test(
    'existing visitor joins companions without losing story or care',
    () async {
      final pets = await PetStore.open();
      final at = DateTime(2026, 9, 6);
      await pets.adopt(PetKind.cat, now: at);
      final story = await FoxAdventureStore.open();
      await story.attachExistingCompanion(pets);
      expect(pets.owns(PetKind.fox), isFalse);
      await story.start();
      await story.creditCampaignWin('one');
      await story.finishScene();
      await story.creditCampaignWin('two');
      await story.finishScene(blueBed: true);
      await story.attachExistingCompanion(pets);
      final foxCare = pets.lastSatisfied(PetNeed.hunger, kind: PetKind.fox);
      await story.attachExistingCompanion(pets);
      expect(pets.owned, [PetKind.cat, PetKind.fox]);
      expect(pets.lastSatisfied(PetNeed.hunger, kind: PetKind.cat), at);
      expect(pets.lastSatisfied(PetNeed.hunger, kind: PetKind.fox), foxCare);
      expect(story.stage, 2);
      expect(story.blueBed, isTrue);
    },
  );

  testWidgets('a pending courtyard gift does not offer a pet adventure', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 2,
      'progress.stars.1': 1,
      'progress.best.1': 400,
      'progress.lastPlayed': 1,
      'progress.courtyardPanHintDone': true,
      'pet.remindersPrompted': true,
      CourtyardRewardStore.storageKey: jsonEncode({
        'levels': [1, 2, 3],
      }),
    });
    Future<void> settleRoute() async {
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: LevelSelectScreen()));
    await settleRoute();
    expect(find.text('Choose a gift'), findsNothing);
    expect(
      find.byKey(const ValueKey('reward-option-adventure-fox_cozy')),
      findsNothing,
    );
    expect((await PetStore.open()).owns(PetKind.fox), isFalse);
    expect((await FoxAdventureStore.open()).started, isFalse);
    expect(find.byKey(courtyardPetAreaKey), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'pending story badge remains available when invitation is hidden',
    (tester) async {
      final pets = await PetStore.open();
      await pets.adopt(PetKind.fox);
      final story = await FoxAdventureStore.open();
      await story.start();
      await story.creditCampaignWin('one');
      await tester.pumpWidget(
        MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.centerRight,
              child: CourtyardPetInvite(
                pets: pets,
                adventure: story,
                onTap: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('Story ready · 1/3'), findsOneWidget);
      await tester.drag(
        find.byKey(const ValueKey('courtyard-pets')),
        const Offset(180, 0),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('courtyard-pets-tab')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('courtyard-pets-tab')));
      await tester.pump();
      expect(find.text('Story ready · 1/3'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
