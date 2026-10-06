import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/leaderboard_entry.dart';
import 'package:mahjong/services/display_name_filter.dart';
import 'package:mahjong/services/leaderboard_service.dart';
import 'package:mahjong/services/ugc_block_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('allows ordinary nicknames', () {
    expect(DisplayNameFilter.isAllowed('Jade Koi 12'), isTrue);
    expect(DisplayNameFilter.isAllowed('Mila'), isTrue);
    expect(DisplayNameFilter.isAllowed('Classic'), isTrue);
    expect(DisplayNameFilter.isAllowed('Тихий Карп 10'), isTrue);
  });

  test('rejects obvious slurs and leetspeak', () {
    expect(DisplayNameFilter.isAllowed('fuck'), isFalse);
    expect(DisplayNameFilter.isAllowed('f u c k'), isFalse);
    expect(DisplayNameFilter.isAllowed('хуйня'), isFalse);
    expect(DisplayNameFilter.publicName('shithead'), 'Player');
  });

  test('moderate hides blocked players and sanitizes names', () {
    const me = LeaderboardEntry(
      id: 'me',
      name: 'Me',
      rating: 2,
      totalStars: 1,
      levelsUnlocked: 1,
      isCurrentPlayer: true,
    );
    const rude = LeaderboardEntry(
      id: 'x',
      name: 'fuck',
      rating: 3,
      totalStars: 1,
      levelsUnlocked: 1,
      isCurrentPlayer: false,
    );
    const other = LeaderboardEntry(
      id: 'y',
      name: 'Ren',
      rating: 1,
      totalStars: 1,
      levelsUnlocked: 1,
      isCurrentPlayer: false,
    );

    final visible = LeaderboardService.moderate(
      [rude, me, other],
      blockedIds: {'y'},
    );
    expect(visible.map((e) => e.id).toList(), ['x', 'me']);
    expect(visible.first.name, 'Player');
  });

  test('block store remembers hidden players', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await UgcBlockStore.open();
    expect(store.isBlocked('abc'), isFalse);
    await store.block('abc');
    expect(store.isBlocked('abc'), isTrue);
    final again = await UgcBlockStore.open();
    expect(again.isBlocked('abc'), isTrue);
  });
}
