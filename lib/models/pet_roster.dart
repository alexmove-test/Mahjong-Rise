import 'dart:convert';

import 'garden.dart';
import 'pet.dart';
import 'pet_combat.dart';
import 'seed_batch.dart';

/// Боевой прогресс одного питомца. Итоговая сила каждый раз считается заново.
class PetCombatRecord {
  const PetCombatRecord({
    required this.kind,
    required this.level,
    required this.xp,
    this.mainItemId,
    this.accessoryItemId,
  });

  final PetKind kind;
  final int level;
  final int xp;
  final String? mainItemId;
  final String? accessoryItemId;

  static PetCombatRecord fresh(PetKind kind) =>
      PetCombatRecord(kind: kind, level: PetCombatRules.minLevel, xp: 0);

  String? itemIn(GearSlot slot) => switch (slot) {
    GearSlot.main => mainItemId,
    GearSlot.accessory => accessoryItemId,
  };

  PetCombatRecord copyWith({
    int? level,
    int? xp,
    String? mainItemId,
    String? accessoryItemId,
    bool clearMain = false,
    bool clearAccessory = false,
  }) {
    return PetCombatRecord(
      kind: kind,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      mainItemId: clearMain ? null : (mainItemId ?? this.mainItemId),
      accessoryItemId: clearAccessory
          ? null
          : (accessoryItemId ?? this.accessoryItemId),
    );
  }

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'level': level,
    'xp': xp,
    'main': mainItemId,
    'accessory': accessoryItemId,
  };

  static PetCombatRecord? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final kind = _kind(raw['kind']);
    final level = raw['level'];
    final xp = raw['xp'];
    final main = raw['main'];
    final accessory = raw['accessory'];
    if (kind == null || level is! int || xp is! int) return null;
    if (main != null && main is! String) return null;
    if (accessory != null && accessory is! String) return null;
    final progress = PetLevelProgress.of(level, xp);
    return PetCombatRecord(
      kind: kind,
      level: progress.level,
      xp: progress.xp,
      mainItemId: main is String && main.isNotEmpty ? main : null,
      accessoryItemId: accessory is String && accessory.isNotEmpty
          ? accessory
          : null,
    );
  }
}

/// Купленный экземпляр. Надет, только если на него ссылается слот питомца.
class GearInstance {
  const GearInstance({required this.id, required this.defId});

  final String id;
  final String defId;

  Map<String, Object> toJson() => {'id': id, 'def': defId};

  static GearInstance? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final defId = raw['def'];
    if (id is! String || id.isEmpty || defId is! String || defId.isEmpty) {
      return null;
    }
    return GearInstance(id: id, defId: defId);
  }
}

class PetRosterSnapshot {
  const PetRosterSnapshot({
    required this.records,
    required this.items,
    required this.seq,
    this.defender,
    this.raider,
  });

  static const empty = PetRosterSnapshot(records: [], items: [], seq: 0);

  final List<PetCombatRecord> records;
  final List<GearInstance> items;
  final PetKind? defender;
  final PetKind? raider;
  final int seq;

  PetCombatRecord? recordOf(PetKind kind) {
    for (final record in records) {
      if (record.kind == kind) return record;
    }
    return null;
  }

  GearInstance? itemOf(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  GearDef? defOf(String? itemId) {
    if (itemId == null) return null;
    final item = itemOf(itemId);
    if (item == null) return null;
    return GearCatalog.byId(item.defId);
  }

  PetKind? wearerOf(String itemId) {
    for (final record in records) {
      if (record.mainItemId == itemId || record.accessoryItemId == itemId) {
        return record.kind;
      }
    }
    return null;
  }

  /// Назначение защитника, если вид всё ещё защитник.
  PetKind? guarding(List<PetKind> owned) {
    final kind = defender;
    if (kind == null || !owned.contains(kind)) return null;
    if (PetCombatRules.roleOf(kind) != PetRole.defender) return null;
    return kind;
  }

  PetKind? raiding(List<PetKind> owned) {
    final kind = raider;
    if (kind == null || !owned.contains(kind)) return null;
    if (PetCombatRules.roleOf(kind) != PetRole.attacker) return null;
    return kind;
  }

  bool ownsDefenderSpecies(List<PetKind> owned) =>
      owned.any((kind) => PetCombatRules.roleOf(kind) == PetRole.defender);

  PetRosterSnapshot ensureOwned(List<PetKind> owned) {
    final missing = [
      for (final kind in owned)
        if (recordOf(kind) == null) kind,
    ];
    if (missing.isEmpty) return this;
    return copyWith(
      records: [
        ...records,
        for (final kind in missing) PetCombatRecord.fresh(kind),
      ],
    );
  }

  PetRosterSnapshot copyWith({
    List<PetCombatRecord>? records,
    List<GearInstance>? items,
    int? seq,
    PetKind? defender,
    PetKind? raider,
    bool clearDefender = false,
    bool clearRaider = false,
  }) {
    return PetRosterSnapshot(
      records: records ?? this.records,
      items: items ?? this.items,
      seq: seq ?? this.seq,
      defender: clearDefender ? null : (defender ?? this.defender),
      raider: clearRaider ? null : (raider ?? this.raider),
    );
  }

  Map<String, Object?> toJson() => {
    'seq': seq,
    'defender': defender?.name,
    'raider': raider?.name,
    'records': [for (final record in records) record.toJson()],
    'items': [for (final item in items) item.toJson()],
  };

  String encode() => jsonEncode(toJson());

  static PetRosterSnapshot? decode(String raw) {
    try {
      return fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  static PetRosterSnapshot? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final seq = raw['seq'];
    if (seq is! int || seq < 0) return null;
    final recordsRaw = raw['records'];
    final itemsRaw = raw['items'];
    if (recordsRaw is! List || itemsRaw is! List) return null;
    final records = <PetCombatRecord>[];
    final seen = <PetKind>{};
    for (final item in recordsRaw) {
      final record = PetCombatRecord.fromJson(item);
      if (record == null || !seen.add(record.kind)) return null;
      records.add(record);
    }
    final items = <GearInstance>[];
    final seenItems = <String>{};
    for (final item in itemsRaw) {
      final gear = GearInstance.fromJson(item);
      if (gear == null || !seenItems.add(gear.id)) return null;
      items.add(gear);
    }
    var defender = _kindOrNull(raw['defender']);
    var raider = _kindOrNull(raw['raider']);
    if (raw['defender'] != null &&
        defender == null &&
        raw['defender'] is! String) {
      return null;
    }
    if (raw['raider'] != null && raider == null && raw['raider'] is! String) {
      return null;
    }
    if (defender != null &&
        PetCombatRules.roleOf(defender) != PetRole.defender) {
      defender = null;
    }
    if (raider != null && PetCombatRules.roleOf(raider) != PetRole.attacker) {
      raider = null;
    }
    return PetRosterSnapshot(
      records: records,
      items: items,
      seq: seq,
      defender: defender,
      raider: raider,
    );
  }
}

enum FeedStatus { fed, notOwned, missingPlant, pointless, unavailable, failed }

class FeedResult {
  const FeedResult({
    required this.status,
    required this.balance,
    required this.seeds,
    required this.garden,
    required this.roster,
    this.preview,
    this.plant,
  });

  final FeedStatus status;
  final int balance;
  final SeedSnapshot seeds;
  final GardenSnapshot garden;
  final PetRosterSnapshot roster;
  final FeedPreview? preview;
  final HarvestedPlant? plant;

  bool get fed => status == FeedStatus.fed;

  const FeedResult.unavailable({
    required int balance,
    required SeedSnapshot seeds,
    required GardenSnapshot garden,
    required PetRosterSnapshot roster,
  }) : this(
         status: FeedStatus.unavailable,
         balance: balance,
         seeds: seeds,
         garden: garden,
         roster: roster,
       );

  const FeedResult.failed({
    required int balance,
    required SeedSnapshot seeds,
    required GardenSnapshot garden,
    required PetRosterSnapshot roster,
  }) : this(
         status: FeedStatus.failed,
         balance: balance,
         seeds: seeds,
         garden: garden,
         roster: roster,
       );
}

class FeedPlan {
  const FeedPlan({
    required this.status,
    this.garden,
    this.roster,
    this.preview,
    this.plant,
    this.hungerMillis,
  });

  final FeedStatus status;
  final GardenSnapshot? garden;
  final PetRosterSnapshot? roster;
  final FeedPreview? preview;
  final HarvestedPlant? plant;
  final int? hungerMillis;

  bool get fed => status == FeedStatus.fed;
}

FeedPlan planFeed({
  required PetRosterSnapshot roster,
  required GardenSnapshot garden,
  required List<PetKind> owned,
  required PetKind kind,
  required String plantId,
  required double hunger,
  required DateTime now,
}) {
  if (!owned.contains(kind)) {
    return const FeedPlan(status: FeedStatus.notOwned);
  }
  HarvestedPlant? plant;
  for (final item in garden.warehouse) {
    if (item.id == plantId) {
      plant = item;
      break;
    }
  }
  if (plant == null) return const FeedPlan(status: FeedStatus.missingPlant);
  final ready = roster.ensureOwned(owned);
  final record = ready.recordOf(kind);
  if (record == null) return const FeedPlan(status: FeedStatus.notOwned);
  final main = ready.defOf(record.mainItemId);
  final accessory = ready.defOf(record.accessoryItemId);
  final preview = previewFeed(
    level: record.level,
    xp: record.xp,
    plantPower: GardenCatalog.foodFor(plant.species),
    hunger: hunger,
    main: main,
    accessory: accessory,
  );
  if (preview.pointless) {
    return FeedPlan(
      status: FeedStatus.pointless,
      preview: preview,
      plant: plant,
    );
  }
  final progressed = record.copyWith(
    level: preview.after.level,
    xp: preview.after.xp,
  );
  return FeedPlan(
    status: FeedStatus.fed,
    garden: garden.copyWith(
      warehouse: [
        for (final item in garden.warehouse)
          if (item.id != plant.id) item,
      ],
      seq: garden.seq + 1,
    ),
    roster: ready.copyWith(
      records: [
        for (final item in ready.records)
          if (item.kind == kind) progressed else item,
      ],
      seq: ready.seq + 1,
    ),
    preview: preview,
    plant: plant,
    hungerMillis: now.millisecondsSinceEpoch,
  );
}

enum GearBuyStatus {
  bought,
  notOwned,
  unknown,
  roleMismatch,
  levelLocked,
  insufficient,
  unavailable,
  failed,
}

class GearBuyResult {
  const GearBuyResult({
    required this.status,
    required this.balance,
    required this.seeds,
    required this.garden,
    required this.roster,
    this.price = 0,
    this.shortfall = 0,
    this.item,
    this.def,
  });

  final GearBuyStatus status;
  final int balance;
  final SeedSnapshot seeds;
  final GardenSnapshot garden;
  final PetRosterSnapshot roster;
  final int price;
  final int shortfall;
  final GearInstance? item;
  final GearDef? def;

  bool get bought => status == GearBuyStatus.bought;

  const GearBuyResult.unavailable({
    required int balance,
    required SeedSnapshot seeds,
    required GardenSnapshot garden,
    required PetRosterSnapshot roster,
  }) : this(
         status: GearBuyStatus.unavailable,
         balance: balance,
         seeds: seeds,
         garden: garden,
         roster: roster,
       );

  const GearBuyResult.failed({
    required int balance,
    required SeedSnapshot seeds,
    required GardenSnapshot garden,
    required PetRosterSnapshot roster,
  }) : this(
         status: GearBuyStatus.failed,
         balance: balance,
         seeds: seeds,
         garden: garden,
         roster: roster,
       );
}

class GearBuyPlan {
  const GearBuyPlan({
    required this.status,
    this.balance,
    this.roster,
    this.price = 0,
    this.shortfall = 0,
    this.item,
    this.def,
  });

  final GearBuyStatus status;
  final int? balance;
  final PetRosterSnapshot? roster;
  final int price;
  final int shortfall;
  final GearInstance? item;
  final GearDef? def;
}

GearBuyPlan planGearBuy({
  required int balance,
  required PetRosterSnapshot roster,
  required List<PetKind> owned,
  required PetKind kind,
  required String defId,
}) {
  final def = GearCatalog.byId(defId);
  if (def == null) return const GearBuyPlan(status: GearBuyStatus.unknown);
  if (!owned.contains(kind)) {
    return GearBuyPlan(status: GearBuyStatus.notOwned, def: def);
  }
  if (PetCombatRules.roleOf(kind) != def.role) {
    return GearBuyPlan(status: GearBuyStatus.roleMismatch, def: def);
  }
  final ready = roster.ensureOwned(owned);
  final record = ready.recordOf(kind);
  if (record == null) {
    return GearBuyPlan(status: GearBuyStatus.notOwned, def: def);
  }
  if (record.level < def.minLevel) {
    return GearBuyPlan(
      status: GearBuyStatus.levelLocked,
      def: def,
      price: def.price,
    );
  }
  if (balance < def.price) {
    return GearBuyPlan(
      status: GearBuyStatus.insufficient,
      def: def,
      price: def.price,
      shortfall: def.price - balance,
    );
  }
  final seq = ready.seq + 1;
  final item = GearInstance(id: 'gear-$seq', defId: def.id);
  return GearBuyPlan(
    status: GearBuyStatus.bought,
    balance: balance - def.price,
    roster: ready.copyWith(items: [...ready.items, item], seq: seq),
    price: def.price,
    item: item,
    def: def,
  );
}

enum EquipStatus {
  equipped,
  unequipped,
  notOwned,
  missingItem,
  wornByOther,
  roleMismatch,
  slotMismatch,
  levelLocked,
  unavailable,
  failed,
}

class EquipResult {
  const EquipResult({
    required this.status,
    required this.balance,
    required this.seeds,
    required this.garden,
    required this.roster,
    this.wornBy,
  });

  final EquipStatus status;
  final int balance;
  final SeedSnapshot seeds;
  final GardenSnapshot garden;
  final PetRosterSnapshot roster;
  final PetKind? wornBy;

  bool get equipped => status == EquipStatus.equipped;
  bool get unequipped => status == EquipStatus.unequipped;

  const EquipResult.unavailable({
    required int balance,
    required SeedSnapshot seeds,
    required GardenSnapshot garden,
    required PetRosterSnapshot roster,
  }) : this(
         status: EquipStatus.unavailable,
         balance: balance,
         seeds: seeds,
         garden: garden,
         roster: roster,
       );

  const EquipResult.failed({
    required int balance,
    required SeedSnapshot seeds,
    required GardenSnapshot garden,
    required PetRosterSnapshot roster,
  }) : this(
         status: EquipStatus.failed,
         balance: balance,
         seeds: seeds,
         garden: garden,
         roster: roster,
       );
}

class EquipPlan {
  const EquipPlan({required this.status, this.roster, this.wornBy});

  final EquipStatus status;
  final PetRosterSnapshot? roster;
  final PetKind? wornBy;
}

EquipPlan planEquip({
  required PetRosterSnapshot roster,
  required List<PetKind> owned,
  required PetKind kind,
  required String itemId,
  required GearSlot slot,
}) {
  if (!owned.contains(kind)) {
    return const EquipPlan(status: EquipStatus.notOwned);
  }
  final ready = roster.ensureOwned(owned);
  final record = ready.recordOf(kind);
  final item = ready.itemOf(itemId);
  if (record == null) return const EquipPlan(status: EquipStatus.notOwned);
  if (item == null) return const EquipPlan(status: EquipStatus.missingItem);
  final def = GearCatalog.byId(item.defId);
  if (def == null) return const EquipPlan(status: EquipStatus.missingItem);
  if (def.role != PetCombatRules.roleOf(kind)) {
    return const EquipPlan(status: EquipStatus.roleMismatch);
  }
  if (def.slot != slot) {
    return const EquipPlan(status: EquipStatus.slotMismatch);
  }
  if (record.level < def.minLevel) {
    return const EquipPlan(status: EquipStatus.levelLocked);
  }
  final wearer = ready.wearerOf(itemId);
  if (wearer != null && wearer != kind) {
    return EquipPlan(status: EquipStatus.wornByOther, wornBy: wearer);
  }
  if (wearer == kind && record.itemIn(slot) == itemId) {
    return EquipPlan(status: EquipStatus.equipped, roster: ready);
  }
  final updated = switch (slot) {
    GearSlot.main => record.copyWith(
      mainItemId: itemId,
      clearAccessory: record.accessoryItemId == itemId,
    ),
    GearSlot.accessory => record.copyWith(
      accessoryItemId: itemId,
      clearMain: record.mainItemId == itemId,
    ),
  };
  return EquipPlan(
    status: EquipStatus.equipped,
    roster: ready.copyWith(
      records: [
        for (final item in ready.records)
          if (item.kind == kind) updated else item,
      ],
    ),
  );
}

EquipPlan planUnequip({
  required PetRosterSnapshot roster,
  required List<PetKind> owned,
  required PetKind kind,
  required GearSlot slot,
}) {
  if (!owned.contains(kind)) {
    return const EquipPlan(status: EquipStatus.notOwned);
  }
  final ready = roster.ensureOwned(owned);
  final record = ready.recordOf(kind);
  if (record == null) return const EquipPlan(status: EquipStatus.notOwned);
  if (record.itemIn(slot) == null) {
    return EquipPlan(status: EquipStatus.unequipped, roster: ready);
  }
  final updated = record.copyWith(
    clearMain: slot == GearSlot.main,
    clearAccessory: slot == GearSlot.accessory,
  );
  return EquipPlan(
    status: EquipStatus.unequipped,
    roster: ready.copyWith(
      records: [
        for (final item in ready.records)
          if (item.kind == kind) updated else item,
      ],
    ),
  );
}

enum AssignStatus {
  assigned,
  cleared,
  notOwned,
  wrongRole,
  unavailable,
  failed,
}

class AssignResult {
  const AssignResult({
    required this.status,
    required this.balance,
    required this.seeds,
    required this.garden,
    required this.roster,
  });

  final AssignStatus status;
  final int balance;
  final SeedSnapshot seeds;
  final GardenSnapshot garden;
  final PetRosterSnapshot roster;

  bool get saved =>
      status == AssignStatus.assigned || status == AssignStatus.cleared;

  const AssignResult.unavailable({
    required int balance,
    required SeedSnapshot seeds,
    required GardenSnapshot garden,
    required PetRosterSnapshot roster,
  }) : this(
         status: AssignStatus.unavailable,
         balance: balance,
         seeds: seeds,
         garden: garden,
         roster: roster,
       );

  const AssignResult.failed({
    required int balance,
    required SeedSnapshot seeds,
    required GardenSnapshot garden,
    required PetRosterSnapshot roster,
  }) : this(
         status: AssignStatus.failed,
         balance: balance,
         seeds: seeds,
         garden: garden,
         roster: roster,
       );
}

class AssignPlan {
  const AssignPlan({required this.status, this.roster});

  final AssignStatus status;
  final PetRosterSnapshot? roster;
}

AssignPlan planAssign({
  required PetRosterSnapshot roster,
  required List<PetKind> owned,
  required PetKind kind,
  required bool active,
}) {
  if (!owned.contains(kind)) {
    return const AssignPlan(status: AssignStatus.notOwned);
  }
  final role = PetCombatRules.roleOf(kind);
  final ready = roster.ensureOwned(owned);
  if (active) {
    return AssignPlan(
      status: AssignStatus.assigned,
      roster: role == PetRole.defender
          ? ready.copyWith(defender: kind)
          : ready.copyWith(raider: kind),
    );
  }
  if (role == PetRole.defender && ready.defender == kind) {
    return AssignPlan(
      status: AssignStatus.cleared,
      roster: ready.copyWith(clearDefender: true),
    );
  }
  if (role == PetRole.attacker && ready.raider == kind) {
    return AssignPlan(
      status: AssignStatus.cleared,
      roster: ready.copyWith(clearRaider: true),
    );
  }
  return AssignPlan(status: AssignStatus.cleared, roster: ready);
}

PetKind? _kind(Object? raw) {
  if (raw is! String) return null;
  for (final kind in PetKind.values) {
    if (kind.name == raw) return kind;
  }
  return null;
}

PetKind? _kindOrNull(Object? raw) {
  if (raw == null) return null;
  return _kind(raw);
}
