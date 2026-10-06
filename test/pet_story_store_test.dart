import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mahjong/models/pet.dart';
import 'package:mahjong/models/pet_story.dart';
import 'package:mahjong/services/pet_story_store.dart';
import 'package:mahjong/widgets/pets/pet_story_section.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final foxCozy = PetStories.byId('fox_cozy')!;
  final foxLantern = PetStories.byId('fox_fireflies')!;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('first stories are offered before any companion is invited', () async {
    final store = await PetStoryStore.open();
    expect(store.offers.length, PetKind.values.length);
    expect(
      store.offers.map((story) => story.pet).toSet(),
      PetKind.values.toSet(),
    );
    expect(store.isUnlocked(foxCozy), isTrue);
    expect(store.currentFor(PetKind.fox), foxCozy);
  });

  test('grantChapter starts a story and adds one item', () async {
    final store = await PetStoryStore.open();
    expect(await store.grantChapter(foxCozy), isTrue);
    expect(store.active, foxCozy);
    expect(store.isStarted(foxCozy), isTrue);
    expect(store.progress(foxCozy), 1);
    expect(store.hasPendingMoment, isTrue);
    expect(await store.grantChapter(foxCozy), isFalse);
  });

  test('offers the next chapter after a gift is acknowledged', () async {
    final store = await PetStoryStore.open();
    await store.grantChapter(foxCozy);
    await store.acknowledgeMoment();
    expect(store.offers.any((story) => story.id == 'fox_cozy'), isTrue);
    expect(store.progress(foxCozy), 1);
  });

  test(
    'campaign wins still add chapters while a story is already open',
    () async {
      final store = await PetStoryStore.open();
      await store.grantChapter(foxCozy);
      await store.acknowledgeMoment();
      await store.creditCampaignWin('mid-story');
      expect(store.progress(foxCozy), 2);
      expect(store.hasPendingMoment, isTrue);
    },
  );

  test('library stays locked until the previous story is finished', () async {
    final store = await PetStoryStore.open();
    expect(store.isUnlocked(foxLantern), isFalse);
    for (var i = 0; i < 3; i++) {
      expect(await store.grantChapter(foxCozy), isTrue);
      await store.acknowledgeMoment();
    }
    expect(store.isComplete(foxCozy), isTrue);
    expect(store.isUnlocked(foxLantern), isTrue);
  });

  testWidgets('story section lists chapters without a start button', (
    tester,
  ) async {
    final store = await PetStoryStore.open();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: PetStorySection(store: store, pet: PetKind.fox, onPlay: () {}),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('start-story-fox_cozy')), findsNothing);
    expect(find.text('Start this adventure'), findsNothing);
    expect(find.text('Play'), findsOneWidget);
    expect(find.byIcon(Icons.card_giftcard_rounded), findsWidgets);
    expect(
      find.byKey(const ValueKey('story-item-reveal-fox_cozy-0')),
      findsOneWidget,
    );
  });
}
