import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/l10n/l10n.dart';
import 'package:mahjong/services/locale_store.dart';

void main() {
  test('system follows Russian only for ru device language', () {
    expect(LocaleStore.resolve(LanguagePref.system, 'ru'), 'ru');
    expect(LocaleStore.resolve(LanguagePref.system, 'en'), 'en');
    expect(LocaleStore.resolve(LanguagePref.system, 'de'), 'en');
    expect(LocaleStore.resolve(LanguagePref.ru, 'en'), 'ru');
    expect(LocaleStore.resolve(LanguagePref.en, 'ru'), 'en');
  });

  test('L10n switches courtyard and menu labels', () {
    const en = L10n('en');
    const ru = L10n('ru');
    expect(en.courtyard, 'Courtyard');
    expect(ru.courtyard, 'Во двор');
    expect(en.anotherLevelCleared, 'Another level cleared');
    expect(ru.anotherLevelCleared, 'Ещё один уровень пройден');
    expect(en.settings, 'Settings');
    expect(ru.settings, 'Настройки');
    expect(en.levels, 'Levels');
    expect(ru.levels, 'Уровни');
    expect(en.hapticFeedback, 'Haptic feedback');
    expect(ru.hapticFeedback, 'Тактильный отклик');
    expect(en.sound, 'Sound');
    expect(ru.sound, 'Звук');
    expect(en.plot(0), 'House');
    expect(ru.plot(0), 'Дом');
    expect(en.plot(1), 'Pond');
    expect(ru.plot(1), 'Ставок');
    expect(en.pet, 'Pet');
    expect(ru.pet, 'Питомец');
    expect(en.scorePlotsLegend, 'Score : plots');
    expect(ru.scorePlotsLegend, 'Баллы : участки');
    expect(en.thisWeek, 'This week');
    expect(ru.thisWeek, 'Эта неделя');
    expect(en.claim, 'Claim');
    expect(ru.claim, 'Забрать');
    expect(en.weekEventTitle('garden'), 'Garden week');
    expect(ru.weekEventTitle('garden'), 'Неделя сада');
    expect(en.questTitle('stars8'), 'Earn 8 stars');
    expect(ru.questTitle('stars8'), 'Наберите 8 звёзд');
    expect(en.questTitle('streak3'), 'Keep three nights lit');
    expect(ru.questTitle('streak3'), 'Три вечера света');
    expect(en.streakKept, 'Three nights kept');
    expect(ru.streakKept, 'Серия сохранена');
    expect(en.streakNights(2), 'Day 2 of 3');
    expect(ru.streakNights(2), 'День 2 из 3');
    expect(
      en.dailyStreakSubtitle(streak: 2, completedToday: false),
      'Goes out at midnight',
    );
    expect(
      ru.dailyStreakSubtitle(streak: 2, completedToday: false),
      'Сгорит в полночь',
    );
    expect(en.streakWinSubtitle(3), 'Three nights kept');
    expect(ru.streakWinSubtitle(1), 'День 1 из 3');
    expect(en.reminders, 'Daily reminders');
    expect(ru.reminders, 'Напоминания');
    expect(en.builtAt('22.08.2026 17:27'), 'Built: 22.08.2026 17:27');
    expect(ru.builtAt('22.08.2026 17:27'), 'Сборка: 22.08.2026 17:27');
  });
}
