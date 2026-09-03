import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/models/weekly_quests.dart';
import 'package:mahjong/services/progress_store.dart';
import 'package:mahjong/services/quest_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('campaign wins credit stars, clears and 3-star quests', () async {
    SharedPreferences.setMockInitialValues({});
    final progress = await ProgressStore.open();
    await progress.ensureWeek(DateTime(2026, 8, 24));
    final quests = await QuestStore.open();
    await quests.ensureWeek(DateTime(2026, 8, 24));

    await progress.recordWin(
      level: Levels.byId(1),
      score: 1200,
      now: DateTime(2026, 8, 24),
    );
    await quests.creditCampaignWin(
      starsGained: 3,
      firstClear: true,
      threeStar: true,
    );

    expect(progress.weeklyStars, 3);
    expect(progress.weeklyClears, 1);
    expect(progress.weeklyDailies, 0);

    expect(quests.quests, isNotEmpty);
    for (final quest in quests.quests) {
      if (quest.def.kind == QuestKind.stars) {
        expect(quest.current, 3);
      } else if (quest.def.kind == QuestKind.campaignClears) {
        expect(quest.current, 1);
      } else if (quest.def.kind == QuestKind.threeStar) {
        expect(quest.current, 1);
      } else {
        expect(quest.current, 0);
      }
    }
  });

  test('daily wins credit daily and streak quests and can be claimed', () async {
    SharedPreferences.setMockInitialValues({});
    final progress = await ProgressStore.open();
    final quests = await QuestStore.open();
    await progress.ensureWeek(DateTime(2026, 8, 24));
    await quests.ensureWeek(DateTime(2026, 8, 24));

    await progress.recordDailyWin(now: DateTime(2026, 8, 24));
    await quests.creditDailyWin(streak: 1, now: DateTime(2026, 8, 24));
    await progress.recordDailyWin(now: DateTime(2026, 8, 25));
    await quests.creditDailyWin(streak: 2, now: DateTime(2026, 8, 25));
    await progress.recordDailyWin(now: DateTime(2026, 8, 26));
    await quests.creditDailyWin(streak: 3, now: DateTime(2026, 8, 26));

    expect(progress.weeklyDailies, 3);

    for (final quest in quests.quests) {
      if (quest.def.kind == QuestKind.dailyWins && quest.def.target <= 3) {
        expect(quest.complete, isTrue);
        expect(quest.canClaim, isTrue);
        final hintsBefore = progress.bankedHints;
        final shufflesBefore = progress.bankedShuffles;
        expect(await quests.claim(quest.def.id, progress), isTrue);
        expect(progress.bankedHints, hintsBefore + 1);
        expect(progress.bankedShuffles, shufflesBefore + 1);
        expect(await quests.claim(quest.def.id, progress), isFalse);
      }
      if (quest.def.kind == QuestKind.streakHold && quest.def.target <= 3) {
        expect(quest.complete, isTrue);
      }
    }
  });

  test('new ISO week resets quest progress', () async {
    SharedPreferences.setMockInitialValues({});
    final quests = await QuestStore.open();
    await quests.ensureWeek(DateTime(2026, 8, 24));
    await quests.creditDailyWin(streak: 1, now: DateTime(2026, 8, 24));
    expect(quests.quests.any((q) => q.current > 0), isTrue);

    await quests.ensureWeek(DateTime(2026, 8, 31));
    expect(quests.weekId, '2026-W36');
    expect(quests.quests.every((q) => q.current == 0), isTrue);
    expect(quests.claimedCount, 0);
  });
}
