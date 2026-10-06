import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/garden.dart';
import 'package:mahjong/models/pet.dart';
import 'package:mahjong/models/pet_combat.dart';
import 'package:mahjong/models/pet_roster.dart';
import 'package:mahjong/models/seed_batch.dart';
import 'package:mahjong/models/seed_catalog.dart';
import 'package:mahjong/services/pet_store.dart';
import 'package:mahjong/services/points_controller.dart';
import 'package:mahjong/services/points_store.dart';
import 'package:mahjong/widgets/garden/plant_chip.dart';
import 'package:mahjong/widgets/pets/pet_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final t0 = DateTime(2026, 8, 1, 12);

  test('roles follow the catalog and every kind keeps one role', () {
    expect(PetCombatRules.roleOf(PetKind.cat), PetRole.attacker);
    expect(PetCombatRules.roleOf(PetKind.fox), PetRole.attacker);
    expect(PetCombatRules.roleOf(PetKind.raccoon), PetRole.attacker);
    expect(PetCombatRules.roleOf(PetKind.dog), PetRole.defender);
    expect(PetCombatRules.roleOf(PetKind.hamster), PetRole.defender);
    expect(PetKind.values, hasLength(5));
    expect(GearCatalog.all, hasLength(12));
  });

  test('xp and base strength match every level', () {
    for (var level = 1; level <= PetCombatRules.maxLevel; level++) {
      expect(
        PetCombatRules.baseStrength(level),
        10 + 5 * (level - 1),
        reason: 'level $level',
      );
      if (level < PetCombatRules.maxLevel) {
        expect(PetCombatRules.xpToAdvance(level), 20 * level);
      } else {
        expect(PetCombatRules.xpToAdvance(level), 0);
      }
    }
    expect(PetLevelProgress.of(1, 0).gain(20).level, 2);
    expect(PetLevelProgress.of(1, 0).gain(20).xp, 0);
    expect(PetLevelProgress.of(2, 0).gain(40).level, 3);
    expect(PetLevelProgress.of(3, 0).gain(60).level, 4);
  });

  test('one feeding can cross several levels and keeps the remainder', () {
    final progress = PetLevelProgress.of(1, 0).gain(100);
    expect(progress.level, 3);
    expect(progress.xp, 40);
    expect(PetCombatRules.baseStrength(progress.level), 20);
    final partial = PetLevelProgress.of(1, 0).gain(25);
    expect(partial.level, 2);
    expect(partial.xp, 5);
  });

  test('maximum level keeps no extra xp and no extra strength', () {
    final capped = PetLevelProgress.of(19, 0).gain(400);
    expect(capped.level, 20);
    expect(capped.xp, 0);
    expect(PetCombatRules.baseStrength(20), 105);
    expect(capped.gain(50).level, 20);
    expect(capped.gain(50).xp, 0);
  });

  test('equipment adds to base strength and buying does not change level', () {
    const base = PetStrength(base: 10, main: 0, accessory: 0);
    final withSash = base.replacing(slot: GearSlot.main, bonus: 3);
    expect(withSash.total, 13);
    final withBoth = withSash.replacing(slot: GearSlot.accessory, bonus: 3);
    expect(withBoth.total, 16);
    final replaced = withBoth.replacing(slot: GearSlot.main, bonus: 7);
    expect(replaced.total, 20);
    expect(replaced.base, 10);
  });

  test('migration gives level 1 and a later open keeps xp and gear', () async {
    SharedPreferences.setMockInitialValues({
      'points.balance': 40,
      'points.earned': 40,
      'points.houseMigrated': true,
      'points.houseState': 3,
      'pet.owned': 'fox,dog',
      'pet.kind': 'fox',
      'pet.fox.hungerAt': t0.millisecondsSinceEpoch,
      'pet.stories.v1': '{"fox":{"chapter":1}}',
    });
    final store = await PointsStore.open();
    expect(store.roster.records.map((record) => record.kind), [
      PetKind.fox,
      PetKind.dog,
    ]);
    final fox = store.roster.recordOf(PetKind.fox)!;
    expect(fox.level, 1);
    expect(fox.xp, 0);
    expect(fox.mainItemId, isNull);
    expect(PetCombatRules.roleOf(PetKind.fox), PetRole.attacker);
    expect(PetCombatRules.roleOf(PetKind.dog), PetRole.defender);
    expect(
      (await SharedPreferences.getInstance()).getString('pet.stories.v1'),
      '{"fox":{"chapter":1}}',
    );

    final kept = PetRosterSnapshot(
      records: [
        const PetCombatRecord(
          kind: PetKind.fox,
          level: 4,
          xp: 15,
          mainItemId: 'gear-1',
        ),
        PetCombatRecord.fresh(PetKind.dog),
      ],
      items: const [GearInstance(id: 'gear-1', defId: 'attacker_main_1')],
      defender: PetKind.dog,
      seq: 3,
    );
    await (await SharedPreferences.getInstance()).setString(
      'pets.roster.v1',
      kept.encode(),
    );
    final again = await PointsStore.open();
    expect(again.roster.recordOf(PetKind.fox)!.level, 4);
    expect(again.roster.recordOf(PetKind.fox)!.xp, 15);
    expect(again.roster.recordOf(PetKind.fox)!.mainItemId, 'gear-1');
    expect(again.roster.items, hasLength(1));
    expect(
      again.roster.records.where((record) => record.kind == PetKind.fox).length,
      1,
    );
    expect(again.roster.defender, PetKind.dog);
    expect(
      (await SharedPreferences.getInstance()).getString('pet.stories.v1'),
      '{"fox":{"chapter":1}}',
    );
  });

  test(
    'feeding spends one plant, keeps points, and can level more than once',
    () async {
      final first = _plant('plant-1', species: SeedSpecies.glassreed);
      final second = _plant('plant-2', species: SeedSpecies.nightlotus);
      SharedPreferences.setMockInitialValues({
        ..._wallet(80),
        'pet.owned': 'cat',
        'pet.cat.hungerAt': t0.millisecondsSinceEpoch,
        'pet.cat.playAt': t0.millisecondsSinceEpoch,
        'pet.cat.restAt': t0.millisecondsSinceEpoch,
        'garden.state.v1': _garden([first, second]).encode(),
      });
      final store = await PointsStore.open();
      final fed = await store.feedPet(
        kind: PetKind.cat,
        plantId: first.id,
        now: t0.add(const Duration(hours: 3)),
      );
      expect(fed.fed, isTrue);
      expect(fed.preview!.leveled, isTrue);
      expect(fed.preview!.after.level, 2);
      expect(fed.preview!.after.xp, 5);
      expect(fed.preview!.afterStrength.total, 15);
      expect(store.balance, 80);
      expect(store.garden.warehouse.map((plant) => plant.id), [second.id]);
      expect(store.garden.plantCount, 1);
      expect(store.roster.recordOf(PetKind.cat)!.level, 2);

      final again = await store.feedPet(
        kind: PetKind.cat,
        plantId: first.id,
        now: t0.add(const Duration(hours: 4)),
      );
      expect(again.status, FeedStatus.missingPlant);
      expect(store.garden.warehouse, hasLength(1));
      expect(store.roster.recordOf(PetKind.cat)!.level, 2);

      final burst = await store.feedPet(
        kind: PetKind.cat,
        plantId: second.id,
        now: t0.add(const Duration(hours: 5)),
      );
      expect(burst.fed, isTrue);
      expect(burst.preview!.after.level, greaterThan(2));
      expect(store.garden.warehouse, isEmpty);
      expect(store.garden.plantCount, 0);
      expect(
        (await PointsStore.open()).roster.recordOf(PetKind.cat)!.xp,
        isNonNegative,
      );
    },
  );

  test('a failed save returns the plant and grants no experience', () async {
    final plant = _plant('plant-1');
    SharedPreferences.setMockInitialValues({
      ..._wallet(20),
      'pet.owned': 'cat',
      'garden.state.v1': _garden([plant]).encode(),
    });
    final store = await PointsStore.open();
    store.debugAbortNextCommit();
    final result = await store.feedPet(
      kind: PetKind.cat,
      plantId: plant.id,
      now: t0,
    );
    expect(result.status, FeedStatus.failed);
    expect(store.garden.warehouse.single.id, plant.id);
    expect(store.roster.recordOf(PetKind.cat)!.level, 1);
    expect(store.roster.recordOf(PetKind.cat)!.xp, 0);
    expect(store.debugGardenJournal, isNull);
    final reopened = await PointsStore.open();
    expect(reopened.garden.warehouse.single.id, plant.id);
    expect(reopened.roster.recordOf(PetKind.cat)!.xp, 0);
  });

  test('reopening finishes a journaled feeding', () async {
    final plant = _plant('plant-9');
    final hungerAt = t0.add(const Duration(hours: 2)).millisecondsSinceEpoch;
    SharedPreferences.setMockInitialValues({
      ..._wallet(11),
      'pet.owned': 'cat',
      'pet.cat.hungerAt': t0.millisecondsSinceEpoch,
      'garden.state.v1': _garden([plant]).encode(),
      'pets.roster.v1': const PetRosterSnapshot(
        records: [PetCombatRecord(kind: PetKind.cat, level: 1, xp: 0)],
        items: [],
        seq: 1,
      ).encode(),
      'garden.journal.v1': jsonEncode({
        'wallet': _walletSnapshot(11).encode(),
        'seeds': SeedSnapshot.empty.toJson(),
        'garden': _garden(const []).copyWith(seq: 5).toJson(),
        'roster': const PetRosterSnapshot(
          records: [PetCombatRecord(kind: PetKind.cat, level: 2, xp: 12)],
          items: [],
          seq: 2,
        ).toJson(),
        'hunger': {'pet.cat.hungerAt': hungerAt},
      }),
    });
    final recovered = await PointsStore.open();
    expect(recovered.garden.warehouse, isEmpty);
    expect(recovered.roster.recordOf(PetKind.cat)!.level, 2);
    expect(recovered.roster.recordOf(PetKind.cat)!.xp, 12);
    expect(recovered.balance, 11);
    expect(recovered.debugGardenJournal, isNull);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('pet.cat.hungerAt'), hungerAt);
  });

  test('a full pet at maximum level does not spend a plant', () async {
    final plant = _plant('plant-1');
    SharedPreferences.setMockInitialValues({
      ..._wallet(10),
      'pet.owned': 'hamster',
      'pet.hamster.hungerAt': t0.millisecondsSinceEpoch,
      'garden.state.v1': _garden([plant]).encode(),
      'pets.roster.v1': const PetRosterSnapshot(
        records: [PetCombatRecord(kind: PetKind.hamster, level: 20, xp: 0)],
        items: [],
        seq: 1,
      ).encode(),
    });
    final store = await PointsStore.open();
    final blocked = await store.feedPet(
      kind: PetKind.hamster,
      plantId: plant.id,
      now: t0,
    );
    expect(blocked.status, FeedStatus.pointless);
    expect(store.garden.warehouse, hasLength(1));
    expect(store.roster.recordOf(PetKind.hamster)!.level, 20);

    final hungry = await store.feedPet(
      kind: PetKind.hamster,
      plantId: plant.id,
      now: t0.add(const Duration(hours: 6)),
    );
    expect(hungry.fed, isTrue);
    expect(hungry.preview!.xpGain, 0);
    expect(hungry.preview!.restoresHunger, isTrue);
    expect(hungry.preview!.after.level, 20);
    expect(store.garden.warehouse, isEmpty);
    expect(store.roster.recordOf(PetKind.hamster)!.level, 20);
    expect(store.roster.recordOf(PetKind.hamster)!.xp, 0);
  });

  test('gear purchase, locks, and a single wearer', () async {
    SharedPreferences.setMockInitialValues({
      ..._wallet(1000),
      'pet.owned': 'cat,fox,dog',
    });
    final store = await PointsStore.open();
    final poor = await store.buyGear(
      kind: PetKind.cat,
      defId: 'attacker_main_3',
    );
    expect(poor.status, GearBuyStatus.levelLocked);
    expect(store.balance, 1000);
    expect(store.roster.items, isEmpty);

    SharedPreferences.setMockInitialValues({
      ..._wallet(50),
      'pet.owned': 'cat',
    });
    final broke = await (await PointsStore.open()).buyGear(
      kind: PetKind.cat,
      defId: 'attacker_main_1',
    );
    expect(broke.status, GearBuyStatus.insufficient);
    expect(broke.shortfall, 50);
    expect((await PointsStore.open()).balance, 50);

    SharedPreferences.setMockInitialValues({
      ..._wallet(800),
      'pet.owned': 'cat,fox,dog',
    });
    final rich = await PointsStore.open();
    final wrongRole = await rich.buyGear(
      kind: PetKind.cat,
      defId: 'defender_main_1',
    );
    expect(wrongRole.status, GearBuyStatus.roleMismatch);
    expect(rich.balance, 800);

    final bought = await rich.buyGear(
      kind: PetKind.cat,
      defId: 'attacker_main_1',
    );
    expect(bought.bought, isTrue);
    expect(rich.balance, 700);
    expect(rich.roster.recordOf(PetKind.cat)!.level, 1);
    expect(rich.garden.plantCount, 0);
    final item = bought.item!;
    final wrongSlot = await rich.equipGear(
      kind: PetKind.cat,
      itemId: item.id,
      slot: GearSlot.accessory,
    );
    expect(wrongSlot.status, EquipStatus.slotMismatch);
    expect(rich.roster.recordOf(PetKind.cat)!.accessoryItemId, isNull);

    final equipped = await rich.equipGear(
      kind: PetKind.cat,
      itemId: item.id,
      slot: GearSlot.main,
    );
    expect(equipped.equipped, isTrue);
    expect(rich.balance, 700);
    expect(
      PetStrength.of(
        level: 1,
        main: rich.roster.defOf(rich.roster.recordOf(PetKind.cat)!.mainItemId),
      ).total,
      13,
    );

    final stolen = await rich.equipGear(
      kind: PetKind.fox,
      itemId: item.id,
      slot: GearSlot.main,
    );
    expect(stolen.status, EquipStatus.wornByOther);
    expect(stolen.wornBy, PetKind.cat);
    expect(rich.roster.recordOf(PetKind.fox)!.mainItemId, isNull);

    await rich.unequipGear(kind: PetKind.cat, slot: GearSlot.main);
    final moved = await rich.equipGear(
      kind: PetKind.fox,
      itemId: item.id,
      slot: GearSlot.main,
    );
    expect(moved.equipped, isTrue);
    expect(rich.roster.recordOf(PetKind.cat)!.mainItemId, isNull);
    expect(rich.roster.recordOf(PetKind.fox)!.mainItemId, item.id);

    final better = await rich.buyGear(
      kind: PetKind.fox,
      defId: 'attacker_main_2',
    );
    expect(better.status, GearBuyStatus.levelLocked);

    final collar = await rich.buyGear(
      kind: PetKind.fox,
      defId: 'attacker_accessory_1',
    );
    expect(collar.bought, isTrue);
    await rich.equipGear(
      kind: PetKind.fox,
      itemId: collar.item!.id,
      slot: GearSlot.accessory,
    );
    expect(
      PetStrength.of(
        level: 1,
        main: rich.roster.defOf(item.id),
        accessory: rich.roster.defOf(collar.item!.id),
      ).total,
      16,
    );
    expect(rich.garden.plantCount, 0);
    expect((await PointsStore.open()).balance, rich.balance);
  });

  test('the garden guard survives restart and hiding from the yard', () async {
    SharedPreferences.setMockInitialValues({
      ..._wallet(10),
      'pet.owned': 'dog,cat',
      'pet.dog.hungerAt': t0.millisecondsSinceEpoch,
      'pet.dog.playAt': t0.millisecondsSinceEpoch,
      'pet.dog.restAt': t0.millisecondsSinceEpoch,
    });
    final store = await PointsStore.open();
    final pets = await PetStore.open();
    await pets.setInYard(PetKind.dog, visible: true);
    final assigned = await store.assignPet(kind: PetKind.dog, active: true);
    expect(assigned.status, AssignStatus.assigned);
    await pets.setInYard(PetKind.dog, visible: false);
    expect(pets.isInYard(PetKind.dog), isFalse);
    final reopened = await PointsStore.open();
    expect(reopened.roster.defender, PetKind.dog);
    expect(
      reopened.roster.guarding(
        PetStore.readOwned(await SharedPreferences.getInstance()),
      ),
      PetKind.dog,
    );
    final attacker = await reopened.assignPet(kind: PetKind.cat, active: true);
    expect(attacker.status, AssignStatus.assigned);
    expect(reopened.roster.raider, PetKind.cat);
    expect(reopened.roster.defender, PetKind.dog);
  });

  test('a mahjong win does not feed or grant combat experience', () async {
    SharedPreferences.setMockInitialValues({
      ..._wallet(10),
      'pet.owned': 'cat',
      'pet.cat.hungerAt': t0.millisecondsSinceEpoch,
      'pet.cat.playAt': t0.millisecondsSinceEpoch,
      'pet.cat.restAt': t0.millisecondsSinceEpoch,
      'pets.roster.v1': const PetRosterSnapshot(
        records: [PetCombatRecord(kind: PetKind.cat, level: 3, xp: 4)],
        items: [],
        seq: 1,
      ).encode(),
    });
    final points = await PointsStore.open();
    final pets = await PetStore.open();
    final later = t0.add(const Duration(hours: 11));
    final filled = await pets.satisfyMostUrgent(now: later);
    expect(filled!.need, isNot(PetNeed.hunger));
    expect(pets.care(kind: PetKind.cat, now: later)!.of(PetNeed.hunger), 0);
    expect(points.roster.recordOf(PetKind.cat)!.level, 3);
    expect(points.roster.recordOf(PetKind.cat)!.xp, 4);
  });

  test(
    'the same plant cannot be fed twice while the first feeding is running',
    () async {
      final plant = _plant('plant-1', species: SeedSpecies.glassreed);
      SharedPreferences.setMockInitialValues({
        ..._wallet(30),
        'pet.owned': 'raccoon',
        'garden.state.v1': _garden([plant]).encode(),
      });
      final controller = PointsController(await PointsStore.open());
      final first = controller.feedPet(
        kind: PetKind.raccoon,
        plantId: plant.id,
        now: t0,
      );
      final second = controller.feedPet(
        kind: PetKind.raccoon,
        plantId: plant.id,
        now: t0,
      );
      final results = await Future.wait([first, second]);
      expect(results.first.fed, isTrue);
      expect(identical(results.first, results.last), isTrue);
      expect(controller.garden.warehouse, isEmpty);
      expect(controller.plantCount, 0);
      expect(controller.roster.recordOf(PetKind.raccoon)!.level, 2);
    },
  );

  testWidgets(
    'the pet page feeds a harvested plant and shows the new strength',
    (tester) async {
      final plant = _plant('plant-32', species: SeedSpecies.glassreed);
      SharedPreferences.setMockInitialValues({
        ..._wallet(400),
        'pet.owned': 'cat',
        'pet.kind': 'cat',
        'pet.cat.hungerAt': t0.millisecondsSinceEpoch,
        'pet.cat.playAt': t0.millisecondsSinceEpoch,
        'pet.cat.restAt': t0.millisecondsSinceEpoch,
        'garden.state.v1': _garden([plant]).encode(),
      });
      final pets = await PetStore.open();
      final points = PointsController(await PointsStore.open());
      await tester.pumpWidget(
        PointsScope(
          controller: points,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: const MediaQueryData(
                disableAnimations: true,
                size: Size(800, 1200),
              ),
              child: Column(
                children: [
                  PlantChipLive(onTap: () {}),
                  Expanded(child: PetPage(pets: pets)),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Attacker'), findsOneWidget);
      expect(find.text('Level 1'), findsOneWidget);
      expect(points.plantCount, 1);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('plant-counter')),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('pet-feed-cat')),
        300,
      );
      await tester.tap(find.byKey(const ValueKey('pet-feed-cat')));
      await tester.pumpAndSettle();

      expect(find.text('Glass Reed'), findsOneWidget);
      expect(find.text('Feed: 25'), findsOneWidget);
      expect(find.text('Experience: 25'), findsOneWidget);
      expect(find.text('×1'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pet-feed-option-plant-32')));
      await tester.pump();
      expect(find.text('Level 1 → 2'), findsOneWidget);
      expect(find.text('Attack 10 → 15'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pet-feed-confirm')));
      await tester.pumpAndSettle();

      expect(points.plantCount, 0);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('plant-counter')),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
      expect(find.text('Level 2'), findsOneWidget);
      expect(find.textContaining('Attack 15'), findsOneWidget);
      expect(find.textContaining('Cat enjoys the meal.'), findsOneWidget);
      expect(points.balance, 400);
    },
  );
}

HarvestedPlant _plant(
  String id, {
  SeedSpecies species = SeedSpecies.amberbell,
}) {
  final at = DateTime.utc(2026, 8, 1);
  return HarvestedPlant(
    id: id,
    species: species,
    power: SeedCatalog.foodFor(species),
    houseLevel: 1,
    seedId: 'seed-$id',
    source: 'house_production',
    batchId: 'batch-1',
    plantingId: 'planting-$id',
    plantedAt: at,
    maturedAt: at,
    harvestedAt: at,
  );
}

GardenSnapshot _garden(List<HarvestedPlant> plants) {
  return GardenSnapshot(
    beds: List<Planting?>.filled(GardenCatalog.bedCount, null),
    warehouse: plants,
    seq: 4,
  );
}

Map<String, Object> _wallet(int balance) => {
  'points.balance': balance,
  'points.earned': balance,
  'points.purchased': 0,
  'points.houseMigrated': true,
  'points.houseState': 1,
};

WalletSnapshot _walletSnapshot(int balance) => WalletSnapshot(
  balance: balance,
  lifetimeEarned: balance,
  purchased: 0,
  houseState: 1,
  houseMigrated: true,
);
