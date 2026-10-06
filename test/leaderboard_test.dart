import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/leaderboard_entry.dart';
import 'package:mahjong/services/guest_name.dart';
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

  test('climb lists people the player just overtook', () {
    LeaderboardEntry row({
      required String id,
      required int rating,
      bool me = false,
    }) {
      return LeaderboardEntry(
        id: id,
        name: id,
        rating: rating,
        totalStars: rating,
        levelsUnlocked: rating,
        isCurrentPlayer: me,
      );
    }

    final entries = [
      row(id: 'a', rating: 500),
      row(id: 'b', rating: 400),
      row(id: 'c', rating: 300),
      row(id: 'd', rating: 200),
      row(id: 'me', rating: 450, me: true),
      row(id: 'e', rating: 100),
    ];

    final climb = LeaderboardService.climb(
      entries: entries,
      ratingFrom: 150,
      ratingTo: 450,
    );

    expect(climb, isNotNull);
    expect(climb!.rose, isTrue);
    expect(climb.rankFrom, 5);
    expect(climb.rankTo, 2);
    expect(climb.passed.map((e) => e.id).toList(), ['b', 'c', 'd']);
    expect(climb.stillAbove.map((e) => e.id).toList(), ['a']);
    expect(climb.below.map((e) => e.id).toList(), ['e']);
    expect(climb.displayRankFrom, 5);
  });

  test('climb keeps only the last steps of a long jump', () {
    LeaderboardEntry row({
      required String id,
      required int rating,
      bool me = false,
    }) {
      return LeaderboardEntry(
        id: id,
        name: id,
        rating: rating,
        totalStars: rating,
        levelsUnlocked: rating,
        isCurrentPlayer: me,
      );
    }

    final others = [
      for (var i = 0; i < 12; i++) row(id: 'p$i', rating: 1200 - i * 50),
    ];
    final climb = LeaderboardService.climb(
      entries: [
        ...others,
        row(id: 'me', rating: 1100, me: true),
      ],
      ratingFrom: 80,
      ratingTo: 1100,
    );

    expect(climb, isNotNull);
    expect(climb!.rankTo, 3);
    expect(climb.passed, hasLength(LeaderboardService.maxClimbSteps));
    expect(climb.passed.first.id, 'p2');
    expect(climb.stillAbove.map((e) => e.id).toList(), ['p0', 'p1']);
    expect(
      LeaderboardService.climb(
        entries: [others.first],
        ratingFrom: 1,
        ratingTo: 2,
      ),
      isNull,
    );
    expect(
      LeaderboardService.climb(
        entries: [row(id: 'me', rating: 10, me: true)],
        ratingFrom: 5,
        ratingTo: 10,
      ),
      isNull,
    );
  });

  test('nearbyOthers takes ranks around the current player', () {
    LeaderboardEntry row({
      required String id,
      required int rating,
      bool me = false,
    }) {
      return LeaderboardEntry(
        id: id,
        name: id,
        rating: rating,
        totalStars: rating,
        levelsUnlocked: rating,
        isCurrentPlayer: me,
      );
    }

    final top = [
      row(id: 'me', rating: 500, me: true),
      row(id: 'a', rating: 400),
      row(id: 'b', rating: 300),
      row(id: 'c', rating: 200),
      row(id: 'd', rating: 100),
    ];
    expect(LeaderboardService.nearbyOthers(top).map((e) => e.id).toList(), [
      'a',
      'b',
      'c',
      'd',
    ]);

    final mid = [
      row(id: 'a', rating: 500),
      row(id: 'b', rating: 400),
      row(id: 'me', rating: 300, me: true),
      row(id: 'c', rating: 200),
      row(id: 'd', rating: 100),
    ];
    expect(LeaderboardService.nearbyOthers(mid).map((e) => e.id).toList(), [
      'b',
      'c',
      'a',
      'd',
    ]);

    final last = [
      row(id: 'a', rating: 400),
      row(id: 'b', rating: 300),
      row(id: 'c', rating: 200),
      row(id: 'me', rating: 100, me: true),
    ];
    expect(LeaderboardService.nearbyOthers(last).map((e) => e.id).toList(), [
      'c',
      'b',
      'a',
    ]);
  });

  test('a failed fetch keeps the local fallback', () async {
    const me = LeaderboardEntry(
      id: 'me',
      name: 'Me',
      rating: 100,
      totalStars: 1,
      levelsUnlocked: 1,
      isCurrentPlayer: true,
    );

    final all = await LeaderboardFetch.guard(
      load: () async => [me],
      fallback: () => const [],
    );
    final down = await LeaderboardFetch.guard(
      load: () async => throw Exception('permission-denied'),
      fallback: () => const [me],
    );

    expect(all.online, isTrue);
    expect(all.entries, [me]);
    expect(down.online, isFalse);
    expect(down.entries, [me]);
  });

  test('ranking names stay within Firestore limit', () {
    expect(GuestName.clamp('  Jade Koi 12  '), 'Jade Koi 12');
    expect(GuestName.clamp(''), 'Player');
    expect(GuestName.clamp('   '), 'Player');
    final long = 'A' * 40;
    expect(GuestName.clamp(long).length, GuestName.maxLength);
    expect(GuestName.clamp(long), 'A' * GuestName.maxLength);
    expect(GuestName.clamp('Золотой Дракон 12').length, lessThanOrEqualTo(20));
    expect(
      utf8.encode(GuestName.clamp('Золотой Дракон 12')).length,
      lessThanOrEqualTo(GuestName.maxLength),
    );
    for (var i = 0; i < 40; i++) {
      final name = GuestName.generate(isRu: true, random: Random(i));
      expect(name.length, lessThanOrEqualTo(GuestName.maxLength));
      expect(utf8.encode(name).length, lessThanOrEqualTo(GuestName.maxLength));
    }
  });
}
