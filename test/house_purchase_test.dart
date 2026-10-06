import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/house_upgrade.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/models/plot_kind.dart';
import 'package:mahjong/models/points_award.dart';
import 'package:mahjong/services/courtyard_reward_store.dart';
import 'package:mahjong/services/points_controller.dart';
import 'package:mahjong/services/points_store.dart';
import 'package:mahjong/services/progress_store.dart';
import 'package:mahjong/widgets/courtyard/courtyard_estate.dart';
import 'package:mahjong/widgets/courtyard/courtyard_lot_build.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('prices step by 50 from 100 and stop at the last look', () {
    expect(HouseUpgrade.priceAfter(1), 100);
    expect(HouseUpgrade.priceAfter(2), 150);
    expect(HouseUpgrade.priceAfter(3), 200);
    expect(HouseUpgrade.priceAfter(5), 300);
    expect(HouseUpgrade.priceAfter(23), 1200);
    expect(HouseUpgrade.canAdvance(24), isFalse);
    expect(HouseUpgrade.fromCampaignFrame(0), 1);
  });

  test('a new player starts on the first look with an empty wallet', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await PointsStore.open();

    expect(store.houseMigrated, isTrue);
    expect(store.houseState, 1);
    expect(store.balance, 0);
    expect((await PointsStore.open()).houseState, 1);
  });

  test('migration keeps the reached house and the balance, once', () async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 5,
      'points.balance': 80,
      'points.earned': 80,
    });
    final campaign = CourtyardEstate.fromUnlocked(5).campaignStage;
    final expected = HouseUpgrade.fromCampaignFrame(
      PlotStages.currentFrame(campaign),
    );
    expect(expected, greaterThan(1));

    final first = await PointsStore.open();
    expect(first.houseState, expected);
    expect(first.balance, 80);

    final progress = await ProgressStore.open();
    await progress.recordWin(
      level: Levels.byId(5),
      score: Levels.byId(5).starsThresholds.$1,
    );
    final second = await PointsStore.open();
    expect(second.houseState, expected);
    expect(second.balance, 80);
    expect(second.houseMigrated, isTrue);
  });

  test('a mahjong win pays points and leaves the house where it is', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 40,
      'points.houseMigrated': true,
      'points.houseState': 3,
    });
    final points = await PointsStore.open();
    final progress = await ProgressStore.open();
    final before = CourtyardEstate.fromStore(
      progress,
      purchasedHome: points.houseState,
    );
    final level = Levels.byId(1);
    final result = await progress.recordWin(
      level: level,
      score: level.starsThresholds.$1,
    );
    final award = PointsAward.campaignWin(
      stars: result.earnedStars,
      firstClear: result.firstClear,
      isNewBest: result.isNewBest,
    );
    await points.add(award.total);

    final after = CourtyardEstate.fromStore(
      progress,
      purchasedHome: points.houseState,
    );
    expect(award.total, greaterThan(0));
    expect(points.balance, 40 + award.total);
    expect(points.houseState, 3);
    expect(after.homeStage, before.homeStage);
    expect(after.purchasedHome, 3);
  });

  test('buying spends the exact price and advances one look', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 1000,
      'points.earned': 1000,
      'points.houseMigrated': true,
      'points.houseState': 2,
    });
    final store = await PointsStore.open();
    final result = await store.buyNextHouse();

    expect(result.purchased, isTrue);
    expect(result.price, 150);
    expect(store.balance, 850);
    expect(store.houseState, 3);
    expect(store.lifetimeEarned, 1000);

    final reopened = await PointsStore.open();
    expect(reopened.balance, 850);
    expect(reopened.houseState, 3);
  });

  test('a short wallet changes nothing', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 99,
      'points.houseMigrated': true,
      'points.houseState': 1,
    });
    final store = await PointsStore.open();
    final result = await store.buyNextHouse();

    expect(result.status, HouseBuyStatus.insufficient);
    expect(result.shortfall, 1);
    expect(store.balance, 99);
    expect(store.houseState, 1);
  });

  test('a second tap while the first is running does not buy twice', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 1000,
      'points.houseMigrated': true,
      'points.houseState': 1,
    });
    final controller = PointsController(await PointsStore.open());
    final first = controller.buyNextHouse();
    final second = controller.buyNextHouse();
    final results = await Future.wait([first, second]);

    expect(identical(results[0], results[1]), isTrue);
    expect(results[0].purchased, isTrue);
    expect(controller.houseState, 2);
    expect(controller.balance, 900);
    controller.dispose();
  });

  test('a win credit and a house purchase do not drop points', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 100,
      'points.earned': 100,
      'points.houseMigrated': true,
      'points.houseState': 1,
    });
    final controller = PointsController(await PointsStore.open());
    await Future.wait([controller.earn(50), controller.buyNextHouse()]);

    expect(controller.houseState, 2);
    expect(controller.balance, 50);
    expect((await PointsStore.open()).balance, 50);
    controller.dispose();
  });

  test('a failed save rolls the purchase back', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 500,
      'points.houseMigrated': true,
      'points.houseState': 4,
    });
    final store = await PointsStore.open();
    store.debugAbortNextCommit();
    final result = await store.buyNextHouse();

    expect(result.status, HouseBuyStatus.failed);
    expect(store.balance, 500);
    expect(store.houseState, 4);
    expect(store.debugJournal, isNull);
  });

  test(
    'reopening finishes a journaled purchase that stopped halfway',
    () async {
      SharedPreferences.setMockInitialValues({
        'points.balance': 400,
        'points.earned': 500,
        'points.purchased': 0,
        'points.houseState': 1,
        'points.houseMigrated': true,
        'points.journal': '400:500:0:2:1',
      });
      final store = await PointsStore.open();

      expect(store.balance, 400);
      expect(store.houseState, 2);
      expect(store.lifetimeEarned, 500);
      expect(store.debugJournal, isNull);
      expect((await PointsStore.open()).houseState, 2);
    },
  );

  test('the last look cannot be bought', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 5000,
      'points.houseMigrated': true,
      'points.houseState': 24,
    });
    final store = await PointsStore.open();
    final result = await store.buyNextHouse();

    expect(result.status, HouseBuyStatus.maxed);
    expect(store.balance, 5000);
    expect(store.houseState, 24);
  });

  test('buying the house leaves the pond, pets and gifts alone', () async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 40,
      'progress.stars.1': 3,
      'points.balance': 500,
      'points.earned': 500,
      'points.houseMigrated': true,
      'points.houseState': 3,
      'courtyard.rewards.v1': '{"owned":["swing","pond"]}',
    });
    final prefs = await SharedPreferences.getInstance();
    final progress = await ProgressStore.open();
    final rewards = await CourtyardRewardStore.open();
    final before = {
      for (final key in prefs.getKeys())
        if (!key.startsWith('points.')) key: prefs.get(key),
    };
    final pond = progress.plotStage(PlotKind.pond);
    final pets = progress.plotStage(PlotKind.pets);
    final owned = Set.of(rewards.owned);

    final store = await PointsStore.open();
    final result = await store.buyNextHouse();

    expect(result.purchased, isTrue);
    expect(progress.plotStage(PlotKind.pond), pond);
    expect(progress.plotStage(PlotKind.pets), pets);
    expect(progress.maxUnlocked, 40);
    expect((await CourtyardRewardStore.open()).owned, owned);
    for (final entry in before.entries) {
      expect(prefs.get(entry.key), entry.value, reason: entry.key);
    }
  });
}
