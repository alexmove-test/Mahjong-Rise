import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/leaderboard_entry.dart';
import 'package:mahjong/models/rank_climb.dart';
import 'package:mahjong/widgets/rank_climb_overlay.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  RankClimb sample() {
    LeaderboardEntry row({
      required String id,
      required int rating,
      bool me = false,
    }) {
      return LeaderboardEntry(
        id: id,
        name: id,
        rating: rating,
        totalStars: 1,
        levelsUnlocked: 1,
        isCurrentPlayer: me,
      );
    }

    return RankClimb(
      rankFrom: 4,
      rankTo: 2,
      ratingFrom: 200,
      ratingTo: 450,
      player: row(id: 'Jade', rating: 450, me: true),
      passed: [
        row(id: 'Bob', rating: 400),
        row(id: 'Cara', rating: 300),
      ],
      stillAbove: [row(id: 'Ada', rating: 500)],
      below: [row(id: 'Drew', rating: 100)],
    );
  }

  testWidgets('rank climb overlay shows the overtaken names', (tester) async {
    final climb = sample();
    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: RankClimbOverlay(climb: climb)));
    await tester.pump();

    expect(find.byKey(rankClimbOverlayKey), findsOneWidget);
    expect(find.text('You climbed!'), findsOneWidget);
    expect(find.text('Place 4 → 2'), findsOneWidget);
    expect(find.text('Ada'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Cara'), findsOneWidget);
    expect(find.text('Jade'), findsOneWidget);
  });

  testWidgets('rank climb overlay finishes after the climb', (tester) async {
    final climb = sample();
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RankClimbOverlay(climb: climb, onFinished: () => finished = true),
      ),
    );
    await tester.pump();
    expect(finished, isFalse);

    await tester.pump(RankClimbOverlay.displayDurationFor(climb));
    await tester.pump();
    expect(finished, isTrue);
  });
}
