import '../models/leaderboard_entry.dart';
import 'player_profile_store.dart';
import 'progress_store.dart';

/// Расчёт рейтинга кампании.
class LeaderboardService {
  const LeaderboardService._();

  static const currentPlayerId = 'local-player';

  /// Сводный рейтинг: звёзды, лучшие счёта и прогресс кампании.
  static int ratingFor(ProgressStore progress) {
    return progress.totalStars * 100000 +
        progress.sumBestScores +
        progress.maxUnlocked * 500;
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

  static int? rankOf(List<LeaderboardEntry> entries) {
    final index = entries.indexWhere((e) => e.isCurrentPlayer);
    if (index < 0) return null;
    return index + 1;
  }
}
