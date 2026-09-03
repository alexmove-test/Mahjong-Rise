import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/pet_store.dart';
import 'package:mahjong/widgets/pets/courtyard_pet_invite.dart';
import 'package:mahjong/widgets/pets/pet_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _petAsset(String name) {
  return find.byWidgetPredicate((widget) {
    if (widget is! Image) return false;
    final image = widget.image;
    return image is AssetImage && image.assetName.endsWith('pets/$name.png');
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('invite without a pet asks the player to visit', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final pets = await PetStore.open();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourtyardPetInvite(pets: pets, onTap: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('A friend is waiting'), findsOneWidget);
  });

  testWidgets('invite with a content pet shows its mood', (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'pet.kind': 'cat',
      'pet.hungerAt': now,
      'pet.playAt': now,
      'pet.restAt': now,
    });
    final pets = await PetStore.open();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourtyardPetInvite(pets: pets, onTap: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Cat is content.'), findsOneWidget);
    expect(_petAsset('cat'), findsOneWidget);
  });

  testWidgets('invite with several pets shows every companion', (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'pet.owned': 'cat,fox',
      'pet.kind': 'cat',
      'pet.cat.hungerAt': now,
      'pet.cat.playAt': now,
      'pet.cat.restAt': now,
      'pet.fox.hungerAt': now,
      'pet.fox.playAt': now,
      'pet.fox.restAt': now,
    });
    final pets = await PetStore.open();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourtyardPetInvite(pets: pets, onTap: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(_petAsset('cat'), findsOneWidget);
    expect(_petAsset('fox'), findsOneWidget);
    expect(find.text('Cat is content.'), findsOneWidget);
    expect(find.text('Fox is content.'), findsOneWidget);
  });

  testWidgets('swiping the yard pets right hides them behind a tab', (
    tester,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'pet.owned': 'cat,fox',
      'pet.kind': 'cat',
      'pet.cat.hungerAt': now,
      'pet.cat.playAt': now,
      'pet.cat.restAt': now,
      'pet.fox.hungerAt': now,
      'pet.fox.playAt': now,
      'pet.fox.restAt': now,
    });
    final pets = await PetStore.open();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.centerRight,
            child: CourtyardPetInvite(pets: pets, onTap: () {}),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.drag(
      find.byKey(const ValueKey('courtyard-pets')),
      const Offset(180, 0),
    );
    await tester.pump();

    expect(find.text('Cat is content.'), findsNothing);
    expect(_petAsset('cat'), findsNothing);
    expect(find.byKey(const ValueKey('courtyard-pets-tab')), findsOneWidget);
    expect(pets.yardHidden, isTrue);

    await tester.tap(find.byKey(const ValueKey('courtyard-pets-tab')));
    await tester.pump();

    expect(find.text('Cat is content.'), findsOneWidget);
    expect(find.text('Fox is content.'), findsOneWidget);
    expect(pets.yardHidden, isFalse);
  });

  testWidgets('invite with a hungry pet shows starving mood', (tester) async {
    final now = DateTime.now();
    SharedPreferences.setMockInitialValues({
      'pet.kind': 'dog',
      'pet.hungerAt': now
          .subtract(const Duration(hours: 12))
          .millisecondsSinceEpoch,
      'pet.playAt': now.millisecondsSinceEpoch,
      'pet.restAt': now.millisecondsSinceEpoch,
    });
    final pets = await PetStore.open();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CourtyardPetInvite(pets: pets, onTap: () {}),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Dog is starving.'), findsOneWidget);
    expect(_petAsset('dog'), findsOneWidget);
  });

  testWidgets('empty pet page offers five companions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final pets = await PetStore.open();

    await tester.pumpWidget(MaterialApp(home: PetPage(pets: pets)));
    await tester.pump();

    expect(find.text('Choose a companion'), findsOneWidget);
    expect(find.text('Cat'), findsOneWidget);
    expect(find.text('Dog'), findsOneWidget);
    expect(find.text('Raccoon'), findsOneWidget);
    expect(find.text('Hamster'), findsOneWidget);
    expect(_petAsset('cat'), findsOneWidget);
    expect(_petAsset('dog'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Fox'), 80);
    expect(find.text('Fox'), findsOneWidget);
    expect(_petAsset('fox'), findsOneWidget);
    expect(find.text('Hunger'), findsNothing);
  });

  testWidgets('owned pet page shows portrait, mood, and need bars', (
    tester,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'pet.kind': 'cat',
      'pet.hungerAt': now,
      'pet.playAt': now,
      'pet.restAt': now,
    });
    final pets = await PetStore.open();

    await tester.pumpWidget(MaterialApp(home: PetPage(pets: pets)));
    await tester.pump();

    expect(find.text('Pet'), findsOneWidget);
    expect(find.text('Cat'), findsOneWidget);
    expect(find.text('Cat is content.'), findsOneWidget);
    expect(_petAsset('cat'), findsOneWidget);
    expect(find.text('Hunger'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Rest'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
    await tester.scrollUntilVisible(find.text('Add a companion'), 80);
    expect(find.text('Add a companion'), findsOneWidget);
  });

  testWidgets('owned pet page lists every companion', (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      'pet.owned': 'cat,dog',
      'pet.kind': 'cat',
      'pet.cat.hungerAt': now,
      'pet.cat.playAt': now,
      'pet.cat.restAt': now,
      'pet.dog.hungerAt': now,
      'pet.dog.playAt': now,
      'pet.dog.restAt': now,
    });
    final pets = await PetStore.open();

    await tester.pumpWidget(MaterialApp(home: PetPage(pets: pets)));
    await tester.pump();

    expect(find.text('Pets'), findsOneWidget);
    expect(find.text('Cat'), findsOneWidget);
    expect(find.text('Dog'), findsOneWidget);
    expect(find.text('Cat is content.'), findsOneWidget);
    expect(find.text('Dog is content.'), findsOneWidget);
    expect(_petAsset('cat'), findsOneWidget);
    expect(_petAsset('dog'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(6));
  });

  testWidgets('openPetPage slides in the pet section', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final pets = await PetStore.open();

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => openPetPage(context, pets: pets),
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 420));

    expect(find.text('Choose a companion'), findsOneWidget);
    expect(find.text('Cat'), findsOneWidget);
  });
}
