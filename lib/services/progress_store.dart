import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_snapshot.dart';
import '../models/levels.dart';

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

  /// Последний открытый/игранный уровень (для «Продолжить»).
  int get lastPlayedLevel {
    final v = _prefs.getInt(_kLastPlayed) ?? 1;
    return v.clamp(1, maxUnlocked);
  }

  Future<void> markPlayed(int levelId) async {
    final id = levelId.clamp(1, Levels.all.length);
    await _prefs.setInt(_kLastPlayed, id);
  }

  bool get tableCoachDone => _prefs.getBool(_kTableCoachDone) ?? false;

  Future<void> markTableCoachDone() => _prefs.setBool(_kTableCoachDone, true);

  GameSnapshot? get savedSnapshot {
    final raw = _prefs.getString(_kSnapshot);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return GameSnapshot.fromJson(Map<String, Object?>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  bool hasSnapshotFor(int levelId) => savedSnapshot?.levelId == levelId;

  Future<void> saveSnapshot(GameSnapshot snapshot) async {
    await _prefs.setString(_kSnapshot, jsonEncode(snapshot.toJson()));
  }

  Future<void> clearSnapshot() async {
    await _prefs.remove(_kSnapshot);
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

  /// Записать победу: звёзды, лучший счёт, разблокировка следующего.
  Future<({int stars, bool unlockedNext, bool isNewBest})> recordWin({
    required LevelDef level,
    required int score,
  }) async {
    final earned = level.starsForScore(score);
    final prevStars = stars(level.id);
    final prevBest = bestScore(level.id);
    final isNewBest = score > prevBest;

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

    await markPlayed(level.id);
    await clearSnapshot();

    return (
      stars: earned > prevStars ? earned : prevStars,
      unlockedNext: unlockedNext,
      isNewBest: isNewBest,
    );
  }
}
