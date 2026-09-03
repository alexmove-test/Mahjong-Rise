import 'package:flutter/foundation.dart';

import '../models/leaderboard_entry.dart';
import '../models/levels.dart';
import 'guest_name.dart';
import 'player_profile_store.dart';
import 'progress_store.dart';

/// Результат загрузки одной таблицы. [online] ложный, если сеть/правила отказали.
class LeaderboardFetch {
  const LeaderboardFetch({required this.entries, required this.online});

  final List<LeaderboardEntry> entries;
  final bool online;

  /// Одна упавшая таблица не должна гасить другую.
  static Future<LeaderboardFetch> guard({
    required Future<List<LeaderboardEntry>> Function() load,
    required List<LeaderboardEntry> Function() fallback,
  }) async {
    try {
      return LeaderboardFetch(entries: await load(), online: true);
    } catch (error) {
      debugPrint('Leaderboard fetch failed: $error');
      return LeaderboardFetch(entries: fallback(), online: false);
    }
  }
}

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
        name: GuestName.clamp(profile.displayName),
        rating: ratingFor(progress),
        totalStars: progress.totalStars,
        levelsUnlocked: progress.maxUnlocked,
        isCurrentPlayer: true,
      ),
    ];
  }

  /// Сколько участков открыто при данном прогрессе кампании.
  static int plotsOpened(int levelsUnlocked) =>
      Levels.cycleOf(levelsUnlocked) + 1;

  /// Соседи вокруг текущего игрока в уже отсортированной таблице.
  static List<LeaderboardEntry> nearbyOthers(
    List<LeaderboardEntry> entries, {
    int count = 4,
  }) {
    if (count <= 0) return const [];
    final me = entries.indexWhere((entry) => entry.isCurrentPlayer);
    if (me < 0) {
      return entries
          .where((entry) => !entry.isCurrentPlayer)
          .take(count)
          .toList();
    }

    final picked = <LeaderboardEntry>[];
    for (var radius = 1; picked.length < count; radius++) {
      final above = me - radius;
      final below = me + radius;
      if (above < 0 && below >= entries.length) break;
      if (above >= 0) picked.add(entries[above]);
      if (picked.length >= count) break;
      if (below < entries.length) picked.add(entries[below]);
    }
    return picked;
  }

  static int? rankOf(List<LeaderboardEntry> entries) {
    final index = entries.indexWhere((e) => e.isCurrentPlayer);
    if (index < 0) return null;
    return index + 1;
  }
}
