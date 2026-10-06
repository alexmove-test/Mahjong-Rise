import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/points_award.dart';
import 'package:mahjong/services/points_controller.dart';
import 'package:mahjong/services/points_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the wallet starts empty and keeps what it earns', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await PointsStore.open();
    expect(store.balance, 0);

    await store.add(90);
    await store.add(1500, purchased: true);

    expect(store.balance, 1590);
    expect(store.lifetimeEarned, 90);
    expect(store.purchased, 1500);
    expect((await PointsStore.open()).balance, 1590);
  });

  test('the memory wallet swallows writes until prefs arrive', () async {
    final store = PointsStore.memory();
    expect(store.isPersistent, isFalse);
    await store.add(100);
    expect(store.balance, 0);
  });

  test('a win before prefs load is credited once they arrive', () async {
    SharedPreferences.setMockInitialValues({'points.balance': 40});
    final controller = PointsController(PointsStore.memory());
    await controller.earn(85);
    expect(controller.balance, 85);

    controller.attachStore(await PointsStore.open());
    await Future<void>.delayed(Duration.zero);

    expect(controller.balance, 125);
    expect((await PointsStore.open()).lifetimeEarned, 85);
    controller.dispose();
  });

  test('a quiet controller hydrates from the stored balance', () async {
    SharedPreferences.setMockInitialValues({'points.balance': 320});
    final controller = PointsController(PointsStore.memory());
    expect(controller.balance, 0);

    controller.attachStore(await PointsStore.open());
    expect(controller.balance, 320);
    controller.dispose();
  });

  test('purchased points are tracked apart from earned ones', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = PointsController(await PointsStore.open());
    await controller.earn(25);
    await controller.creditPurchase(1650);

    final store = await PointsStore.open();
    expect(controller.balance, 1675);
    expect(store.lifetimeEarned, 25);
    expect(store.purchased, 1650);
    controller.dispose();
  });

  testWidgets('a win pays into the wallet standing in the tree', (
    tester,
  ) async {
    final controller = PointsController(PointsStore.memory());
    late BuildContext tableContext;
    await tester.pumpWidget(
      PointsScope(
        controller: controller,
        child: Builder(
          builder: (context) {
            tableContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    PointsScope.credit(
      tableContext,
      PointsAward.campaignWin(stars: 2, firstClear: true, isNewBest: false),
    );
    await tester.pump();

    expect(controller.balance, 25 + 30 + 50);
    expect(controller.lastGain, 105);
    controller.dispose();
  });

  test('a three-star first clear pays clear, stars and first-clear', () {
    final award = PointsAward.campaignWin(
      stars: 3,
      firstClear: true,
      isNewBest: true,
    );
    expect(award.total, 25 + 45 + 50 + 20);

    final replay = PointsAward.campaignWin(
      stars: 1,
      firstClear: false,
      isNewBest: false,
    );
    expect(replay.total, 25 + 15);
    expect(replay.isEmpty, isFalse);
  });

  test('a daily replayed the same day pays nothing', () {
    expect(PointsAward.dailyWin(streak: 4, counted: false).isEmpty, isTrue);
    expect(PointsAward.dailyWin(streak: 4).total, 40 + 20);
    expect(PointsAward.dailyWin(streak: 30).total, 40 + 35);
  });
}
