import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_snapshot.dart';
import '../models/levels.dart';
import '../models/week_id.dart';
import '../models/weekly_score.dart';

/// Сохранённый прогресс кампании.
class ProgressStore {
  ProgressStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _kUnlocked = 'progress.maxUnlocked';
  static const _kLastPlayed = 'progress.lastPlayed';
  static const _kStarsPrefix = 'progress.stars.';
  static const _kBestPrefix = 'progress.best.';
  static const _kTableCoachDone = 'progress.tableCoachDone';
  static const _kSnapshot = 'progress.snapshot';
  static const _kSnapshotPrefix = 'progress.snapshot.';
  static const _kSnapshotActive = 'progress.snapshotActive';
  static const _kDailyDate = 'progress.dailyDate';
  static const _kDailyStreak = 'progress.dailyStreak';
  static const _kBankedHints = 'progress.bankedHints';
  static const _kBankedShuffles = 'progress.bankedShuffles';
  static const _kWeekId = 'progress.weekId';
  static const _kWeeklyStars = 'progress.weeklyStars';
  static const _kWeeklyClears = 'progress.weeklyClears';
  static const _kWeeklyDailies = 'progress.weeklyDailies';
  static const _kWeeklyLastRank = 'progress.weeklyLastRank';
  static const _kPrevWeekId = 'progress.prevWeekId';
  static const _kPrevWeekRating = 'progress.prevWeekRating';
  static const _kPrevWeekStars = 'progress.prevWeekStars';
  static const _kPrevWeekClears = 'progress.prevWeekClears';
  static const _kPrevWeekDailies = 'progress.prevWeekDailies';
  static const _kPrevWeekRank = 'progress.prevWeekRank';
  static const _kSeasonSheetPending = 'progress.seasonSheetPending';

  static Future<ProgressStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return ProgressStore._(prefs);
  }

  /// Максимальный открытый уровень (1-based). Минимум 1.
  int get maxUnlocked {
    final v = _prefs.getInt(_kUnlocked) ?? 1;
    return v.clamp(1, Levels.all.length);
  }

  bool isUnlocked(int levelId) => levelId <= maxUnlocked;

  int stars(int levelId) => _prefs.getInt('$_kStarsPrefix$levelId') ?? 0;

  int bestScore(int levelId) => _prefs.getInt('$_kBestPrefix$levelId') ?? 0;

  bool isCompleted(int levelId) => stars(levelId) > 0 || bestScore(levelId) > 0;

  /// Хоть один уровень закрыт — больше не первый запуск.
  bool get hasCompletedAny => maxUnlocked > 1 || isCompleted(1);

  /// Подсказки на столе уровня 1 уже прошли.
  bool get tableCoachDone => _prefs.getBool(_kTableCoachDone) ?? false;

  Future<void> markTableCoachDone() => _prefs.setBool(_kTableCoachDone, true);

  /// Незавершённая партия, к которой ведёт «Продолжить».
  GameSnapshot? get savedSnapshot {
    final active = _prefs.getInt(_kSnapshotActive);
    if (active != null) {
      final snap = snapshotFor(active);
      if (snap != null) return snap;
    }
    final last = snapshotFor(lastPlayedLevel);
    if (last != null) return last;
    final daily = snapshotFor(GameSnapshot.dailyLevelId);
    if (daily != null) return daily;
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith(_kSnapshotPrefix)) continue;
      final id = int.tryParse(key.substring(_kSnapshotPrefix.length));
      if (id == null) continue;
      final snap = snapshotFor(id);
      if (snap != null) return snap;
    }
    return _decode(_prefs.getString(_kSnapshot));
  }

  bool hasSnapshotFor(int levelId) => snapshotFor(levelId) != null;

  GameSnapshot? snapshotFor(int levelId) {
    final slotted = _decode(_prefs.getString('$_kSnapshotPrefix$levelId'));
    if (slotted != null) return slotted;
    final legacy = _decode(_prefs.getString(_kSnapshot));
    if (legacy?.levelId == levelId) return legacy;
    return null;
  }

  Future<void> saveSnapshot(GameSnapshot snapshot) async {
    await _prefs.setString(
      '$_kSnapshotPrefix${snapshot.levelId}',
      jsonEncode(snapshot.toJson()),
    );
    await _prefs.setInt(_kSnapshotActive, snapshot.levelId);
    await _prefs.remove(_kSnapshot);
  }

  /// Стереть слот [levelId]; без аргумента — текущий «Продолжить».
  Future<void> clearSnapshot([int? levelId]) async {
    final id = levelId ?? savedSnapshot?.levelId;
    if (id != null) {
      await _prefs.remove('$_kSnapshotPrefix$id');
      if (_prefs.getInt(_kSnapshotActive) == id) {
        await _prefs.remove(_kSnapshotActive);
      }
    }
    final legacy = _decode(_prefs.getString(_kSnapshot));
    if (legacy != null && (id == null || legacy.levelId == id)) {
      await _prefs.remove(_kSnapshot);
    }
  }

  GameSnapshot? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return GameSnapshot.fromJson(Map<String, Object?>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  String get lastDailyDate => _prefs.getString(_kDailyDate) ?? '';

  int get dailyStreak => _prefs.getInt(_kDailyStreak) ?? 0;

  int get bankedHints => _prefs.getInt(_kBankedHints) ?? 0;

  int get bankedShuffles => _prefs.getInt(_kBankedShuffles) ?? 0;

  bool isDailyCompletedOn(DateTime date) => lastDailyDate == dateKey(date);

  int visibleStreak([DateTime? now]) {
    final date = now ?? DateTime.now();
    final today = dateKey(date);
    final yesterday = dateKey(date.subtract(const Duration(days: 1)));
    if (lastDailyDate == today || lastDailyDate == yesterday) return dailyStreak;
    return 0;
  }

  Future<void> expireStreakIfNeeded([DateTime? now]) async {
    if (visibleStreak(now) > 0 || dailyStreak == 0) return;
    await _prefs.setInt(_kDailyStreak, 0);
  }

  /// Зачёт ежедневки. Повтор в тот же день серию не растит.
  Future<({int streak, bool counted, bool rewarded})> recordDailyWin({
    DateTime? now,
  }) async {
    final date = now ?? DateTime.now();
    await ensureWeek(date);
    final today = dateKey(date);
    if (lastDailyDate == today) {
      return (streak: dailyStreak, counted: false, rewarded: false);
    }

    final yesterday = dateKey(date.subtract(const Duration(days: 1)));
    final streak = lastDailyDate == yesterday ? dailyStreak + 1 : 1;
    final rewarded = streak == 3 || streak == 7;

    await _prefs.setString(_kDailyDate, today);
    await _prefs.setInt(_kDailyStreak, streak);
    if (rewarded) {
      await _prefs.setInt(_kBankedHints, bankedHints + 1);
      await _prefs.setInt(_kBankedShuffles, bankedShuffles + 1);
    }
    await _prefs.setInt(
      _kWeeklyDailies,
      (weeklyDailies + 1).clamp(0, WeeklyScore.maxDailies),
    );

    return (streak: streak, counted: true, rewarded: rewarded);
  }

  Future<({int hints, int shuffles})> consumeBankedBoosts() async {
    final hints = bankedHints;
    final shuffles = bankedShuffles;
    if (hints != 0) await _prefs.setInt(_kBankedHints, 0);
    if (shuffles != 0) await _prefs.setInt(_kBankedShuffles, 0);
    return (hints: hints, shuffles: shuffles);
  }

  Future<void> addBankedBoosts({int hints = 0, int shuffles = 0}) async {
    if (hints != 0) {
      await _prefs.setInt(_kBankedHints, bankedHints + hints);
    }
    if (shuffles != 0) {
      await _prefs.setInt(_kBankedShuffles, bankedShuffles + shuffles);
    }
  }

  String get weekId => _prefs.getString(_kWeekId) ?? '';

  int get weeklyStars => _prefs.getInt(_kWeeklyStars) ?? 0;

  int get weeklyClears => _prefs.getInt(_kWeeklyClears) ?? 0;

  int get weeklyDailies => _prefs.getInt(_kWeeklyDailies) ?? 0;

  int? get weeklyLastRank {
    final v = _prefs.getInt(_kWeeklyLastRank);
    if (v == null || v <= 0) return null;
    return v;
  }

  Future<void> setWeeklyLastRank(int rank) =>
      _prefs.setInt(_kWeeklyLastRank, rank);

  /// Сброс счётчиков при смене ISO-недели. Прошлую неделю с очками кладёт в шит.
  Future<void> ensureWeek([DateTime? now]) async {
    final current = WeekId.fromDate(now ?? DateTime.now()).value;
    if (weekId == current) return;

    if (weekId.isNotEmpty) {
      final rating = WeeklyScore.ratingFrom(
        weeklyStars: weeklyStars,
        weeklyClears: weeklyClears,
        weeklyDailies: weeklyDailies,
      );
      if (rating > 0) {
        await _prefs.setString(_kPrevWeekId, weekId);
        await _prefs.setInt(_kPrevWeekRating, rating);
        await _prefs.setInt(_kPrevWeekStars, weeklyStars);
        await _prefs.setInt(_kPrevWeekClears, weeklyClears);
        await _prefs.setInt(_kPrevWeekDailies, weeklyDailies);
        final rank = weeklyLastRank;
        if (rank != null) {
          await _prefs.setInt(_kPrevWeekRank, rank);
        } else {
          await _prefs.remove(_kPrevWeekRank);
        }
        await _prefs.setBool(_kSeasonSheetPending, true);
      }
    }

    await _prefs.setString(_kWeekId, current);
    await _prefs.setInt(_kWeeklyStars, 0);
    await _prefs.setInt(_kWeeklyClears, 0);
    await _prefs.setInt(_kWeeklyDailies, 0);
    await _prefs.remove(_kWeeklyLastRank);
  }

  WeekSeasonSummary? get pendingSeasonSummary {
    if (!(_prefs.getBool(_kSeasonSheetPending) ?? false)) return null;
    final id = _prefs.getString(_kPrevWeekId) ?? '';
    if (id.isEmpty) return null;
    final rank = _prefs.getInt(_kPrevWeekRank);
    return WeekSeasonSummary(
      weekId: id,
      rating: _prefs.getInt(_kPrevWeekRating) ?? 0,
      stars: _prefs.getInt(_kPrevWeekStars) ?? 0,
      clears: _prefs.getInt(_kPrevWeekClears) ?? 0,
      dailies: _prefs.getInt(_kPrevWeekDailies) ?? 0,
      rank: rank != null && rank > 0 ? rank : null,
    );
  }

  Future<WeekSeasonSummary?> consumeSeasonSheet() async {
    final summary = pendingSeasonSummary;
    if (summary == null) return null;
    await _prefs.setBool(_kSeasonSheetPending, false);
    return summary;
  }

  static String dateKey(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  /// Последний открытый/игранный уровень (для «Продолжить»).
  int get lastPlayedLevel {
    final v = _prefs.getInt(_kLastPlayed) ?? 1;
    return v.clamp(1, maxUnlocked);
  }

  Future<void> markPlayed(int levelId) async {
    final id = levelId.clamp(1, Levels.all.length);
    await _prefs.setInt(_kLastPlayed, id);
  }

  int get totalStars {
    var sum = 0;
    for (final level in Levels.all) {
      sum += stars(level.id);
    }
    return sum;
  }

  int get sumBestScores {
    var sum = 0;
    for (final level in Levels.all) {
      sum += bestScore(level.id);
    }
    return sum;
  }

  int starsInCycle(int cycle) {
    var sum = 0;
    for (final level in Levels.cycleLevels(cycle)) {
      sum += stars(level.id);
    }
    return sum;
  }

  /// Сколько уровней участка открыто (1–24).
  int unlockedInCycle(int cycle) {
    final start = Levels.cycleStartId(cycle);
    final end = Levels.cycleEndId(cycle);
    if (maxUnlocked < start) return 0;
    if (maxUnlocked > end) return Levels.storyLength;
    return maxUnlocked - start + 1;
  }

  bool isCycleComplete(int cycle) {
    final end = Levels.cycleEndId(cycle);
    return isCompleted(end) || maxUnlocked > end;
  }

  bool isCycleUnlocked(int cycle) {
    if (cycle <= 0) return true;
    return maxUnlocked >= Levels.cycleStartId(cycle);
  }

  /// Записать победу: звёзды, лучший счёт, разблокировка следующего.
  Future<
    ({
      int stars,
      int starsGained,
      int earnedStars,
      bool firstClear,
      bool unlockedNext,
      bool isNewBest,
    })
  >
  recordWin({required LevelDef level, required int score, DateTime? now}) async {
    await ensureWeek(now);
    final earned = level.starsForScore(score);
    final prevStars = stars(level.id);
    final prevBest = bestScore(level.id);
    final firstClear = prevStars == 0 && prevBest == 0;
    final isNewBest = score > prevBest;
    final starsGained = earned > prevStars ? earned - prevStars : 0;

    if (earned > prevStars) {
      await _prefs.setInt('$_kStarsPrefix${level.id}', earned);
    }
    if (isNewBest) {
      await _prefs.setInt('$_kBestPrefix${level.id}', score);
    }

    var unlockedNext = false;
    final nextId = level.id + 1;
    if (nextId <= Levels.all.length && nextId > maxUnlocked) {
      await _prefs.setInt(_kUnlocked, nextId);
      unlockedNext = true;
    }

    if (starsGained > 0) {
      await _prefs.setInt(
        _kWeeklyStars,
        (weeklyStars + starsGained).clamp(0, WeeklyScore.maxStars),
      );
    }
    if (firstClear) {
      await _prefs.setInt(
        _kWeeklyClears,
        (weeklyClears + 1).clamp(0, WeeklyScore.maxClears),
      );
    }

    await markPlayed(level.id);

    return (
      stars: earned > prevStars ? earned : prevStars,
      starsGained: starsGained,
      earnedStars: earned,
      firstClear: firstClear,
      unlockedNext: unlockedNext,
      isNewBest: isNewBest,
    );
  }
}
