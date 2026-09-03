import 'package:flutter/widgets.dart';

import '../models/levels.dart';
import '../models/pet.dart';
import '../models/plot_kind.dart';
import '../widgets/courtyard/courtyard_lot_build.dart';
import '../widgets/courtyard/courtyard_progress.dart';

/// UI strings: Russian only when [code] is `ru`, otherwise English.
class L10n {
  const L10n(this.code);

  final String code;

  bool get isRu => code == 'ru';

  String pick(String en, String ru) => isRu ? ru : en;

  static L10n of(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    return L10n(lang == 'ru' ? 'ru' : 'en');
  }

  String get continueGame => pick('Continue', 'Продолжить');
  String continueWith(String title) =>
      pick('Continue · $title', 'Продолжить · $title');

  String get newPlot => pick('New plot', 'Новый участок');
  String get previousPlot => pick('Previous plot', 'Предыдущий участок');
  String get nextPlot => pick('Next plot', 'Следующий участок');
  String get plotLockedHint => pick(
    'Next wins will grow this plot',
    'Следующие победы будут строить этот участок',
  );
  String neighborYard(String name) => pick("$name's courtyard", 'Двор: $name');
  String neighborRating(String name, int rating) =>
      pick('$name · $rating', '$name · $rating');
  String get neighboringCourtyard =>
      pick('A neighboring courtyard', 'Соседский двор');
  String get courtyardPanHint => pick(
    'Drag to look around the courtyard',
    'Потяните, чтобы осмотреть двор',
  );
  String plot(int cycle) => plotTitle(PlotKind.ofCycle(cycle));

  String plotTitle(PlotKind kind) => isRu ? kind.titleRu : kind.titleEn;

  String plotEra(PlotKind kind, int era) => isRu
      ? CourtyardLotBuild.eraNameRu(kind, era)
      : CourtyardLotBuild.eraNameEn(kind, era);

  String plotLookProgress(PlotKind kind, int remaining) {
    final name = plotTitle(kind);
    if (remaining <= 0) {
      return pick('$name is complete', '$name собран');
    }
    if (remaining == 1) {
      return pick(
        '1 level until the next $name look',
        '1 уровень до следующего вида: $name',
      );
    }
    return pick(
      '$remaining levels until the next $name look',
      '$remaining ур. до следующего вида: $name',
    );
  }

  String get today => pick('Today', 'Сегодня');
  String get clearedToday => pick('Cleared today', 'День закрыт');
  String streakNights(int n) => pick('Day $n of 3', 'День $n из 3');
  String get streakKept => pick('Three nights kept', 'Серия сохранена');
  String get streakAtRisk => pick('Goes out at midnight', 'Сгорит в полночь');
  String get keepTheLight => pick('Keep the light', 'Сохрани свет');

  String streakWinSubtitle(int n) {
    if (n <= 0) return streakLabel(0);
    if (n < 3) return streakNights(n);
    if (n == 3) return streakKept;
    return streakLabel(n);
  }

  String dailyStreakSubtitle({
    required int streak,
    required bool completedToday,
  }) {
    if (completedToday) {
      if (streak >= 3) return streakKept;
      if (streak > 0) return streakNights(streak);
      return clearedToday;
    }
    if (streak > 0) return streakAtRisk;
    return keepTheLight;
  }

  String openedProgress(int unlocked, int total) =>
      pick('$unlocked/$total open', 'открыто $unlocked/$total');

  String get courtyard => pick('Courtyard', 'Во двор');
  String get howToPlay => pick('How to play', 'Как играть');
  String get levels => pick('Levels', 'Уровни');
  String get retry => pick('Retry', 'Заново');
  String get playAgain => pick('Play again', 'Ещё раз');
  String get next => pick('Next', 'Дальше');
  String get menu => pick('Menu', 'Меню');
  String get close => pick('Close', 'Закрыть');
  String get cancel => pick('Cancel', 'Отмена');
  String get save => pick('Save', 'Сохранить');
  String get back => pick('Back', 'Назад');
  String get privacyPolicy =>
      pick('Privacy Policy', 'Политика конфиденциальности');
  String get aboutGame => pick('About game', 'О игре');
  String builtAt(String time) => pick('Built: $time', 'Сборка: $time');

  String get settings => pick('Settings', 'Настройки');
  String get sound => pick('Sound', 'Звук');
  String get music => pick('Music', 'Музыка');
  String get hapticFeedback => pick('Haptic feedback', 'Тактильный отклик');
  String get qMode => pick('Q mode', 'Режим Q');
  String get qModeHint =>
      pick('Magnet ads grant 50', 'Реклама на магните даёт 50');
  String get dimCoveredTiles => pick('Dim covered tiles', 'Затемнять закрытые');
  String get dimCoveredTilesHint => pick(
    'Gray out tiles you cannot pick',
    'Серым — плитки, которые нельзя взять',
  );
  String get language => pick('Language', 'Язык');
  String get languageSystem => pick('System', 'Как в системе');
  String get languageEnglish => 'English';
  String get languageRussian => 'Русский';

  String get tileLocked => pick('Tile is locked', 'Плитка заблокирована');
  String get trayFull => pick('Tray is full', 'Лоток полон');
  String get trayFullHint =>
      pick('No matching pair.', 'Нет пары для совпадения.');
  String get noMovesShuffle =>
      pick('No moves — shuffle', 'Нет ходов — перемешайте');
  String get youWin => pick('You win!', 'Победа!');
  String get noFreeTiles => pick('No free tiles', 'Нет открытых плиток');
  String get shuffled => pick('Shuffled', 'Перемешано');
  String get stillNoMoves => pick('Still no moves', 'Всё ещё нет ходов');
  String get loadingAd => pick('Loading ad…', 'Загрузка рекламы…');
  String get rewardNotEarned =>
      pick('Reward not earned', 'Награда не получена');
  String get adUnavailable => pick('Ad unavailable', 'Реклама недоступна');
  String get noUsefulMoves => pick('No useful moves', 'Нет полезных ходов');
  String get continuing => pick('Continuing', 'Продолжаем');
  String get moveUndone => pick('Move undone', 'Ход отменён');
  String get noMatchingTiles =>
      pick('No matching tiles', 'Нет подходящих плиток');
  String get couldNotOpenLink =>
      pick('Could not open link', 'Не удалось открыть ссылку');

  String get dailyComplete => pick('Daily complete', 'Сегодня сыграно');
  String streakLabel(int n) => pick('Streak: $n', 'Серия: $n');
  String score(int value) => pick('Score: $value', 'Счёт: $value');
  String get dailyBonus =>
      pick('Bonus: +1 hint and shuffle', 'Запас: +1 подсказка и перемешивание');

  String level(int id) => pick('Level $id', 'Уровень $id');
  String get anotherLevelCleared =>
      pick('Another level cleared', 'Ещё один уровень пройден');
  String get newBest => pick('New best!', 'Новый рекорд!');
  String levelUnlocked(int id) =>
      pick('Level $id unlocked', 'Открыт уровень $id');

  String get shuffle => pick('Shuffle', 'Перемешать');
  String get magnet => pick('Magnet', 'Магнит');
  String get hint => pick('Hint', 'Подсказка');
  String get undo => pick('Undo', 'Отмена');
  String watchAd(String name) => pick('Watch ad → $name', 'Реклама → $name');
  String boostEarned(String name, {int count = 1}) =>
      pick('+$count $name', '+$count $name');
  String get noneLeft => pick('none left', 'нет использований');

  String boostTooltip(String name, int left, {required bool adsAvailable}) {
    if (left > 0) return name;
    if (adsAvailable) return watchAd(name);
    return noneLeft;
  }

  String get coachTapFree => pick(
    'Take a free tile — open on top and one side',
    'Бери свободную: сверху и сбоку открыта',
  );
  String get coachMatchPair =>
      pick('A pair in the tray clears', 'Пара в лотке снимается');
  String get coachTrayLimit => pick(
    'The tray holds 4 — fill it with no pair and you lose',
    'Лоток на 4 — если забьётся, партия проиграна',
  );

  String coachMessage(String stepName) => switch (stepName) {
    'tapFree' => coachTapFree,
    'matchPair' => coachMatchPair,
    _ => coachTrayLimit,
  };

  String get easy => pick('Easy', 'Легко');
  String get normal => pick('Normal', 'Нормально');
  String get hard => pick('Hard', 'Сложно');
  String get expert => pick('Expert', 'Эксперт');

  String difficulty(LevelDef level) {
    final n = level.storyId;
    if (n <= 5) return easy;
    if (n <= 12) return normal;
    if (n <= 20) return hard;
    return expert;
  }

  String style(LevelDef level) {
    switch (level.style) {
      case 'fruit':
        return pick('Fruit', 'Фрукты');
      case 'nature':
        return pick('Nature', 'Природа');
      case 'court':
        return pick('Court', 'Двор');
      case 'myth':
        return pick('Myth', 'Миф');
      case 'classic':
        return pick('Classic', 'Классика');
      case 'shape':
        return pick('Shapes', 'Фигуры');
      case 'number':
        return pick('Numbers', 'Цифры');
      default:
        return pick('Mix', 'Микс');
    }
  }

  String levelTitle(LevelDef level, {PlotKind? plotKind}) {
    if (level.title == 'Today') return today;
    final kind = plotKind ?? level.plotKind;
    return isRu ? kind.titleRu : kind.titleEn;
  }

  String storyTitle(int storyId) {
    const en = [
      'Sprout',
      'Bud',
      'Bloom',
      'Glade',
      'Lawn',
      'Grove',
      'Wave',
      'Stream',
      'Garden',
      'Gazebo',
      'Fan',
      'Peacock Fan',
      'Lotus',
      'Pond',
      'Carp',
      'Lake',
      'Vine',
      'Ivy',
      'Festival',
      'Lanterns',
      'Pavilion',
      'Wind Temple',
      'Dragon',
      'Sky Dragon',
    ];
    const ru = [
      'Росток',
      'Бутон',
      'Цветение',
      'Поляна',
      'Лужайка',
      'Рощица',
      'Волна',
      'Ручей',
      'Сад',
      'Беседка',
      'Веер',
      'Павлиний веер',
      'Лотос',
      'Пруд',
      'Карпы',
      'Озеро',
      'Лоза',
      'Плющ',
      'Праздник',
      'Фонари',
      'Павильон',
      'Храм ветров',
      'Дракон',
      'Небесный дракон',
    ];
    final i = (storyId - 1).clamp(0, 23);
    return isRu ? ru[i] : en[i];
  }

  String displayName(String raw) {
    if (raw.isEmpty || raw == 'You' || raw == 'Вы') return you;
    if (raw == 'Player' || raw == 'Игрок') return player;
    return raw;
  }

  String get you => pick('You', 'Вы');
  String get player => pick('Player', 'Игрок');
  String get yourName => pick('Your name', 'Ваше имя');
  String get leaderboard => pick('Leaderboard', 'Общий рейтинг');
  String get refresh => pick('Refresh', 'Обновить');
  String get changeName => pick('Change name', 'Изменить имя');
  String get name => pick('Name', 'Имя');
  String onlineRanking(int top) =>
      pick('Online ranking · top $top', 'Онлайн-рейтинг · топ $top');
  String get offlineRanking => pick(
    'Offline: only your result is shown.',
    'Офлайн-режим: показан только ваш результат.',
  );
  String get rankingFormula => pick(
    'Rating: stars × 100,000 + best scores + campaign progress.',
    'Рейтинг: звёзды × 100 000 + лучшие счёта + прогресс кампании.',
  );
  String get scorePlotsLegend => pick('Score : plots', 'Баллы : участки');
  String get loadRankingFailed => pick(
    'Could not load the online ranking',
    'Не удалось загрузить онлайн-рейтинг',
  );
  String starsLevel(int stars, int unlocked) =>
      pick('$stars ★ · lv. $unlocked', '$stars ★ · ур. $unlocked');

  String get ad => pick('AD', 'РЕКЛАМА');
  String get done => pick('Done', 'Готово');
  String get closeWithoutReward =>
      pick('Close without reward', 'Закрыть без награды');
  String get simulatedAd => pick('Simulated ad', 'Имитация рекламы');
  String get watchClipForBoost => pick(
    'Watch the clip to earn a boost',
    'Досмотрите ролик, чтобы получить буст',
  );
  String get claimReward => pick('Claim reward', 'Получить награду');
  String get watchingAd => pick('Watching ad…', 'Смотрите рекламу…');

  String firstHomePhraseFor(PlotKind kind) => switch (kind) {
    PlotKind.house => pick(
      'This house grows as you play.',
      'Этот дом растёт, пока ты играешь.',
    ),
    PlotKind.pond => pick(
      'This pond fills as you play.',
      'Этот ставок наполняется, пока ты играешь.',
    ),
    PlotKind.pets => pick(
      'This pet house grows as you play.',
      'Этот домик питомца растёт, пока ты играешь.',
    ),
    PlotKind.guest => pick(
      'This yard comes online as you play.',
      'Этот двор выходит в сеть, пока ты играешь.',
    ),
  };

  String get firstHomePhrase => firstHomePhraseFor(PlotKind.house);

  List<String> pathStagePhrasesFor(PlotKind kind) =>
      eraPhrasesFor(kind, ru: isRu);

  List<String> get pathStagePhrases => pathStagePhrasesFor(PlotKind.house);

  List<String> pathWarmPhrasesFor(PlotKind kind) {
    switch (kind) {
      case PlotKind.pond:
        return isRu
            ? const [
                'Вода поднялась чуть.',
                'Ставок стал своим.',
                'Берега ближе.',
              ]
            : pondWarmPhrases;
      case PlotKind.pets:
        return isRu
            ? const [
                'Домик чуть уютнее.',
                'Питомцам просторнее.',
                'Двор стал своим.',
              ]
            : petsWarmPhrases;
      case PlotKind.guest:
        return isRu
            ? const ['Сигнал чуть сильнее.', 'Двор связаннее.', 'Линия ближе.']
            : guestWarmPhrases;
      case PlotKind.house:
        return isRu
            ? const [
                'Ещё один шаг по тропе.',
                'Участок стал своим.',
                'Дом чуть ближе.',
              ]
            : const [
                'Another step along the path.',
                'The plot is yours now.',
                'The house is a little closer.',
              ];
    }
  }

  List<String> get pathWarmPhrases => pathWarmPhrasesFor(PlotKind.house);

  String pathLifePhraseFor(PlotKind kind) => switch (kind) {
    PlotKind.house => pick('The house feels warmer.', 'В доме стало теплее.'),
    PlotKind.pond => pick('The pond feels alive.', 'Ставок ожил.'),
    PlotKind.pets => pick(
      'The pet house feels warmer.',
      'В домике стало теплее.',
    ),
    PlotKind.guest => pick('The yard hums a little.', 'Двор чуть гудит.'),
  };

  String get pathLifePhrase => pathLifePhraseFor(PlotKind.house);

  String get weeklyQuests => pick('Weekly quests', 'Задания недели');
  String get claim => pick('Claim', 'Забрать');
  String get claimed => pick('Claimed', 'Получено');
  String get questBonus =>
      pick('+1 hint and shuffle', '+1 подсказка и перемешивание');
  String questTitle(String id) => switch (id) {
    'daily3' => pick('Clear daily 3 times', 'Закройте daily 3 раза'),
    'stars8' => pick('Earn 8 stars', 'Наберите 8 звёзд'),
    'clears4' => pick('Clear 4 campaign levels', 'Пройдите 4 уровня кампании'),
    'threeStar1' => pick('Score 3★ on a level', 'Возьмите 3★ на уровне'),
    'streak3' => pick('Keep three nights lit', 'Три вечера света'),
    _ => id,
  };
  String weekEventTitle(String id) => switch (id) {
    'garden' => pick('Garden week', 'Неделя сада'),
    'court' => pick('Courtyard week', 'Неделя двора'),
    'lanterns' => pick('Lantern week', 'Неделя фонарей'),
    'myth' => pick('Myth week', 'Неделя мифа'),
    'harvest' => pick('Harvest week', 'Неделя урожая'),
    _ => pick('This week’s table', 'Стол этой недели'),
  };
  String get extraBoostThisWeek =>
      pick('+1 boost on today’s table', '+1 буст на столе сегодня');
  String get seasonClosed => pick('Season closed', 'Сезон закрыт');
  String lastWeekPlace(int rank) =>
      pick('Last week: place $rank', 'Прошлая неделя: место $rank');
  String lastWeekScore(String rating) => pick('Score $rating', 'Счёт $rating');
  String get reminders => pick('Daily reminders', 'Напоминания');
  String get reminderDailyTitle =>
      pick('Your courtyard is waiting', 'Двор ждёт вас');
  String get reminderDailyBody =>
      pick('A new table is ready today.', 'Сегодня готов новый стол.');
  String get reminderStreakTitle =>
      pick('Your streak is at risk', 'Серия сейчас сгорит');
  String get reminderStreakBody => pick(
    'The third lantern goes out at midnight.',
    'Третий фонарь погаснет в полночь.',
  );
  String get reminderWeekTitle =>
      pick('A new courtyard season', 'Новый сезон двора');
  String get reminderWeekBody => pick(
    'Weekly quests and ranking have reset.',
    'Задания и рейтинг недели обновились.',
  );

  String get pet => pick('Pet', 'Питомец');
  String get pets => pick('Pets', 'Питомцы');
  String petsTitle(int count) => count > 1 ? pets : pet;
  String get chooseAPet => pick('Choose a companion', 'Выберите питомца');
  String get addPet => pick('Add a companion', 'Добавить питомца');
  String get petInviteAdopt => pick('A friend is waiting', 'Друг ждёт тебя');
  String get petInviteShow => pick('Show pets', 'Показать питомцев');
  String get petCareHint => pick(
    'Clear a table to help whoever needs you most.',
    'Пройдите уровень — помощь тому, кому сейчас нужнее.',
  );
  String get petStarvingLine => pick(
    'They are starving. Clear a table to feed them.',
    'Голодает. Пройдите уровень, чтобы покормить.',
  );
  String get petRemindersPromptTitle =>
      pick('Hungry reminders?', 'Напомнить о голоде?');
  String get petRemindersPromptBody => pick(
    'We can ping you when they get hungry.',
    'Можем напомнить, когда питомец проголодается.',
  );
  String get petRemindersYes => pick('Remind me', 'Напомнить');
  String get petRemindersLater => pick('Not now', 'Не сейчас');

  String petName(PetKind kind) => switch (kind) {
    PetKind.cat => pick('Cat', 'Кот'),
    PetKind.dog => pick('Dog', 'Собака'),
    PetKind.raccoon => pick('Raccoon', 'Енот'),
    PetKind.hamster => pick('Hamster', 'Хомяк'),
    PetKind.fox => pick('Fox', 'Лисица'),
  };

  String petNeedLabel(PetNeed need) => switch (need) {
    PetNeed.hunger => pick('Hunger', 'Голод'),
    PetNeed.play => pick('Play', 'Игра'),
    PetNeed.rest => pick('Rest', 'Отдых'),
  };

  String petMoodLine(PetKind kind, PetMood mood) {
    final name = petName(kind);
    return switch (mood) {
      PetMood.content => pick('$name is content.', '$name в порядке.'),
      PetMood.asking => pick('$name needs you.', '$name просит внимания.'),
      PetMood.starving => pick('$name is starving.', '$name голодает.'),
    };
  }

  String petCareWinLine(PetKind kind, PetNeed need) {
    final name = petName(kind);
    return switch (need) {
      PetNeed.hunger => pick('You fed $name.', 'Вы покормили $name.'),
      PetNeed.play => pick('You played with $name.', 'Вы поиграли с $name.'),
      PetNeed.rest => pick('$name rested.', 'Вы дали $name отдохнуть.'),
    };
  }

  String reminderPetHungerTitle(String name) =>
      pick('$name is hungry', '$name хочет есть');
  String get reminderPetHungerBody =>
      pick('Clear a table to feed them.', 'Пройдите уровень, чтобы покормить.');
  String reminderPetPlayTitle(String name) =>
      pick('$name wants to play', '$name хочет играть');
  String get reminderPetPlayBody => pick(
    'Clear a table to play with them.',
    'Пройдите уровень, чтобы поиграть.',
  );
  String reminderPetRestTitle(String name) =>
      pick('$name wants to rest', '$name хочет отдохнуть');
  String get reminderPetRestBody => pick(
    'Clear a table so they can rest.',
    'Пройдите уровень — питомцу нужен отдых.',
  );
  String reminderPetStarveTitle(String name) =>
      pick('$name is starving', '$name голодает');
  String get reminderPetStarveBody =>
      pick('Clear a table to feed them.', 'Пройдите стол, чтобы покормить.');

  String homePathPhrase(CourtyardSnapshot snapshot, {double? stage}) {
    final phrases = pathStagePhrasesFor(snapshot.plotKind);
    final era = CourtyardLotBuild.eraIndex(stage ?? snapshot.step);
    return phrases[era];
  }

  String winPathPhrase({
    required CourtyardSnapshot from,
    required CourtyardSnapshot to,
    double? fromStage,
    double? toStage,
  }) {
    final phrases = pathStagePhrasesFor(to.plotKind);
    final warm = pathWarmPhrasesFor(to.plotKind);
    final a = fromStage ?? from.step;
    final b = toStage ?? to.step;
    final fromEra = CourtyardLotBuild.eraIndex(a);
    final toEra = CourtyardLotBuild.eraIndex(b);
    if (toEra > fromEra) return phrases[toEra];
    if (b > a + 0.01) {
      return warm[b.floor() % warm.length];
    }
    if (to.totalStars > from.totalStars) {
      return pathLifePhraseFor(to.plotKind);
    }
    if (to.streakLife > from.streakLife + 0.01 ||
        to.festival > from.festival + 0.01) {
      return pathLifePhraseFor(to.plotKind);
    }
    return warm.first;
  }

  String get boardSemantic => pick('Board', 'Поле');

  String traySemantic(int filled, int capacity) =>
      pick('Tray, $filled of $capacity', 'Лоток, $filled из $capacity');

  String get trayEmptySlot => pick('Empty slot', 'Пустой слот');

  String courtyardSemantic(int cycle) =>
      courtyardSemanticKind(PlotKind.ofCycle(cycle));

  String courtyardSemanticKind(PlotKind kind) =>
      pick('${plotTitle(kind)} courtyard', 'Двор: ${plotTitle(kind)}');

  String petsButtonSemantic({required bool asking}) {
    if (asking) return pick('Pets, need care', 'Питомцы, нужна забота');
    return pets;
  }

  String dailyButtonSemantic({
    required int streak,
    required bool completedToday,
  }) {
    final status = dailyStreakSubtitle(
      streak: streak,
      completedToday: completedToday,
    );
    return '$today. $status';
  }

  String levelCardSemantic({
    required int localId,
    required String title,
    required bool unlocked,
    required int stars,
    required bool inProgress,
  }) {
    if (!unlocked) {
      return pick('Level $localId, locked', 'Уровень $localId, закрыт');
    }
    final star = stars == 0
        ? pick('no stars', 'без звёзд')
        : pick('$stars stars', '$stars ★');
    final progress = inProgress ? pick(', in progress', ', партия начата') : '';
    return pick(
      'Level $localId, $title, $star$progress',
      'Уровень $localId, $title, $star$progress',
    );
  }

  String boostSemantic(String name, int left, {required bool adsAvailable}) {
    if (left > 0) {
      return pick('$name, $left left', '$name, осталось $left');
    }
    if (adsAvailable) return watchAd(name);
    return pick('$name, none left', '$name, нет использований');
  }

  String tileFamilyName(String family) {
    switch (family) {
      case 'fruit':
        return pick('Fruit', 'Фрукт');
      case 'flower':
        return pick('Flower', 'Цветок');
      case 'animal':
        return pick('Animal', 'Животное');
      case 'bamboo':
        return pick('Bamboo', 'Бамбук');
      case 'character':
        return pick('Character', 'Иероглиф');
      case 'dot':
      case 'dots':
        return pick('Dot', 'Точка');
      case 'dragon':
        return pick('Dragon', 'Дракон');
      case 'wind':
        return pick('Wind', 'Ветер');
      case 'season':
        return pick('Season', 'Сезон');
      case 'number':
        return pick('Number', 'Цифра');
      case 'shape':
        return pick('Shape', 'Фигура');
      case 'soft':
      case 'tile':
        return pick('Tile', 'Плитка');
      case 'art':
        return pick('Art', 'Узор');
      case 'clown':
        return pick('Clown', 'Клоун');
      case 'emperor':
        return pick('Emperor', 'Император');
      case 'joker':
        return pick('Joker', 'Джокер');
      case 'profession':
        return pick('Profession', 'Профессия');
      case 'queen':
        return pick('Queen', 'Королева');
      case 'east':
        return pick('East', 'Восток');
      case 'south':
        return pick('South', 'Юг');
      case 'west':
        return pick('West', 'Запад');
      case 'north':
        return pick('North', 'Север');
      case 'spring':
        return pick('Spring', 'Весна');
      case 'summer':
        return pick('Summer', 'Лето');
      case 'fall':
      case 'autumn':
        return pick('Autumn', 'Осень');
      case 'winter':
        return pick('Winter', 'Зима');
      default:
        if (family.isEmpty) return family;
        return '${family[0].toUpperCase()}${family.substring(1)}';
    }
  }

  String tileSymbolName(String symbol) {
    var s = symbol.toLowerCase().trim();
    if (s.startsWith('set1-')) s = s.substring(5);
    switch (s) {
      case 'wind-east':
        return pick('East wind', 'Восточный ветер');
      case 'wind-south':
        return pick('South wind', 'Южный ветер');
      case 'wind-west':
        return pick('West wind', 'Западный ветер');
      case 'wind-north':
        return pick('North wind', 'Северный ветер');
    }
    final parts = s
        .split(RegExp(r'[-_/]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return symbol;
    final family = tileFamilyName(parts.first);
    if (parts.length == 1) return family;
    final rest = parts
        .skip(1)
        .map((part) {
          final n = int.tryParse(part);
          if (n != null) return '$n';
          return tileFamilyName(part);
        })
        .join(' ');
    return '$family $rest';
  }

  String tileSemanticLabel({
    required String symbol,
    required bool free,
    required bool hinted,
    required bool inTray,
    required bool removing,
  }) {
    final name = tileSymbolName(symbol);
    if (removing) {
      return pick('$name, matching', '$name, снятие пары');
    }
    if (inTray) {
      return hinted
          ? pick('$name in tray, hinted', '$name в лотке, подсказка')
          : pick('$name in tray', '$name в лотке');
    }
    final state = free ? pick('free', 'свободна') : pick('locked', 'закрыта');
    if (hinted) {
      return pick('$name, $state, hinted', '$name, $state, подсказка');
    }
    return '$name, $state';
  }
}
