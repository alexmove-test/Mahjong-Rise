import '../models/leaderboard_entry.dart';
import '../models/weekly_score.dart';
import 'guest_name.dart';
import 'player_profile_store.dart';
import 'progress_store.dart';

/// Локальный fallback недельного рейтинга.
abstract final class WeeklyLeaderboardService {
  WeeklyLeaderboardService._();

  static int ratingFor(ProgressStore progress) {
    return WeeklyScore.ratingFrom(
      weeklyStars: progress.weeklyStars,
      weeklyClears: progress.weeklyClears,
      weeklyDailies: progress.weeklyDailies,
    );
  }

  static List<LeaderboardEntry> buildLocal({
    required ProgressStore progress,
    required PlayerProfileStore profile,
  }) {
    return [
      LeaderboardEntry(
        id: 'local-player',
        name: GuestName.clamp(profile.displayName),
        rating: ratingFor(progress),
        totalStars: progress.weeklyStars,
        levelsUnlocked: progress.weeklyClears,
        weeklyDailies: progress.weeklyDailies,
        isCurrentPlayer: true,
      ),
    ];
  }
}
