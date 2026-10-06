import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/garden.dart';
import '../models/house_upgrade.dart';
import '../models/pet.dart';
import '../models/pet_combat.dart';
import '../models/pet_roster.dart';
import '../models/seed_batch.dart';
import '../models/seed_catalog.dart';
import '../widgets/courtyard/courtyard_estate.dart';
import '../widgets/courtyard/courtyard_lot_build.dart';
import 'pet_store.dart';
import 'progress_store.dart';

/// Снимок кошелька и купленного дома. Запись целиком, без второго баланса.
class WalletSnapshot {
  const WalletSnapshot({
    required this.balance,
    required this.lifetimeEarned,
    required this.purchased,
    required this.houseState,
    required this.houseMigrated,
  });

  final int balance;
  final int lifetimeEarned;
  final int purchased;
  final int houseState;
  final bool houseMigrated;

  WalletSnapshot copyWith({
    int? balance,
    int? lifetimeEarned,
    int? purchased,
    int? houseState,
    bool? houseMigrated,
  }) {
    return WalletSnapshot(
      balance: balance ?? this.balance,
      lifetimeEarned: lifetimeEarned ?? this.lifetimeEarned,
      purchased: purchased ?? this.purchased,
      houseState: houseState ?? this.houseState,
      houseMigrated: houseMigrated ?? this.houseMigrated,
    );
  }

  String encode() =>
      '$balance:$lifetimeEarned:$purchased:$houseState:${houseMigrated ? 1 : 0}';

  static WalletSnapshot? decode(String raw) {
    final parts = raw.split(':');
    if (parts.length != 5) return null;
    final balance = int.tryParse(parts[0]);
    final earned = int.tryParse(parts[1]);
    final purchased = int.tryParse(parts[2]);
    final house = int.tryParse(parts[3]);
    final migrated = int.tryParse(parts[4]);
    if (balance == null ||
        earned == null ||
        purchased == null ||
        house == null ||
        migrated == null) {
      return null;
    }
    return WalletSnapshot(
      balance: balance,
      lifetimeEarned: earned,
      purchased: purchased,
      houseState: HouseUpgrade.clampState(house),
      houseMigrated: migrated == 1,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WalletSnapshot &&
        other.balance == balance &&
        other.lifetimeEarned == lifetimeEarned &&
        other.purchased == purchased &&
        other.houseState == houseState &&
        other.houseMigrated == houseMigrated;
  }

  @override
  int get hashCode => Object.hash(
    balance,
    lifetimeEarned,
    purchased,
    houseState,
    houseMigrated,
  );
}

/// Кошелёк баллов и купленное состояние дома.
///
/// Начисление и покупка идут через одну очередь. Покупка сначала пишет журнал
/// с итоговым снимком, затем сам снимок: обрыв посередине доигрывается при
/// следующем открытии, а пойманная ошибка откатывает оба поля.
class PointsStore {
  PointsStore._(this._prefs);

  final SharedPreferences? _prefs;
  final _serial = _Serial();

  static const _kBalance = 'points.balance';
  static const _kEarned = 'points.earned';
  static const _kPurchased = 'points.purchased';
  static const _kHouse = 'points.houseState';
  static const _kHouseMigrated = 'points.houseMigrated';
  static const _kJournal = 'points.journal';
  static const _kSeedState = 'seeds.state.v1';
  static const _kSeedJournal = 'seeds.journal.v1';
  static const _kGardenState = 'garden.state.v1';
  static const _kGardenJournal = 'garden.journal.v1';
  static const _kRosterState = 'pets.roster.v1';

  static const maxBalance = 9999999;

  bool _abortNextCommit = false;

  static PointsStore memory() => PointsStore._(null);

  static Future<PointsStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    final store = PointsStore._(prefs);
    await store._recover();
    final progress = await ProgressStore.open();
    await store.migrateFromCampaign(progress);
    await store.migrateGarden();
    await store.migrateRoster();
    return store;
  }

  bool get isPersistent => _prefs != null;

  int get balance => (_prefs?.getInt(_kBalance) ?? 0).clamp(0, maxBalance);

  /// Сколько баллов всего заработано игрой, без покупок.
  int get lifetimeEarned => _prefs?.getInt(_kEarned) ?? 0;

  /// Сколько баллов всего пришло из магазина.
  int get purchased => _prefs?.getInt(_kPurchased) ?? 0;

  bool get houseMigrated => _prefs?.getBool(_kHouseMigrated) ?? false;

  /// 1…24. До миграции это бесплатное первое состояние, не чтение кампании.
  int get houseState {
    final raw = _prefs?.getInt(_kHouse);
    if (raw == null) return HouseUpgrade.firstState;
    return HouseUpgrade.clampState(raw);
  }

  /// Следующее открытие дописывает журнал, если процесс оборвался после него.
  @visibleForTesting
  String? get debugJournal => _prefs?.getString(_kJournal);

  /// Журнал партии. Пустой, когда списание и семя уже согласованы.
  @visibleForTesting
  String? get debugSeedJournal => _prefs?.getString(_kSeedJournal);

  /// Журнал посадки или сбора. Пустой, когда грядка и склад уже согласованы.
  @visibleForTesting
  String? get debugGardenJournal => _prefs?.getString(_kGardenJournal);

  /// Партия и семена. Повреждённая запись не подменяется пустой молча.
  SeedSnapshot get seeds {
    final loaded = _loadSeeds();
    if (loaded.corrupt) return SeedSnapshot.empty;
    return loaded.snapshot ?? SeedSnapshot.empty;
  }

  /// Грядки и собранные растения. Счётчик склада равен числу экземпляров.
  GardenSnapshot get garden {
    final loaded = _loadGarden();
    if (loaded.corrupt) return GardenSnapshot.empty;
    return loaded.snapshot ?? GardenSnapshot.empty;
  }

  /// Уровни, опыт и купленные вещи. Сила из этого снимка не читается как число.
  PetRosterSnapshot get roster {
    final loaded = _loadRoster();
    if (loaded.corrupt) return PetRosterSnapshot.empty;
    return loaded.snapshot ?? PetRosterSnapshot.empty;
  }

  /// Бросить после журнала, до записи снимка. Вызывающий откатывает оба поля.
  @visibleForTesting
  void debugAbortNextCommit() {
    _abortNextCommit = true;
  }

  /// Зачисление; [purchased] отделяет купленные баллы от заработанных.
  Future<int> add(int amount, {bool purchased = false}) async {
    if (!isPersistent || amount <= 0) return balance;
    final next = await _transact((current) {
      final updated = (current.balance + amount).clamp(0, maxBalance);
      if (purchased) {
        return current.copyWith(
          balance: updated,
          purchased: current.purchased + amount,
        );
      }
      return current.copyWith(
        balance: updated,
        lifetimeEarned: current.lifetimeEarned + amount,
      );
    });
    return next.balance;
  }

  /// Один раз переносит уже видимый кадр дома. Баланс не трогает.
  Future<void> migrateFromCampaign(ProgressStore progress) async {
    if (!isPersistent || houseMigrated) return;
    final campaign = CourtyardEstate.fromStore(progress).campaignStage;
    final frame = PlotStages.currentFrame(campaign);
    final state = HouseUpgrade.fromCampaignFrame(frame);
    await _transact((current) {
      if (current.houseMigrated) return current;
      return current.copyWith(houseState: state, houseMigrated: true);
    });
  }

  /// Купить ровно следующее состояние, если хватает баллов и есть куда расти.
  Future<HouseBuyResult> buyNextHouse() async {
    if (!isPersistent) {
      return const HouseBuyResult.unavailable(
        balance: 0,
        houseState: HouseUpgrade.firstState,
      );
    }
    HouseBuyResult result = HouseBuyResult.failed(
      balance: balance,
      houseState: houseState,
    );
    try {
      await _transact((current) {
        final decision = _quote(current);
        result = decision.result;
        return decision.next;
      });
    } catch (_) {
      result = HouseBuyResult.failed(balance: balance, houseState: houseState);
    }
    return result;
  }

  _Quote _quote(WalletSnapshot current) {
    if (!current.houseMigrated) {
      return _Quote(
        current,
        HouseBuyResult.failed(
          balance: current.balance,
          houseState: current.houseState,
        ),
      );
    }
    final nextState = HouseUpgrade.nextState(current.houseState);
    if (nextState == null) {
      return _Quote(
        current,
        HouseBuyResult(
          status: HouseBuyStatus.maxed,
          balance: current.balance,
          houseState: current.houseState,
        ),
      );
    }
    final price = HouseUpgrade.priceAfter(current.houseState);
    if (current.balance < price) {
      return _Quote(
        current,
        HouseBuyResult(
          status: HouseBuyStatus.insufficient,
          balance: current.balance,
          houseState: current.houseState,
          price: price,
          shortfall: price - current.balance,
        ),
      );
    }
    final next = current.copyWith(
      balance: current.balance - price,
      houseState: nextState,
    );
    return _Quote(
      next,
      HouseBuyResult(
        status: HouseBuyStatus.purchased,
        balance: next.balance,
        houseState: next.houseState,
        price: price,
      ),
    );
  }

  WalletSnapshot _read() {
    final rawHouse = _prefs?.getInt(_kHouse);
    return WalletSnapshot(
      balance: balance,
      lifetimeEarned: lifetimeEarned,
      purchased: purchased,
      houseState: rawHouse == null
          ? HouseUpgrade.firstState
          : HouseUpgrade.clampState(rawHouse),
      houseMigrated: houseMigrated,
    );
  }

  Future<WalletSnapshot> _transact(
    WalletSnapshot Function(WalletSnapshot current) edit,
  ) {
    return _serial.run(() async {
      await _recover();
      final current = _read();
      final next = edit(current);
      if (next == current) return current;
      try {
        return await _commit(next);
      } catch (_) {
        await _apply(current);
        await _prefs?.remove(_kJournal);
        rethrow;
      }
    });
  }

  Future<WalletSnapshot> _commit(WalletSnapshot next) async {
    final prefs = _prefs;
    if (prefs == null) return next;
    await prefs.setString(_kJournal, next.encode());
    if (_abortNextCommit) {
      _abortNextCommit = false;
      throw StateError('wallet commit aborted');
    }
    await _apply(next);
    await prefs.remove(_kJournal);
    return next;
  }

  Future<void> _recover() async {
    await _recoverWallet();
    await _recoverSeeds();
    await _recoverGarden();
  }

  Future<void> _recoverWallet() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final raw = prefs.getString(_kJournal);
    if (raw == null || raw.isEmpty) return;
    final snapshot = WalletSnapshot.decode(raw);
    if (snapshot == null) {
      await prefs.remove(_kJournal);
      return;
    }
    await _apply(snapshot);
    await prefs.remove(_kJournal);
  }

  /// Время устройства — единственные часы этой версии.
  /// Сдвиг вперёд заканчивает партию раньше, сдвиг назад её задерживает.
  /// Журнал защищает от обрыва записи, но не от правки локальных данных.
  Future<SeedStartResult> startSeedBatch({
    DateTime? now,
    int? speciesIndex,
    int Function(int count)? roll,
  }) async {
    if (!isPersistent) {
      return SeedStartResult.unavailable(balance: balance, seeds: seeds);
    }
    try {
      return await _serial.run(
        () => _startSeedBatch(now: now, speciesIndex: speciesIndex, roll: roll),
      );
    } catch (_) {
      return SeedStartResult.failed(balance: balance, seeds: seeds);
    }
  }

  Future<SeedStartResult> _startSeedBatch({
    DateTime? now,
    int? speciesIndex,
    int Function(int count)? roll,
  }) async {
    await _recover();
    final wallet = _read();
    final loaded = _loadSeeds();
    if (loaded.corrupt || loaded.snapshot == null) {
      return SeedStartResult.failed(balance: wallet.balance, seeds: seeds);
    }
    final current = loaded.snapshot!;
    if (current.batch != null) {
      return SeedStartResult(
        status: SeedStartStatus.busy,
        balance: wallet.balance,
        seeds: current,
      );
    }
    final offer = SeedCatalog.offerFor(wallet.houseState);
    if (offer.species.isEmpty) {
      return SeedStartResult.failed(balance: wallet.balance, seeds: current);
    }
    if (wallet.balance < offer.cost) {
      return SeedStartResult(
        status: SeedStartStatus.insufficient,
        balance: wallet.balance,
        seeds: current,
        cost: offer.cost,
        shortfall: offer.cost - wallet.balance,
      );
    }
    final SeedSpecies species;
    if (speciesIndex != null) {
      if (speciesIndex < 0 || speciesIndex >= offer.species.length) {
        return SeedStartResult.failed(balance: wallet.balance, seeds: current);
      }
      species = offer.species[speciesIndex];
    } else {
      species = SeedCatalog.rollSpecies(
        offer.houseLevel,
        roll ?? Random().nextInt,
      );
    }
    final clock = (now ?? DateTime.now()).toUtc();
    final seq = current.seq + 1;
    final batch = SeedBatch(
      id: 'batch-$seq',
      startedAt: clock,
      readyAt: clock.add(offer.duration),
      houseLevel: offer.houseLevel,
      cost: offer.cost,
      species: species,
      power: SeedCatalog.foodFor(species),
      rulesVersion: SeedCatalog.rulesVersion,
    );
    final nextSeeds = current.copyWith(batch: batch, seq: seq);
    final nextWallet = wallet.copyWith(balance: wallet.balance - offer.cost);
    try {
      await _commitSeeds(wallet: nextWallet, seeds: nextSeeds);
    } catch (_) {
      await _apply(wallet);
      await _writeSeeds(current);
      await _prefs?.remove(_kSeedJournal);
      rethrow;
    }
    return SeedStartResult(
      status: SeedStartStatus.started,
      balance: nextWallet.balance,
      seeds: nextSeeds,
      cost: offer.cost,
    );
  }

  Future<SeedClaimResult> claimSeed({DateTime? now}) async {
    if (!isPersistent) {
      return SeedClaimResult.unavailable(balance: balance, seeds: seeds);
    }
    try {
      return await _serial.run(() => _claimSeed(now: now));
    } catch (_) {
      return SeedClaimResult.failed(balance: balance, seeds: seeds);
    }
  }

  Future<SeedClaimResult> _claimSeed({DateTime? now}) async {
    await _recover();
    final wallet = _read();
    final loaded = _loadSeeds();
    if (loaded.corrupt || loaded.snapshot == null) {
      return SeedClaimResult.failed(balance: wallet.balance, seeds: seeds);
    }
    final current = loaded.snapshot!;
    final batch = current.batch;
    if (batch == null) {
      return SeedClaimResult(
        status: SeedClaimStatus.empty,
        balance: wallet.balance,
        seeds: current,
      );
    }
    final clock = (now ?? DateTime.now()).toUtc();
    if (!batch.isReady(clock)) {
      return SeedClaimResult(
        status: SeedClaimStatus.notReady,
        balance: wallet.balance,
        seeds: current,
      );
    }
    final seq = current.seq + 1;
    final seed = SeedInstance(
      id: 'seed-$seq',
      species: batch.species,
      power: batch.power,
      houseLevel: batch.houseLevel,
      createdAt: clock,
      source: SeedSource.houseProduction,
      batchId: batch.id,
    );
    final nextSeeds = current.copyWith(
      clearBatch: true,
      inventory: [...current.inventory, seed],
      seq: seq,
    );
    try {
      await _commitSeeds(wallet: wallet, seeds: nextSeeds);
    } catch (_) {
      await _apply(wallet);
      await _writeSeeds(current);
      await _prefs?.remove(_kSeedJournal);
      rethrow;
    }
    return SeedClaimResult(
      status: SeedClaimStatus.claimed,
      balance: wallet.balance,
      seeds: nextSeeds,
      seed: seed,
    );
  }

  Future<void> _commitSeeds({
    required WalletSnapshot wallet,
    required SeedSnapshot seeds,
  }) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(
      _kSeedJournal,
      jsonEncode({'wallet': wallet.encode(), 'seeds': seeds.toJson()}),
    );
    if (_abortNextCommit) {
      _abortNextCommit = false;
      throw StateError('wallet commit aborted');
    }
    await _apply(wallet);
    await _writeSeeds(seeds);
    await prefs.remove(_kSeedJournal);
  }

  Future<void> _recoverSeeds() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final raw = prefs.getString(_kSeedJournal);
    if (raw == null || raw.isEmpty) return;
    final decoded = _decodeSeedJournal(raw);
    if (decoded == null) {
      await prefs.remove(_kSeedJournal);
      return;
    }
    await _apply(decoded.wallet);
    await _writeSeeds(decoded.seeds);
    await prefs.remove(_kSeedJournal);
  }

  ({WalletSnapshot wallet, SeedSnapshot seeds})? _decodeSeedJournal(
    String raw,
  ) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final walletRaw = json['wallet'];
      final seedsRaw = json['seeds'];
      if (walletRaw is! String) return null;
      final wallet = WalletSnapshot.decode(walletRaw);
      final seeds = SeedSnapshot.fromJson(seedsRaw);
      if (wallet == null || seeds == null) return null;
      return (wallet: wallet, seeds: seeds);
    } catch (_) {
      return null;
    }
  }

  ({SeedSnapshot? snapshot, bool corrupt}) _loadSeeds() {
    final prefs = _prefs;
    if (prefs == null) return (snapshot: SeedSnapshot.empty, corrupt: false);
    final raw = prefs.getString(_kSeedState);
    if (raw == null || raw.isEmpty) {
      return (snapshot: SeedSnapshot.empty, corrupt: false);
    }
    final decoded = SeedSnapshot.decode(raw);
    if (decoded == null) return (snapshot: null, corrupt: true);
    return (snapshot: decoded, corrupt: false);
  }

  Future<void> _writeSeeds(SeedSnapshot snapshot) async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (snapshot.isEmpty) {
      await prefs.remove(_kSeedState);
      return;
    }
    await prefs.setString(_kSeedState, snapshot.encode());
  }

  Future<void> _apply(WalletSnapshot snapshot) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setInt(_kBalance, snapshot.balance.clamp(0, maxBalance));
    await prefs.setInt(_kEarned, snapshot.lifetimeEarned);
    await prefs.setInt(_kPurchased, snapshot.purchased);
    await prefs.setInt(_kHouse, HouseUpgrade.clampState(snapshot.houseState));
    await prefs.setBool(_kHouseMigrated, snapshot.houseMigrated);
  }

  /// Один раз создаёт три пустые грядки. Повторный вызов посадки не стирает.
  Future<void> migrateGarden() async {
    if (!isPersistent) return;
    await _serial.run(() async {
      await _recover();
      final loaded = _loadGarden();
      if (loaded.corrupt || loaded.snapshot != null) return;
      await _writeGarden(GardenSnapshot.empty);
    });
  }

  /// Списывает одно семя и цену посадки, затем занимает свободную грядку.
  Future<PlantResult> plantSeed({
    required int bedIndex,
    required String seedId,
    DateTime? now,
  }) async {
    if (!isPersistent) {
      return PlantResult.unavailable(
        balance: balance,
        seeds: seeds,
        garden: garden,
      );
    }
    try {
      return await _serial.run(
        () => _plantSeed(bedIndex: bedIndex, seedId: seedId, now: now),
      );
    } catch (_) {
      return PlantResult.failed(balance: balance, seeds: seeds, garden: garden);
    }
  }

  Future<PlantResult> _plantSeed({
    required int bedIndex,
    required String seedId,
    DateTime? now,
  }) async {
    await _recover();
    final wallet = _read();
    final loadedSeeds = _loadSeeds();
    final loadedGarden = _loadGarden();
    if (loadedSeeds.corrupt ||
        loadedSeeds.snapshot == null ||
        loadedGarden.corrupt) {
      return PlantResult.failed(
        balance: wallet.balance,
        seeds: seeds,
        garden: garden,
      );
    }
    final currentSeeds = loadedSeeds.snapshot!;
    final currentGarden = loadedGarden.snapshot ?? GardenSnapshot.empty;
    if (bedIndex < 0 || bedIndex >= GardenCatalog.bedCount) {
      return PlantResult.failed(
        balance: wallet.balance,
        seeds: currentSeeds,
        garden: currentGarden,
      );
    }
    if (currentGarden.bedAt(bedIndex) != null) {
      return PlantResult(
        status: PlantStatus.occupied,
        balance: wallet.balance,
        seeds: currentSeeds,
        garden: currentGarden,
      );
    }
    SeedInstance? seed;
    for (final item in currentSeeds.inventory) {
      if (item.id == seedId) {
        seed = item;
        break;
      }
    }
    if (seed == null || currentGarden.occupiesSeed(seedId)) {
      return PlantResult(
        status: PlantStatus.missingSeed,
        balance: wallet.balance,
        seeds: currentSeeds,
        garden: currentGarden,
      );
    }
    final cost = GardenCatalog.costFor(seed.species);
    if (wallet.balance < cost) {
      return PlantResult(
        status: PlantStatus.insufficient,
        balance: wallet.balance,
        seeds: currentSeeds,
        garden: currentGarden,
        cost: cost,
        shortfall: cost - wallet.balance,
      );
    }
    final clock = (now ?? DateTime.now()).toUtc();
    final seq = currentGarden.seq + 1;
    final planting = Planting(
      id: 'planting-$seq',
      seedId: seed.id,
      species: seed.species,
      power: GardenCatalog.foodFor(seed.species),
      houseLevel: seed.houseLevel,
      variant: seed.variant,
      source: seed.source,
      batchId: seed.batchId,
      plantedAt: clock,
      readyAt: clock.add(GardenCatalog.durationFor(seed.species)),
      cost: cost,
      rulesVersion: GardenCatalog.rulesVersion,
    );
    final beds = [...currentGarden.beds];
    beds[bedIndex] = planting;
    final nextGarden = currentGarden.copyWith(beds: beds, seq: seq);
    final nextSeeds = currentSeeds.copyWith(
      inventory: [
        for (final item in currentSeeds.inventory)
          if (item.id != seed.id) item,
      ],
    );
    final nextWallet = wallet.copyWith(balance: wallet.balance - cost);
    try {
      await _commitGarden(
        wallet: nextWallet,
        seeds: nextSeeds,
        garden: nextGarden,
      );
    } catch (_) {
      await _apply(wallet);
      await _writeSeeds(currentSeeds);
      await _writeGarden(currentGarden);
      await _prefs?.remove(_kGardenJournal);
      rethrow;
    }
    return PlantResult(
      status: PlantStatus.planted,
      balance: nextWallet.balance,
      seeds: nextSeeds,
      garden: nextGarden,
      cost: cost,
      planting: planting,
    );
  }

  /// Кладёт одно созревшее растение на склад и освобождает грядку.
  Future<HarvestResult> harvestBed({
    required int bedIndex,
    DateTime? now,
  }) async {
    if (!isPersistent) {
      return HarvestResult.unavailable(
        balance: balance,
        seeds: seeds,
        garden: garden,
      );
    }
    try {
      return await _serial.run(() => _harvestBed(bedIndex: bedIndex, now: now));
    } catch (_) {
      return HarvestResult.failed(
        balance: balance,
        seeds: seeds,
        garden: garden,
      );
    }
  }

  Future<HarvestResult> _harvestBed({
    required int bedIndex,
    DateTime? now,
  }) async {
    await _recover();
    final wallet = _read();
    final loadedSeeds = _loadSeeds();
    final loadedGarden = _loadGarden();
    if (loadedSeeds.corrupt ||
        loadedSeeds.snapshot == null ||
        loadedGarden.corrupt ||
        loadedGarden.snapshot == null) {
      return HarvestResult.failed(
        balance: wallet.balance,
        seeds: seeds,
        garden: garden,
      );
    }
    final currentSeeds = loadedSeeds.snapshot!;
    final currentGarden = loadedGarden.snapshot!;
    if (bedIndex < 0 || bedIndex >= currentGarden.beds.length) {
      return HarvestResult.failed(
        balance: wallet.balance,
        seeds: currentSeeds,
        garden: currentGarden,
      );
    }
    final planting = currentGarden.bedAt(bedIndex);
    if (planting == null) {
      return HarvestResult(
        status: HarvestStatus.empty,
        balance: wallet.balance,
        seeds: currentSeeds,
        garden: currentGarden,
      );
    }
    final clock = (now ?? DateTime.now()).toUtc();
    if (!planting.isReady(clock)) {
      return HarvestResult(
        status: HarvestStatus.notReady,
        balance: wallet.balance,
        seeds: currentSeeds,
        garden: currentGarden,
      );
    }
    final seq = currentGarden.seq + 1;
    final plant = HarvestedPlant(
      id: 'plant-$seq',
      species: planting.species,
      power: GardenCatalog.foodFor(planting.species),
      houseLevel: planting.houseLevel,
      variant: planting.variant,
      seedId: planting.seedId,
      source: planting.source,
      batchId: planting.batchId,
      plantingId: planting.id,
      plantedAt: planting.plantedAt,
      maturedAt: planting.readyAt,
      harvestedAt: clock,
    );
    final beds = [...currentGarden.beds];
    beds[bedIndex] = null;
    final nextGarden = currentGarden.copyWith(
      beds: beds,
      warehouse: [...currentGarden.warehouse, plant],
      seq: seq,
    );
    try {
      await _commitGarden(
        wallet: wallet,
        seeds: currentSeeds,
        garden: nextGarden,
      );
    } catch (_) {
      await _apply(wallet);
      await _writeSeeds(currentSeeds);
      await _writeGarden(currentGarden);
      await _prefs?.remove(_kGardenJournal);
      rethrow;
    }
    return HarvestResult(
      status: HarvestStatus.harvested,
      balance: wallet.balance,
      seeds: currentSeeds,
      garden: nextGarden,
      plant: plant,
    );
  }

  Future<void> _commitGarden({
    required WalletSnapshot wallet,
    required SeedSnapshot seeds,
    required GardenSnapshot garden,
    PetRosterSnapshot? roster,
    Map<String, int>? hungerAt,
  }) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(
      _kGardenJournal,
      jsonEncode({
        'wallet': wallet.encode(),
        'seeds': seeds.toJson(),
        'garden': garden.toJson(),
        'roster': ?roster?.toJson(),
        'hunger': ?hungerAt,
      }),
    );
    if (_abortNextCommit) {
      _abortNextCommit = false;
      throw StateError('wallet commit aborted');
    }
    await _apply(wallet);
    await _writeSeeds(seeds);
    await _writeGarden(garden);
    if (roster != null) await _writeRoster(roster);
    if (hungerAt != null) {
      for (final entry in hungerAt.entries) {
        await prefs.setInt(entry.key, entry.value);
      }
    }
    await prefs.remove(_kGardenJournal);
  }

  Future<void> _recoverGarden() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final raw = prefs.getString(_kGardenJournal);
    if (raw == null || raw.isEmpty) return;
    final decoded = _decodeGardenJournal(raw);
    if (decoded == null) {
      await prefs.remove(_kGardenJournal);
      return;
    }
    await _apply(decoded.wallet);
    await _writeSeeds(decoded.seeds);
    await _writeGarden(decoded.garden);
    if (decoded.roster != null) await _writeRoster(decoded.roster!);
    if (decoded.hunger != null) {
      for (final entry in decoded.hunger!.entries) {
        await prefs.setInt(entry.key, entry.value);
      }
    }
    await prefs.remove(_kGardenJournal);
  }

  ({
    WalletSnapshot wallet,
    SeedSnapshot seeds,
    GardenSnapshot garden,
    PetRosterSnapshot? roster,
    Map<String, int>? hunger,
  })?
  _decodeGardenJournal(String raw) {
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final walletRaw = json['wallet'];
      if (walletRaw is! String) return null;
      final wallet = WalletSnapshot.decode(walletRaw);
      final seeds = SeedSnapshot.fromJson(json['seeds']);
      final garden = GardenSnapshot.fromJson(json['garden']);
      if (wallet == null || seeds == null || garden == null) return null;
      PetRosterSnapshot? roster;
      if (json.containsKey('roster')) {
        roster = PetRosterSnapshot.fromJson(json['roster']);
        if (roster == null) return null;
      }
      Map<String, int>? hunger;
      if (json.containsKey('hunger')) {
        final rawHunger = json['hunger'];
        if (rawHunger is! Map) return null;
        hunger = {};
        for (final entry in rawHunger.entries) {
          final key = entry.key;
          final value = entry.value;
          if (key is! String || key.isEmpty || value is! int) return null;
          hunger[key] = value;
        }
      }
      return (
        wallet: wallet,
        seeds: seeds,
        garden: garden,
        roster: roster,
        hunger: hunger,
      );
    } catch (_) {
      return null;
    }
  }

  ({GardenSnapshot? snapshot, bool corrupt}) _loadGarden() {
    final prefs = _prefs;
    if (prefs == null) return (snapshot: GardenSnapshot.empty, corrupt: false);
    final raw = prefs.getString(_kGardenState);
    if (raw == null || raw.isEmpty) {
      return (snapshot: null, corrupt: false);
    }
    final decoded = GardenSnapshot.decode(raw);
    if (decoded == null) return (snapshot: null, corrupt: true);
    return (snapshot: decoded, corrupt: false);
  }

  Future<void> _writeGarden(GardenSnapshot snapshot) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_kGardenState, snapshot.encode());
  }

  /// Добавляет записи новым питомцам. Уже полученный опыт и вещи не сбрасывает.
  Future<void> migrateRoster() async {
    if (!isPersistent) return;
    await _serial.run(() async {
      await _recover();
      final loaded = _loadRoster();
      if (loaded.corrupt) return;
      final current = loaded.snapshot ?? PetRosterSnapshot.empty;
      final next = current.ensureOwned(PetStore.readOwned(_prefs));
      if (loaded.snapshot != null && identical(next, current)) return;
      await _writeRoster(next);
    });
  }

  Future<void> syncOwnedPets() => migrateRoster();

  Future<FeedResult> feedPet({
    required PetKind kind,
    required String plantId,
    DateTime? now,
  }) async {
    if (!isPersistent) {
      return FeedResult.unavailable(
        balance: balance,
        seeds: seeds,
        garden: garden,
        roster: roster,
      );
    }
    try {
      return await _serial.run(
        () => _feedPet(kind: kind, plantId: plantId, now: now),
      );
    } catch (_) {
      return FeedResult.failed(
        balance: balance,
        seeds: seeds,
        garden: garden,
        roster: roster,
      );
    }
  }

  Future<FeedResult> _feedPet({
    required PetKind kind,
    required String plantId,
    DateTime? now,
  }) async {
    await _recover();
    final wallet = _read();
    final loadedSeeds = _loadSeeds();
    final loadedGarden = _loadGarden();
    final loadedRoster = _loadRoster();
    if (loadedSeeds.corrupt ||
        loadedSeeds.snapshot == null ||
        loadedGarden.corrupt ||
        loadedGarden.snapshot == null ||
        loadedRoster.corrupt) {
      return FeedResult.failed(
        balance: wallet.balance,
        seeds: seeds,
        garden: garden,
        roster: roster,
      );
    }
    final currentSeeds = loadedSeeds.snapshot!;
    final currentGarden = loadedGarden.snapshot!;
    final currentRoster = loadedRoster.snapshot ?? PetRosterSnapshot.empty;
    final owned = PetStore.readOwned(_prefs);
    final clock = now ?? DateTime.now();
    final pets = _prefs == null ? null : PetStore.bound(_prefs);
    final hunger = pets?.care(kind: kind, now: clock)?.of(PetNeed.hunger) ?? 1;
    final plan = planFeed(
      roster: currentRoster,
      garden: currentGarden,
      owned: owned,
      kind: kind,
      plantId: plantId,
      hunger: hunger,
      now: clock,
    );
    FeedResult rejected(FeedStatus status) => FeedResult(
      status: status,
      balance: wallet.balance,
      seeds: currentSeeds,
      garden: currentGarden,
      roster: currentRoster,
      preview: plan.preview,
      plant: plan.plant,
    );
    if (!plan.fed || plan.garden == null || plan.roster == null) {
      return rejected(plan.status);
    }
    final hungerKey = PetStore.satisfiedKey(kind, PetNeed.hunger);
    final previousHunger = _prefs?.getInt(hungerKey);
    try {
      await _commitGarden(
        wallet: wallet,
        seeds: currentSeeds,
        garden: plan.garden!,
        roster: plan.roster,
        hungerAt: {hungerKey: plan.hungerMillis!},
      );
    } catch (_) {
      await _apply(wallet);
      await _writeSeeds(currentSeeds);
      await _writeGarden(currentGarden);
      await _writeRoster(currentRoster);
      final prefs = _prefs;
      if (prefs != null) {
        if (previousHunger == null) {
          await prefs.remove(hungerKey);
        } else {
          await prefs.setInt(hungerKey, previousHunger);
        }
        await prefs.remove(_kGardenJournal);
      }
      rethrow;
    }
    return FeedResult(
      status: FeedStatus.fed,
      balance: wallet.balance,
      seeds: currentSeeds,
      garden: plan.garden!,
      roster: plan.roster!,
      preview: plan.preview,
      plant: plan.plant,
    );
  }

  Future<GearBuyResult> buyGear({
    required PetKind kind,
    required String defId,
  }) async {
    if (!isPersistent) {
      return GearBuyResult.unavailable(
        balance: balance,
        seeds: seeds,
        garden: garden,
        roster: roster,
      );
    }
    try {
      return await _serial.run(() => _buyGear(kind: kind, defId: defId));
    } catch (_) {
      return GearBuyResult.failed(
        balance: balance,
        seeds: seeds,
        garden: garden,
        roster: roster,
      );
    }
  }

  Future<GearBuyResult> _buyGear({
    required PetKind kind,
    required String defId,
  }) async {
    await _recover();
    final wallet = _read();
    final loadedSeeds = _loadSeeds();
    final loadedGarden = _loadGarden();
    final loadedRoster = _loadRoster();
    if (loadedSeeds.corrupt ||
        loadedSeeds.snapshot == null ||
        loadedGarden.corrupt ||
        loadedGarden.snapshot == null ||
        loadedRoster.corrupt) {
      return GearBuyResult.failed(
        balance: wallet.balance,
        seeds: seeds,
        garden: garden,
        roster: roster,
      );
    }
    final currentSeeds = loadedSeeds.snapshot!;
    final currentGarden = loadedGarden.snapshot!;
    final currentRoster = loadedRoster.snapshot ?? PetRosterSnapshot.empty;
    final plan = planGearBuy(
      balance: wallet.balance,
      roster: currentRoster,
      owned: PetStore.readOwned(_prefs),
      kind: kind,
      defId: defId,
    );
    GearBuyResult rejected() => GearBuyResult(
      status: plan.status,
      balance: wallet.balance,
      seeds: currentSeeds,
      garden: currentGarden,
      roster: currentRoster,
      price: plan.price,
      shortfall: plan.shortfall,
      def: plan.def,
    );
    if (plan.status != GearBuyStatus.bought ||
        plan.roster == null ||
        plan.balance == null) {
      return rejected();
    }
    final nextWallet = wallet.copyWith(balance: plan.balance!);
    try {
      await _commitGarden(
        wallet: nextWallet,
        seeds: currentSeeds,
        garden: currentGarden,
        roster: plan.roster,
      );
    } catch (_) {
      await _apply(wallet);
      await _writeSeeds(currentSeeds);
      await _writeGarden(currentGarden);
      await _writeRoster(currentRoster);
      await _prefs?.remove(_kGardenJournal);
      rethrow;
    }
    return GearBuyResult(
      status: GearBuyStatus.bought,
      balance: nextWallet.balance,
      seeds: currentSeeds,
      garden: currentGarden,
      roster: plan.roster!,
      price: plan.price,
      item: plan.item,
      def: plan.def,
    );
  }

  Future<EquipResult> equipGear({
    required PetKind kind,
    required String itemId,
    required GearSlot slot,
  }) async {
    if (!isPersistent) {
      return EquipResult.unavailable(
        balance: balance,
        seeds: seeds,
        garden: garden,
        roster: roster,
      );
    }
    try {
      return await _serial.run(
        () => _equipGear(kind: kind, itemId: itemId, slot: slot),
      );
    } catch (_) {
      return EquipResult.failed(
        balance: balance,
        seeds: seeds,
        garden: garden,
        roster: roster,
      );
    }
  }

  Future<EquipResult> _equipGear({
    required PetKind kind,
    required String itemId,
    required GearSlot slot,
  }) async {
    final plan = planEquip(
      roster: await _rosterForEdit(),
      owned: PetStore.readOwned(_prefs),
      kind: kind,
      itemId: itemId,
      slot: slot,
    );
    return _commitEquip(plan, success: EquipStatus.equipped);
  }

  Future<EquipResult> unequipGear({
    required PetKind kind,
    required GearSlot slot,
  }) async {
    if (!isPersistent) {
      return EquipResult.unavailable(
        balance: balance,
        seeds: seeds,
        garden: garden,
        roster: roster,
      );
    }
    try {
      return await _serial.run(() => _unequipGear(kind: kind, slot: slot));
    } catch (_) {
      return EquipResult.failed(
        balance: balance,
        seeds: seeds,
        garden: garden,
        roster: roster,
      );
    }
  }

  Future<EquipResult> _unequipGear({
    required PetKind kind,
    required GearSlot slot,
  }) async {
    final plan = planUnequip(
      roster: await _rosterForEdit(),
      owned: PetStore.readOwned(_prefs),
      kind: kind,
      slot: slot,
    );
    return _commitEquip(plan, success: EquipStatus.unequipped);
  }

  Future<PetRosterSnapshot> _rosterForEdit() async {
    await _recover();
    final loaded = _loadRoster();
    if (loaded.corrupt) return PetRosterSnapshot.empty;
    return loaded.snapshot ?? PetRosterSnapshot.empty;
  }

  Future<EquipResult> _commitEquip(
    EquipPlan plan, {
    required EquipStatus success,
  }) async {
    await _recover();
    final wallet = _read();
    final loadedSeeds = _loadSeeds();
    final loadedGarden = _loadGarden();
    final loadedRoster = _loadRoster();
    if (loadedSeeds.corrupt ||
        loadedSeeds.snapshot == null ||
        loadedGarden.corrupt ||
        loadedGarden.snapshot == null ||
        loadedRoster.corrupt) {
      return EquipResult.failed(
        balance: wallet.balance,
        seeds: seeds,
        garden: garden,
        roster: roster,
      );
    }
    final currentSeeds = loadedSeeds.snapshot!;
    final currentGarden = loadedGarden.snapshot!;
    final currentRoster = loadedRoster.snapshot ?? PetRosterSnapshot.empty;
    if (plan.roster == null ||
        (plan.status != success && plan.status != EquipStatus.equipped)) {
      return EquipResult(
        status: plan.status,
        balance: wallet.balance,
        seeds: currentSeeds,
        garden: currentGarden,
        roster: currentRoster,
        wornBy: plan.wornBy,
      );
    }
    if (identical(plan.roster, currentRoster)) {
      return EquipResult(
        status: plan.status,
        balance: wallet.balance,
        seeds: currentSeeds,
        garden: currentGarden,
        roster: currentRoster,
      );
    }
    try {
      await _commitGarden(
        wallet: wallet,
        seeds: currentSeeds,
        garden: currentGarden,
        roster: plan.roster,
      );
    } catch (_) {
      await _apply(wallet);
      await _writeSeeds(currentSeeds);
      await _writeGarden(currentGarden);
      await _writeRoster(currentRoster);
      await _prefs?.remove(_kGardenJournal);
      rethrow;
    }
    return EquipResult(
      status: plan.status,
      balance: wallet.balance,
      seeds: currentSeeds,
      garden: currentGarden,
      roster: plan.roster!,
    );
  }

  Future<AssignResult> assignPet({
    required PetKind kind,
    required bool active,
  }) async {
    if (!isPersistent) {
      return AssignResult.unavailable(
        balance: balance,
        seeds: seeds,
        garden: garden,
        roster: roster,
      );
    }
    try {
      return await _serial.run(() => _assignPet(kind: kind, active: active));
    } catch (_) {
      return AssignResult.failed(
        balance: balance,
        seeds: seeds,
        garden: garden,
        roster: roster,
      );
    }
  }

  Future<AssignResult> _assignPet({
    required PetKind kind,
    required bool active,
  }) async {
    await _recover();
    final wallet = _read();
    final loadedSeeds = _loadSeeds();
    final loadedGarden = _loadGarden();
    final loadedRoster = _loadRoster();
    if (loadedSeeds.corrupt ||
        loadedSeeds.snapshot == null ||
        loadedGarden.corrupt ||
        loadedGarden.snapshot == null ||
        loadedRoster.corrupt) {
      return AssignResult.failed(
        balance: balance,
        seeds: seeds,
        garden: garden,
        roster: roster,
      );
    }
    final currentSeeds = loadedSeeds.snapshot!;
    final currentGarden = loadedGarden.snapshot!;
    final currentRoster = loadedRoster.snapshot ?? PetRosterSnapshot.empty;
    final plan = planAssign(
      roster: currentRoster,
      owned: PetStore.readOwned(_prefs),
      kind: kind,
      active: active,
    );
    if (plan.roster == null) {
      return AssignResult(
        status: plan.status,
        balance: wallet.balance,
        seeds: currentSeeds,
        garden: currentGarden,
        roster: currentRoster,
      );
    }
    if (identical(plan.roster, currentRoster)) {
      return AssignResult(
        status: plan.status,
        balance: wallet.balance,
        seeds: currentSeeds,
        garden: currentGarden,
        roster: currentRoster,
      );
    }
    try {
      await _commitGarden(
        wallet: wallet,
        seeds: currentSeeds,
        garden: currentGarden,
        roster: plan.roster,
      );
    } catch (_) {
      await _apply(wallet);
      await _writeSeeds(currentSeeds);
      await _writeGarden(currentGarden);
      await _writeRoster(currentRoster);
      await _prefs?.remove(_kGardenJournal);
      rethrow;
    }
    return AssignResult(
      status: plan.status,
      balance: wallet.balance,
      seeds: currentSeeds,
      garden: currentGarden,
      roster: plan.roster!,
    );
  }

  ({PetRosterSnapshot? snapshot, bool corrupt}) _loadRoster() {
    final prefs = _prefs;
    if (prefs == null)
      return (snapshot: PetRosterSnapshot.empty, corrupt: false);
    final raw = prefs.getString(_kRosterState);
    if (raw == null || raw.isEmpty) return (snapshot: null, corrupt: false);
    final decoded = PetRosterSnapshot.decode(raw);
    if (decoded == null) return (snapshot: null, corrupt: true);
    return (snapshot: decoded, corrupt: false);
  }

  Future<void> _writeRoster(PetRosterSnapshot snapshot) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_kRosterState, snapshot.encode());
  }
}

class _Quote {
  const _Quote(this.next, this.result);

  final WalletSnapshot next;
  final HouseBuyResult result;
}

class _Serial {
  Future<void> _tail = Future<void>.value();

  Future<T> run<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then((_) {}, onError: (_) {});
    return result;
  }
}
