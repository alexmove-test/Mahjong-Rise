import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/weekly_quests.dart';
import 'package:mahjong/widgets/liveops/weekly_quests_strip.dart';
import 'package:mahjong/widgets/streak_lanterns.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('daily lanterns render the three-night ritual', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StreakLanterns(
            litCount: 2,
            waitingNext: false,
            celebrate: false,
            idle: false,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(StreakLanterns), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('streak quest card shows lanterns instead of a fraction', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WeeklyQuestsStrip(
            quests: [
              QuestProgress(
                def: QuestDef.byId('streak3')!,
                current: 2,
                claimed: false,
              ),
            ],
            onClaim: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Keep three nights lit'), findsOneWidget);
    expect(find.text('2/3'), findsNothing);
    expect(find.byType(StreakLanterns), findsOneWidget);
  });
}
