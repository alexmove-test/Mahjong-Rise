import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/widgets/courtyard/courtyard_progress.dart';
import 'package:mahjong/widgets/courtyard/courtyard_win_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('win overlay fills the screen with courtyard and victory copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CourtyardWinOverlay(
          levelId: 3,
          levelTitle: 'Sprout',
          score: 1200,
          stars: 2,
          isNewBest: true,
          unlockedNext: true,
          hasNext: true,
          nextUnlocked: true,
          courtyardFrom: CourtyardSnapshot.fromStep(step: 2, totalStars: 3),
          courtyardTo: CourtyardSnapshot.fromStep(step: 3, totalStars: 5),
          pathPhrase: 'Another step along the path.',
          firstHome: false,
          onMap: () {},
          onNext: () {},
          onRetry: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('You win!'), findsOneWidget);
    expect(find.text('Level 3 cleared!'), findsOneWidget);
    expect(find.text('Another step along the path.'), findsOneWidget);
    expect(find.text('Score: 1200'), findsOneWidget);
    expect(find.text('New best!'), findsOneWidget);
    expect(find.text('Courtyard'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.byType(CourtyardWinOverlay), findsOneWidget);
  });
}
