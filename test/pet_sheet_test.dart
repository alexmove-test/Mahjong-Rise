import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/pet_store.dart';
import 'package:mahjong/widgets/pets/pet_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('empty yard offers five companions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final pets = await PetStore.open();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PetSheet(height: 640, pets: pets),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Choose a companion'), findsOneWidget);
    expect(find.text('Cat'), findsOneWidget);
    expect(find.text('Dog'), findsOneWidget);
    expect(find.text('Raccoon'), findsOneWidget);
    expect(find.text('Hamster'), findsOneWidget);
    expect(find.text('Fox'), findsOneWidget);
    expect(find.text('Hunger'), findsNothing);
  });

  testWidgets('chosen pet shows mood, need bars, and add', (tester) async {
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
          body: PetSheet(height: 640, pets: pets),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Pet'), findsOneWidget);
    expect(find.text('Cat is content.'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Image) return false;
        final image = widget.image;
        return image is AssetImage && image.assetName.endsWith('pets/cat.png');
      }),
      findsOneWidget,
    );
    expect(find.text('Hunger'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Rest'), findsOneWidget);
    expect(
      find.text('Clear a table to help whoever needs you most.'),
      findsOneWidget,
    );
    expect(find.text('Add a companion'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(3));
  });

  testWidgets('add companion lists only pets not yet owned', (tester) async {
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
          body: PetSheet(height: 640, pets: pets),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Pets'), findsOneWidget);
    expect(find.text('Cat'), findsOneWidget);
    expect(find.text('Fox'), findsOneWidget);
    expect(find.text('Add a companion'), findsOneWidget);
    await tester.tap(find.text('Add a companion'));
    await tester.pump();

    expect(find.text('Dog'), findsOneWidget);
    expect(find.text('Raccoon'), findsOneWidget);
    expect(find.text('Hamster'), findsOneWidget);
    expect(find.text('Cat'), findsNothing);
    expect(find.text('Fox'), findsNothing);
  });
}
