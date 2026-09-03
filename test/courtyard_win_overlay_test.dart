import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/plot_kind.dart';
import 'package:mahjong/screens/game_screen.dart';
import 'package:mahjong/widgets/courtyard/courtyard_estate.dart';
import 'package:mahjong/widgets/courtyard/courtyard_progress.dart';
import 'package:mahjong/widgets/courtyard/courtyard_win_overlay.dart';
import 'package:mahjong/widgets/courtyard/courtyard_world.dart';
import 'package:mahjong/widgets/streak_lanterns.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('win overlay celebrates on the courtyard without a win screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          fit: StackFit.expand,
          children: [
            CourtyardWorld(
              from: CourtyardEstate.fromFocus(
                CourtyardSnapshot.fromStep(step: 2, totalStars: 3),
              ),
              to: CourtyardEstate.fromFocus(
                CourtyardSnapshot.fromStep(step: 3, totalStars: 5),
              ),
              animate: true,
            ),
            const CourtyardWinOverlay(),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('You win!'), findsOneWidget);
    expect(find.text('Another level cleared'), findsNothing);
    expect(find.text('Next'), findsNothing);
    expect(find.text('Play again'), findsNothing);
    expect(find.text('Courtyard'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(CourtyardWinOverlay), findsOneWidget);
    expect(find.byType(CourtyardWorld), findsOneWidget);
    expect(find.byType(StreakLanterns), findsNothing);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Image) return false;
        final image = widget.image;
        return image is AssetImage &&
            image.assetName.endsWith('world/country_base.png');
      }),
      findsWidgets,
    );
  });

  testWidgets('win overlay finishes after the celebration', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(home: CourtyardWinOverlay(onFinished: () => finished = true)),
    );
    await tester.pump();
    expect(finished, isFalse);
    expect(find.text('You win!'), findsOneWidget);

    await tester.pump(CourtyardWinOverlay.displayDuration);
    expect(finished, isTrue);
  });

  testWidgets('pond plot win overlay uses pond courtyard art', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Stack(
          fit: StackFit.expand,
          children: [
            CourtyardWorld(
              to: CourtyardEstate.fromFocus(
                CourtyardSnapshot.fromStep(
                  step: 24,
                  totalStars: 72,
                  plotKind: PlotKind.pond,
                ),
              ),
              animate: false,
            ),
            const CourtyardWinOverlay(),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Image) return false;
        final image = widget.image;
        return image is AssetImage &&
            image.assetName.endsWith('world/country_base.png');
      }),
      findsWidgets,
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('You win!'), findsOneWidget);
    expect(find.byType(CourtyardWorld), findsOneWidget);
  });

  test('game table pops back to the courtyard without a reverse animation', () {
    final route = GameScreen.route(const SizedBox());
    expect(route.reverseTransitionDuration, Duration.zero);
  });
}
