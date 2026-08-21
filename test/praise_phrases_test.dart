import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/l10n/praise_phrases.dart';

void main() {
  group('praiseClipAsset', () {
    test('maps phrase index to numbered clips', () {
      expect(praiseClipAsset('ru', 0), 'sfx/praise/ru_1.mp3');
      expect(praiseClipAsset('ru', 1), 'sfx/praise/ru_2.mp3');
      expect(praiseClipAsset('ru', 3), 'sfx/praise/ru_4.mp3');
      expect(praiseClipAsset('ru', 4), 'sfx/praise/ru_1.mp3');
    });

    test('unknown language falls back to English', () {
      expect(praiseClipAsset('de', 0), 'sfx/praise/en_1.mp3');
    });
  });

  group('FastMatchStreak', () {
    test('stays silent until the second match inside the window', () {
      final streak = FastMatchStreak(random: Random(1));
      final t0 = DateTime.utc(2026, 8, 19, 0, 0, 0);

      expect(streak.registerMatch(now: t0, languageCode: 'en'), isNull);
      final asset = streak.registerMatch(
        now: t0.add(const Duration(seconds: 1)),
        languageCode: 'en',
      );
      expect(asset, isNotNull);
      expect(asset, startsWith('sfx/praise/en_'));
    });

    test('cooldown blocks praise even if the streak continues', () {
      final streak = FastMatchStreak(random: Random(1));
      final t0 = DateTime.utc(2026, 8, 19, 0, 0, 0);

      expect(streak.registerMatch(now: t0, languageCode: 'ru'), isNull);
      expect(
        streak.registerMatch(
          now: t0.add(const Duration(milliseconds: 400)),
          languageCode: 'ru',
        ),
        isNotNull,
      );
      expect(
        streak.registerMatch(
          now: t0.add(const Duration(milliseconds: 800)),
          languageCode: 'ru',
        ),
        isNull,
      );
    });

    test('next burst after cooldown plays another clip', () {
      final streak = FastMatchStreak(random: Random(1));
      final t0 = DateTime.utc(2026, 8, 19, 0, 0, 0);

      streak.registerMatch(now: t0, languageCode: 'ru');
      final first = streak.registerMatch(
        now: t0.add(const Duration(seconds: 1)),
        languageCode: 'ru',
      );
      expect(first, isNotNull);

      final t1 = t0.add(const Duration(seconds: 13));
      expect(streak.registerMatch(now: t1, languageCode: 'ru'), isNull);
      final second = streak.registerMatch(
        now: t1.add(const Duration(seconds: 1)),
        languageCode: 'ru',
      );
      expect(second, isNotNull);
      expect(second, startsWith('sfx/praise/ru_'));
    });

    test('window break starts a new silent burst', () {
      final streak = FastMatchStreak();
      final t0 = DateTime.utc(2026, 8, 19, 0, 0, 0);

      streak.registerMatch(now: t0, languageCode: 'en');
      expect(
        streak.registerMatch(
          now: t0.add(const Duration(seconds: 5)),
          languageCode: 'en',
        ),
        isNull,
      );
    });

    test('reset clears the burst but keeps cooldown', () {
      final streak = FastMatchStreak();
      final t0 = DateTime.utc(2026, 8, 19, 0, 0, 0);
      streak.registerMatch(now: t0, languageCode: 'en');
      streak.registerMatch(
        now: t0.add(const Duration(milliseconds: 400)),
        languageCode: 'en',
      );
      streak.registerMatch(
        now: t0.add(const Duration(milliseconds: 800)),
        languageCode: 'en',
      );
      streak.reset();

      expect(
        streak.registerMatch(
          now: t0.add(const Duration(seconds: 1)),
          languageCode: 'en',
        ),
        isNull,
      );
      streak.registerMatch(
        now: t0.add(const Duration(milliseconds: 1400)),
        languageCode: 'en',
      );
      expect(
        streak.registerMatch(
          now: t0.add(const Duration(milliseconds: 1800)),
          languageCode: 'en',
        ),
        isNull,
      );
    });
  });
}
