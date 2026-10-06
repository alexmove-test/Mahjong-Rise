import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/l10n/l10n.dart';
import 'package:mahjong/models/pet.dart';
import 'package:mahjong/models/plot_kind.dart';
import 'package:mahjong/services/locale_store.dart';

void main() {
  test('system follows Russian and falls back to English', () {
    expect(LocaleStore.resolve(LanguagePref.system, 'ru'), 'ru');
    expect(LocaleStore.resolve(LanguagePref.system, 'th'), 'th');
    expect(LocaleStore.resolve(LanguagePref.system, 'uk'), 'en');
    expect(LocaleStore.resolve(LanguagePref.system, 'en'), 'en');
    expect(LocaleStore.resolve(LanguagePref.system, 'de'), 'en');
    expect(LocaleStore.resolve(LanguagePref.ru, 'en'), 'ru');
    expect(LocaleStore.resolve(LanguagePref.en, 'ru'), 'en');
    expect(LocaleStore.resolve(LanguagePref.th, 'en'), 'th');
  });

  test('AppLocalizations switches courtyard and menu labels', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final ru = lookupAppLocalizations(const Locale('ru'));
    final th = lookupAppLocalizations(const Locale('th'));
    expect(en.courtyard, 'Courtyard');
    expect(ru.courtyard, 'Во двор');
    expect(th.courtyard, 'ลานบ้าน');
    expect(th.settings, 'ตั้งค่า');
    expect(th.languageThai, 'ไทย');
    expect(th.winsUntilHouseUpgrade(1), 'ชัยชนะครั้งถัดไปจะอัปเกรดบ้าน');
    expect(th.winsUntilHouseUpgrade(2), 'อีก 2 ชัยชนะก่อนบ้านจะอัปเกรด');
    expect(th.pointsReward(1), '+1 แต้ม');
    expect(th.pointsReward(5), '+5 แต้ม');
    expect(th.plot(0), 'บ้าน');
    expect(th.plot(1), 'สระน้ำ');
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
    expect(en.tableLook, 'Table look');
    expect(ru.tableLook, 'Оформление стола');
    expect(en.tableLookClassic, 'Classic mahjong');
    expect(ru.tableLookClassic, 'Классический маджонг');
    expect(en.tableLookCasual, 'Bright match');
    expect(ru.tableLookCasual, 'Яркий матч');
    expect(en.tableLookPremium, 'New');
    expect(ru.tableLookPremium, 'Новая');
    expect(
      en.tableLookSettingsHint,
      'You can choose different table themes in the menu',
    );
    expect(ru.tableLookSettingsHint, 'Разные темы стола можно выбрать в меню');
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
    expect(
      en.hubStarsUntilPlot(PlotKind.pond, 2),
      '2 more stars until the Pond',
    );
    expect(ru.hubStarsUntilPlot(PlotKind.pond, 2), 'ещё 2 звезды до ставка');
    expect(en.hubDailiesUntilReward(1), 'One daily until the reward');
    expect(ru.hubDailiesUntilReward(1), 'Одна ежедневка до награды');
    expect(en.courtyardLevelsUntilGift(1), 'One level until a courtyard gift');
    expect(
      ru.courtyardLevelsUntilGift(1),
      'Ещё 1 уровень до подарка для двора',
    );
    expect(en.courtyardLevelsUntilGift(3), '3 levels until a courtyard gift');
    expect(ru.courtyardLevelsUntilGift(3), 'Ещё 3 уровня до подарка для двора');
    expect(en.hubLevelUnlocksPet(25), 'Level 25 unlocks a pet');
    expect(ru.hubLevelUnlocksPet(25), 'Уровень 25 откроет питомца');
    expect(en.pet, 'Pet');
    expect(ru.pet, 'Питомец');
    expect(en.petMoodLine(PetKind.cat, PetMood.content), 'Cat is content.');
    expect(ru.petMoodLine(PetKind.cat, PetMood.content), 'Кот в порядке.');
    expect(en.petInviteAdopt, 'A friend is waiting');
    expect(ru.petInviteAdopt, 'Друг ждёт тебя');
    expect(en.petInviteShow, 'Show pets');
    expect(ru.petInviteShow, 'Показать питомцев');
    expect(en.petYardStartAdventure, 'Start an adventure');
    expect(ru.petYardStartAdventure, 'Начать приключение');
    expect(en.petYardVisit, 'Visit the den');
    expect(ru.petYardVisit, 'Заглянуть в уголок');
    expect(en.petYardShow, 'Show in yard');
    expect(ru.petYardShow, 'Показать во дворе');
    expect(en.petYardShowing, 'In the yard');
    expect(ru.petYardShowing, 'Во дворе');
    expect(en.petYardShowAll, 'Show everyone in the yard');
    expect(ru.petYardShowAll, 'Показать всех во дворе');
    expect(en.youClimbed, 'You climbed!');
    expect(ru.youClimbed, 'Вы поднялись!');
    expect(en.rankClimbPlaces(12, 8), 'Place 12 → 8');
    expect(ru.rankClimbPlaces(12, 8), 'Место 12 → 8');
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
