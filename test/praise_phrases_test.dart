import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/l10n/praise_phrases.dart';

void main() {
  group('praiseClipAsset', () {
    test('maps phrase index to numbered clips', () {
      expect(praiseClipAsset('ru', 0), 'sfx/praise/ru_1.mp3');
      expect(praiseClipAsset('ru', 1), 'sfx/praise/ru_2.mp3');
      expect(praiseClipAsset('ru', 2), 'sfx/praise/ru_1.mp3');
    });

    test('unknown language falls back to English', () {
      expect(praiseClipAsset('de', 0), 'sfx/praise/en_1.mp3');
    });

    test('ru has two clips and en has eight', () {
      expect(praiseClipCount('ru'), 2);
      expect(praiseClipCount('en'), 8);
    });
  });

  group('FastMatchStreak', () {
    test('stays silent until the third match inside the window', () {
      final streak = FastMatchStreak();
      final t0 = DateTime.utc(2026, 8, 19, 0, 0, 0);

      expect(streak.registerMatch(now: t0, languageCode: 'en'), isNull);
      expect(
        streak.registerMatch(
          now: t0.add(const Duration(seconds: 1)),
          languageCode: 'en',
        ),
        isNull,
      );
      expect(
        streak.registerMatch(
          now: t0.add(const Duration(seconds: 2)),
          languageCode: 'en',
        ),
        'sfx/praise/en_1.mp3',
      );
    });

    test('cooldown blocks praise even if the streak continues', () {
      final streak = FastMatchStreak();
      final t0 = DateTime.utc(2026, 8, 19, 0, 0, 0);

      streak.registerMatch(now: t0, languageCode: 'ru');
      streak.registerMatch(
        now: t0.add(const Duration(milliseconds: 400)),
        languageCode: 'ru',
      );
      expect(
        streak.registerMatch(
          now: t0.add(const Duration(milliseconds: 800)),
          languageCode: 'ru',
        ),
        'sfx/praise/ru_1.mp3',
      );
      expect(
        streak.registerMatch(
          now: t0.add(const Duration(seconds: 1)),
          languageCode: 'ru',
        ),
        isNull,
      );
    });

    test('next burst after cooldown rotates to the next clip', () {
      final streak = FastMatchStreak();
      final t0 = DateTime.utc(2026, 8, 19, 0, 0, 0);

      streak.registerMatch(now: t0, languageCode: 'ru');
      streak.registerMatch(
        now: t0.add(const Duration(seconds: 1)),
        languageCode: 'ru',
      );
      streak.registerMatch(
        now: t0.add(const Duration(seconds: 2)),
        languageCode: 'ru',
      );

      final t1 = t0.add(const Duration(seconds: 13));
      expect(streak.registerMatch(now: t1, languageCode: 'ru'), isNull);
      expect(
        streak.registerMatch(
          now: t1.add(const Duration(seconds: 1)),
          languageCode: 'ru',
        ),
        isNull,
      );
      expect(
        streak.registerMatch(
          now: t1.add(const Duration(seconds: 2)),
          languageCode: 'ru',
        ),
        'sfx/praise/ru_2.mp3',
      );
    });

    test('second burst wraps back to the first clip', () {
      final streak = FastMatchStreak();
      var t = DateTime.utc(2026, 8, 19, 0, 0, 0);
      String? last;
      for (var i = 0; i < 2; i++) {
        streak.registerMatch(now: t, languageCode: 'ru');
        streak.registerMatch(
          now: t.add(const Duration(seconds: 1)),
          languageCode: 'ru',
        );
        last = streak.registerMatch(
          now: t.add(const Duration(seconds: 2)),
          languageCode: 'ru',
        );
        t = t.add(const Duration(seconds: 13));
      }
      expect(last, 'sfx/praise/ru_2.mp3');

      streak.registerMatch(now: t, languageCode: 'ru');
      streak.registerMatch(
        now: t.add(const Duration(seconds: 1)),
        languageCode: 'ru',
      );
      expect(
        streak.registerMatch(
          now: t.add(const Duration(seconds: 2)),
          languageCode: 'ru',
        ),
        'sfx/praise/ru_1.mp3',
      );
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
