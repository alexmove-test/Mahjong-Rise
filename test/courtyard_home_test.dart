import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/pet.dart';
import 'package:mahjong/models/pet_story.dart';
import 'package:mahjong/services/pet_store.dart';
import 'package:mahjong/services/pet_story_store.dart';
import 'package:mahjong/widgets/courtyard/courtyard_estate.dart';
import 'package:mahjong/widgets/courtyard/courtyard_world.dart';
import 'package:mahjong/widgets/courtyard/plot_stage_view.dart';
import 'package:mahjong/widgets/pets/pet_portrait.dart';
import 'package:mahjong/widgets/pets/pet_story_section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('several owned pets can stand in the yard together', () async {
    final pets = await PetStore.open();
    await pets.adopt(PetKind.cat);
    await pets.adopt(PetKind.dog);
    await pets.adopt(PetKind.fox);
    expect(pets.yardPetKinds, [PetKind.cat]);
    await pets.setInYard(PetKind.dog, visible: true);
    expect((await PetStore.open()).yardPetKinds, [PetKind.cat, PetKind.dog]);
    await pets.setInYard(PetKind.fox, visible: true);
    expect(pets.yardPetKinds, [PetKind.cat, PetKind.dog, PetKind.fox]);
    await pets.setInYard(PetKind.hamster, visible: true);
    expect(pets.yardPetKinds, [PetKind.cat, PetKind.dog, PetKind.fox]);
    await pets.showAllInYard();
    expect(pets.allOwnedInYard, isTrue);
    await pets.setInYard(PetKind.dog, visible: false);
    expect(pets.yardPetKinds, [PetKind.cat, PetKind.fox]);
    expect(pets.isInYard(PetKind.dog), isFalse);
  });

  test('legacy single yard pet still loads into the visible set', () async {
    SharedPreferences.setMockInitialValues({
      'pet.owned': 'cat,dog',
      'pet.kind': 'cat',
      'pet.yardPet': 'dog',
    });
    final pets = await PetStore.open();
    expect(pets.yardPetKinds, [PetKind.dog]);
  });

  testWidgets('the yard shows one house and the selected pet story items', (
    tester,
  ) async {
    final pets = await PetStore.open();
    await pets.adopt(PetKind.raccoon);
    final stories = await PetStoryStore.open();
    final story = PetStories.forPet(PetKind.raccoon).first;
    await stories.grantChapter(story);
    await stories.acknowledgeMoment();
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CourtyardWorld(
            to: CourtyardEstate.fromUnlocked(30),
            pets: pets.yardCare(),
            petStories: stories,
            onPetTap: () => opened = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(courtyardHomeKey), findsOneWidget);
    expect(find.byKey(courtyardPondKey), findsOneWidget);
    expect(find.byKey(courtyardPetAreaKey), findsOneWidget);
    expect(find.byType(PlotStageView), findsNWidgets(2));
    expect(find.byType(PetStoryItemView), findsNWidgets(3));
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byKey(courtyardPetStartAdventureKey), findsNothing);
    expect(find.byKey(courtyardPetVisitKey), findsOneWidget);
    expect(find.text('Visit the den'), findsOneWidget);
    expect(
      tester.getBottomLeft(find.byKey(courtyardPetVisitKey)).dy,
      lessThan(tester.getTopLeft(find.byType(PetPortrait)).dy + 8),
    );
    // Название истории живёт на странице питомца, во дворе — предметы и приглашение.
    expect(find.text('Shiny Workshop · 1/3'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('courtyard-pets')));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the yard invites a companion to visit', (tester) async {
    final pets = await PetStore.open();
    await pets.adopt(PetKind.cat);
    final stories = await PetStoryStore.open();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CourtyardWorld(
            to: CourtyardEstate.fromUnlocked(30),
            pets: pets.yardCare(),
            petStories: stories,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(courtyardPetVisitKey), findsOneWidget);
    expect(find.text('Visit the den'), findsOneWidget);
    expect(find.text('Start an adventure'), findsNothing);
    expect(find.byKey(courtyardPetStartAdventureKey), findsNothing);
    expect(find.byType(PetPortrait), findsOneWidget);
    expect(
      tester.getCenter(find.byKey(courtyardPetVisitKey)).dy,
      lessThan(tester.getCenter(find.byType(PetPortrait)).dy),
    );
  });

  testWidgets('the yard can show every companion at once', (tester) async {
    final pets = await PetStore.open();
    await pets.adopt(PetKind.cat);
    await pets.adopt(PetKind.dog);
    await pets.adopt(PetKind.fox);
    await pets.showAllInYard();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: CourtyardWorld(
            to: CourtyardEstate.fromUnlocked(30),
            pets: pets.yardCare(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PetPortrait), findsNWidgets(3));
    expect(find.byKey(const ValueKey('courtyard-pet-cat')), findsOneWidget);
    expect(find.byKey(const ValueKey('courtyard-pet-dog')), findsOneWidget);
    expect(find.byKey(const ValueKey('courtyard-pet-fox')), findsOneWidget);
    expect(find.byKey(courtyardPetVisitKey), findsOneWidget);
  });
}
