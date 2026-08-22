import 'package:flutter/widgets.dart';

import '../models/levels.dart';
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
  String plot(int cycle) => pick('Plot ${cycle + 1}', 'Участок ${cycle + 1}');

  String get today => pick('Today', 'Сегодня');
  String get clearedToday => pick('Cleared today', 'День закрыт');
  String streak(int n) => pick('Streak $n', 'Серия $n');
  String get newTableEveryDay =>
      pick('A new table every day', 'Новый стол каждый день');

  String openedProgress(int unlocked, int total) =>
      pick('$unlocked/$total open', 'открыто $unlocked/$total');

  String get courtyard => pick('Courtyard', 'Во двор');
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
  String get iconsBy => pick('Icons: Uicons by ', 'Иконки: Uicons от ');

  String get settings => pick('Settings', 'Настройки');
  String get sound => pick('Sound', 'Звук');
  String get hapticFeedback => pick('Haptic feedback', 'Тактильный отклик');
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
  String levelCleared(int id) =>
      pick('Level $id cleared!', 'Уровень $id пройден!');
  String get newBest => pick('New best!', 'Новый рекорд!');
  String levelUnlocked(int id) =>
      pick('Level $id unlocked', 'Открыт уровень $id');

  String get shuffle => pick('Shuffle', 'Перемешать');
  String get magnet => pick('Magnet', 'Магнит');
  String get hint => pick('Hint', 'Подсказка');
  String get undo => pick('Undo', 'Отмена');
  String watchAd(String name) => pick('Watch ad → $name', 'Реклама → $name');
  String boostEarned(String name) => pick('+1 $name', '+1 $name');
  String get noneLeft => pick('none left', 'нет использований');

  String boostTooltip(String name, int left, {required bool adsAvailable}) {
    if (left > 0) return name;
    if (adsAvailable) return watchAd(name);
    return noneLeft;
  }

  String get coachTapFree =>
      pick('Take only a free top tile', 'Бери только верхнюю плитку');
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

  String levelTitle(LevelDef level) {
    if (level.title == 'Today') return today;
    return storyTitle(level.storyId);
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

  String get firstHomePhrase => pick(
    'This house grows as you play.',
    'Этот дом растёт, пока ты играешь.',
  );

  List<String> get pathStagePhrases => isRu
      ? const [
          'Здесь будет дом.',
          'Забор держит участок.',
          'Стены уже свои.',
          'Крыша легла.',
          'В окнах можно жить.',
          'Дом собрался из пройденного.',
        ]
      : const [
          'A house will stand here.',
          'The fence holds the plot.',
          'The walls are yours.',
          'The roof is on.',
          'The windows are ready.',
          'The house rose from your wins.',
        ];

  List<String> get pathWarmPhrases => isRu
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

  String get pathLifePhrase =>
      pick('The house feels warmer.', 'В доме стало теплее.');

  String homePathPhrase(CourtyardSnapshot snapshot) {
    final band = snapshot.band;
    if (band <= 0) return pathStagePhrases.first;
    return pathStagePhrases[band - 1];
  }

  String winPathPhrase({
    required CourtyardSnapshot from,
    required CourtyardSnapshot to,
  }) {
    final fromBand = from.band;
    final toBand = to.band;
    if (toBand > fromBand && toBand > 0) {
      return pathStagePhrases[toBand - 1];
    }
    if (to.step > from.step + 0.01) {
      return pathWarmPhrases[to.step.floor() % pathWarmPhrases.length];
    }
    if (to.totalStars > from.totalStars) return pathLifePhrase;
    return pathWarmPhrases.first;
  }
}
