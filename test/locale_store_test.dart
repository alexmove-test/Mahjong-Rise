import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/l10n/l10n.dart';
import 'package:mahjong/models/pet.dart';
import 'package:mahjong/models/plot_kind.dart';
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
    expect(en.qMode, 'Q mode');
    expect(ru.qMode, 'Режим Q');
    expect(en.qModeHint, 'Magnet ads grant 50');
    expect(ru.qModeHint, 'Реклама на магните даёт 50');
    expect(en.dimCoveredTiles, 'Dim covered tiles');
    expect(ru.dimCoveredTiles, 'Затемнять закрытые');
    expect(en.boostEarned('Magnet', count: 50), '+50 Magnet');
    expect(en.sound, 'Sound');
    expect(ru.sound, 'Звук');
    expect(en.music, 'Music');
    expect(ru.music, 'Музыка');
    expect(en.plotLockedHint, 'Next wins will grow this plot');
    expect(ru.plotLockedHint, 'Следующие победы будут строить этот участок');
    expect(en.neighboringCourtyard, 'A neighboring courtyard');
    expect(ru.neighboringCourtyard, 'Соседский двор');
    expect(en.courtyardPanHint, 'Drag to look around the courtyard');
    expect(ru.courtyardPanHint, 'Потяните, чтобы осмотреть двор');
    expect(en.plot(0), 'House');
    expect(ru.plot(0), 'Дом');
    expect(en.plot(1), 'Pond');
    expect(ru.plot(1), 'Ставок');
    expect(en.plot(2), 'Guest house');
    expect(ru.plot(2), 'Дом для гостей');
    expect(en.plot(3), 'Pets');
    expect(ru.plot(3), 'Питомцы');
    expect(
      en.firstHomePhraseFor(PlotKind.guest),
      'This yard comes online as you play.',
    );
    expect(en.plotEra(PlotKind.guest, 8), 'Observatory');
    expect(
      en.plotLookProgress(PlotKind.house, 3),
      '3 levels until the next House look',
    );
    expect(
      ru.plotLookProgress(PlotKind.house, 3),
      '3 ур. до следующего вида: Дом',
    );
    expect(en.plotLookProgress(PlotKind.pond, 0), 'Pond is complete');
    expect(en.pet, 'Pet');
    expect(ru.pet, 'Питомец');
    expect(en.petMoodLine(PetKind.cat, PetMood.content), 'Cat is content.');
    expect(ru.petMoodLine(PetKind.cat, PetMood.content), 'Кот в порядке.');
    expect(en.petInviteAdopt, 'A friend is waiting');
    expect(ru.petInviteAdopt, 'Друг ждёт тебя');
    expect(en.petInviteShow, 'Show pets');
    expect(ru.petInviteShow, 'Показать питомцев');
    expect(en.scorePlotsLegend, 'Score : plots');
    expect(ru.scorePlotsLegend, 'Баллы : участки');
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
    expect(en.tileSymbolName('bamboo-3'), 'Bamboo 3');
    expect(ru.tileSymbolName('bamboo-3'), 'Бамбук 3');
    expect(en.tileSymbolName('wind-east'), 'East wind');
    expect(en.tileSymbolName('fruit-01'), 'Fruit 1');
    expect(ru.tileSymbolName('fruit-01'), 'Фрукт 1');
    expect(
      en.tileSemanticLabel(
        symbol: 'bamboo-3',
        free: true,
        hinted: false,
        inTray: false,
        removing: false,
      ),
      'Bamboo 3, free',
    );
    expect(
      ru.tileSemanticLabel(
        symbol: 'bamboo-3',
        free: false,
        hinted: true,
        inTray: false,
        removing: false,
      ),
      'Бамбук 3, закрыта, подсказка',
    );
    expect(en.traySemantic(2, 4), 'Tray, 2 of 4');
    expect(
      ru.boostSemantic('Подсказка', 2, adsAvailable: false),
      'Подсказка, осталось 2',
    );
  });
}
