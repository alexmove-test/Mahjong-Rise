import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/courtyard_reward.dart';
import 'package:mahjong/models/house_upgrade.dart';
import 'package:mahjong/models/seed_batch.dart';
import 'package:mahjong/models/garden.dart';
import 'package:mahjong/models/seed_catalog.dart';
import 'package:mahjong/services/points_controller.dart';
import 'package:mahjong/services/points_store.dart';
import 'package:mahjong/widgets/courtyard/courtyard_world_layout.dart';
import 'package:mahjong/widgets/courtyard/home_upgrade_preview.dart';
import 'package:mahjong/widgets/seeds/seed_production_panel.dart';
import 'package:mahjong/widgets/seeds/seed_storage_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('production time and price follow the house level', () {
    expect(SeedCatalog.durationForLevel(1), const Duration(minutes: 10));
    expect(SeedCatalog.costForLevel(1), 10);
    expect(SeedCatalog.durationForLevel(2), const Duration(seconds: 580));
    expect(SeedCatalog.costForLevel(2), 10);
    expect(SeedCatalog.durationForLevel(3), const Duration(seconds: 560));
    expect(SeedCatalog.costForLevel(3), 9);
    expect(SeedCatalog.durationForLevel(24), const Duration(minutes: 3));
    expect(SeedCatalog.costForLevel(24), 3);
    for (var level = 1; level <= HouseUpgrade.stateCount; level++) {
      final seconds = 600 - 20 * (level - 1);
      final duration = Duration(seconds: seconds < 180 ? 180 : seconds);
      expect(SeedCatalog.durationForLevel(level), duration);
      expect(
        SeedCatalog.costForLevel(level),
        (duration.inSeconds / 60).round(),
      );
      expect(SeedCatalog.offerFor(level).cost, SeedCatalog.costForLevel(level));
    }
    expect(HouseUpgrade.priceAfter(1), 100);
  });

  test('class bands replace one-by-one species gates', () {
    expect(SeedCatalog.speciesAt(1), [
      SeedSpecies.amberbell,
      SeedSpecies.mistfern,
    ]);
    expect(SeedCatalog.speciesAt(4), SeedCatalog.speciesAt(1));
    expect(SeedCatalog.chancesAt(5).map((chance) => chance.percent), [75, 25]);
    expect(SeedCatalog.chancesAt(12).map((chance) => chance.percent), [75, 25]);
    expect(SeedCatalog.chancesAt(13).map((chance) => chance.percent), [
      55,
      35,
      10,
    ]);
    expect(SeedCatalog.chancesAt(20).map((chance) => chance.percent), [
      55,
      35,
      10,
    ]);
    expect(SeedCatalog.chancesAt(21).map((chance) => chance.percent), [
      40,
      40,
      20,
    ]);
    expect(SeedCatalog.chancesAt(24).map((chance) => chance.percent), [
      40,
      40,
      20,
    ]);
    expect(SeedCatalog.bandChanges(4, 5), isTrue);
    expect(SeedCatalog.bandChanges(5, 6), isFalse);
    expect(SeedCatalog.bandChanges(12, 13), isTrue);
    expect(SeedCatalog.bandChanges(20, 21), isTrue);
    expect(SeedCatalog.foodFor(SeedSpecies.amberbell), 10);
    expect(SeedCatalog.foodFor(SeedSpecies.glassreed), 25);
    expect(SeedCatalog.foodFor(SeedSpecies.nightlotus), 60);
    expect(
      GardenCatalog.durationFor(SeedSpecies.crimsonplum),
      const Duration(minutes: 20),
    );
    expect(GardenCatalog.costFor(SeedSpecies.starbamboo), 60);
  });

  test('a weighted roll stays inside the current band', () {
    expect(
      SeedCatalog.rollSpecies(1, (count) => count == 100 ? 99 : 1),
      SeedSpecies.mistfern,
    );
    expect(
      SeedCatalog.rollSpecies(5, (count) => count == 100 ? 74 : 0),
      SeedSpecies.amberbell,
    );
    expect(
      SeedCatalog.rollSpecies(5, (count) => count == 100 ? 75 : 1),
      SeedSpecies.crimsonplum,
    );
    expect(
      SeedCatalog.rollSpecies(13, (count) => count == 100 ? 90 : 0),
      SeedSpecies.nightlotus,
    );
    expect(
      SeedCatalog.rollSpecies(21, (count) => count == 100 ? 80 : 1),
      SeedSpecies.starbamboo,
    );
  });

  test('a forced index can only return a species from the band', () async {
    for (final level in [1, 4, 5, 9, 13, 17, 20, 21, 24]) {
      final available = SeedCatalog.speciesAt(level);
      SharedPreferences.setMockInitialValues({
        'points.balance': 500,
        'points.houseMigrated': true,
        'points.houseState': level,
      });
      final store = await PointsStore.open();
      for (var index = 0; index < available.length; index++) {
        await _clearBatch(store);
        final result = await store.startSeedBatch(
          now: DateTime.utc(2026, 1, 1),
          speciesIndex: index,
        );
        expect(result.started, isTrue, reason: 'level $level index $index');
        expect(result.seeds.batch!.species, available[index]);
        expect(
          result.seeds.batch!.power,
          SeedCatalog.foodFor(available[index]),
        );
        expect(result.cost, SeedCatalog.costForLevel(level));
      }
      final rejectedBalance = store.balance;
      await _clearBatch(store);
      final rejected = await store.startSeedBatch(
        speciesIndex: available.length,
      );
      expect(rejected.status, SeedStartStatus.failed);
      expect(store.balance, rejectedBalance);
      expect(store.seeds.batch, isNull);
    }
  });

  test(
    'an old courtyard keeps its points, house and empty seed chest',
    () async {
      SharedPreferences.setMockInitialValues({
        'points.balance': 400,
        'points.earned': 400,
        'points.houseMigrated': true,
        'points.houseState': 12,
        'pet.owned': 'fox',
        'progress.maxUnlocked': 8,
      });
      final store = await PointsStore.open();

      expect(store.balance, 400);
      expect(store.houseState, 12);
      expect(store.seeds.batch, isNull);
      expect(store.seeds.inventory, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pet.owned'), 'fox');
      expect(prefs.getInt('progress.maxUnlocked'), 8);
      expect(prefs.getString('seeds.state.v1'), isNull);
    },
  );

  test('starting debits once and refuses a second batch', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 25,
      'points.earned': 25,
      'points.houseMigrated': true,
      'points.houseState': 3,
    });
    final store = await PointsStore.open();
    final now = DateTime.utc(2026, 3, 1, 8);
    final result = await store.startSeedBatch(now: now, speciesIndex: 0);

    expect(result.started, isTrue);
    expect(result.cost, 9);
    expect(store.balance, 16);
    expect(store.seeds.batch!.power, 10);
    expect(store.seeds.batch!.houseLevel, 3);
    expect(store.seeds.batch!.rulesVersion, SeedCatalog.rulesVersion);
    expect(store.seeds.batch!.readyAt, now.add(const Duration(seconds: 560)));

    final second = await store.startSeedBatch(now: now, speciesIndex: 0);
    expect(second.status, SeedStartStatus.busy);
    expect(store.balance, 16);
    expect(store.seeds.inventory, isEmpty);
  });

  test('an old seed reloads as class feed and keeps its clock', () async {
    final start = DateTime.utc(2026, 4, 1);
    final ready = start.add(const Duration(minutes: 10));
    final snapshot = SeedSnapshot(
      batch: SeedBatch(
        id: 'batch-old',
        startedAt: start,
        readyAt: ready,
        houseLevel: 20,
        cost: 29,
        species: SeedSpecies.amberbell,
        power: 48,
        rulesVersion: 1,
      ),
      inventory: [
        SeedInstance(
          id: 'seed-old',
          species: SeedSpecies.amberbell,
          power: 48,
          houseLevel: 20,
          createdAt: start,
          source: SeedSource.houseProduction,
          batchId: 'batch-old',
        ),
        SeedInstance(
          id: 'seed-other',
          species: SeedSpecies.amberbell,
          power: 12,
          houseLevel: 2,
          createdAt: start,
          source: SeedSource.houseProduction,
          batchId: 'batch-old',
        ),
      ],
      seq: 3,
    );
    SharedPreferences.setMockInitialValues({
      'points.balance': 40,
      'points.houseMigrated': true,
      'points.houseState': 20,
      'seeds.state.v1': snapshot.encode(),
    });
    final store = await PointsStore.open();
    expect(store.seeds.batch!.readyAt, ready);
    expect(store.seeds.batch!.cost, 29);
    expect(store.seeds.batch!.power, 10);
    expect(store.seeds.inventory.map((seed) => seed.power), [10, 10]);
    expect(stackSeeds(store.seeds.inventory).single.count, 2);
    expect(store.balance, 40);
  });

  test('a short wallet is not charged', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 9,
      'points.houseMigrated': true,
      'points.houseState': 1,
    });
    final store = await PointsStore.open();
    final result = await store.startSeedBatch(speciesIndex: 0);

    expect(result.status, SeedStartStatus.insufficient);
    expect(result.shortfall, 1);
    expect(store.balance, 9);
    expect(store.seeds.batch, isNull);
  });

  test('the chosen seed survives a restart and is not rolled again', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 80,
      'points.houseMigrated': true,
      'points.houseState': 9,
    });
    var rolls = 0;
    final store = await PointsStore.open();
    final now = DateTime.utc(2026, 4, 2, 10, 15);
    final started = await store.startSeedBatch(
      now: now,
      roll: (count) {
        rolls++;
        if (rolls == 1) {
          expect(count, 100);
          return 1;
        }
        expect(count, 2);
        return 1;
      },
    );
    final batch = started.seeds.batch!;
    expect(batch.species, SeedSpecies.mistfern);
    expect(batch.power, SeedCatalog.foodFor(SeedSpecies.mistfern));

    final reopened = await PointsStore.open();
    expect(rolls, 2);
    expect(reopened.seeds.batch!.id, batch.id);
    expect(reopened.seeds.batch!.species, SeedSpecies.mistfern);
    expect(reopened.seeds.batch!.power, batch.power);
    expect(reopened.seeds.batch!.readyAt, batch.readyAt);
    expect(reopened.balance, 80 - SeedCatalog.costForLevel(9));
  });

  test('readiness advances from the saved clock, not an open screen', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 40,
      'points.houseMigrated': true,
      'points.houseState': 1,
    });
    final store = await PointsStore.open();
    final start = DateTime.utc(2026, 5, 1, 12);
    await store.startSeedBatch(now: start, speciesIndex: 0);

    final early = await store.claimSeed(
      now: start.add(const Duration(minutes: 9, seconds: 59)),
    );
    expect(early.status, SeedClaimStatus.notReady);
    expect(store.seeds.inventory, isEmpty);
    expect(store.seeds.batch, isNotNull);
    expect(store.balance, 30);

    final ready = await store.claimSeed(
      now: start.add(const Duration(minutes: 10)),
    );
    expect(ready.claimed, isTrue);
    expect(ready.seed!.species, SeedSpecies.amberbell);
    expect(ready.seed!.power, 10);
    expect(ready.seed!.houseLevel, 1);
    expect(ready.seed!.source, SeedSource.houseProduction);
    expect(ready.seed!.batchId, store.seeds.inventory.single.batchId);
    expect(store.seeds.batch, isNull);
    expect(store.balance, 30);

    final again = await store.claimSeed(
      now: start.add(const Duration(minutes: 11)),
    );
    expect(again.status, SeedClaimStatus.empty);
    expect(store.seeds.inventory, hasLength(1));
  });

  test('a house upgrade does not change the batch already running', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 500,
      'points.earned': 500,
      'points.houseMigrated': true,
      'points.houseState': 3,
    });
    final store = await PointsStore.open();
    final start = DateTime.utc(2026, 6, 1);
    final started = await store.startSeedBatch(now: start, speciesIndex: 0);
    final batch = started.seeds.batch!;
    final bought = await store.buyNextHouse();

    expect(bought.purchased, isTrue);
    expect(store.houseState, 4);
    expect(store.seeds.batch!.id, batch.id);
    expect(store.seeds.batch!.power, 10);
    expect(store.seeds.batch!.houseLevel, 3);
    expect(store.seeds.batch!.cost, 9);
    expect(store.seeds.batch!.readyAt, batch.readyAt);
    expect(store.seeds.batch!.species, batch.species);

    await store.claimSeed(now: start.add(const Duration(minutes: 10)));
    final next = await store.startSeedBatch(
      now: start.add(const Duration(minutes: 11)),
      speciesIndex: 0,
    );
    expect(next.seeds.batch!.houseLevel, 4);
    expect(next.seeds.batch!.power, SeedCatalog.foodFor(SeedSpecies.amberbell));
    expect(next.seeds.batch!.cost, SeedCatalog.costForLevel(4));
    expect(store.seeds.inventory.single.power, 10);
  });

  test(
    'level 20 still prices the shorter production, not seed strength',
    () async {
      SharedPreferences.setMockInitialValues({
        'points.balance': 100,
        'points.houseMigrated': true,
        'points.houseState': 20,
      });
      final store = await PointsStore.open();
      final result = await store.startSeedBatch(speciesIndex: 0);

      expect(result.seeds.batch!.species, SeedSpecies.amberbell);
      expect(result.seeds.batch!.power, 10);
      expect(result.cost, SeedCatalog.costForLevel(20));
      expect(result.cost, 4);
      expect(store.balance, 96);
    },
  );

  test('a failed save rolls the debit and the batch back together', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 40,
      'points.earned': 40,
      'points.houseMigrated': true,
      'points.houseState': 2,
    });
    final store = await PointsStore.open();
    store.debugAbortNextCommit();
    final result = await store.startSeedBatch(speciesIndex: 0);

    expect(result.status, SeedStartStatus.failed);
    expect(store.balance, 40);
    expect(store.houseState, 2);
    expect(store.seeds.batch, isNull);
    expect(store.debugSeedJournal, isNull);
    expect(store.debugJournal, isNull);

    final reopened = await PointsStore.open();
    expect(reopened.balance, 40);
    expect(reopened.seeds.batch, isNull);
  });

  test('reopening finishes a journaled batch that stopped halfway', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 50,
      'points.earned': 50,
      'points.houseMigrated': true,
      'points.houseState': 1,
    });
    final store = await PointsStore.open();
    final now = DateTime.utc(2026, 7, 1, 9);
    final started = await store.startSeedBatch(now: now, speciesIndex: 0);
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('seeds.state.v1');
    final journal = jsonEncode({
      'wallet': WalletSnapshot(
        balance: store.balance,
        lifetimeEarned: store.lifetimeEarned,
        purchased: store.purchased,
        houseState: store.houseState,
        houseMigrated: true,
      ).encode(),
      'seeds': jsonDecode(saved!),
    });
    await prefs.setInt('points.balance', 50);
    await prefs.remove('seeds.state.v1');
    await prefs.setString('seeds.journal.v1', journal);

    final recovered = await PointsStore.open();
    expect(recovered.balance, started.balance);
    expect(recovered.seeds.batch!.id, started.seeds.batch!.id);
    expect(recovered.seeds.batch!.species, SeedSpecies.amberbell);
    expect(recovered.debugSeedJournal, isNull);
    expect((await PointsStore.open()).seeds.inventory, isEmpty);
    expect((await PointsStore.open()).seeds.batch!.id, started.seeds.batch!.id);
  });

  test('claiming twice from the controller stores one seed', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 30,
      'points.houseMigrated': true,
      'points.houseState': 1,
    });
    final controller = PointsController(await PointsStore.open());
    final start = DateTime.utc(2026, 8, 1);
    await controller.startSeedBatch(now: start, speciesIndex: 0);
    final ready = start.add(const Duration(minutes: 10));
    final first = controller.claimSeed(now: ready);
    final second = controller.claimSeed(now: ready);
    expect(identical(first, second), isTrue);
    final result = await first;

    expect(result.claimed, isTrue);
    expect(controller.seedCount, 1);
    expect(controller.balance, 20);
    expect((await PointsStore.open()).seeds.inventory, hasLength(1));
    controller.dispose();
  });

  test(
    'a win credit and a seed start do not drop or double-spend points',
    () async {
      SharedPreferences.setMockInitialValues({
        'points.balance': 100,
        'points.earned': 100,
        'points.houseMigrated': true,
        'points.houseState': 1,
      });
      final controller = PointsController(await PointsStore.open());
      final now = DateTime.utc(2026, 8, 2);
      await Future.wait([
        controller.earn(50),
        controller.startSeedBatch(now: now, speciesIndex: 0),
      ]);

      expect(controller.balance, 140);
      expect(controller.houseState, 1);
      expect(controller.seedBatch!.power, 10);
      expect(controller.seedBatch!.cost, 10);
      expect((await PointsStore.open()).balance, 140);
      controller.dispose();
    },
  );

  test('starting and then buying keeps the original batch', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 500,
      'points.earned': 500,
      'points.houseMigrated': true,
      'points.houseState': 1,
    });
    final controller = PointsController(await PointsStore.open());
    final now = DateTime.utc(2026, 8, 3);
    await Future.wait([
      controller.startSeedBatch(now: now, speciesIndex: 0),
      controller.buyNextHouse(),
    ]);

    expect(controller.houseState, 2);
    expect(controller.balance, 390);
    expect(controller.seedBatch!.houseLevel, 1);
    expect(controller.seedBatch!.power, 10);
    expect(controller.seedBatch!.cost, 10);
    expect((await PointsStore.open()).balance, 390);
    controller.dispose();
  });

  test(
    'production leaves pets and campaign progress where they were',
    () async {
      SharedPreferences.setMockInitialValues({
        'points.balance': 40,
        'points.earned': 40,
        'points.houseMigrated': true,
        'points.houseState': 1,
        'pet.owned': 'fox',
        'progress.maxUnlocked': 6,
        'progress.stars.1': 3,
      });
      final store = await PointsStore.open();
      await store.startSeedBatch(
        now: DateTime.utc(2026, 9, 1),
        speciesIndex: 0,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pet.owned'), 'fox');
      expect(prefs.getInt('progress.maxUnlocked'), 6);
      expect(prefs.getInt('progress.stars.1'), 3);
      expect(store.houseState, 1);
    },
  );

  test('stacks group species and power but keep each id', () {
    final t = DateTime.utc(2026, 1, 1);
    SeedInstance seed(String id, SeedSpecies species, int power, int hours) {
      return SeedInstance(
        id: id,
        species: species,
        power: power,
        houseLevel: ((power - 10) ~/ 2) + 1,
        createdAt: t.add(Duration(hours: hours)),
        source: SeedSource.houseProduction,
        batchId: 'batch-$id',
      );
    }

    final seeds = [
      seed('a', SeedSpecies.amberbell, 10, 1),
      seed('b', SeedSpecies.amberbell, 10, 2),
      seed('c', SeedSpecies.amberbell, 12, 3),
      seed('d', SeedSpecies.mistfern, 12, 4),
    ];
    final byPower = stackSeeds(seeds, sort: SeedSort.power);
    expect(byPower.map((stack) => (stack.species, stack.power, stack.count)), [
      (SeedSpecies.mistfern, 12, 1),
      (SeedSpecies.amberbell, 12, 1),
      (SeedSpecies.amberbell, 10, 2),
    ]);
    expect(byPower.last.instances.map((seed) => seed.id), ['a', 'b']);

    final byTime = stackSeeds(seeds);
    expect(byTime.first.species, SeedSpecies.mistfern);
    expect(byTime.first.receivedAt, t.add(const Duration(hours: 4)));
  });

  test('the seed sign sits off the house, pets, pond and gifts', () {
    final badge = CourtyardWorldLayout.seedBadge;
    expect(badge.overlaps(CourtyardWorldLayout.homeYard), isFalse);
    expect(badge.overlaps(CourtyardWorldLayout.petYard), isFalse);
    expect(badge.overlaps(CourtyardWorldLayout.pondYard), isFalse);
    for (final reward in CourtyardReward.values) {
      expect(
        badge.overlaps(CourtyardWorldLayout.rewardOf(reward)),
        isFalse,
        reason: reward.name,
      );
    }
  });

  testWidgets('the upgrade card shows the next duration, cost and chances', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(const HomeUpgradePreview(state: 8, balance: 900, onBuy: _noop)),
    );
    expect(
      find.text('Время производства: 7 мин 40 с → 7 мин 20 с'),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('house-upgrade-curtain')));
    await tester.pumpAndSettle();
    expect(
      find.text('Время производства: 7 мин 40 с → 7 мин 20 с'),
      findsOneWidget,
    );
    expect(find.text('Стоимость производства: 8 → 7 поинтов'), findsOneWidget);
    expect(find.byKey(const ValueKey('seed-chance-step')), findsNothing);
    expect(find.text('Улучшение дома — 450'), findsOneWidget);

    await tester.pumpWidget(
      _app(
        const HomeUpgradePreview(
          key: ValueKey('band-change'),
          state: 4,
          balance: 900,
          onBuy: _noop,
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('house-upgrade-curtain')));
    await tester.pumpAndSettle();
    expect(find.text('Время производства: 9 мин → 8 мин 40 с'), findsOneWidget);
    expect(find.text('Шансы: Обычные 75%, Питательные 25%'), findsOneWidget);
  });

  testWidgets('production hides the species until it is ready', (tester) async {
    final start = DateTime.utc(2026, 10, 1, 12);
    final batch = SeedBatch(
      id: 'batch-1',
      startedAt: start,
      readyAt: start.add(const Duration(minutes: 10)),
      houseLevel: 1,
      cost: 10,
      species: SeedSpecies.amberbell,
      power: 10,
      rulesVersion: 1,
    );
    await tester.pumpWidget(
      _app(
        SeedProductionPanel(
          houseLevel: 5,
          balance: 100,
          batch: batch,
          tick: false,
          now: () => start.add(const Duration(minutes: 3)),
          onStart: () async =>
              SeedStartResult.failed(balance: 100, seeds: SeedSnapshot.empty),
          onClaim: () async =>
              SeedClaimResult.failed(balance: 100, seeds: SeedSnapshot.empty),
        ),
      ),
    );
    expect(find.text('Янтарный колокольчик'), findsNothing);
    expect(find.text('Неизвестное семя'), findsOneWidget);
    expect(find.text('07:00'), findsOneWidget);
    expect(find.text('Корм: 10'), findsNothing);
    expect(find.byKey(const ValueKey('seed-glyph-unknown')), findsOneWidget);

    await tester.pumpWidget(
      _app(
        SeedProductionPanel(
          houseLevel: 8,
          balance: 100,
          batch: batch,
          tick: false,
          now: () => start.add(const Duration(minutes: 10)),
          onStart: () async =>
              SeedStartResult.failed(balance: 100, seeds: SeedSnapshot.empty),
          onClaim: () async => const SeedClaimResult(
            status: SeedClaimStatus.claimed,
            balance: 100,
            seeds: SeedSnapshot.empty,
            seed: null,
          ),
        ),
      ),
    );
    expect(find.text('Янтарный колокольчик'), findsOneWidget);
    expect(find.text('Обычные'), findsOneWidget);
    expect(find.text('Корм: 10'), findsOneWidget);
    expect(find.text('Неизвестное семя'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('seed-claim-button')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('a short wallet shows the gap and a way into mahjong', (
    tester,
  ) async {
    var played = false;
    await tester.pumpWidget(
      _app(
        SeedProductionPanel(
          houseLevel: 1,
          balance: 4,
          batch: null,
          tick: false,
          onStart: () async =>
              SeedStartResult.failed(balance: 4, seeds: SeedSnapshot.empty),
          onClaim: () async =>
              SeedClaimResult.failed(balance: 4, seeds: SeedSnapshot.empty),
          onPlayMahjong: () => played = true,
        ),
      ),
    );
    expect(find.text('Произвести семя · 10 поинтов'), findsOneWidget);
    expect(find.text('Не хватает 6 поинтов'), findsOneWidget);
    expect(find.text('Янтарный колокольчик'), findsOneWidget);
    expect(find.text('Туманный папоротник'), findsOneWidget);
    expect(find.text('Обычные 100%'), findsOneWidget);
    expect(find.text('1/2'), findsNWidgets(2));
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('seed-produce-button')),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('seed-play-mahjong')));
    expect(played, isTrue);
  });

  testWidgets('collecting shows the storage note without motion', (
    tester,
  ) async {
    final start = DateTime.utc(2026, 10, 2);
    final batch = SeedBatch(
      id: 'batch-9',
      startedAt: start,
      readyAt: start,
      houseLevel: 2,
      cost: 11,
      species: SeedSpecies.amberbell,
      power: 12,
      rulesVersion: 1,
    );
    final seed = SeedInstance(
      id: 'seed-1',
      species: SeedSpecies.amberbell,
      power: 12,
      houseLevel: 2,
      createdAt: start,
      source: SeedSource.houseProduction,
      batchId: batch.id,
    );
    var claims = 0;
    await tester.pumpWidget(
      _app(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: SeedProductionPanel(
            houseLevel: 2,
            balance: 20,
            batch: batch,
            tick: false,
            now: () => start,
            onStart: () async =>
                SeedStartResult.failed(balance: 20, seeds: SeedSnapshot.empty),
            onClaim: () async {
              claims++;
              await Future<void>.delayed(const Duration(milliseconds: 30));
              return SeedClaimResult(
                status: SeedClaimStatus.claimed,
                balance: 20,
                seeds: SeedSnapshot(batch: null, inventory: [seed], seq: 2),
                seed: seed,
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('seed-claim-button')));
    await tester.tap(find.byKey(const ValueKey('seed-claim-button')));
    await tester.pump();
    expect(claims, 1);
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byKey(const ValueKey('seed-added')), findsOneWidget);
    expect(find.text('Семя добавлено в хранилище'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('storage groups equal seeds and explains an empty chest', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 100,
      'points.houseMigrated': true,
      'points.houseState': 1,
    });
    final store = await PointsStore.open();
    final controller = PointsController(store);
    var produce = false;
    await tester.pumpWidget(
      _scoped(
        controller,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              produce = await showSeedStorage(context);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Семена'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('seed-produce-first')));
    await tester.pumpAndSettle();
    expect(produce, isTrue);

    final start = DateTime.utc(2026, 11, 1, 8);
    await controller.startSeedBatch(now: start, speciesIndex: 0);
    await controller.claimSeed(now: start.add(const Duration(minutes: 10)));
    await controller.startSeedBatch(
      now: start.add(const Duration(minutes: 11)),
      speciesIndex: 0,
    );
    await controller.claimSeed(now: start.add(const Duration(minutes: 21)));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('seed-stack-amberbell-10')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('seed-stack-amberbell-10')));
    await tester.pumpAndSettle();
    expect(
      find.text('Из этого семени можно будет вырастить растение.'),
      findsOneWidget,
    );
    expect(find.text('Произведено домом уровня 1'), findsOneWidget);
    expect(find.text('Посадить'), findsNothing);
    controller.dispose();
  });
}

Future<void> _noop() async {}

Future<void> _clearBatch(PointsStore store) async {
  final batch = store.seeds.batch;
  if (batch == null) return;
  final claimed = await store.claimSeed(now: batch.readyAt);
  expect(claimed.claimed, isTrue);
}

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru'), Locale('en')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

Widget _scoped(PointsController controller, Widget child) {
  return PointsScope(
    controller: controller,
    child: MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
}
