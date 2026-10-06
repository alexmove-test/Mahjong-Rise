import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/l10n/l10n.dart';
import 'package:mahjong/models/hub_goal.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/models/plot_kind.dart';
import 'package:mahjong/models/weekly_quests.dart';
import 'package:mahjong/services/hub_goals.dart';
import 'package:mahjong/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ru = lookupAppLocalizations(const Locale('ru'));
  final now = DateTime(2026, 9, 5);

  Future<ProgressStore> openProgress(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    return ProgressStore.open();
  }

  test(
    'end of the first stretch teases the house, not the pond plot',
    () async {
      final progress = await openProgress({
        'progress.maxUnlocked': 23,
        'progress.stars.1': 1,
        'progress.dailyStreak': 0,
      });

      final goal = HubGoals.pick(progress: progress, now: now);

      expect(goal?.kind, HubGoalKind.plotLook);
      expect(goal?.plot, PlotKind.house);
      expect(goal?.kind, isNot(HubGoalKind.plotUnlock));
      expect(en.hubGoalText(goal!).contains('Pond'), isFalse);
      expect(ru.hubGoalText(goal).contains('ставк'), isFalse);
      expect(en.hubGoalText(goal), '100 points short');
      expect(ru.hubGoalText(goal), 'Не хватает 100 поинтов');
    },
  );

  test('a finished house does not offer the pond for purchase', () async {
    final progress = await openProgress({
      'progress.maxUnlocked': 25,
      'progress.stars.1': 1,
    });

    final goal = HubGoals.pick(
      progress: progress,
      now: now,
      houseState: 24,
      pointsBalance: 5000,
    );

    expect(goal, isNull);
  });

  test('an affordable house names its price instead of levels left', () async {
    final progress = await openProgress({'progress.maxUnlocked': 1});

    final goal = HubGoals.pick(
      progress: progress,
      now: now,
      houseState: 5,
      pointsBalance: 300,
    );

    expect(goal?.pointsCost, 300);
    expect(goal?.pointsShort, 0);
    expect(en.hubGoalText(goal!), 'House upgrade · 300');
    expect(ru.hubGoalText(goal), 'Улучшение дома — 300');
  });

  test('does not tease a daily when the pond is still far', () async {
    final progress = await openProgress({
      'progress.maxUnlocked': 6,
      'progress.stars.1': 1,
      'progress.dailyStreak': 2,
      'progress.dailyDate': '2026-09-04',
    });

    final goal = HubGoals.pick(progress: progress, now: now);

    expect(goal?.kind, isNot(HubGoalKind.dailyReward));
    expect(goal?.kind, HubGoalKind.plotLook);
    expect(goal?.plot, PlotKind.house);
    expect(en.hubGoalText(goal!).contains('Pond'), isFalse);
    expect(ru.hubGoalText(goal).contains('ставк'), isFalse);
    expect(en.hubGoalText(goal), '100 points short');
    expect(ru.hubGoalText(goal), 'Не хватает 100 поинтов');
  });

  test('daily weekly quests do not become the hub banner', () async {
    final progress = await openProgress({
      'progress.maxUnlocked': 6,
      'progress.stars.1': 1,
    });
    const dailies = [
      QuestProgress(
        def: QuestDef(id: 'daily3', kind: QuestKind.dailyWins, target: 3),
        current: 2,
        claimed: false,
      ),
      QuestProgress(
        def: QuestDef(id: 'streak3', kind: QuestKind.streakHold, target: 3),
        current: 2,
        claimed: false,
      ),
    ];

    for (final quest in dailies) {
      final goal = HubGoals.pick(progress: progress, quests: [quest], now: now);

      expect(goal?.kind, isNot(HubGoalKind.questRemain));
      expect(goal?.kind, isNot(HubGoalKind.dailyReward));
      expect(goal?.kind, HubGoalKind.plotLook);
    }
  });

  test('level that opens pets is the tease when that plot is next', () async {
    final progress = await openProgress({
      'progress.maxUnlocked': 72,
      'progress.stars.1': 1,
      'progress.dailyStreak': 7,
      'progress.dailyDate': '2026-09-05',
    });

    final goal = HubGoals.pick(progress: progress, hasPet: false, now: now);

    expect(goal?.kind, HubGoalKind.petUnlock);
    expect(goal?.levelId, Levels.plotStartId(PlotKind.pets));
    expect(goal?.remaining, 1);
    expect(en.hubGoalText(goal!), 'Level 73 unlocks a pet');
    expect(ru.hubGoalText(goal), 'Уровень 73 откроет питомца');
  });

  test('a claimable weekly quest is closer than any remaining count', () async {
    final progress = await openProgress({
      'progress.maxUnlocked': 23,
      'progress.stars.1': 1,
      'progress.dailyStreak': 2,
    });
    const quest = QuestProgress(
      def: QuestDef(id: 'stars8', kind: QuestKind.stars, target: 8),
      current: 8,
      claimed: false,
    );

    final goal = HubGoals.pick(
      progress: progress,
      quests: const [quest],
      now: now,
    );

    expect(goal?.kind, HubGoalKind.questClaim);
    expect(en.hubGoalText(goal!), 'Weekly reward is ready');
    expect(ru.hubGoalText(goal), 'Награда недели ждёт');
  });

  test('quest remaining uses the same countdown voice', () async {
    final progress = await openProgress({
      'progress.maxUnlocked': 34,
      'progress.dailyStreak': 7,
      'progress.dailyDate': '2026-09-05',
    });
    const quest = QuestProgress(
      def: QuestDef(id: 'stars8', kind: QuestKind.stars, target: 8),
      current: 6,
      claimed: false,
    );

    final goal = HubGoals.pick(
      progress: progress,
      quests: const [quest],
      now: now,
    );

    expect(goal?.kind, HubGoalKind.questRemain);
    expect(goal?.remaining, 2);
    expect(en.hubGoalText(goal!), '2 more stars until the reward');
    expect(ru.hubGoalText(goal), 'ещё 2 звезды до награды');
  });
}
