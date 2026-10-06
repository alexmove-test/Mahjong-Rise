import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/courtyard_reward.dart';
import 'package:mahjong/models/garden.dart';
import 'package:mahjong/models/house_upgrade.dart';
import 'package:mahjong/models/seed_batch.dart';
import 'package:mahjong/models/seed_catalog.dart';
import 'package:mahjong/services/points_controller.dart';
import 'package:mahjong/services/points_store.dart';
import 'package:mahjong/widgets/courtyard/courtyard_world.dart';
import 'package:mahjong/widgets/courtyard/courtyard_estate.dart';
import 'package:mahjong/widgets/courtyard/courtyard_world_layout.dart';
import 'package:mahjong/widgets/garden/garden_sheets.dart';
import 'package:mahjong/widgets/garden/plant_art.dart';
import 'package:mahjong/widgets/garden/plant_chip.dart';
import 'package:mahjong/widgets/garden/plant_flight.dart';
import 'package:mahjong/widgets/points/points_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('growth follows the saved fraction and never goes backwards', () {
    final start = DateTime.utc(2026, 6, 1, 12);
    final planting = _planting(start);
    expect(stageOf(planting, start), GrowthStage.sown);
    expect(
      stageOf(planting, start.add(const Duration(minutes: 1))),
      GrowthStage.sprout,
    );
    expect(
      stageOf(planting, start.add(const Duration(minutes: 2, seconds: 30))),
      GrowthStage.growing,
    );
    expect(
      stageOf(planting, start.add(const Duration(minutes: 4, seconds: 59))),
      GrowthStage.growing,
    );
    expect(
      stageOf(planting, start.add(const Duration(minutes: 5))),
      GrowthStage.ripe,
    );
    expect(
      stageOf(planting, start.add(const Duration(days: 30))),
      GrowthStage.ripe,
    );
    final rewound = start.subtract(const Duration(hours: 3));
    expect(planting.progress(rewound), 0);
    expect(stageOf(planting, rewound), GrowthStage.sown);
    expect(planting.remaining(rewound).isNegative, isFalse);
    expect(planting.progress(start.add(const Duration(minutes: 1))), 0.2);
    expect(
      planting.progress(start.add(const Duration(minutes: 2, seconds: 30))),
      0.5,
    );
  });

  test('beds and the warehouse stay off the house, pets, pond and gifts', () {
    final blocked = [
      CourtyardWorldLayout.homeYard,
      CourtyardWorldLayout.petYard,
      CourtyardWorldLayout.pondYard,
      CourtyardWorldLayout.seedBadge,
      for (final reward in CourtyardReward.values)
        CourtyardWorldLayout.rewardOf(reward),
    ];
    final plots = [
      ...CourtyardWorldLayout.gardenBeds,
      CourtyardWorldLayout.warehouse,
    ];
    for (final plot in plots) {
      for (final other in blocked) {
        expect(plot.overlaps(other), isFalse, reason: '$plot vs $other');
      }
    }
    for (var i = 0; i < plots.length; i++) {
      for (var j = i + 1; j < plots.length; j++) {
        expect(plots[i].overlaps(plots[j]), isFalse);
      }
    }
    expect(CourtyardWorldLayout.gardenBeds, hasLength(GardenCatalog.bedCount));
  });

  test(
    'an existing yard gains three empty beds and an empty warehouse',
    () async {
      final seed = _seed();
      SharedPreferences.setMockInitialValues({
        'points.balance': 80,
        'points.earned': 80,
        'points.purchased': 15,
        'points.houseMigrated': true,
        'points.houseState': 7,
        'seeds.state.v1': _chest([seed]).encode(),
        'pet.owned': 'fox',
        'progress.stars.1': 3,
        'progress.maxUnlocked': 4,
      });
      final store = await PointsStore.open();

      expect(store.balance, 80);
      expect(store.lifetimeEarned, 80);
      expect(store.purchased, 15);
      expect(store.houseState, 7);
      expect(store.seeds.inventory.single.id, seed.id);
      expect(store.garden.beds, hasLength(3));
      expect(store.garden.beds, everyElement(isNull));
      expect(store.garden.warehouse, isEmpty);
      expect(store.garden.plantCount, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pet.owned'), 'fox');
      expect(prefs.getInt('progress.stars.1'), 3);
      expect(prefs.getInt('progress.maxUnlocked'), 4);

      final again = await PointsStore.open();
      expect(again.garden.beds, everyElement(isNull));
      expect(again.seeds.inventory.single.id, seed.id);
      expect(again.balance, 80);
    },
  );

  test('planting spends one seed and a price that follows its class', () async {
    final first = _seed(id: 'seed-a');
    final second = _seed(
      id: 'seed-b',
      species: SeedSpecies.nightlotus,
      variant: 'dew',
    );
    SharedPreferences.setMockInitialValues({
      'points.balance': 90,
      'points.earned': 90,
      'points.houseMigrated': true,
      'points.houseState': 1,
      'seeds.state.v1': _chest([first, second], seq: 4).encode(),
    });
    final store = await PointsStore.open();
    final now = DateTime.utc(2026, 6, 2, 8);
    final result = await store.plantSeed(
      bedIndex: 1,
      seedId: second.id,
      now: now,
    );

    expect(result.planted, isTrue);
    expect(result.cost, GardenCatalog.costFor(second.species));
    expect(result.cost, greaterThan(GardenCatalog.costFor(first.species)));
    expect(store.balance, 30);
    expect(store.lifetimeEarned, 90);
    expect(store.seeds.inventory.map((seed) => seed.id), ['seed-a']);
    final planting = store.garden.bedAt(1)!;
    expect(planting.seedId, second.id);
    expect(planting.species, SeedSpecies.nightlotus);
    expect(planting.power, 60);
    expect(planting.variant, 'dew');
    expect(planting.houseLevel, 1);
    expect(planting.source, SeedSource.houseProduction);
    expect(planting.batchId, 'batch-1');
    expect(planting.readyAt, now.add(const Duration(minutes: 60)));
    expect(store.garden.bedAt(0), isNull);
    expect(store.garden.plantCount, 0);

    final again = await store.plantSeed(
      bedIndex: 1,
      seedId: first.id,
      now: now,
    );
    expect(again.status, PlantStatus.occupied);
    expect(store.balance, 30);
    expect(store.seeds.inventory, hasLength(1));

    final duplicate = await store.plantSeed(
      bedIndex: 0,
      seedId: second.id,
      now: now,
    );
    expect(duplicate.status, PlantStatus.missingSeed);
    expect(store.balance, 30);
    expect(store.garden.bedAt(0), isNull);
  });

  test('a short wallet or a missing seed leaves both resources', () async {
    final seed = _seed();
    SharedPreferences.setMockInitialValues({
      'points.balance': 4,
      'points.earned': 4,
      'points.houseMigrated': true,
      'points.houseState': 3,
      'seeds.state.v1': _chest([seed]).encode(),
    });
    final store = await PointsStore.open();
    final short = await store.plantSeed(bedIndex: 0, seedId: seed.id);

    expect(short.status, PlantStatus.insufficient);
    expect(short.shortfall, GardenCatalog.costFor(seed.species) - 4);
    expect(store.balance, 4);
    expect(store.seeds.inventory.single.id, seed.id);
    expect(store.garden.bedAt(0), isNull);

    final missing = await store.plantSeed(bedIndex: 0, seedId: 'nope');
    expect(missing.status, PlantStatus.missingSeed);
    expect(store.balance, 4);
    expect(store.houseState, 3);
  });

  test('a failed save rolls the seed and the points back', () async {
    final seed = _seed();
    SharedPreferences.setMockInitialValues({
      'points.balance': 80,
      'points.earned': 80,
      'points.houseMigrated': true,
      'points.houseState': 2,
      'seeds.state.v1': _chest([seed]).encode(),
    });
    final store = await PointsStore.open();
    store.debugAbortNextCommit();
    final result = await store.plantSeed(bedIndex: 0, seedId: seed.id);

    expect(result.status, PlantStatus.failed);
    expect(store.balance, 80);
    expect(store.seeds.inventory.single.id, seed.id);
    expect(store.garden.bedAt(0), isNull);
    expect(store.garden.warehouse, isEmpty);
    expect(store.debugGardenJournal, isNull);

    final reopened = await PointsStore.open();
    expect(reopened.balance, 80);
    expect(reopened.seeds.inventory.single.id, seed.id);
    expect(reopened.garden.bedAt(0), isNull);
  });

  test(
    'a house upgrade does not change a plant already in the ground',
    () async {
      final seed = _seed(power: 10);
      SharedPreferences.setMockInitialValues({
        'points.balance': 200,
        'points.earned': 200,
        'points.houseMigrated': true,
        'points.houseState': 1,
        'seeds.state.v1': _chest([seed]).encode(),
      });
      final store = await PointsStore.open();
      final planted = await store.plantSeed(
        bedIndex: 0,
        seedId: seed.id,
        now: DateTime.utc(2026, 6, 3),
      );
      final bought = await store.buyNextHouse();

      expect(bought.purchased, isTrue);
      expect(store.houseState, 2);
      expect(store.garden.bedAt(0)!.readyAt, planted.planting!.readyAt);
      expect(store.garden.bedAt(0)!.cost, GardenCatalog.costFor(seed.species));
      expect(store.garden.bedAt(0)!.power, planted.planting!.power);
      expect(store.garden.bedAt(0)!.power, 10);
      expect(store.garden.bedAt(0)!.species, seed.species);
      expect(
        store.balance,
        200 -
            GardenCatalog.costFor(SeedSpecies.amberbell) -
            HouseUpgrade.priceAfter(1),
      );
    },
  );

  test(
    'harvest stores one plant, frees the bed, and ignores a second call',
    () async {
      final seed = _seed(variant: 'dew');
      SharedPreferences.setMockInitialValues({
        'points.balance': 57,
        'points.earned': 57,
        'points.houseMigrated': true,
        'points.houseState': 1,
        'seeds.state.v1': _chest([seed]).encode(),
      });
      final store = await PointsStore.open();
      final start = DateTime.utc(2026, 6, 4, 9);
      await store.plantSeed(bedIndex: 2, seedId: seed.id, now: start);

      final early = await store.harvestBed(
        bedIndex: 2,
        now: start.add(const Duration(minutes: 4)),
      );
      expect(early.status, HarvestStatus.notReady);
      expect(store.garden.warehouse, isEmpty);
      expect(store.garden.bedAt(2), isNotNull);
      expect(store.balance, 52);

      final readyAt = start.add(const Duration(minutes: 5));
      final first = await store.harvestBed(bedIndex: 2, now: readyAt);
      final second = await store.harvestBed(
        bedIndex: 2,
        now: readyAt.add(const Duration(days: 9)),
      );

      expect(first.harvested, isTrue);
      expect(second.status, HarvestStatus.empty);
      expect(store.garden.bedAt(2), isNull);
      expect(store.garden.warehouse, hasLength(1));
      expect(store.garden.plantCount, 1);
      expect(store.balance, 52);
      final plant = store.garden.warehouse.single;
      expect(plant.species, seed.species);
      expect(plant.power, seed.power);
      expect(plant.variant, 'dew');
      expect(plant.seedId, seed.id);
      expect(plant.source, seed.source);
      expect(plant.batchId, seed.batchId);
      expect(plant.plantingId, first.plant!.plantingId);
      expect(plant.plantedAt, start);
      expect(plant.maturedAt, readyAt);
      expect(plant.harvestedAt, readyAt);

      final reopened = await PointsStore.open();
      expect(reopened.balance, 52);
      expect(reopened.garden.bedAt(2), isNull);
      expect(reopened.garden.warehouse.single.id, plant.id);
      expect(reopened.seeds.inventory, isEmpty);
      expect(reopened.lifetimeEarned, 57);
    },
  );

  test('reopening finishes a journaled harvest that stopped halfway', () async {
    final seed = _seed();
    final start = DateTime.utc(2026, 7, 1);
    final ready = start.add(GardenCatalog.durationFor(SeedSpecies.amberbell));
    final planting = Planting(
      id: 'planting-1',
      seedId: seed.id,
      species: seed.species,
      power: seed.power,
      houseLevel: seed.houseLevel,
      source: seed.source,
      batchId: seed.batchId,
      plantedAt: start,
      readyAt: ready,
      cost: 5,
      rulesVersion: 1,
    );
    final plant = HarvestedPlant(
      id: 'plant-2',
      species: seed.species,
      power: seed.power,
      houseLevel: seed.houseLevel,
      seedId: seed.id,
      source: seed.source,
      batchId: seed.batchId,
      plantingId: planting.id,
      plantedAt: start,
      maturedAt: ready,
      harvestedAt: ready,
    );
    SharedPreferences.setMockInitialValues({
      'points.balance': 9,
      'points.earned': 9,
      'points.houseMigrated': true,
      'points.houseState': 1,
      'seeds.state.v1': _chest([seed]).encode(),
      'garden.state.v1': GardenSnapshot(
        beds: [planting, null, null],
        warehouse: const [],
        seq: 1,
      ).encode(),
      'garden.journal.v1': jsonEncode({
        'wallet': const WalletSnapshot(
          balance: 4,
          lifetimeEarned: 9,
          purchased: 0,
          houseState: 1,
          houseMigrated: true,
        ).encode(),
        'seeds': SeedSnapshot(
          batch: null,
          inventory: const [],
          seq: 1,
        ).toJson(),
        'garden': GardenSnapshot(
          beds: const [null, null, null],
          warehouse: [plant],
          seq: 2,
        ).toJson(),
      }),
    });

    final recovered = await PointsStore.open();
    expect(recovered.balance, 4);
    expect(recovered.seeds.inventory, isEmpty);
    expect(recovered.garden.bedAt(0), isNull);
    expect(recovered.garden.warehouse.single.id, plant.id);
    expect(recovered.debugGardenJournal, isNull);
    expect((await PointsStore.open()).garden.warehouse, hasLength(1));
  });

  test('a repeated controller harvest cannot mint a second plant', () async {
    final seed = _seed();
    SharedPreferences.setMockInitialValues({
      'points.balance': 55,
      'points.houseMigrated': true,
      'points.houseState': 1,
      'seeds.state.v1': _chest([seed]).encode(),
    });
    final controller = PointsController(await PointsStore.open());
    final start = DateTime.utc(2026, 8, 1);
    final planted = controller.plantSeed(
      bedIndex: 0,
      seedId: seed.id,
      now: start,
    );
    final plantedAgain = controller.plantSeed(
      bedIndex: 0,
      seedId: seed.id,
      now: start,
    );
    expect(identical(planted, plantedAgain), isTrue);
    expect((await planted).planted, isTrue);
    expect(controller.balance, 50);
    expect(controller.seedCount, 0);
    expect(controller.plantCount, 0);

    final ready = start.add(GardenCatalog.durationFor(SeedSpecies.amberbell));
    final first = controller.harvestBed(bedIndex: 0, now: ready);
    final second = controller.harvestBed(bedIndex: 0, now: ready);
    expect(identical(first, second), isTrue);
    expect((await first).harvested, isTrue);
    expect(controller.plantCount, 1);
    expect((await PointsStore.open()).garden.warehouse, hasLength(1));
    controller.dispose();
  });

  test('mahjong points, production and planting keep one balance', () async {
    final seed = _seed();
    SharedPreferences.setMockInitialValues({
      'points.balance': 100,
      'points.earned': 100,
      'points.houseMigrated': true,
      'points.houseState': 1,
      'seeds.state.v1': _chest([seed]).encode(),
      'progress.stars.2': 2,
    });
    final controller = PointsController(await PointsStore.open());
    final now = DateTime.utc(2026, 8, 2);
    await Future.wait([
      controller.earn(40),
      controller.startSeedBatch(now: now, speciesIndex: 0),
      controller.plantSeed(bedIndex: 0, seedId: seed.id, now: now),
    ]);

    expect(
      controller.balance,
      100 + 40 - 10 - GardenCatalog.costFor(seed.species),
    );
    expect(controller.seedBatch, isNotNull);
    expect(controller.garden.bedAt(0)!.power, 10);
    expect(controller.plantCount, 0);
    expect(controller.seedCount, 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('progress.stars.2'), 2);
    expect((await PointsStore.open()).balance, 125);
    controller.dispose();
  });

  test('stacks group species, power and variant, and sort both ways', () {
    final t = DateTime.utc(2026, 1, 1);
    HarvestedPlant plant({
      required String id,
      required SeedSpecies species,
      required int power,
      String? variant,
      required int hour,
    }) {
      return HarvestedPlant(
        id: id,
        species: species,
        power: power,
        houseLevel: 1,
        variant: variant,
        seedId: 'seed-$id',
        source: SeedSource.houseProduction,
        batchId: 'batch-$id',
        plantingId: 'planting-$id',
        plantedAt: t,
        maturedAt: t,
        harvestedAt: t.add(Duration(hours: hour)),
      );
    }

    final plants = [
      plant(id: 'a', species: SeedSpecies.amberbell, power: 10, hour: 1),
      plant(id: 'b', species: SeedSpecies.amberbell, power: 10, hour: 2),
      plant(
        id: 'c',
        species: SeedSpecies.amberbell,
        power: 10,
        variant: 'dew',
        hour: 3,
      ),
      plant(id: 'd', species: SeedSpecies.mistfern, power: 16, hour: 4),
    ];
    final byPower = stackPlants(plants, sort: PlantSort.power);
    expect(
      byPower.map(
        (stack) => (stack.species, stack.power, stack.variant, stack.count),
      ),
      [
        (SeedSpecies.mistfern, 16, null, 1),
        (SeedSpecies.amberbell, 10, 'dew', 1),
        (SeedSpecies.amberbell, 10, null, 2),
      ],
    );
    expect(byPower.last.instances.map((plant) => plant.id), ['a', 'b']);
    final byTime = stackPlants(plants);
    expect(byTime.first.instances.single.id, 'd');
  });

  testWidgets('the yard shows three beds and a warehouse', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: const [Locale('ru'), Locale('en')],
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: CourtyardWorld(
            to: CourtyardEstate.fromUnlocked(1),
            showGarden: true,
            garden: GardenSnapshot.empty,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('garden-bed-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('garden-bed-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('garden-bed-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('courtyard-warehouse')), findsOneWidget);
    expect(find.text('Склад'), findsOneWidget);
  });

  testWidgets('a ripe bed is marked for collection and a young one is not', (
    tester,
  ) async {
    final start = DateTime.utc(2026, 6, 1);
    final planting = _planting(start);
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SizedBox(
              width: 80,
              height: 64,
              child: GardenBedView(
                index: 0,
                planting: planting,
                onTap: () {},
                now: () => start.add(const Duration(minutes: 5)),
              ),
            ),
            SizedBox(
              width: 80,
              height: 64,
              child: GardenBedView(
                index: 1,
                planting: planting,
                onTap: () {},
                now: () => start,
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('garden-ready-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('garden-ready-1')), findsNothing);
  });

  testWidgets('the picker shows the cost, the gap, and the way into mahjong', (
    tester,
  ) async {
    final seed = _seed();
    SharedPreferences.setMockInitialValues({
      'points.balance': 2,
      'points.houseMigrated': true,
      'points.houseState': 1,
      'seeds.state.v1': _chest([seed, _seed(id: 'seed-2')]).encode(),
    });
    final controller = PointsController(await PointsStore.open());
    var played = false;
    await tester.pumpWidget(
      _scoped(
        controller,
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                final result = await showSeedPicker(context, bedIndex: 0);
                if (result == SeedPickerResult.play) played = true;
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Посадить · 1 семя + 5 поинтов'), findsOneWidget);
    expect(find.text('Не хватает 3 поинтов'), findsOneWidget);
    expect(find.text('Янтарный колокольчик'), findsWidgets);
    expect(find.text('Корм: 10'), findsWidgets);
    expect(find.text('Доступно: 2'), findsOneWidget);
    expect(find.text('Стоимость посадки: 5 поинтов'), findsWidgets);
    expect(find.text('Время выращивания: 5 мин'), findsWidgets);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('plant-seed-button')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('plant-play-mahjong')));
    await tester.pumpAndSettle();
    expect(played, isTrue);
    expect(controller.balance, 2);
    expect(controller.seedCount, 2);
    controller.dispose();
  });

  testWidgets('no seeds offers house production instead of a charge', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 40,
      'points.houseMigrated': true,
      'points.houseState': 1,
    });
    final controller = PointsController(await PointsStore.open());
    var produce = false;
    await tester.pumpWidget(
      _scoped(
        controller,
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                final result = await showSeedPicker(context, bedIndex: 0);
                if (result == SeedPickerResult.produce) produce = true;
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('plant-no-seeds')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('plant-open-production')));
    await tester.pumpAndSettle();
    expect(produce, isTrue);
    expect(controller.balance, 40);
    controller.dispose();
  });

  testWidgets('planting from the picker spends the chosen seed once', (
    tester,
  ) async {
    final seed = _seed();
    SharedPreferences.setMockInitialValues({
      'points.balance': 54,
      'points.houseMigrated': true,
      'points.houseState': 1,
      'seeds.state.v1': _chest([seed]).encode(),
    });
    final controller = PointsController(await PointsStore.open());
    await tester.pumpWidget(
      _scoped(
        controller,
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => showSeedPicker(context, bedIndex: 0),
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('plant-seed-button')));
    await tester.pumpAndSettle();

    expect(controller.balance, 49);
    expect(controller.seedCount, 0);
    expect(controller.garden.bedAt(0)!.seedId, seed.id);
    expect(controller.plantCount, 0);
    controller.dispose();
  });

  testWidgets('the warehouse and the top counter open the same stored plants', (
    tester,
  ) async {
    final seed = _seed();
    SharedPreferences.setMockInitialValues({
      'points.balance': 60,
      'points.houseMigrated': true,
      'points.houseState': 1,
      'seeds.state.v1': _chest([seed]).encode(),
    });
    final controller = PointsController(await PointsStore.open());
    final start = DateTime.utc(2026, 9, 1);
    await controller.plantSeed(bedIndex: 0, seedId: seed.id, now: start);
    await controller.harvestBed(
      bedIndex: 0,
      now: start.add(const Duration(days: 2)),
    );

    await tester.pumpWidget(
      _scoped(
        controller,
        Builder(
          builder: (context) {
            return Column(
              children: [
                PlantChipLive(onTap: () => showWarehouse(context)),
                PointsChip(points: controller.balance),
                TextButton(
                  onPressed: () => showWarehouse(context),
                  child: const Text('building'),
                ),
              ],
            );
          },
        ),
      ),
    );
    expect(find.byKey(const ValueKey('plant-counter')), findsOneWidget);
    expect(find.text('1'), findsWidgets);

    await tester.tap(find.byKey(const ValueKey('plant-counter')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('warehouse-count')), findsOneWidget);
    expect(find.text('Корм: 10'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('plant-stack-amberbell-10-')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('plant-details')), findsOneWidget);
    expect(find.text('Происхождение: производство дома'), findsOneWidget);
    expect(find.text('Покормить'), findsNothing);
    expect(find.text('Продать'), findsNothing);
    controller.dispose();
  });

  testWidgets('an empty warehouse explains itself and offers the garden', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 3,
      'points.houseMigrated': true,
      'points.houseState': 1,
    });
    final controller = PointsController(await PointsStore.open());
    var opened = false;
    await tester.pumpWidget(
      _scoped(
        controller,
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                opened = await showWarehouse(context);
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(
      find.text('Здесь будут храниться собранные растения'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('warehouse-open-garden')));
    await tester.pumpAndSettle();
    expect(opened, isTrue);
    expect(controller.plantCount, 0);
    controller.dispose();
  });

  testWidgets('collection stays locked until the saved time is reached', (
    tester,
  ) async {
    final seed = _seed();
    SharedPreferences.setMockInitialValues({
      'points.balance': 60,
      'points.houseMigrated': true,
      'points.houseState': 1,
      'seeds.state.v1': _chest([seed]).encode(),
    });
    final controller = PointsController(await PointsStore.open());
    final start = DateTime.utc(2026, 9, 2, 10);
    await controller.plantSeed(bedIndex: 0, seedId: seed.id, now: start);
    await tester.pumpWidget(
      _scoped(
        controller,
        Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => showGardenBed(
                context,
                bedIndex: 0,
                now: () => start.add(const Duration(minutes: 2)),
              ),
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('harvest-locked')), findsOneWidget);
    expect(find.byKey(const ValueKey('harvest-button')), findsNothing);
    expect(find.text('Росток'), findsOneWidget);
    expect(find.text('Корм: 10'), findsOneWidget);
    expect(controller.plantCount, 0);
    controller.dispose();
  });

  testWidgets('skipping the flight still leaves the harvested plant stored', (
    tester,
  ) async {
    var done = false;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: PlantFlight(
            species: SeedSpecies.amberbell,
            from: Offset.zero,
            to: const Offset(20, 20),
            onDone: () => done = true,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(done, isTrue);
  });
}

SeedInstance _seed({
  String id = 'seed-1',
  int power = 10,
  String? variant,
  SeedSpecies species = SeedSpecies.amberbell,
}) {
  return SeedInstance(
    id: id,
    species: species,
    power: power,
    houseLevel: 1,
    createdAt: DateTime.utc(2026, 1, 1),
    source: SeedSource.houseProduction,
    batchId: 'batch-1',
    variant: variant,
  );
}

SeedSnapshot _chest(List<SeedInstance> seeds, {int seq = 1}) {
  return SeedSnapshot(batch: null, inventory: seeds, seq: seq);
}

Planting _planting(DateTime start) {
  return Planting(
    id: 'planting-1',
    seedId: 'seed-1',
    species: SeedSpecies.amberbell,
    power: 10,
    houseLevel: 1,
    source: SeedSource.houseProduction,
    batchId: 'batch-1',
    plantedAt: start,
    readyAt: start.add(const Duration(minutes: 5)),
    cost: 5,
    rulesVersion: 1,
  );
}

Widget _app(Widget child) {
  return MaterialApp(
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru'), Locale('en')],
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
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
