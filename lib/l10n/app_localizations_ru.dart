// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get continueGame => 'Продолжить';

  @override
  String get noShuffleMoves =>
      'Нет доступной пары — попробуйте отмену, подсказку или магнит';

  @override
  String get shuffleLockedChallenge =>
      'В этом испытании перемешивание недоступно';

  @override
  String get specialTile => 'Целевая плитка со звездой';

  @override
  String continueWith(String title) {
    return 'Продолжить · $title';
  }

  @override
  String get newPlot => 'Новый участок';

  @override
  String get previousPlot => 'Предыдущий участок';

  @override
  String get nextPlot => 'Следующий участок';

  @override
  String get plotLockedHint => 'Следующие победы будут строить этот участок';

  @override
  String neighborYard(String name) {
    return 'Двор: $name';
  }

  @override
  String neighborRating(String name, int rating) {
    return '$name · $rating';
  }

  @override
  String get neighboringCourtyard => 'Соседский двор';

  @override
  String get courtyardPanHint => 'Потяните, чтобы осмотреть двор';

  @override
  String houseStateTitle(int state, int total) {
    return 'Дом · $state/$total';
  }

  @override
  String get houseFullyUpgraded => 'Дом полностью улучшен';

  @override
  String get houseDetailsShow => 'Подробнее';

  @override
  String get houseDetailsHide => 'Скрыть';

  @override
  String upgradeHouseForText(String price) {
    return 'Улучшить за $price';
  }

  @override
  String pointsShortfallText(String amount) {
    return 'Не хватает $amount поинтов';
  }

  @override
  String houseUpgradeOfferText(String cost) {
    return 'Улучшение дома — $cost';
  }

  @override
  String get nextHouseLook => 'Следующий облик дома';

  @override
  String houseLookLine(int built, int total) {
    return 'Облики дома: построено $built из $total';
  }

  @override
  String hubLevelUnlocksPet(int id) {
    return 'Уровень $id откроет питомца';
  }

  @override
  String get hubQuestRewardReady => 'Награда недели ждёт';

  @override
  String get hubThreeStarUntilReward => '3★ откроет награду';

  @override
  String get today => 'Сегодня';

  @override
  String get clearedToday => 'День закрыт';

  @override
  String streakNights(int n) {
    return 'День $n из 3';
  }

  @override
  String get streakKept => 'Серия сохранена';

  @override
  String get streakAtRisk => 'Сгорит в полночь';

  @override
  String get keepTheLight => 'Сохрани свет';

  @override
  String openedProgress(int unlocked, int total) {
    return 'открыто $unlocked/$total';
  }

  @override
  String get courtyard => 'Во двор';

  @override
  String get howToPlay => 'Как играть';

  @override
  String get levels => 'Уровни';

  @override
  String get retry => 'Заново';

  @override
  String get playAgain => 'Ещё раз';

  @override
  String get next => 'Дальше';

  @override
  String get menu => 'Меню';

  @override
  String get close => 'Закрыть';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get back => 'Назад';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get privacySettings => 'Настройки конфиденциальности';

  @override
  String get hideBannerButton => '24 часа';

  @override
  String get hideBannerTitle => 'Убрать баннер на 24 часа';

  @override
  String get hideBannerSubtitle =>
      'Посмотреть рекламу. На этом устройстве его не будет.';

  @override
  String get hideBannerWatch => 'Смотреть рекламу';

  @override
  String get hideBannerNotNow => 'Не сейчас';

  @override
  String get aboutGame => 'О игре';

  @override
  String builtAt(String time) {
    return 'Сборка: $time';
  }

  @override
  String get settings => 'Настройки';

  @override
  String get sound => 'Звук';

  @override
  String get music => 'Музыка';

  @override
  String get hapticFeedback => 'Тактильный отклик';

  @override
  String get qMode => 'Режим Q';

  @override
  String get qModeHint => 'Реклама на магните даёт 50';

  @override
  String get dimCoveredTiles => 'Затемнять закрытые';

  @override
  String get dimCoveredTilesHint => 'Серым — плитки, которые нельзя взять';

  @override
  String get tableLook => 'Оформление стола';

  @override
  String get tableLookClassic => 'Классический маджонг';

  @override
  String get tableLookClassicHint => 'Объёмные кости и медные кнопки';

  @override
  String get tableLookCasual => 'Яркий матч';

  @override
  String get tableLookCasualHint => 'Плоские плитки, зелень и золото';

  @override
  String get tableLookPremium => 'Новая';

  @override
  String get tableLookPremiumHint => 'Фарфоровые кости, тёплый деревянный стол';

  @override
  String get tableLookGift => 'Стол';

  @override
  String get tableLookUse => 'Взять';

  @override
  String get tableLookLockedHint => 'Откроется подарком двора';

  @override
  String get tableLookSettingsHint => 'Разные темы стола можно выбрать в меню';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get tileLocked => 'Плитка заблокирована';

  @override
  String get trayFull => 'Лоток полон';

  @override
  String get trayFullHint => 'Нет пары для совпадения.';

  @override
  String get noMovesShuffle => 'Нет ходов — перемешайте';

  @override
  String get youWin => 'Победа!';

  @override
  String get noFreeTiles => 'Нет открытых плиток';

  @override
  String get shuffled => 'Перемешано';

  @override
  String get stillNoMoves => 'Всё ещё нет ходов';

  @override
  String get loadingAd => 'Загрузка рекламы…';

  @override
  String get rewardNotEarned => 'Награда не получена';

  @override
  String get adUnavailable => 'Не удалось загрузить рекламу. Нажмите ещё раз.';

  @override
  String get noUsefulMoves => 'Нет полезных ходов';

  @override
  String get continuing => 'Продолжаем';

  @override
  String get moveUndone => 'Ход отменён';

  @override
  String get noMatchingTiles => 'Нет подходящих плиток';

  @override
  String get couldNotOpenLink => 'Не удалось открыть ссылку';

  @override
  String get dailyComplete => 'Сегодня сыграно';

  @override
  String streakLabel(int n) {
    return 'Серия: $n';
  }

  @override
  String score(int value) {
    return 'Счёт: $value';
  }

  @override
  String starsCount(int n) {
    return '$n ★';
  }

  @override
  String get dailyBonus => 'Запас: +1 подсказка и перемешивание';

  @override
  String get points => 'Баллы';

  @override
  String pointsBalanceText(String value) {
    return 'Баллы: $value';
  }

  @override
  String get pointsShopTitle => 'Баллы';

  @override
  String get pointsShopSubtitle =>
      'Копятся за пройденные уровни. Пополнить можно в любой момент.';

  @override
  String pointsEarnRuleText(int perClear, int perStar) {
    return 'За пройденный уровень +$perClear, ещё +$perStar за каждую звезду.';
  }

  @override
  String pointsPackBonus(int percent) {
    return '+$percent% сверху';
  }

  @override
  String get pointsPackPopular => 'Берут чаще всего';

  @override
  String get pointsPackBest => 'Выгоднее всего';

  @override
  String get pointsBuy => 'Купить';

  @override
  String pointsCreditedText(String value) {
    return 'Зачислено +$value';
  }

  @override
  String get pointsPurchaseCancelled => 'Покупка отменена';

  @override
  String get pointsPurchaseUnavailable => 'Магазин недоступен';

  @override
  String get pointsDemoNote =>
      'Оплата ещё не подключена — пакет зачисляется сразу.';

  @override
  String get pointsWatchAd => 'Смотреть ролик';

  @override
  String pointsWatchAdRewardText(String value) {
    return 'Бесплатно +$value';
  }

  @override
  String level(int id) {
    return 'Уровень $id';
  }

  @override
  String get anotherLevelCleared => 'Ещё один уровень пройден';

  @override
  String get newBest => 'Новый рекорд!';

  @override
  String levelUnlocked(int id) {
    return 'Открыт уровень $id';
  }

  @override
  String get shuffle => 'Перемешать';

  @override
  String get magnet => 'Магнит';

  @override
  String get hint => 'Подсказка';

  @override
  String get undo => 'Отмена';

  @override
  String watchAd(String name) {
    return 'Реклама → $name';
  }

  @override
  String boostEarnedText(int count, String name) {
    return '+$count $name';
  }

  @override
  String get noneLeft => 'нет использований';

  @override
  String get coachTapFree => 'Бери свободную: сверху и сбоку открыта';

  @override
  String get coachMatchPair => 'Пара в лотке снимается';

  @override
  String get coachTrayLimit => 'Лоток на 4 — если забьётся, партия проиграна';

  @override
  String get easy => 'Легко';

  @override
  String get normal => 'Нормально';

  @override
  String get hard => 'Сложно';

  @override
  String get expert => 'Эксперт';

  @override
  String get you => 'Вы';

  @override
  String get player => 'Игрок';

  @override
  String get yourName => 'Ваше имя';

  @override
  String get youClimbed => 'Вы поднялись!';

  @override
  String rankClimbPlaces(int from, int to) {
    return 'Место $from → $to';
  }

  @override
  String get leaderboard => 'Общий рейтинг';

  @override
  String get refresh => 'Обновить';

  @override
  String get changeName => 'Изменить имя';

  @override
  String get nameNotAllowed => 'Такое имя нельзя. Выберите другое.';

  @override
  String get rankingNamesNote =>
      'Имена задают игроки. Пожалуйтесь или скройте тех, кто нарушает правила.';

  @override
  String get reportPlayer => 'Пожаловаться или скрыть';

  @override
  String get reportName => 'Пожаловаться на имя';

  @override
  String get hidePlayer => 'Скрыть этого игрока';

  @override
  String get reportThanks => 'Спасибо. Мы проверим это имя.';

  @override
  String get playerHidden => 'Игрок скрыт на устройстве.';

  @override
  String get name => 'Имя';

  @override
  String onlineRanking(int top) {
    return 'Онлайн-рейтинг · топ $top';
  }

  @override
  String get offlineRanking => 'Офлайн-режим: показан только ваш результат.';

  @override
  String get rankingFormula =>
      'Рейтинг: звёзды × 100 000 + лучшие счёта + прогресс кампании.';

  @override
  String get scorePlotsLegend => 'Баллы : участки';

  @override
  String get loadRankingFailed => 'Не удалось загрузить онлайн-рейтинг';

  @override
  String starsLevel(int stars, int unlocked) {
    return '$stars ★ · ур. $unlocked';
  }

  @override
  String get ad => 'РЕКЛАМА';

  @override
  String get done => 'Готово';

  @override
  String get closeWithoutReward => 'Закрыть без награды';

  @override
  String get simulatedAd => 'Имитация рекламы';

  @override
  String get watchClipForBoost => 'Досмотрите ролик, чтобы получить буст';

  @override
  String get claimReward => 'Получить награду';

  @override
  String get watchingAd => 'Смотрите рекламу…';

  @override
  String get weeklyQuests => 'Задания недели';

  @override
  String get claim => 'Забрать';

  @override
  String get claimed => 'Получено';

  @override
  String get questBonus => '+1 подсказка и перемешивание';

  @override
  String get extraBoostThisWeek => '+1 буст на столе сегодня';

  @override
  String get seasonClosed => 'Сезон закрыт';

  @override
  String lastWeekPlace(int rank) {
    return 'Прошлая неделя: место $rank';
  }

  @override
  String lastWeekScore(String rating) {
    return 'Счёт $rating';
  }

  @override
  String get reminders => 'Напоминания';

  @override
  String get reminderDailyTitle => 'Двор ждёт вас';

  @override
  String get reminderDailyBody => 'Сегодня готов новый стол.';

  @override
  String get reminderStreakTitle => 'Серия сейчас сгорит';

  @override
  String get reminderStreakBody => 'Третий фонарь погаснет в полночь.';

  @override
  String get reminderWeekTitle => 'Новый сезон двора';

  @override
  String get reminderWeekBody => 'Задания и рейтинг недели обновились.';

  @override
  String get pet => 'Питомец';

  @override
  String get pets => 'Питомцы';

  @override
  String get chooseAPet => 'Выберите питомца';

  @override
  String get addPet => 'Добавить питомца';

  @override
  String get petInviteAdopt => 'Друг ждёт тебя';

  @override
  String get petInviteShow => 'Показать питомцев';

  @override
  String get petYardStartAdventure => 'Начать приключение';

  @override
  String get petYardVisit => 'Заглянуть в уголок';

  @override
  String get petYardShow => 'Показать во дворе';

  @override
  String get petYardShowing => 'Во дворе';

  @override
  String get petYardShowAll => 'Показать всех во дворе';

  @override
  String get petCareHint =>
      'Победы помогают с игрой и отдыхом. Кормите собранными растениями со склада.';

  @override
  String get petStarvingLine => 'Голодает. Покормите растением со склада.';

  @override
  String get petRemindersPromptTitle => 'Напомнить о голоде?';

  @override
  String get petRemindersPromptBody =>
      'Можем напомнить, когда питомец проголодается.';

  @override
  String get petRemindersYes => 'Напомнить';

  @override
  String get petRemindersLater => 'Не сейчас';

  @override
  String reminderPetHungerTitle(String name) {
    return '$name хочет есть';
  }

  @override
  String get reminderPetHungerBody => 'Покормите растением со склада.';

  @override
  String reminderPetPlayTitle(String name) {
    return '$name хочет играть';
  }

  @override
  String get reminderPetPlayBody => 'Пройдите уровень, чтобы поиграть.';

  @override
  String reminderPetRestTitle(String name) {
    return '$name хочет отдохнуть';
  }

  @override
  String get reminderPetRestBody => 'Пройдите уровень — питомцу нужен отдых.';

  @override
  String reminderPetStarveTitle(String name) {
    return '$name голодает';
  }

  @override
  String get reminderPetStarveBody => 'Покормите растением со склада.';

  @override
  String petLevelLabel(int level) {
    return 'Уровень $level';
  }

  @override
  String petLevelShort(int level) {
    return 'Ур. $level';
  }

  @override
  String get petMaxLevel => 'Максимальный уровень';

  @override
  String petXpLabel(int xp, int need) {
    return 'Опыт $xp / $need';
  }

  @override
  String petStrengthLineText(
    String stat,
    int total,
    int base,
    int main,
    int accessory,
  ) {
    return '$stat $total = основа $base + предмет $main + аксессуар $accessory';
  }

  @override
  String petLevelChange(int from, int to) {
    return 'Уровень $from → $to';
  }

  @override
  String petStatChange(String stat, int from, int to) {
    return '$stat $from → $to';
  }

  @override
  String get petFeed => 'Покормить';

  @override
  String get petFeedTitle => 'Выбор растения';

  @override
  String get petFeedEmpty => 'На складе нет собранных растений.';

  @override
  String get petFeedPointless => 'Питомец сыт, и уровень уже максимальный.';

  @override
  String petFeedXp(int xp) {
    return 'Опыт: $xp';
  }

  @override
  String get petFeedSatiety => 'Восстановит сытость. Сила не вырастет.';

  @override
  String get petFeedConfirm => 'Скормить это растение';

  @override
  String petFedReaction(String name) {
    return '$name довольно ест.';
  }

  @override
  String get petFeedFailed => 'Не удалось сохранить. Растение не потрачено.';

  @override
  String get petFeedMissing => 'Этого растения уже нет на складе.';

  @override
  String get petSlotEmpty => 'Пусто';

  @override
  String get petGuardAction => 'Охранять огород';

  @override
  String get petGuarding => 'Охраняет огород';

  @override
  String get petStopGuard => 'Снять охрану';

  @override
  String get petRaidAction => 'Выбрать для набегов';

  @override
  String get petRaiding => 'Выбран для набегов';

  @override
  String get petStopRaid => 'Снять выбор набега';

  @override
  String gearBonus(int bonus) {
    return '+$bonus к силе';
  }

  @override
  String gearPriceText(String price) {
    return '$price поинтов';
  }

  @override
  String gearLevelRequired(int level) {
    return 'Нужен уровень $level';
  }

  @override
  String gearIfEquipped(String stat, int from, int to) {
    return 'Если надеть: $stat $from → $to';
  }

  @override
  String get gearBuy => 'Купить';

  @override
  String get gearEquip => 'Надеть';

  @override
  String get gearUnequip => 'Снять';

  @override
  String gearWornBy(String name) {
    return 'Надето на $name';
  }

  @override
  String gearShortfallText(String shortfall) {
    return 'Не хватает $shortfall поинтов';
  }

  @override
  String get gearBuyFailed => 'Не удалось сохранить. Поинты не списаны.';

  @override
  String gardenGuardLabel(String name, int power) {
    return '$name охраняет огород. Защита $power';
  }

  @override
  String get gardenNoDefender => 'Защитника пока нет';

  @override
  String get gardenUnguarded => 'Огород без охраны';

  @override
  String get boardSemantic => 'Поле';

  @override
  String traySemantic(int filled, int capacity) {
    return 'Лоток, $filled из $capacity';
  }

  @override
  String get trayEmptySlot => 'Пустой слот';

  @override
  String get trayAlmostFull => 'Осталось одно место — найдите пару';

  @override
  String get houseCardTitle => 'Дом';

  @override
  String get seedsHeading => 'Семена';

  @override
  String seedsButton(int count) {
    return 'Семена · $count';
  }

  @override
  String seedPowerStep(int from, int to) {
    return 'Сила семян: $from → $to';
  }

  @override
  String seedCostStep(int from, int to) {
    return 'Стоимость производства: $from → $to поинтов';
  }

  @override
  String seedSpeciesUnlock(String name) {
    return 'Новый вид: $name';
  }

  @override
  String seedDurationStep(String from, String to) {
    return 'Время производства: $from → $to';
  }

  @override
  String seedChanceStep(String summary) {
    return 'Шансы: $summary';
  }

  @override
  String get seedClassCommon => 'Обычные';

  @override
  String get seedClassNutrient => 'Питательные';

  @override
  String get seedClassRare => 'Редкие';

  @override
  String seedClassLine(String name, int percent) {
    return '$name $percent%';
  }

  @override
  String seedSpan(int minutes, int seconds) {
    return '$minutes мин $seconds с';
  }

  @override
  String seedPowerLabel(int power) {
    return 'Корм: $power';
  }

  @override
  String seedPowerPending(int power) {
    return 'Сила ожидаемого семени: $power';
  }

  @override
  String seedMinutes(int minutes) {
    return '$minutes мин';
  }

  @override
  String get seedSpeciesHeading => 'Возможные виды';

  @override
  String get seedEqualChance => 'Внутри класса оба вида равновероятны';

  @override
  String produceSeedForText(String price) {
    return 'Произвести семя · $price поинтов';
  }

  @override
  String get claimSeed => 'Забрать семя';

  @override
  String get seedAdded => 'Семя добавлено в хранилище';

  @override
  String get openSeedStorage => 'Открыть хранилище';

  @override
  String get seedPurpose => 'Из этого семени можно будет вырастить растение.';

  @override
  String seedHouseLevel(int level) {
    return 'Произведено домом уровня $level';
  }

  @override
  String seedReceived(String date) {
    return 'Получено $date';
  }

  @override
  String seedGroupCount(int count) {
    return '×$count';
  }

  @override
  String get seedSortPower => 'По корму';

  @override
  String get seedSortTime => 'По времени получения';

  @override
  String get seedProducing => 'Семя производится';

  @override
  String get seedReadyTitle => 'Семя готово';

  @override
  String get seedUnknown => 'Неизвестное семя';

  @override
  String seedTimeLeft(int minutes, int seconds) {
    return 'Осталось $minutes мин $seconds с';
  }

  @override
  String get seedBadgeIdle => 'Производство семян доступно';

  @override
  String seedBadgeProducing(String time) {
    return 'Семя производится, осталось $time';
  }

  @override
  String get seedBadgeReady => 'Семя можно забрать';

  @override
  String get seedReadyMark => 'Готово';

  @override
  String get seedPlayMahjong => 'Играть в махджонг';

  @override
  String get produceFirstSeed => 'Произвести первое семя';

  @override
  String get seedsEmptyBody => 'Дом ещё не произвёл ни одного семени.';

  @override
  String seedStackLabel(String name, int power, int count) {
    return '$name, корм $power, $count';
  }

  @override
  String get seedProductionTitle => 'Производство семян';

  @override
  String plantsButton(int count) {
    return 'Растения · $count';
  }

  @override
  String get warehouseTitle => 'Склад';

  @override
  String warehouseSemantic(int count) {
    return 'Склад, растений $count';
  }

  @override
  String get warehouseEmptyBody => 'Здесь будут храниться собранные растения';

  @override
  String get openGarden => 'Открыть огород';

  @override
  String plantActionText(int seeds, String points) {
    return 'Посадить · $seeds семя + $points поинтов';
  }

  @override
  String get chooseSeedTitle => 'Выбор семени';

  @override
  String get noSeedsBody => 'Семян пока нет. Откройте производство в доме.';

  @override
  String get openHouseProduction => 'Открыть производство';

  @override
  String gardenBedEmpty(int number) {
    return 'Грядка $number, пустая';
  }

  @override
  String bedTitle(int number) {
    return 'Грядка $number';
  }

  @override
  String get harvestAction => 'Собрать';

  @override
  String get harvestMark => 'Собрать';

  @override
  String plantPower(int power) {
    return 'Корм: $power';
  }

  @override
  String plantCostLabelText(String points) {
    return 'Стоимость посадки: $points поинтов';
  }

  @override
  String growDurationLabel(int minutes) {
    return 'Время выращивания: $minutes мин';
  }

  @override
  String seedsAvailable(int count) {
    return 'Доступно: $count';
  }

  @override
  String get plantPreviewLabel => 'Будущее растение';

  @override
  String plantVariant(String variant) {
    return 'Внешний вариант: $variant';
  }

  @override
  String plantedOn(String date) {
    return 'Посажено $date';
  }

  @override
  String maturedOn(String date) {
    return 'Созрело $date';
  }

  @override
  String harvestedOn(String date) {
    return 'Собрано $date';
  }

  @override
  String get gardenSaveFailed => 'Не удалось сохранить. Ничего не списано.';

  @override
  String get gardenNotReady => 'Ещё не созрело';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languageThai => 'ไทย';

  @override
  String get challengeCompactTower => 'Башня: разберите все слои';

  @override
  String challengeSpecialPair(int cleared) {
    return 'Снимите две плитки со звездой · $cleared/2';
  }

  @override
  String get challengeNoShuffle => 'Разберите поле без перемешивания';

  @override
  String plotKindTitle(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'house': 'Дом',
      'pond': 'Ставок',
      'pets': 'Питомцы',
      'guest': 'Дом для гостей',
      'other': 'Дом',
    });
    return '$_temp0';
  }

  @override
  String plotKindTitleToward(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'house': 'дома',
      'pond': 'ставка',
      'pets': 'питомцев',
      'guest': 'дома для гостей',
      'other': 'дома',
    });
    return '$_temp0';
  }

  @override
  String plotLookComplete(String name) {
    return '$name собран';
  }

  @override
  String plotLookNextOne(String name) {
    return '1 уровень до следующего вида: $name';
  }

  @override
  String plotLookProgressText(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ур. до следующего вида: $name',
    );
    return '$_temp0';
  }

  @override
  String get nextWinUpgradesHouse => 'Следующая победа улучшит дом';

  @override
  String winsUntilHouseUpgradeText(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'До улучшения дома — $count побед',
      many: 'До улучшения дома — $count побед',
      few: 'До улучшения дома — $count победы',
      one: 'До улучшения дома — $count победа',
    );
    return '$_temp0';
  }

  @override
  String get nextWinImprovesPond => 'Следующая победа улучшит пруд';

  @override
  String winsUntilPondUpgradeText(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'До улучшения пруда — $count побед',
      many: 'До улучшения пруда — $count побед',
      few: 'До улучшения пруда — $count победы',
      one: 'До улучшения пруда — $count победа',
    );
    return '$_temp0';
  }

  @override
  String get nextPondLook => 'Следующий облик пруда';

  @override
  String hubStarsUntilPlotText(int count, String dest) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ещё $count звёзд до $dest',
      many: 'ещё $count звёзд до $dest',
      few: 'ещё $count звезды до $dest',
      one: 'ещё $count звезда до $dest',
      zero: 'ещё 1 звезда до $dest',
    );
    return '$_temp0';
  }

  @override
  String get oneDailyUntilReward => 'Одна ежедневка до награды';

  @override
  String hubDailiesUntilRewardText(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ещё $count ежедневок до награды',
      many: 'ещё $count ежедневок до награды',
      few: 'ещё $count ежедневки до награды',
      one: 'ещё $count ежедневка до награды',
    );
    return '$_temp0';
  }

  @override
  String get oneLevelUntilReward => 'Один уровень до награды';

  @override
  String hubLevelsUntilRewardText(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ещё $count уровней до награды',
      many: 'ещё $count уровней до награды',
      few: 'ещё $count уровня до награды',
      one: 'ещё $count уровень до награды',
    );
    return '$_temp0';
  }

  @override
  String courtyardLevelsUntilGift(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ещё $count уровней до подарка для двора',
      many: 'Ещё $count уровней до подарка для двора',
      few: 'Ещё $count уровня до подарка для двора',
      one: 'Ещё $count уровень до подарка для двора',
      zero: 'Ещё 1 уровень до подарка для двора',
    );
    return '$_temp0';
  }

  @override
  String hubStarsUntilReward(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ещё $count звёзд до награды',
      many: 'ещё $count звёзд до награды',
      few: 'ещё $count звезды до награды',
      one: 'ещё $count звезда до награды',
      zero: 'ещё 1 звезда до награды',
    );
    return '$_temp0';
  }

  @override
  String pointsRewardText(int count, String amount) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$amount баллов',
      many: '+$amount баллов',
      few: '+$amount балла',
      one: '+$amount балл',
    );
    return '$_temp0';
  }

  @override
  String get styleFruit => 'Фрукты';

  @override
  String get styleNature => 'Природа';

  @override
  String get styleCourt => 'Двор';

  @override
  String get styleMyth => 'Миф';

  @override
  String get styleClassic => 'Классика';

  @override
  String get styleShape => 'Фигуры';

  @override
  String get styleNumber => 'Цифры';

  @override
  String get styleMix => 'Микс';

  @override
  String get questDaily3 => 'Закройте daily 3 раза';

  @override
  String get questStars8 => 'Наберите 8 звёзд';

  @override
  String get questClears4 => 'Пройдите 4 уровня кампании';

  @override
  String get questThreeStar1 => 'Возьмите 3★ на уровне';

  @override
  String get questStreak3 => 'Три вечера света';

  @override
  String get weekGarden => 'Неделя сада';

  @override
  String get weekCourt => 'Неделя двора';

  @override
  String get weekLanterns => 'Неделя фонарей';

  @override
  String get weekMyth => 'Неделя мифа';

  @override
  String get weekHarvest => 'Неделя урожая';

  @override
  String get weekDefault => 'Стол этой недели';

  @override
  String get petCat => 'Кот';

  @override
  String get petDog => 'Собака';

  @override
  String get petRaccoon => 'Енот';

  @override
  String get petHamster => 'Хомяк';

  @override
  String get petFox => 'Лисица';

  @override
  String get petNeedHunger => 'Голод';

  @override
  String get petNeedPlay => 'Игра';

  @override
  String get petNeedRest => 'Отдых';

  @override
  String petMoodContent(String name) {
    return '$name в порядке.';
  }

  @override
  String petMoodAsking(String name) {
    return '$name просит внимания.';
  }

  @override
  String petMoodStarving(String name) {
    return '$name голодает.';
  }

  @override
  String petCareHunger(String name) {
    return 'Вы покормили $name.';
  }

  @override
  String petCarePlay(String name) {
    return 'Вы поиграли с $name.';
  }

  @override
  String petCareRest(String name) {
    return 'Вы дали $name отдохнуть.';
  }

  @override
  String get petRoleAttacker => 'Атакующий';

  @override
  String get petRoleDefender => 'Защитник';

  @override
  String get petStatAttack => 'Атака';

  @override
  String get petStatDefense => 'Защита';

  @override
  String get gearSlotMain => 'Основной предмет';

  @override
  String get gearSlotAccessory => 'Аксессуар';

  @override
  String get growthSown => 'Семя посажено';

  @override
  String get growthSprout => 'Росток';

  @override
  String get growthGrowing => 'Растение растёт';

  @override
  String get growthRipe => 'Можно собрать';

  @override
  String get seedAmberbell => 'Янтарный колокольчик';

  @override
  String get seedMistfern => 'Туманный папоротник';

  @override
  String get seedGlassreed => 'Стеклянный тростник';

  @override
  String get seedCrimsonplum => 'Багряная слива';

  @override
  String get seedNightlotus => 'Ночной лотос';

  @override
  String get seedStarbamboo => 'Звёздный бамбук';

  @override
  String get seedBlurbAmberbell =>
      'Тёплое семя, внутри которого звенит крошечный колокольчик.';

  @override
  String get seedBlurbMistfern => 'Бледный лист папоротника, свёрнутый в семя.';

  @override
  String get seedBlurbGlassreed =>
      'Прозрачный тростник, который звенит на свету.';

  @override
  String get seedBlurbCrimsonplum => 'Тёмная сладкая косточка дворовой сливы.';

  @override
  String get seedBlurbNightlotus =>
      'Фиолетовый бутон, который раскрывается после заката.';

  @override
  String get seedBlurbStarbamboo => 'Членистое зерно с искоркой на кончике.';

  @override
  String get plantOriginHouse => 'Происхождение: производство дома';

  @override
  String plantOriginOther(String source) {
    return 'Происхождение: $source';
  }

  @override
  String get firstPhraseHouse => 'Следующий облик дома покупается за поинты.';

  @override
  String get firstPhrasePond => 'Этот ставок наполняется, пока ты играешь.';

  @override
  String get firstPhrasePets => 'Этот домик питомца растёт, пока ты играешь.';

  @override
  String get firstPhraseGuest => 'Этот двор выходит в сеть, пока ты играешь.';

  @override
  String get pathLifeHouse => 'В доме стало теплее.';

  @override
  String get pathLifePond => 'Ставок ожил.';

  @override
  String get pathLifePets => 'В домике стало теплее.';

  @override
  String get pathLifeGuest => 'Двор чуть гудит.';

  @override
  String get rewardPond => 'Маленький пруд';

  @override
  String get rewardSwing => 'Садовые качели';

  @override
  String get rewardFlowerBed => 'Цветник';

  @override
  String get tileStateFree => 'свободна';

  @override
  String get tileStateLocked => 'закрыта';

  @override
  String tileRemoving(String name) {
    return '$name, снятие пары';
  }

  @override
  String tileInTrayHinted(String name) {
    return '$name в лотке, подсказка';
  }

  @override
  String tileInTray(String name) {
    return '$name в лотке';
  }

  @override
  String tileFreeHinted(String name) {
    return '$name, свободна, подсказка';
  }

  @override
  String tileLockedHinted(String name) {
    return '$name, закрыта, подсказка';
  }

  @override
  String tileFreeState(String name) {
    return '$name, свободна';
  }

  @override
  String tileLockedState(String name) {
    return '$name, закрыта';
  }

  @override
  String levelCardLocked(int id) {
    return 'Уровень $id, закрыт';
  }

  @override
  String levelCardOpen(int id, String title, String stars, String progress) {
    return 'Уровень $id, $title, $stars$progress';
  }

  @override
  String get levelStarsNone => 'без звёзд';

  @override
  String levelStarsSome(int count) {
    return '$count ★';
  }

  @override
  String get levelInProgress => ', партия начата';

  @override
  String boostLeft(String name, int count) {
    return '$name, осталось $count';
  }

  @override
  String boostNone(String name) {
    return '$name, нет использований';
  }

  @override
  String get petsNeedCare => 'Питомцы, нужна забота';

  @override
  String dailyButtonSemanticText(String today, String status) {
    return '$today. $status';
  }

  @override
  String courtyardSemanticText(String name) {
    return 'Двор: $name';
  }

  @override
  String gardenBedReady(int number, String name) {
    return 'Грядка $number, $name, можно собрать';
  }

  @override
  String gardenBedGrowing(int number, String name, String stage, String time) {
    return 'Грядка $number, $name, $stage, осталось $time';
  }

  @override
  String storyNextItem(String item) {
    return 'Дальше: $item';
  }

  @override
  String newGiftItem(String item) {
    return 'Новый подарок: $item';
  }

  @override
  String storyProgressLine(String title, int progress) {
    return '$title · $progress/3';
  }

  @override
  String newChapterProgress(int progress) {
    return 'Новая глава · $progress/3';
  }

  @override
  String storyReadyProgress(int stage) {
    return 'История ждёт · $stage/3';
  }

  @override
  String foxStoryProgress(int stage) {
    return 'История лисёнка · $stage/3';
  }

  @override
  String gearOfferText(String role, String slot) {
    return '$role · $slot';
  }

  @override
  String petBadgeText(String role, String level) {
    return '$role, $level';
  }

  @override
  String get chooseAPetYard => 'Выбрать питомца';

  @override
  String get chooseAPetStatus => 'Выбрать питомца';

  @override
  String get homeSemantic => 'Дом';

  @override
  String get petAdventures => 'Приключения питомцев';

  @override
  String get adventures => 'Приключения';

  @override
  String get adventureComplete => 'Приключение завершено';

  @override
  String get adventureCompleteBang => 'Приключение завершено!';

  @override
  String get play => 'Играть';

  @override
  String get storyLocked => 'Заверши предыдущую историю';

  @override
  String get fiveAdventures => '5 приключений';

  @override
  String get foxTitle => 'Уютный уголок лисёнка';

  @override
  String get foxGoal0 => 'Одна победа — и место готово';

  @override
  String get foxGoal1 => 'Одна победа — и появится лежанка';

  @override
  String get foxGoal2 => 'Одна победа — и принесём игрушку';

  @override
  String get foxGoalDone => 'Лисёнок теперь дома!';

  @override
  String get foxSeeWhatChanged => 'Посмотри, что изменилось!';

  @override
  String get foxHelpSettle => 'Поможем обустроиться · 3 победы';

  @override
  String get foxSaveFailed => 'Не удалось сохранить. Попробуй ещё раз.';

  @override
  String get foxIntro =>
      'Лисёнок нашёл тихое место в твоём дворе. Три победы в кампании — и здесь станет уютно.';

  @override
  String get foxStage0 =>
      'Уберём листья! Победи в уровне кампании, чтобы подготовить место.';

  @override
  String get foxStage1 =>
      'Место готово! Ещё одна победа — и появится мягкая лежанка.';

  @override
  String get foxStage2 =>
      'Какая мягкая лежанка! Выбери цвет. Ещё одна победа — и принесём игрушку.';

  @override
  String get foxStageDone =>
      'Лисёнок теперь дома! Нажми на него, чтобы поиграть. Этот уголок остаётся в твоём дворе.';

  @override
  String get foxHoney => 'Медовая';

  @override
  String get foxSkyBlue => 'Голубая';

  @override
  String get foxBall => 'Мячик';

  @override
  String get foxPlushToy => 'Мягкая игрушка';

  @override
  String get later => 'Позже';

  @override
  String get foxHelpStages => 'Помочь · 3 этапа';

  @override
  String get foxLovely => 'Как уютно!';

  @override
  String get foxIsHome => 'Лисёнок дома · 3/3';

  @override
  String get foxStory => 'История лисёнка';

  @override
  String get windEast => 'Восточный ветер';

  @override
  String get windSouth => 'Южный ветер';

  @override
  String get windWest => 'Западный ветер';

  @override
  String get windNorth => 'Северный ветер';

  @override
  String get familyFruit => 'Фрукт';

  @override
  String get familyFlower => 'Цветок';

  @override
  String get familyAnimal => 'Животное';

  @override
  String get familyBamboo => 'Бамбук';

  @override
  String get familyCharacter => 'Иероглиф';

  @override
  String get familyDot => 'Точка';

  @override
  String get familyDragon => 'Дракон';

  @override
  String get familyWind => 'Ветер';

  @override
  String get familySeason => 'Сезон';

  @override
  String get familyNumber => 'Цифра';

  @override
  String get familyShape => 'Фигура';

  @override
  String get familyTile => 'Плитка';

  @override
  String get familyArt => 'Узор';

  @override
  String get familyClown => 'Клоун';

  @override
  String get familyEmperor => 'Император';

  @override
  String get familyJoker => 'Джокер';

  @override
  String get familyProfession => 'Профессия';

  @override
  String get familyQueen => 'Королева';

  @override
  String get familyEast => 'Восток';

  @override
  String get familySouth => 'Юг';

  @override
  String get familyWest => 'Запад';

  @override
  String get familyNorth => 'Север';

  @override
  String get familySpring => 'Весна';

  @override
  String get familySummer => 'Лето';

  @override
  String get familyAutumn => 'Осень';

  @override
  String get familyWinter => 'Зима';

  @override
  String get gearAttackerMain1 => 'Шёлковый пояс';

  @override
  String get gearAttackerMain2 => 'Ночной коготь';

  @override
  String get gearAttackerMain3 => 'Фонарь набега';

  @override
  String get gearAttackerAccessory1 => 'Колокольчик разведчика';

  @override
  String get gearAttackerAccessory2 => 'Сумка следопыта';

  @override
  String get gearAttackerAccessory3 => 'Лунный оберег';

  @override
  String get gearDefenderMain1 => 'Мягкий жилет';

  @override
  String get gearDefenderMain2 => 'Жилет стража';

  @override
  String get gearDefenderMain3 => 'Пластина фонаря';

  @override
  String get gearDefenderAccessory1 => 'Кожаный ошейник';

  @override
  String get gearDefenderAccessory2 => 'Повязка дозора';

  @override
  String get gearDefenderAccessory3 => 'Оберег калитки';

  @override
  String get storyCampaign0 => 'Росток';

  @override
  String get storyCampaign1 => 'Бутон';

  @override
  String get storyCampaign2 => 'Цветение';

  @override
  String get storyCampaign3 => 'Поляна';

  @override
  String get storyCampaign4 => 'Лужайка';

  @override
  String get storyCampaign5 => 'Рощица';

  @override
  String get storyCampaign6 => 'Волна';

  @override
  String get storyCampaign7 => 'Ручей';

  @override
  String get storyCampaign8 => 'Сад';

  @override
  String get storyCampaign9 => 'Беседка';

  @override
  String get storyCampaign10 => 'Веер';

  @override
  String get storyCampaign11 => 'Павлиний веер';

  @override
  String get storyCampaign12 => 'Лотос';

  @override
  String get storyCampaign13 => 'Пруд';

  @override
  String get storyCampaign14 => 'Карпы';

  @override
  String get storyCampaign15 => 'Озеро';

  @override
  String get storyCampaign16 => 'Лоза';

  @override
  String get storyCampaign17 => 'Плющ';

  @override
  String get storyCampaign18 => 'Праздник';

  @override
  String get storyCampaign19 => 'Фонари';

  @override
  String get storyCampaign20 => 'Павильон';

  @override
  String get storyCampaign21 => 'Храм ветров';

  @override
  String get storyCampaign22 => 'Дракон';

  @override
  String get storyCampaign23 => 'Небесный дракон';

  @override
  String get houseEraName0 => 'Пустырь';

  @override
  String get houseEraPhrase0 => 'Здесь будет дом.';

  @override
  String get houseEraName1 => 'Лачуга';

  @override
  String get houseEraPhrase1 => 'На участке встала лачуга.';

  @override
  String get houseEraName2 => 'Хижина';

  @override
  String get houseEraPhrase2 => 'У хижины появилась дверь.';

  @override
  String get houseEraName3 => 'Изба';

  @override
  String get houseEraPhrase3 => 'Изба уже из бревен.';

  @override
  String get houseEraName4 => 'Дом';

  @override
  String get houseEraPhrase4 => 'Стоит настоящий дом.';

  @override
  String get houseEraName5 => 'Коттедж';

  @override
  String get houseEraPhrase5 => 'У коттеджа два этажа.';

  @override
  String get houseEraName6 => 'Усадьба';

  @override
  String get houseEraPhrase6 => 'Усадьба расправила крылья.';

  @override
  String get houseEraName7 => 'Особняк';

  @override
  String get houseEraPhrase7 => 'Особняк стал каменным.';

  @override
  String get houseEraName8 => 'Крепость';

  @override
  String get houseEraPhrase8 => 'Стены стали крепостью.';

  @override
  String get houseEraName9 => 'Замок';

  @override
  String get houseEraPhrase9 => 'Растёт замок.';

  @override
  String get houseEraName10 => 'Большой замок';

  @override
  String get houseEraPhrase10 => 'Замок занял холм.';

  @override
  String get houseEraName11 => 'Резиденция';

  @override
  String get houseEraPhrase11 => 'Резиденция собрана.';

  @override
  String get pondEraName0 => 'Низина';

  @override
  String get pondEraPhrase0 => 'Здесь нальётся ставок.';

  @override
  String get pondEraName1 => 'Лужа';

  @override
  String get pondEraPhrase1 => 'Лужа держит воду.';

  @override
  String get pondEraName2 => 'Ставок';

  @override
  String get pondEraPhrase2 => 'Камыш взял кромку.';

  @override
  String get pondEraName3 => 'Мостки';

  @override
  String get pondEraPhrase3 => 'Мостки легли.';

  @override
  String get pondEraName4 => 'Пруд с карпами';

  @override
  String get pondEraPhrase4 => 'Карпам есть дом.';

  @override
  String get pondEraName5 => 'Беседка';

  @override
  String get pondEraPhrase5 => 'Беседка смотрит на воду.';

  @override
  String get pondEraName6 => 'Водный сад';

  @override
  String get pondEraPhrase6 => 'Ставок стал садом.';

  @override
  String get pondEraName7 => 'Каменные берега';

  @override
  String get pondEraPhrase7 => 'Каменные берега и фонари.';

  @override
  String get pondEraName8 => 'Мост';

  @override
  String get pondEraPhrase8 => 'Мост перешёл воду.';

  @override
  String get pondEraName9 => 'Водный двор';

  @override
  String get pondEraPhrase9 => 'Водный двор обнесён стеной.';

  @override
  String get pondEraName10 => 'Дворцовый пруд';

  @override
  String get pondEraPhrase10 => 'Дворцовый сад дошёл до ставка.';

  @override
  String get pondEraName11 => 'Сад готов';

  @override
  String get pondEraPhrase11 => 'Водный сад собран.';

  @override
  String get petsEraName0 => 'Двор';

  @override
  String get petsEraPhrase0 => 'Здесь будет домик питомца.';

  @override
  String get petsEraName1 => 'Миски';

  @override
  String get petsEraPhrase1 => 'Миски ждут в траве.';

  @override
  String get petsEraName2 => 'Будка';

  @override
  String get petsEraPhrase2 => 'На участке встала будка.';

  @override
  String get petsEraName3 => 'Клетка';

  @override
  String get petsEraPhrase3 => 'У клетки появилась дверь.';

  @override
  String get petsEraName4 => 'Домик питомца';

  @override
  String get petsEraPhrase4 => 'У питомцев есть дом.';

  @override
  String get petsEraName5 => 'Площадка';

  @override
  String get petsEraPhrase5 => 'Открылась площадка.';

  @override
  String get petsEraName6 => 'Сад';

  @override
  String get petsEraPhrase6 => 'Сад стал их.';

  @override
  String get petsEraName7 => 'Нора';

  @override
  String get petsEraPhrase7 => 'Нора выстлана.';

  @override
  String get petsEraName8 => 'Флигель';

  @override
  String get petsEraPhrase8 => 'Флигель тёплый.';

  @override
  String get petsEraName9 => 'Зверинец';

  @override
  String get petsEraPhrase9 => 'Зверинец собирается.';

  @override
  String get petsEraName10 => 'Приют';

  @override
  String get petsEraPhrase10 => 'Приют обнесён.';

  @override
  String get petsEraName11 => 'Домик готов';

  @override
  String get petsEraPhrase11 => 'Домик питомца собран.';

  @override
  String get guestEraName0 => 'Тихий двор';

  @override
  String get guestEraPhrase0 => 'Сюда дойдёт сигнал.';

  @override
  String get guestEraName1 => 'Столб';

  @override
  String get guestEraPhrase1 => 'Столб держит линию.';

  @override
  String get guestEraName2 => 'Кабель';

  @override
  String get guestEraPhrase2 => 'Кабель нашёл дом.';

  @override
  String get guestEraName3 => 'Тарелка';

  @override
  String get guestEraPhrase3 => 'Тарелка стоит.';

  @override
  String get guestEraName4 => 'Экраны';

  @override
  String get guestEraPhrase4 => 'Экраны светятся во дворе.';

  @override
  String get guestEraName5 => 'Фонарь линии';

  @override
  String get guestEraPhrase5 => 'Фонарь линии.';

  @override
  String get guestEraName6 => 'Дальняя связь';

  @override
  String get guestEraPhrase6 => 'Двор говорит дальше.';

  @override
  String get guestEraName7 => 'Башня сигнала';

  @override
  String get guestEraPhrase7 => 'Башня сигнала.';

  @override
  String get guestEraName8 => 'Обсерватория';

  @override
  String get guestEraPhrase8 => 'Растёт обсерватория.';

  @override
  String get guestEraName9 => 'Хрустальная линия';

  @override
  String get guestEraPhrase9 => 'Хрусталь и провод.';

  @override
  String get guestEraName10 => 'Маяк';

  @override
  String get guestEraPhrase10 => 'Маяк на холме.';

  @override
  String get guestEraName11 => 'Двор в сети';

  @override
  String get guestEraPhrase11 => 'Двор полностью в сети.';

  @override
  String get houseWarm0 => 'Ещё один шаг по тропе.';

  @override
  String get houseWarm1 => 'Участок стал своим.';

  @override
  String get houseWarm2 => 'Дом чуть ближе.';

  @override
  String get pondWarm0 => 'Вода поднялась чуть.';

  @override
  String get pondWarm1 => 'Ставок стал своим.';

  @override
  String get pondWarm2 => 'Берега ближе.';

  @override
  String get petsWarm0 => 'Домик чуть уютнее.';

  @override
  String get petsWarm1 => 'Питомцам просторнее.';

  @override
  String get petsWarm2 => 'Двор стал своим.';

  @override
  String get guestWarm0 => 'Сигнал чуть сильнее.';

  @override
  String get guestWarm1 => 'Двор связаннее.';

  @override
  String get guestWarm2 => 'Линия ближе.';

  @override
  String get storyCatWindowTitle => 'Солнечный подоконник';

  @override
  String get storyCatWindowChapter0 => 'Найдём самое тёплое солнечное место.';

  @override
  String get storyCatWindowChapter1 => 'Принесём мягкую подушку и клубок.';

  @override
  String get storyCatWindowChapter2 =>
      'Повесим занавеску для идеального дневного сна.';

  @override
  String get storyCatWatchTitle => 'Ночной дозор';

  @override
  String get storyCatWatchChapter0 => 'Осветим тихую дорожку через двор.';

  @override
  String get storyCatWatchChapter1 =>
      'Добавим колокольчик, чтобы слышать гостей.';

  @override
  String get storyCatWatchChapter2 => 'Посмотрим на луну в маленький телескоп.';

  @override
  String get storyCatGardenTitle => 'Тайный сад';

  @override
  String get storyCatGardenChapter0 => 'Посадим укромный зелёный уголок.';

  @override
  String get storyCatGardenChapter1 => 'Позовём в гости ярких бабочек.';

  @override
  String get storyCatGardenChapter2 => 'Завершим сад журчащим фонтаном.';

  @override
  String get storyCatLibraryTitle => 'Маленькая библиотека';

  @override
  String get storyCatLibraryChapter0 => 'Соберём три любимые книги.';

  @override
  String get storyCatLibraryChapter1 => 'Расстелим плед рядом с полками.';

  @override
  String get storyCatLibraryChapter2 => 'Зажжём лампу для долгих вечеров.';

  @override
  String get storyCatTeaTitle => 'Хранитель чайного домика';

  @override
  String get storyCatTeaChapter0 => 'Поставим первую маленькую чашку.';

  @override
  String get storyCatTeaChapter1 => 'Украсим стол свежими цветами.';

  @override
  String get storyCatTeaChapter2 => 'Поднимем флаг чайного домика для гостей.';

  @override
  String get storyDogTrailTitle => 'Тропа знакомств';

  @override
  String get storyDogTrailChapter0 => 'Отметим дружелюбную тропу через двор.';

  @override
  String get storyDogTrailChapter1 => 'Оставим путникам свежую воду.';

  @override
  String get storyDogTrailChapter2 =>
      'Положим у финиша мяч для весёлой встречи.';

  @override
  String get storyDogBridgeTitle => 'Страж моста';

  @override
  String get storyDogBridgeChapter0 => 'Укрепим старый мост прочной верёвкой.';

  @override
  String get storyDogBridgeChapter1 => 'Повесим фонарь для туманных утр.';

  @override
  String get storyDogBridgeChapter2 => 'Заслужим золотой значок стража двора.';

  @override
  String get storyDogPicnicTitle => 'День пикника';

  @override
  String get storyDogPicnicChapter0 => 'Соберём корзину для всех друзей.';

  @override
  String get storyDogPicnicChapter1 => 'Выберем солнечное место для пледа.';

  @override
  String get storyDogPicnicChapter2 =>
      'Разделим угощение, когда все соберутся.';

  @override
  String get storyDogKiteTitle => 'Потерянный воздушный змей';

  @override
  String get storyDogKiteChapter0 =>
      'Заметив змея за холмами, отправимся в путь.';

  @override
  String get storyDogKiteChapter1 => 'Пойдём за ветром по компасу.';

  @override
  String get storyDogKiteChapter2 =>
      'Вернём змея домой и привяжем новую ленту.';

  @override
  String get storyDogFestivalTitle => 'Помощник праздника';

  @override
  String get storyDogFestivalChapter0 => 'Отнесём цветные флажки на площадь.';

  @override
  String get storyDogFestivalChapter1 => 'Поведём парад с маленьким барабаном.';

  @override
  String get storyDogFestivalChapter2 =>
      'Получим медаль за помощь всему двору.';

  @override
  String get storyRaccoonWorkshopTitle => 'Блестящая мастерская';

  @override
  String get storyRaccoonWorkshopChapter0 =>
      'Откроем ящик любопытных изобретений.';

  @override
  String get storyRaccoonWorkshopChapter1 =>
      'Соединим самые блестящие шестерёнки.';

  @override
  String get storyRaccoonWorkshopChapter2 =>
      'Соберём часы, которые звонят на закате.';

  @override
  String get storyRaccoonMarketTitle => 'Лунный рынок';

  @override
  String get storyRaccoonMarketChapter0 =>
      'Сплетём корзину для необычных находок.';

  @override
  String get storyRaccoonMarketChapter1 => 'Зажжём лавку под луной.';

  @override
  String get storyRaccoonMarketChapter2 =>
      'Обменяем три блестящие монеты на сюрприз.';

  @override
  String get storyRaccoonRiverTitle => 'Речное сокровище';

  @override
  String get storyRaccoonRiverChapter0 =>
      'Прочтём карту, спрятанную под камнем.';

  @override
  String get storyRaccoonRiverChapter1 => 'Починим лодочку для переправы.';

  @override
  String get storyRaccoonRiverChapter2 =>
      'Найдём поющую ракушку на дальнем берегу.';

  @override
  String get storyRaccoonRecycleTitle => 'Сад второй жизни';

  @override
  String get storyRaccoonRecycleChapter0 => 'Превратим старый ящик в клумбу.';

  @override
  String get storyRaccoonRecycleChapter1 => 'Починим помятую лейку.';

  @override
  String get storyRaccoonRecycleChapter2 =>
      'Соберём мельницу из забытых деталей.';

  @override
  String get storyRaccoonCafeTitle => 'Ночное кафе';

  @override
  String get storyRaccoonCafeChapter0 => 'Начистим кружку для первого гостя.';

  @override
  String get storyRaccoonCafeChapter1 => 'Испечём печенье в форме луны.';

  @override
  String get storyRaccoonCafeChapter2 =>
      'Повесим вывеску кафе до наступления ночи.';

  @override
  String get storyHamsterRailwayTitle => 'Крошечная железная дорога';

  @override
  String get storyHamsterRailwayChapter0 => 'Проложим рельсы вокруг цветника.';

  @override
  String get storyHamsterRailwayChapter1 =>
      'Соберём вагончик подходящего размера.';

  @override
  String get storyHamsterRailwayChapter2 =>
      'Откроем самую маленькую станцию двора.';

  @override
  String get storyHamsterPantryTitle => 'Большая кладовая';

  @override
  String get storyHamsterPantryChapter0 => 'Соберём мешочек семян на зиму.';

  @override
  String get storyHamsterPantryChapter1 => 'Построим полки из гладких веточек.';

  @override
  String get storyHamsterPantryChapter2 => 'Подпишем лучшую банку в кладовой.';

  @override
  String get storyHamsterCloudsTitle => 'Облачная обсерватория';

  @override
  String get storyHamsterCloudsChapter0 =>
      'Поднимем лестницу над высокой травой.';

  @override
  String get storyHamsterCloudsChapter1 => 'Направим телескоп между облаками.';

  @override
  String get storyHamsterCloudsChapter2 =>
      'Назовём новую звезду в честь двора.';

  @override
  String get storyHamsterGardenTitle => 'Миниатюрный сад';

  @override
  String get storyHamsterGardenChapter0 => 'Посадим сад в глиняном горшке.';

  @override
  String get storyHamsterGardenChapter1 =>
      'Поставим мостик над ручьём из камешков.';

  @override
  String get storyHamsterGardenChapter2 => 'Добавим домик-гриб для гостей.';

  @override
  String get storyHamsterBirthdayTitle => 'Парад ко дню рождения';

  @override
  String get storyHamsterBirthdayChapter0 =>
      'Сделаем самый маленький праздничный колпак.';

  @override
  String get storyHamsterBirthdayChapter1 => 'Испечём торт с тремя ягодами.';

  @override
  String get storyHamsterBirthdayChapter2 =>
      'Начнём парад под дождём конфетти.';

  @override
  String get storyFoxCozyTitle => 'Уютный уголок';

  @override
  String get storyFoxCozyChapter0 => 'Уберём листья в тихом уголке.';

  @override
  String get storyFoxCozyChapter1 =>
      'Принесём мягкую лежанку для дневного сна.';

  @override
  String get storyFoxCozyChapter2 =>
      'Выберем любимую игрушку и устроим настоящий дом.';

  @override
  String get storyFoxFirefliesTitle => 'Тропа светлячков';

  @override
  String get storyFoxFirefliesChapter0 => 'Поставим фонарь у края леса.';

  @override
  String get storyFoxFirefliesChapter1 => 'Посадим ночные цветы вдоль тропы.';

  @override
  String get storyFoxFirefliesChapter2 =>
      'Встретим мерцающее облако светлячков.';

  @override
  String get storyFoxPostTitle => 'Лесная почта';

  @override
  String get storyFoxPostChapter0 => 'Поставим красный ящик под дубом.';

  @override
  String get storyFoxPostChapter1 => 'Разберём письма для всех друзей двора.';

  @override
  String get storyFoxPostChapter2 => 'Отнесём первую почту в новой сумке.';

  @override
  String get storyFoxStudioTitle => 'Осенняя мастерская';

  @override
  String get storyFoxStudioChapter0 =>
      'Поставим мольберт среди золотых листьев.';

  @override
  String get storyFoxStudioChapter1 => 'Смешаем краски для осеннего портрета.';

  @override
  String get storyFoxStudioChapter2 => 'Оформим картину для дома во дворе.';

  @override
  String get storyFoxCampTitle => 'Лагерь под звёздами';

  @override
  String get storyFoxCampChapter0 => 'Поставим палатку под соснами.';

  @override
  String get storyFoxCampChapter1 => 'Разведём тёплый и безопасный костёр.';

  @override
  String get storyFoxCampChapter2 => 'Не уснём, чтобы увидеть падающую звезду.';

  @override
  String get petItemCushion => 'Подушка';

  @override
  String get petItemYarn => 'Клубок';

  @override
  String get petItemCurtain => 'Занавеска';

  @override
  String get petItemLantern => 'Фонарь';

  @override
  String get petItemBell => 'Колокольчик';

  @override
  String get petItemTelescope => 'Телескоп';

  @override
  String get petItemSeedling => 'Саженец';

  @override
  String get petItemButterflies => 'Бабочки';

  @override
  String get petItemFountain => 'Фонтан';

  @override
  String get petItemBooks => 'Книги';

  @override
  String get petItemBlanket => 'Плед';

  @override
  String get petItemLamp => 'Лампа';

  @override
  String get petItemTeacup => 'Чайный набор';

  @override
  String get petItemFlowers => 'Цветы';

  @override
  String get petItemBanner => 'Флаг';

  @override
  String get petItemSignpost => 'Указатель';

  @override
  String get petItemBowl => 'Миска';

  @override
  String get petItemBall => 'Мяч';

  @override
  String get petItemRope => 'Верёвка';

  @override
  String get petItemBadge => 'Значок';

  @override
  String get petItemBasket => 'Корзина';

  @override
  String get petItemTreats => 'Угощение';

  @override
  String get petItemKite => 'Воздушный змей';

  @override
  String get petItemCompass => 'Компас';

  @override
  String get petItemRibbon => 'Лента';

  @override
  String get petItemFlags => 'Флажки';

  @override
  String get petItemDrum => 'Барабан';

  @override
  String get petItemMedal => 'Медаль';

  @override
  String get petItemToolbox => 'Ящик инструментов';

  @override
  String get petItemGears => 'Шестерёнки';

  @override
  String get petItemClock => 'Часы';

  @override
  String get petItemCoins => 'Монеты';

  @override
  String get petItemMap => 'Карта';

  @override
  String get petItemBoat => 'Лодочка';

  @override
  String get petItemShell => 'Ракушка';

  @override
  String get petItemCrate => 'Ящик-клумба';

  @override
  String get petItemWateringCan => 'Лейка';

  @override
  String get petItemWindmill => 'Мельница';

  @override
  String get petItemMug => 'Кружка';

  @override
  String get petItemCookies => 'Печенье';

  @override
  String get petItemTracks => 'Рельсы';

  @override
  String get petItemCart => 'Вагончик';

  @override
  String get petItemStation => 'Станция';

  @override
  String get petItemSeedBag => 'Мешочек семян';

  @override
  String get petItemShelf => 'Полки';

  @override
  String get petItemJar => 'Банка';

  @override
  String get petItemLadder => 'Лестница';

  @override
  String get petItemStar => 'Новая звезда';

  @override
  String get petItemPot => 'Горшок';

  @override
  String get petItemBridge => 'Мостик';

  @override
  String get petItemMushroom => 'Домик-гриб';

  @override
  String get petItemHat => 'Колпак';

  @override
  String get petItemCake => 'Торт';

  @override
  String get petItemConfetti => 'Конфетти';

  @override
  String get petItemClearing => 'Тихое место';

  @override
  String get petItemBed => 'Лежанка';

  @override
  String get petItemToy => 'Игрушка';

  @override
  String get petItemFireflies => 'Светлячки';

  @override
  String get petItemMailbox => 'Почтовый ящик';

  @override
  String get petItemLetters => 'Письма';

  @override
  String get petItemSatchel => 'Почтовая сумка';

  @override
  String get petItemEasel => 'Мольберт';

  @override
  String get petItemPaints => 'Краски';

  @override
  String get petItemFrame => 'Рама';

  @override
  String get petItemTent => 'Палатка';

  @override
  String get petItemCampfire => 'Костёр';
}
