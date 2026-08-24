import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/leaderboard_entry.dart';
import 'package:mahjong/services/leaderboard_service.dart';
import 'package:mahjong/services/player_profile_store.dart';
import 'package:mahjong/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    expect(LeaderboardService.plotsOpened(progress.maxUnlocked), 1);
    expect(profile.hasCustomName, isFalse);
    expect(entries.single.name, profile.displayName);
    expect(entries.single.name, isNot(anyOf('You', 'Вы', '')));
  });

  test('one extra star outranks a huge best-score gap', () {
    final withMoreStars = LeaderboardService.ratingFrom(
      totalStars: 10,
      sumBestScores: 0,
      levelsUnlocked: 4,
    );
    final withMoreScore = LeaderboardService.ratingFrom(
      totalStars: 9,
      sumBestScores: 99999,
      levelsUnlocked: 4,
    );
    expect(withMoreStars, greaterThan(withMoreScore));
  });

  test('full campaign rating matches rules and fits Firestore caps', () {
    const totalStars = 720;
    const levelsUnlocked = 240;
    const sumBestScores = 20000000;
    final rating = LeaderboardService.ratingFrom(
      totalStars: totalStars,
      sumBestScores: sumBestScores,
      levelsUnlocked: levelsUnlocked,
    );

    expect(
      rating,
      totalStars * LeaderboardService.starWeight +
          sumBestScores +
          levelsUnlocked * LeaderboardService.unlockWeight,
    );
    expect(totalStars, lessThanOrEqualTo(720));
    expect(levelsUnlocked, lessThanOrEqualTo(240));
    expect(sumBestScores, lessThanOrEqualTo(20000000));
    expect(rating, lessThanOrEqualTo(100000000));
  });

  test('rankOf is 1-based and skips missing current player', () {
    const other = LeaderboardEntry(
      id: 'a',
      name: 'A',
      rating: 200,
      totalStars: 2,
      levelsUnlocked: 2,
      isCurrentPlayer: false,
    );
    const me = LeaderboardEntry(
      id: 'me',
      name: 'Me',
      rating: 100,
      totalStars: 1,
      levelsUnlocked: 1,
      isCurrentPlayer: true,
    );

    expect(LeaderboardService.rankOf([other, me]), 2);
    expect(LeaderboardService.rankOf([other]), isNull);
  });

  test('plotsOpened counts unlocked courtyard plots', () {
    expect(LeaderboardService.plotsOpened(1), 1);
    expect(LeaderboardService.plotsOpened(24), 1);
    expect(LeaderboardService.plotsOpened(25), 2);
    expect(LeaderboardService.plotsOpened(240), 10);
  });
}
