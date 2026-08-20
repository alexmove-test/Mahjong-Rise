import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/leaderboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mahjong/services/player_profile_store.dart';
import 'package:mahjong/services/progress_store.dart';

void main() {
  test('rating grows with stars and best scores', () async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 3,
      'progress.stars.1': 3,
      'progress.best.1': 900,
      'progress.stars.2': 2,
      'progress.best.2': 600,
    });

    final progress = await ProgressStore.open();
    final profile = await PlayerProfileStore.open();

    expect(progress.totalStars, 5);
    expect(progress.sumBestScores, 1500);
    expect(LeaderboardService.ratingFor(progress), 5 * 100000 + 1500 + 3 * 500);

    final entries = LeaderboardService.buildLocal(
      progress: progress,
      profile: profile,
    );
    expect(entries.any((e) => e.isCurrentPlayer), isTrue);
    expect(LeaderboardService.rankOf(entries), 1);
  });
}
