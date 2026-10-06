import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/courtyard_reward.dart';
import 'package:mahjong/models/plot_kind.dart';
import 'package:mahjong/models/table_look.dart';
import 'package:mahjong/screens/level_select_screen.dart';
import 'package:mahjong/services/courtyard_reward_store.dart';
import 'package:mahjong/widgets/courtyard/courtyard_estate.dart';
import 'package:mahjong/widgets/courtyard/courtyard_world.dart';
import 'package:mahjong/widgets/courtyard/courtyard_progress.dart';
import 'package:mahjong/widgets/hub_goal_banner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('every three unique first clears unlock one remaining choice', () async {
    final store = await CourtyardRewardStore.open();
    await Future.wait([
      store.recordFirstClear(1),
      store.recordFirstClear(1),
      store.recordFirstClear(2),
    ]);
    expect(store.seriesProgress, 2);
    expect(store.remaining, 1);
    expect(store.pendingChoice, isFalse);

    await store.recordFirstClear(3);
    expect(store.pendingChoice, isTrue);
    await store.recordFirstClear(4);
    expect(store.creditedLevels, [1, 2, 3]);

    expect(await store.choose(CourtyardReward.swing), isTrue);
    expect(store.owned, {CourtyardReward.swing});
    expect(store.seriesProgress, 0);

    for (final level in [4, 5, 6]) {
      await store.recordFirstClear(level);
    }
    expect(store.pendingChoice, isTrue);
    expect(await store.choose(CourtyardReward.swing), isFalse);
    expect(await store.choose(CourtyardReward.pond), isTrue);

    for (final level in [7, 8, 9]) {
      await store.recordFirstClear(level);
    }
    expect(await store.choose(CourtyardReward.flowerBed), isTrue);
    expect(store.owned, {
      CourtyardReward.swing,
      CourtyardReward.pond,
      CourtyardReward.flowerBed,
    });
    expect(store.complete, isFalse);
    expect(store.pendingChoice, isFalse);
    await store.recordFirstClear(10);
    expect(store.creditedLevels, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  });

  test('adventure gifts spend the same three-win token', () async {
    final store = await CourtyardRewardStore.open();
    for (final level in [1, 2, 3]) {
      await store.recordFirstClear(level);
    }
    expect(await store.chooseAdventure(), isTrue);
    expect(store.adventureChoices, 1);
    expect(store.pendingChoice, isFalse);
    expect(await store.chooseAdventure(), isFalse);
  });

  test('table looks spend the same three-win token', () async {
    final store = await CourtyardRewardStore.open();
    for (final level in [1, 2, 3]) {
      await store.recordFirstClear(level);
    }
    expect(store.giftableLooks, TableLook.giftLooks);
    expect(await store.chooseLook(TableLook.casual), isTrue);
    expect(store.ownedLooks, {TableLook.casual});
    expect(store.isLookUnlocked(TableLook.casual), isTrue);
    expect(store.isLookUnlocked(TableLook.classic), isFalse);
    expect(store.pendingChoice, isFalse);
    expect(await store.chooseLook(TableLook.classic), isFalse);
    expect(await store.chooseLook(TableLook.premium), isFalse);
  });

  test('legacy table look stays unlocked without spending a gift', () async {
    final store = await CourtyardRewardStore.open();
    for (final level in [1, 2, 3]) {
      await store.recordFirstClear(level);
    }
    expect(store.pendingChoice, isTrue);
    await store.grandfatherLook(TableLook.classic);
    expect(store.legacyLooks, {TableLook.classic});
    expect(store.ownedLooks, isEmpty);
    expect(store.spentChoices, 0);
    expect(store.pendingChoice, isTrue);
    expect(store.giftableLooks, [TableLook.casual]);
    expect(await store.chooseLook(TableLook.classic), isFalse);
    expect(await store.chooseLook(TableLook.casual), isTrue);
    expect(store.ownedLooks, {TableLook.casual});
  });

  test(
    'existing campaign progress is credited only on first feature load',
    () async {
      final store = await CourtyardRewardStore.open();
      await store.bootstrapCompleted([1, 2, 3, 4, 5]);
      expect(store.creditedLevels, [1, 2, 3, 4, 5]);
      expect(store.pendingChoice, isTrue);
      await store.bootstrapCompleted([6, 7, 8, 9]);
      expect(store.creditedLevels, [1, 2, 3, 4, 5]);
    },
  );

  testWidgets('hub does not offer another courtyard build as a gift', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 2,
      'progress.stars.1': 1,
      'progress.best.1': 400,
      'progress.lastPlayed': 1,
      'progress.courtyardPanHintDone': true,
      CourtyardRewardStore.storageKey: jsonEncode({
        'levels': [1, 2, 3],
      }),
    });
    await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: LevelSelectScreen()));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Choose a gift'), findsNothing);
    expect(find.text('Little pond'), findsNothing);
    expect(find.text('Garden swing'), findsNothing);
    expect(find.text('Flower bed'), findsNothing);
    expect(find.byKey(const ValueKey('courtyard-reward-progress')), findsNothing);
    expect(find.byType(HubGoalBanner), findsOneWidget);
    expect((await CourtyardRewardStore.open()).owned, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('owned choices appear together in the courtyard', (tester) async {
    final estate = CourtyardEstate.fromFocus(
      CourtyardSnapshot.fromStep(
        step: 3,
        totalStars: 3,
        plotKind: PlotKind.house,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CourtyardWorld(
          to: estate,
          interactive: false,
          courtyardRewards: const {
            CourtyardReward.pond,
            CourtyardReward.swing,
            CourtyardReward.flowerBed,
          },
        ),
      ),
    );
    await tester.pump();
    for (final reward in CourtyardReward.values) {
      expect(
        find.byKey(ValueKey('courtyard-reward-${reward.name}')),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });
}
