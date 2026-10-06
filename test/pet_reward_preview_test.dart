import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mahjong/models/pet_story.dart';
import 'package:mahjong/services/pet_story_store.dart';
import 'package:mahjong/widgets/pets/pet_story_section.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('granting a chapter shows the story moment', (tester) async {
    final store = await PetStoryStore.open();
    final story = PetStories.byId('fox_cozy')!;
    expect(await store.grantChapter(story), isTrue);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showPetStoryMoment(context, store),
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('pet-story-moment')), findsOneWidget);
    expect(find.textContaining('Quiet clearing'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(store.hasPendingMoment, isFalse);
    expect(store.progress(story), 1);
  });
}
