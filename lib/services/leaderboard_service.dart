import '../models/leaderboard_entry.dart';
import '../models/levels.dart';
import 'player_profile_store.dart';
import 'progress_store.dart';

/// Расчёт рейтинга кампании.
class LeaderboardService {
  const LeaderboardService._();

  static const currentPlayerId = 'local-player';

  /// Вес одной звезды. Держит звёзды главным критерием таблицы.
  static const starWeight = 100000;

  /// Вес открытого уровня — слабый тай-брейк после счёта.
  static const unlockWeight = 500;

  /// Сводный рейтинг: звёзды, лучшие счёта и прогресс кампании.
  static int ratingFor(ProgressStore progress) {
    return ratingFrom(
      totalStars: progress.totalStars,
      sumBestScores: progress.sumBestScores,
      levelsUnlocked: progress.maxUnlocked,
    );
  }

  /// Та же формула, что в `firestore.rules`.
  static int ratingFrom({
    required int totalStars,
    required int sumBestScores,
    required int levelsUnlocked,
  }) {
    return totalStars * starWeight +
        sumBestScores +
        levelsUnlocked * unlockWeight;
  }

  /// Локальный fallback, если Firebase недоступен.
  static List<LeaderboardEntry> buildLocal({
    required ProgressStore progress,
    required PlayerProfileStore profile,
  }) {
    return [
      LeaderboardEntry(
        id: currentPlayerId,
        name: profile.displayName,
        rating: ratingFor(progress),
        totalStars: progress.totalStars,
        levelsUnlocked: progress.maxUnlocked,
        isCurrentPlayer: true,
      ),
    ];
  }

  /// Сколько участков открыто при данном прогрессе кампании (1–10).
  static int plotsOpened(int levelsUnlocked) =>
      Levels.cycleOf(levelsUnlocked) + 1;

  static int? rankOf(List<LeaderboardEntry> entries) {
    final index = entries.indexWhere((e) => e.isCurrentPlayer);
    if (index < 0) return null;
    return index + 1;
  }
}
