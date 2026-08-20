import 'package:shared_preferences/shared_preferences.dart';

import '../models/levels.dart';

/// Сохранённый прогресс кампании.
class ProgressStore {
  ProgressStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _kUnlocked = 'progress.maxUnlocked';
  static const _kLastPlayed = 'progress.lastPlayed';
  static const _kStarsPrefix = 'progress.stars.';
  static const _kBestPrefix = 'progress.best.';

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

    return (
      stars: earned > prevStars ? earned : prevStars,
      unlockedNext: unlockedNext,
      isNewBest: isNewBest,
    );
  }
}
