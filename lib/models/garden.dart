import 'dart:convert';

import 'seed_batch.dart';
import 'seed_catalog.dart';

/// Цена и срок посадки. Оба следуют классу: дольше растёт — дороже стоит.
abstract final class GardenCatalog {
  static const rulesVersion = 3;
  static const bedCount = 3;

  static Duration durationFor(SeedSpecies species) =>
      switch (species.seedClass) {
        SeedClass.common => const Duration(minutes: 5),
        SeedClass.nutrient => const Duration(minutes: 20),
        SeedClass.rare => const Duration(minutes: 60),
      };

  static int costFor(SeedSpecies species) =>
      SeedCatalog.pointsFor(durationFor(species));

  static int foodFor(SeedSpecies species) => SeedCatalog.foodFor(species);
}

/// Доля времени от посадки до готовности. Часы назад не дают отрицательный рост.
enum GrowthStage { sown, sprout, growing, ripe }

GrowthStage stageOf(Planting planting, DateTime now) {
  if (planting.isReady(now)) return GrowthStage.ripe;
  final done = planting.progress(now);
  if (done < 0.20) return GrowthStage.sown;
  if (done < 0.50) return GrowthStage.sprout;
  return GrowthStage.growing;
}

/// Посадка на одной грядке. Сила и вид скопированы с семени и больше не меняются.
class Planting {
  const Planting({
    required this.id,
    required this.seedId,
    required this.species,
    required this.power,
    required this.houseLevel,
    required this.source,
    required this.batchId,
    required this.plantedAt,
    required this.readyAt,
    required this.cost,
    required this.rulesVersion,
    this.variant,
  });

  final String id;
  final String seedId;
  final SeedSpecies species;
  final int power;
  final int houseLevel;
  final String? variant;
  final String source;
  final String batchId;
  final DateTime plantedAt;
  final DateTime readyAt;
  final int cost;
  final int rulesVersion;

  bool isReady(DateTime now) => !now.toUtc().isBefore(readyAt);

  Duration remaining(DateTime now) {
    final left = readyAt.difference(now.toUtc());
    if (left.isNegative) return Duration.zero;
    return left;
  }

  double progress(DateTime now) {
    final total = readyAt.difference(plantedAt).inMilliseconds;
    if (total <= 0) return 1;
    final done = now.toUtc().difference(plantedAt).inMilliseconds;
    if (done <= 0) return 0;
    final value = done / total;
    if (value <= 0) return 0;
    if (value >= 1) return 1;
    return value;
  }

  Map<String, Object> toJson() => {
    'id': id,
    'seedId': seedId,
    'species': species.name,
    'power': power,
    'houseLevel': houseLevel,
    'source': source,
    'batchId': batchId,
    'plantedAt': plantedAt.millisecondsSinceEpoch,
    'readyAt': readyAt.millisecondsSinceEpoch,
    'cost': cost,
    'rules': rulesVersion,
    'variant': ?variant,
  };

  static Planting? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final seedId = raw['seedId'];
    final speciesName = raw['species'];
    final power = raw['power'];
    final house = raw['houseLevel'];
    final source = raw['source'];
    final batchId = raw['batchId'];
    final planted = raw['plantedAt'];
    final ready = raw['readyAt'];
    final cost = raw['cost'];
    final rules = raw['rules'];
    final variantRaw = raw['variant'];
    if (id is! String ||
        id.isEmpty ||
        seedId is! String ||
        seedId.isEmpty ||
        speciesName is! String ||
        power is! int ||
        house is! int ||
        source is! String ||
        source.isEmpty ||
        batchId is! String ||
        batchId.isEmpty ||
        planted is! int ||
        ready is! int ||
        cost is! int ||
        rules is! int ||
        ready < planted) {
      return null;
    }
    if (variantRaw != null && variantRaw is! String) return null;
    final species = _species(speciesName);
    if (species == null) return null;
    final variant = variantRaw is String && variantRaw.isNotEmpty
        ? variantRaw
        : null;
    return Planting(
      id: id,
      seedId: seedId,
      species: species,
      power: SeedCatalog.foodFor(species),
      houseLevel: house,
      source: source,
      batchId: batchId,
      plantedAt: DateTime.fromMillisecondsSinceEpoch(planted, isUtc: true),
      readyAt: DateTime.fromMillisecondsSinceEpoch(ready, isUtc: true),
      cost: cost,
      rulesVersion: rules,
      variant: variant,
    );
  }
}

/// Собранное растение. Один экземпляр — один идентификатор.
class HarvestedPlant {
  const HarvestedPlant({
    required this.id,
    required this.species,
    required this.power,
    required this.houseLevel,
    required this.seedId,
    required this.source,
    required this.batchId,
    required this.plantingId,
    required this.plantedAt,
    required this.maturedAt,
    required this.harvestedAt,
    this.variant,
  });

  final String id;
  final SeedSpecies species;
  final int power;
  final int houseLevel;
  final String? variant;
  final String seedId;
  final String source;
  final String batchId;
  final String plantingId;
  final DateTime plantedAt;
  final DateTime maturedAt;
  final DateTime harvestedAt;

  Map<String, Object> toJson() => {
    'id': id,
    'species': species.name,
    'power': power,
    'houseLevel': houseLevel,
    'seedId': seedId,
    'source': source,
    'batchId': batchId,
    'plantingId': plantingId,
    'plantedAt': plantedAt.millisecondsSinceEpoch,
    'maturedAt': maturedAt.millisecondsSinceEpoch,
    'harvestedAt': harvestedAt.millisecondsSinceEpoch,
    'variant': ?variant,
  };

  static HarvestedPlant? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final speciesName = raw['species'];
    final power = raw['power'];
    final house = raw['houseLevel'];
    final seedId = raw['seedId'];
    final source = raw['source'];
    final batchId = raw['batchId'];
    final plantingId = raw['plantingId'];
    final planted = raw['plantedAt'];
    final matured = raw['maturedAt'];
    final harvested = raw['harvestedAt'];
    final variantRaw = raw['variant'];
    if (id is! String ||
        id.isEmpty ||
        speciesName is! String ||
        power is! int ||
        house is! int ||
        seedId is! String ||
        seedId.isEmpty ||
        source is! String ||
        source.isEmpty ||
        batchId is! String ||
        batchId.isEmpty ||
        plantingId is! String ||
        plantingId.isEmpty ||
        planted is! int ||
        matured is! int ||
        harvested is! int ||
        matured < planted) {
      return null;
    }
    if (variantRaw != null && variantRaw is! String) return null;
    final species = _species(speciesName);
    if (species == null) return null;
    final variant = variantRaw is String && variantRaw.isNotEmpty
        ? variantRaw
        : null;
    return HarvestedPlant(
      id: id,
      species: species,
      power: SeedCatalog.foodFor(species),
      houseLevel: house,
      seedId: seedId,
      source: source,
      batchId: batchId,
      plantingId: plantingId,
      plantedAt: DateTime.fromMillisecondsSinceEpoch(planted, isUtc: true),
      maturedAt: DateTime.fromMillisecondsSinceEpoch(matured, isUtc: true),
      harvestedAt: DateTime.fromMillisecondsSinceEpoch(harvested, isUtc: true),
      variant: variant,
    );
  }
}

/// Три грядки и склад. Пустой снимок — миграция игрока без посадок.
class GardenSnapshot {
  const GardenSnapshot({
    required this.beds,
    required this.warehouse,
    required this.seq,
  });

  static final empty = GardenSnapshot(
    beds: List<Planting?>.unmodifiable(
      List<Planting?>.filled(GardenCatalog.bedCount, null),
    ),
    warehouse: const [],
    seq: 0,
  );

  final List<Planting?> beds;
  final List<HarvestedPlant> warehouse;
  final int seq;

  int get plantCount => warehouse.length;

  Planting? bedAt(int index) {
    if (index < 0 || index >= beds.length) return null;
    return beds[index];
  }

  bool occupiesSeed(String seedId) {
    for (final bed in beds) {
      if (bed != null && bed.seedId == seedId) return true;
    }
    return false;
  }

  GardenSnapshot copyWith({
    List<Planting?>? beds,
    List<HarvestedPlant>? warehouse,
    int? seq,
  }) {
    return GardenSnapshot(
      beds: beds ?? this.beds,
      warehouse: warehouse ?? this.warehouse,
      seq: seq ?? this.seq,
    );
  }

  Map<String, Object> toJson() => {
    'seq': seq,
    'beds': [for (final bed in beds) bed?.toJson()],
    'warehouse': [for (final plant in warehouse) plant.toJson()],
  };

  String encode() => jsonEncode(toJson());

  static GardenSnapshot? decode(String raw) {
    try {
      return fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static GardenSnapshot? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final seq = raw['seq'];
    if (seq is! int || seq < 0) return null;
    final bedsRaw = raw['beds'];
    final warehouseRaw = raw['warehouse'];
    if (bedsRaw is! List || bedsRaw.length != GardenCatalog.bedCount) {
      return null;
    }
    if (warehouseRaw is! List) return null;
    final beds = <Planting?>[];
    for (final item in bedsRaw) {
      if (item == null) {
        beds.add(null);
        continue;
      }
      final planting = Planting.fromJson(item);
      if (planting == null) return null;
      beds.add(planting);
    }
    final warehouse = <HarvestedPlant>[];
    for (final item in warehouseRaw) {
      final plant = HarvestedPlant.fromJson(item);
      if (plant == null) return null;
      warehouse.add(plant);
    }
    return GardenSnapshot(beds: beds, warehouse: warehouse, seq: seq);
  }

  @override
  bool operator ==(Object other) {
    return other is GardenSnapshot &&
        other.seq == seq &&
        other.warehouse.length == warehouse.length &&
        _sameBeds(other.beds, beds) &&
        _sameWarehouse(other.warehouse, warehouse);
  }

  @override
  int get hashCode => Object.hash(seq, beds.length, warehouse.length);

  static bool _sameBeds(List<Planting?> a, List<Planting?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i]?.id != b[i]?.id ||
          a[i]?.power != b[i]?.power ||
          a[i]?.readyAt != b[i]?.readyAt) {
        return false;
      }
    }
    return true;
  }

  static bool _sameWarehouse(List<HarvestedPlant> a, List<HarvestedPlant> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
}

enum PlantSort { power, received }

/// Группа склада: один вид, одна сила и один внешний вариант.
class PlantStack {
  const PlantStack({required this.instances});

  final List<HarvestedPlant> instances;

  HarvestedPlant get newest => instances.last;

  SeedSpecies get species => newest.species;

  int get power => newest.power;

  String? get variant => newest.variant;

  int get count => instances.length;

  DateTime get receivedAt => newest.harvestedAt;
}

List<PlantStack> stackPlants(
  List<HarvestedPlant> plants, {
  PlantSort sort = PlantSort.received,
}) {
  final groups = <String, List<HarvestedPlant>>{};
  for (final plant in plants) {
    final key = '${plant.species.name}#${plant.power}#${plant.variant ?? ''}';
    groups.putIfAbsent(key, () => []).add(plant);
  }
  final stacks = [
    for (final group in groups.values)
      PlantStack(instances: [...group]..sort(_byHarvested)),
  ];
  switch (sort) {
    case PlantSort.power:
      stacks.sort((a, b) {
        final byPower = b.power.compareTo(a.power);
        if (byPower != 0) return byPower;
        return b.receivedAt.compareTo(a.receivedAt);
      });
    case PlantSort.received:
      stacks.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
  }
  return stacks;
}

int _byHarvested(HarvestedPlant a, HarvestedPlant b) =>
    a.harvestedAt.compareTo(b.harvestedAt);

enum PlantStatus {
  planted,
  occupied,
  missingSeed,
  insufficient,
  unavailable,
  failed,
}

class PlantResult {
  const PlantResult({
    required this.status,
    required this.balance,
    required this.seeds,
    required this.garden,
    this.cost = 0,
    this.shortfall = 0,
    this.planting,
  });

  final PlantStatus status;
  final int balance;
  final SeedSnapshot seeds;
  final GardenSnapshot garden;
  final int cost;
  final int shortfall;
  final Planting? planting;

  bool get planted => status == PlantStatus.planted;

  const PlantResult.unavailable({
    required int balance,
    required SeedSnapshot seeds,
    required GardenSnapshot garden,
  }) : this(
         status: PlantStatus.unavailable,
         balance: balance,
         seeds: seeds,
         garden: garden,
       );

  const PlantResult.failed({
    required int balance,
    required SeedSnapshot seeds,
    required GardenSnapshot garden,
  }) : this(
         status: PlantStatus.failed,
         balance: balance,
         seeds: seeds,
         garden: garden,
       );
}

enum HarvestStatus { harvested, notReady, empty, unavailable, failed }

class HarvestResult {
  const HarvestResult({
    required this.status,
    required this.balance,
    required this.seeds,
    required this.garden,
    this.plant,
  });

  final HarvestStatus status;
  final int balance;
  final SeedSnapshot seeds;
  final GardenSnapshot garden;
  final HarvestedPlant? plant;

  bool get harvested => status == HarvestStatus.harvested;

  const HarvestResult.unavailable({
    required int balance,
    required SeedSnapshot seeds,
    required GardenSnapshot garden,
  }) : this(
         status: HarvestStatus.unavailable,
         balance: balance,
         seeds: seeds,
         garden: garden,
       );

  const HarvestResult.failed({
    required int balance,
    required SeedSnapshot seeds,
    required GardenSnapshot garden,
  }) : this(
         status: HarvestStatus.failed,
         balance: balance,
         seeds: seeds,
         garden: garden,
       );
}

SeedSpecies? _species(String name) {
  for (final species in SeedSpecies.values) {
    if (species.name == name) return species;
  }
  return null;
}
