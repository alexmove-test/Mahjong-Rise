import 'dart:convert';

import 'seed_catalog.dart';

/// Одна партия дома. Вид выбран при запуске и не пересчитывается.
class SeedBatch {
  const SeedBatch({
    required this.id,
    required this.startedAt,
    required this.readyAt,
    required this.houseLevel,
    required this.cost,
    required this.species,
    required this.power,
    required this.rulesVersion,
  });

  final String id;
  final DateTime startedAt;
  final DateTime readyAt;
  final int houseLevel;
  final int cost;
  final SeedSpecies species;
  final int power;
  final int rulesVersion;

  bool isReady(DateTime now) => !now.toUtc().isBefore(readyAt);

  Duration remaining(DateTime now) {
    final left = readyAt.difference(now.toUtc());
    if (left.isNegative) return Duration.zero;
    return left;
  }

  double progress(DateTime now) {
    final total = readyAt.difference(startedAt).inMilliseconds;
    if (total <= 0) return 1;
    final done = now.toUtc().difference(startedAt).inMilliseconds;
    return (done / total).clamp(0.0, 1.0);
  }

  Map<String, Object> toJson() => {
    'id': id,
    'startedAt': startedAt.millisecondsSinceEpoch,
    'readyAt': readyAt.millisecondsSinceEpoch,
    'houseLevel': houseLevel,
    'cost': cost,
    'species': species.name,
    'power': power,
    'rules': rulesVersion,
  };

  static SeedBatch? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final started = raw['startedAt'];
    final ready = raw['readyAt'];
    final house = raw['houseLevel'];
    final cost = raw['cost'];
    final speciesName = raw['species'];
    final power = raw['power'];
    final rules = raw['rules'];
    if (id is! String ||
        id.isEmpty ||
        started is! int ||
        ready is! int ||
        house is! int ||
        cost is! int ||
        speciesName is! String ||
        power is! int ||
        rules is! int ||
        ready < started) {
      return null;
    }
    final species = _species(speciesName);
    if (species == null) return null;
    return SeedBatch(
      id: id,
      startedAt: DateTime.fromMillisecondsSinceEpoch(started, isUtc: true),
      readyAt: DateTime.fromMillisecondsSinceEpoch(ready, isUtc: true),
      houseLevel: house,
      cost: cost,
      species: species,
      power: SeedCatalog.foodFor(species),
      rulesVersion: rules,
    );
  }
}

/// Отдельное семя. Позже его можно посадить или отдать на скрещивание.
class SeedInstance {
  const SeedInstance({
    required this.id,
    required this.species,
    required this.power,
    required this.houseLevel,
    required this.createdAt,
    required this.source,
    required this.batchId,
    this.variant,
  });

  final String id;
  final SeedSpecies species;
  final int power;
  final int houseLevel;
  final DateTime createdAt;
  final String source;
  final String batchId;

  /// Внешний вариант, если он уже есть у экземпляра. Новые мутации не выдаются.
  final String? variant;

  Map<String, Object> toJson() => {
    'id': id,
    'species': species.name,
    'power': power,
    'houseLevel': houseLevel,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'source': source,
    'batchId': batchId,
    'variant': ?variant,
  };

  static SeedInstance? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final speciesName = raw['species'];
    final power = raw['power'];
    final house = raw['houseLevel'];
    final created = raw['createdAt'];
    final source = raw['source'];
    final batchId = raw['batchId'];
    final variantRaw = raw['variant'];
    if (id is! String ||
        id.isEmpty ||
        speciesName is! String ||
        power is! int ||
        house is! int ||
        created is! int ||
        source is! String ||
        source.isEmpty ||
        batchId is! String ||
        batchId.isEmpty) {
      return null;
    }
    if (variantRaw != null && variantRaw is! String) return null;
    final species = _species(speciesName);
    if (species == null) return null;
    final variant = variantRaw is String && variantRaw.isNotEmpty
        ? variantRaw
        : null;
    return SeedInstance(
      id: id,
      species: species,
      power: SeedCatalog.foodFor(species),
      houseLevel: house,
      createdAt: DateTime.fromMillisecondsSinceEpoch(created, isUtc: true),
      source: source,
      batchId: batchId,
      variant: variant,
    );
  }
}

enum SeedPhase { idle, producing, ready }

SeedPhase phaseOf(SeedBatch? batch, DateTime now) {
  if (batch == null) return SeedPhase.idle;
  if (batch.isReady(now)) return SeedPhase.ready;
  return SeedPhase.producing;
}

/// Как показывать оставшееся время: не ноль, пока партия ещё не готова.
String formatSeedCountdown(Duration remaining) {
  var seconds = remaining.inSeconds;
  if (remaining > Duration.zero && seconds == 0) seconds = 1;
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = rest.toString().padLeft(2, '0');
  return '$mm:$ss';
}

/// Партия и экземпляры. Пустое состояние — игрок без семян и без партии.
class SeedSnapshot {
  const SeedSnapshot({
    required this.batch,
    required this.inventory,
    required this.seq,
  });

  static const empty = SeedSnapshot(batch: null, inventory: [], seq: 0);

  final SeedBatch? batch;
  final List<SeedInstance> inventory;
  final int seq;

  bool get isEmpty => batch == null && inventory.isEmpty && seq == 0;

  SeedSnapshot copyWith({
    SeedBatch? batch,
    bool clearBatch = false,
    List<SeedInstance>? inventory,
    int? seq,
  }) {
    return SeedSnapshot(
      batch: clearBatch ? null : batch ?? this.batch,
      inventory: inventory ?? this.inventory,
      seq: seq ?? this.seq,
    );
  }

  Map<String, Object?> toJson() => {
    'seq': seq,
    'batch': batch?.toJson(),
    'inventory': [for (final seed in inventory) seed.toJson()],
  };

  String encode() => jsonEncode(toJson());

  static SeedSnapshot? decode(String raw) {
    try {
      return fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static SeedSnapshot? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final seq = raw['seq'];
    if (seq is! int || seq < 0) return null;
    final batchRaw = raw['batch'];
    SeedBatch? batch;
    if (batchRaw != null) {
      batch = SeedBatch.fromJson(batchRaw);
      if (batch == null) return null;
    }
    final list = raw['inventory'];
    if (list is! List) return null;
    final inventory = <SeedInstance>[];
    for (final item in list) {
      final seed = SeedInstance.fromJson(item);
      if (seed == null) return null;
      inventory.add(seed);
    }
    return SeedSnapshot(batch: batch, inventory: inventory, seq: seq);
  }

  @override
  bool operator ==(Object other) {
    return other is SeedSnapshot &&
        other.seq == seq &&
        other.batch?.id == batch?.id &&
        other.batch?.species == batch?.species &&
        other.batch?.power == batch?.power &&
        other.batch?.readyAt == batch?.readyAt &&
        _sameInventory(other.inventory, inventory);
  }

  @override
  int get hashCode => Object.hash(seq, batch?.id, inventory.length);

  static bool _sameInventory(List<SeedInstance> a, List<SeedInstance> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].species != b[i].species ||
          a[i].power != b[i].power) {
        return false;
      }
    }
    return true;
  }
}

enum SeedSort { power, received }

/// Группа одинаковых вида и силы. Идентификаторы экземпляров сохраняются.
class SeedStack {
  const SeedStack({required this.instances});

  final List<SeedInstance> instances;

  SeedInstance get newest => instances.last;

  SeedSpecies get species => newest.species;

  int get power => newest.power;

  int get count => instances.length;

  int get houseLevel => newest.houseLevel;

  DateTime get receivedAt => newest.createdAt;
}

List<SeedStack> stackSeeds(
  List<SeedInstance> seeds, {
  SeedSort sort = SeedSort.received,
}) {
  final groups = <String, List<SeedInstance>>{};
  for (final seed in seeds) {
    final key = '${seed.species.name}#${seed.power}';
    groups.putIfAbsent(key, () => []).add(seed);
  }
  final stacks = [
    for (final group in groups.values)
      SeedStack(instances: [...group]..sort(_byReceived)),
  ];
  switch (sort) {
    case SeedSort.power:
      stacks.sort((a, b) {
        final byPower = b.power.compareTo(a.power);
        if (byPower != 0) return byPower;
        return b.receivedAt.compareTo(a.receivedAt);
      });
    case SeedSort.received:
      stacks.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
  }
  return stacks;
}

int _byReceived(SeedInstance a, SeedInstance b) =>
    a.createdAt.compareTo(b.createdAt);

enum SeedStartStatus { started, insufficient, busy, unavailable, failed }

class SeedStartResult {
  const SeedStartResult({
    required this.status,
    required this.balance,
    required this.seeds,
    this.cost = 0,
    this.shortfall = 0,
  });

  final SeedStartStatus status;
  final int balance;
  final SeedSnapshot seeds;
  final int cost;
  final int shortfall;

  bool get started => status == SeedStartStatus.started;

  const SeedStartResult.unavailable({
    required int balance,
    required SeedSnapshot seeds,
  }) : this(
         status: SeedStartStatus.unavailable,
         balance: balance,
         seeds: seeds,
       );

  const SeedStartResult.failed({
    required int balance,
    required SeedSnapshot seeds,
  }) : this(status: SeedStartStatus.failed, balance: balance, seeds: seeds);
}

enum SeedClaimStatus { claimed, notReady, empty, unavailable, failed }

class SeedClaimResult {
  const SeedClaimResult({
    required this.status,
    required this.balance,
    required this.seeds,
    this.seed,
  });

  final SeedClaimStatus status;
  final int balance;
  final SeedSnapshot seeds;
  final SeedInstance? seed;

  bool get claimed => status == SeedClaimStatus.claimed;

  const SeedClaimResult.unavailable({
    required int balance,
    required SeedSnapshot seeds,
  }) : this(
         status: SeedClaimStatus.unavailable,
         balance: balance,
         seeds: seeds,
       );

  const SeedClaimResult.failed({
    required int balance,
    required SeedSnapshot seeds,
  }) : this(status: SeedClaimStatus.failed, balance: balance, seeds: seeds);
}

SeedSpecies? _species(String name) {
  for (final species in SeedSpecies.values) {
    if (species.name == name) return species;
  }
  return null;
}
