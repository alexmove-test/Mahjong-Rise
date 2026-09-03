import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/week_id.dart';
import '../models/weekly_quests.dart';
import 'progress_store.dart';

/// Локальный прогресс трёх квестов текущей недели.
class QuestStore {
  QuestStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _kWeekId = 'quests.weekId';
  static const _kProgressPrefix = 'quests.progress.';
  static const _kClaimed = 'quests.claimed';

  static Future<QuestStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    final store = QuestStore._(prefs);
    await store.ensureWeek();
    return store;
  }

  String get weekId => _prefs.getString(_kWeekId) ?? '';

  Set<String> get _claimed {
    final raw = _prefs.getStringList(_kClaimed) ?? const [];
    return raw.toSet();
  }

  int get claimedCount => _claimed.length;

  List<QuestDef> get defs {
    final id = weekId.isEmpty ? WeekId.fromDate(DateTime.now()) : WeekId(weekId);
    return WeeklyQuests.forWeek(id);
  }

  List<QuestProgress> get quests {
    final claimed = _claimed;
    return [
      for (final def in defs)
        QuestProgress(
          def: def,
          current: _prefs.getInt('$_kProgressPrefix${def.id}') ?? 0,
          claimed: claimed.contains(def.id),
        ),
    ];
  }

  Future<void> ensureWeek([DateTime? now]) async {
    final current = WeekId.fromDate(now ?? DateTime.now()).value;
    if (weekId == current) return;
    await _reset(current);
  }

  Future<void> _reset(String week) async {
    for (final key in _prefs.getKeys()) {
      if (key.startsWith(_kProgressPrefix)) {
        await _prefs.remove(key);
      }
    }
    await _prefs.remove(_kClaimed);
    await _prefs.setString(_kWeekId, week);
  }

  Future<void> creditCampaignWin({
    required int starsGained,
    required bool firstClear,
    required bool threeStar,
  }) async {
    await ensureWeek();
    if (starsGained > 0) {
      await _add(QuestKind.stars, starsGained);
    }
    if (firstClear) {
      await _add(QuestKind.campaignClears, 1);
    }
    if (threeStar) {
      await _add(QuestKind.threeStar, 1);
    }
  }

  Future<void> creditDailyWin({required int streak, DateTime? now}) async {
    await ensureWeek(now);
    await _add(QuestKind.dailyWins, 1);
    await _setAtLeast(QuestKind.streakHold, streak);
  }

  Future<bool> claim(String questId, ProgressStore progress) async {
    await ensureWeek();
    final quest = quests.where((q) => q.def.id == questId).firstOrNull;
    if (quest == null || !quest.canClaim) return false;
    final next = {..._claimed, questId};
    await _prefs.setStringList(_kClaimed, next.toList());
    await progress.addBankedBoosts(hints: 1, shuffles: 1);
    return true;
  }

  Future<void> _add(QuestKind kind, int amount) async {
    for (final def in defs) {
      if (def.kind != kind) continue;
      if (_claimed.contains(def.id)) continue;
      final key = '$_kProgressPrefix${def.id}';
      final current = _prefs.getInt(key) ?? 0;
      await _prefs.setInt(key, min(def.target, current + amount));
    }
  }

  Future<void> _setAtLeast(QuestKind kind, int value) async {
    for (final def in defs) {
      if (def.kind != kind) continue;
      if (_claimed.contains(def.id)) continue;
      final key = '$_kProgressPrefix${def.id}';
      final current = _prefs.getInt(key) ?? 0;
      await _prefs.setInt(key, min(def.target, max(current, value)));
    }
  }
}
