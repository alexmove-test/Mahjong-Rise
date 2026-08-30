import 'package:shared_preferences/shared_preferences.dart';

import '../models/pet.dart';

/// Двор питомцев: список заведённых и timestamp сытости у каждого.
class PetStore {
  PetStore._(this._prefs);

  final SharedPreferences? _prefs;

  static const _kOwned = 'pet.owned';
  static const _kKind = 'pet.kind';
  static const _kHungerAt = 'pet.hungerAt';
  static const _kPlayAt = 'pet.playAt';
  static const _kRestAt = 'pet.restAt';
  static const _kRemindersPrompted = 'pet.remindersPrompted';

  static PetStore memory() => PetStore._(null);

  static Future<PetStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return PetStore._(prefs);
  }

  List<PetKind> get owned {
    final raw = _prefs?.getString(_kOwned);
    if (raw != null && raw.isNotEmpty) {
      return [
        for (final part in raw.split(','))
          if (_parseKind(part.trim()) case final kind?) kind,
      ];
    }
    final legacy = _parseKind(_prefs?.getString(_kKind));
    return legacy == null ? const [] : [legacy];
  }

  bool owns(PetKind kind) => owned.contains(kind);

  bool get hasPet => owned.isNotEmpty;

  bool get canAdoptMore => owned.length < PetKind.values.length;

  /// Первый заведённый; для экранов, которым нужен «главный» питомец.
  PetKind? get kind {
    final list = owned;
    return list.isEmpty ? null : list.first;
  }

  bool get remindersPrompted =>
      _prefs?.getBool(_kRemindersPrompted) ?? false;

  bool anyAsking({DateTime? now}) =>
      allCare(now: now).any((care) => care.asking);

  DateTime? lastSatisfied(PetNeed need, {PetKind? kind}) {
    final selected = kind ?? this.kind;
    if (selected == null) return null;
    final millis = _prefs?.getInt(_keyFor(selected, need));
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    final legacy = _prefs?.getInt(_legacyKeyFor(need));
    if (legacy == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(legacy);
  }

  /// Питомец с самым старым timestamp этой потребности — ему раньше всех плохо.
  ({PetKind kind, DateTime last})? soonestClock(PetNeed need) {
    ({PetKind kind, DateTime last})? best;
    for (final kind in owned) {
      final last = lastSatisfied(need, kind: kind);
      if (last == null) continue;
      if (best == null || last.isBefore(best.last)) {
        best = (kind: kind, last: last);
      }
    }
    return best;
  }

  PetCare? care({PetKind? kind, DateTime? now}) {
    final selected = kind ?? this.kind;
    if (selected == null) return null;
    final at = now ?? DateTime.now();
    return PetCare(
      kind: selected,
      fullness: {
        for (final need in PetNeed.values)
          need: PetNeeds.fullness(
            lastSatisfied: lastSatisfied(need, kind: selected) ?? at,
            need: need,
            now: at,
          ),
      },
    );
  }

  List<PetCare> allCare({DateTime? now}) {
    final at = now ?? DateTime.now();
    return [
      for (final kind in owned)
        if (care(kind: kind, now: at) case final snapshot?) snapshot,
    ];
  }

  PetCare? mostUrgentCare({DateTime? now}) {
    PetCare? chosen;
    for (final snapshot in allCare(now: now)) {
      if (chosen == null || snapshot.lowest < chosen.lowest) {
        chosen = snapshot;
      }
    }
    return chosen;
  }

  Future<void> adopt(PetKind next, {DateTime? now}) async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (owns(next) || !canAdoptMore) return;
    final at = now ?? DateTime.now();
    final nextOwned = [...owned, next];
    await prefs.setString(
      _kOwned,
      nextOwned.map((kind) => kind.name).join(','),
    );
    await prefs.setString(_kKind, next.name);
    final millis = at.millisecondsSinceEpoch;
    await prefs.setInt(_keyFor(next, PetNeed.hunger), millis);
    await prefs.setInt(_keyFor(next, PetNeed.play), millis);
    await prefs.setInt(_keyFor(next, PetNeed.rest), millis);
  }

  Future<void> markRemindersPrompted() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_kRemindersPrompted, true);
  }

  /// Заполняет самую пустую потребность самого нуждающегося питомца.
  Future<PetFill?> satisfyMostUrgent({DateTime? now}) async {
    final prefs = _prefs;
    if (prefs == null || !hasPet) return null;
    final at = now ?? DateTime.now();
    final snapshot = mostUrgentCare(now: at);
    if (snapshot == null) return null;
    final need = snapshot.mostUrgent;
    await prefs.setInt(
      _keyFor(snapshot.kind, need),
      at.millisecondsSinceEpoch,
    );
    return PetFill(kind: snapshot.kind, need: need);
  }

  static PetKind? _parseKind(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final value in PetKind.values) {
      if (value.name == raw) return value;
    }
    return null;
  }

  static String _keyFor(PetKind kind, PetNeed need) =>
      'pet.${kind.name}.${need.name}At';

  static String _legacyKeyFor(PetNeed need) => switch (need) {
    PetNeed.hunger => _kHungerAt,
    PetNeed.play => _kPlayAt,
    PetNeed.rest => _kRestAt,
  };
}
