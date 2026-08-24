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
    expect(en.storyTitle(1), 'Sprout');
    expect(ru.storyTitle(1), 'Росток');
    expect(en.plot(0), 'Plot 1');
    expect(ru.plot(0), 'Участок 1');
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
    expect(en.reminders, 'Daily reminders');
    expect(ru.reminders, 'Напоминания');
    expect(en.builtAt('22.08.2026 17:27'), 'Built: 22.08.2026 17:27');
    expect(ru.builtAt('22.08.2026 17:27'), 'Сборка: 22.08.2026 17:27');
  });
}
