import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/widgets/game_hud.dart';
import 'package:mahjong/widgets/score_popup.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  testWidgets('score popup shows pair points and combo', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ScorePopup(
            points: 125,
            combo: 2,
            onFinished: () => finished = true,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(ScorePopup), findsOneWidget);
    expect(find.text('+125'), findsOneWidget);
    expect(find.text('×2'), findsOneWidget);
    expect(finished, isFalse);

    await tester.pump(ScorePopup.displayDuration);
    expect(finished, isTrue);
  });

  testWidgets('first pair popup hides the combo mark', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ScorePopup(points: 100, combo: 1)),
      ),
    );
    await tester.pump();

    expect(find.text('+100'), findsOneWidget);
    expect(find.text('×1'), findsNothing);
  });

  testWidgets('hud no longer shows a standing score or combo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GameHud(
            onBack: () {},
            onMenu: () {},
            backTooltip: 'Back',
            menuTooltip: 'Menu',
          ),
        ),
      ),
    );

    expect(find.text('100'), findsNothing);
    expect(find.text('×1'), findsNothing);
  });
}
