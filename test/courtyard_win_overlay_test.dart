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
          stars: 2,
          hasNext: true,
          nextUnlocked: true,
          courtyardFrom: CourtyardSnapshot.fromStep(step: 2, totalStars: 3),
          courtyardTo: CourtyardSnapshot.fromStep(step: 3, totalStars: 5),
          pathPhrase: 'Another step along the path.',
          onMap: () {},
          onNext: () {},
          onRetry: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('You win!'), findsOneWidget);
    expect(find.text('Another level cleared'), findsOneWidget);
    expect(find.text('Another step along the path.'), findsOneWidget);
    expect(find.text('Courtyard'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.textContaining('Score'), findsNothing);
    expect(find.text('Sprout'), findsNothing);
    expect(find.textContaining('Level'), findsNothing);
    expect(find.byType(CourtyardWinOverlay), findsOneWidget);

    final nextButton = tester.widget<FilledButton>(
      find.ancestor(of: find.text('Next'), matching: find.byType(FilledButton)),
    );
    expect(nextButton.style?.backgroundColor?.resolve({}), const Color(0xFFD4AF37));
  });

  testWidgets('daily win overlay uses courtyard and hides stars', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CourtyardWinOverlay(
          stars: 0,
          hasNext: false,
          nextUnlocked: false,
          showStars: false,
          title: 'Daily complete',
          subtitle: 'Streak: 3',
          courtyardFrom: CourtyardSnapshot.fromStep(step: 4, totalStars: 6),
          courtyardTo: CourtyardSnapshot.fromStep(
            step: 4,
            totalStars: 6,
            streak: 3,
            festival: true,
          ),
          pathPhrase: 'The house feels warmer.',
          onMap: () {},
          onNext: () {},
          onRetry: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Daily complete'), findsOneWidget);
    expect(find.text('Streak: 3'), findsOneWidget);
    expect(find.text('You win!'), findsNothing);
    expect(find.text('Play again'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
  });

  testWidgets('second plot win overlay uses cartoon courtyard art', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CourtyardWinOverlay(
          stars: 3,
          hasNext: true,
          nextUnlocked: true,
          cycle: 1,
          courtyardFrom: CourtyardSnapshot.fromStep(step: 22, totalStars: 60),
          courtyardTo: CourtyardSnapshot.fromStep(step: 24, totalStars: 72),
          pathPhrase: 'The house rose from your wins.',
          onMap: () {},
          onNext: () {},
          onRetry: () {},
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Image) return false;
        final image = widget.image;
        return image is AssetImage && image.assetName.contains('/plot2/');
      }),
      findsWidgets,
    );
  });
}
