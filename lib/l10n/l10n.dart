import 'package:flutter/material.dart';

import '../models/levels.dart';

/// Manual bilingual strings. Locale comes from [Localizations.localeOf].
class L10n {
  const L10n(this.code);

  final String code;

  bool get isRu => code == 'ru';

  String pick(String en, String ru) => isRu ? ru : en;

  static L10n of(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode.toLowerCase();
    return L10n(lang == 'ru' ? 'ru' : 'en');
  }

  String get language => pick('Language', 'Язык');
  String get languageSystem => pick('System', 'Как в системе');
  String get languageEnglish => 'English';
  String get languageRussian => 'Русский';

  String get continueGame => pick('Continue', 'Продолжить');
  String continueLevel(int id) =>
      pick('Continue · Lv. $id', 'Продолжить · Ур. $id');

  String get courtyard => pick('Courtyard', 'К уровням');
  String get retry => pick('Retry', 'Заново');
  String get menu => pick('Menu', 'Меню');
  String get privacyPolicy => pick('Privacy policy', 'Политика конфиденциальности');
  String get aboutGame => pick('About game', 'Об игре');
  String get iconsBy => pick('Icons: Uicons by ', 'Иконки: Uicons от ');

  String get shuffle => pick('Shuffle', 'Перемешать');
  String get magnet => pick('Magnet', 'Магнит');
  String get hint => pick('Hint', 'Подсказка');
  String get undo => pick('Undo', 'Отмена');
  String get noneLeft => pick('none left', 'нет использований');
  String watchAd(String name) => pick('Watch ad → $name', 'Реклама → $name');

  String boostTooltip(String name, int left, {required bool adsAvailable}) {
    if (left > 0) return name;
    if (adsAvailable) return watchAd(name);
    return noneLeft;
  }

  String get tileBlocked => pick('Tile is blocked', 'Плитка заблокирована');
  String get trayIsFull => pick('Tray is full', 'Лоток полон');
  String get noMovesShuffle =>
      pick('No moves — shuffle', 'Нет ходов — перемешайте');
  String get shuffled => pick('Shuffled', 'Перемешано');
  String get stillNoMoves => pick('Still no moves', 'Всё ещё нет ходов');
  String get noFreeTiles => pick('No free tiles', 'Нет свободных плиток');
  String get noUsefulMoves => pick('No useful moves', 'Нет полезных ходов');
  String get noMatchingTiles =>
      pick('No matching tiles', 'Нет подходящих плиток');
  String get moveUndone => pick('Move undone', 'Ход отменён');
  String get victory => pick('Victory!', 'Победа!');
  String get loadingAd => pick('Loading ad…', 'Загрузка рекламы…');
  String get adUnavailable => pick('Ad unavailable', 'Реклама недоступна');
  String get rewardNotEarned =>
      pick('Watch the ad to claim the reward', 'Досмотрите ролик, чтобы получить награду');
  String get riskyFill =>
      pick('That would fill the tray with no pair', 'Ход забьёт лоток без пары');
  String get continuing => pick('Continuing', 'Продолжаем');

  String get trayFullTitle => pick('Tray is full', 'Лоток полон');
  String get noPairToMatch =>
      pick('No pair to match.', 'Нет пары для совпадения.');
  String scoreLabel(int score) => pick('Score: $score', 'Счёт: $score');
  String get watchToContinue =>
      pick('Watch ad to continue', 'Реклама — продолжить');

  String get levelsTitle => pick('Levels', 'Уровни');
  String starsOpen(int stars, int unlocked, int total) => pick(
    'Levels · $stars ★ · open $unlocked/$total',
    'Уровни · $stars ★ · открыто $unlocked/$total',
  );
  String bestScore(int score) => pick('Best: $score', 'Лучший: $score');

  String get easy => pick('Easy', 'Легко');
  String get normal => pick('Normal', 'Нормально');
  String get hard => pick('Hard', 'Сложно');
  String get expert => pick('Expert', 'Эксперт');

  String difficulty(LevelDef level) {
    final n = level.id;
    if (n <= 5) return easy;
    if (n <= 12) return normal;
    if (n <= 20) return hard;
    return expert;
  }

  String styleLabel(LevelDef level) {
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
      case 'mixed':
        return pick('Mix', 'Микс');
      default:
        return pick('Mix', 'Микс');
    }
  }

  String get simulatedAdTitle => pick('Sponsored pause', 'Пауза спонсора');
  String get simulatedAdBody => pick(
    'A real ad will play after the public release. Claim the reward when the timer ends.',
    'После публикации здесь будет настоящая реклама. Заберите награду, когда таймер закончится.',
  );
  String secondsLeft(int n) => pick('$n s', '$n с');
  String get claimReward => pick('Claim reward', 'Забрать награду');
  String get skip => pick('Close', 'Закрыть');
  String get close => pick('Close', 'Закрыть');
  String get map => pick('Map', 'Карта');
  String get next => pick('Next', 'Дальше');
  String get playAgain => pick('Play again', 'Ещё раз');
  String get newRecord => pick('New record!', 'Новый рекорд!');
  String get couldNotOpenLink =>
      pick('Could not open the link', 'Не удалось открыть ссылку');
  String get inProgress => pick('In progress', 'Партия начата');
  String levelCleared(int id) =>
      pick('Level $id cleared!', 'Уровень $id пройден!');
  String unlockedLevel(int id) =>
      pick('Level $id unlocked', 'Открыт уровень $id');
  String levelShort(int id) => pick('Lv. $id', 'Ур. $id');
  String levelN(int id) => pick('Level $id', 'Уровень $id');

  String get coachTapFree => pick(
    'Take only a free top tile',
    'Бери только верхнюю свободную плитку',
  );
  String get coachMatchPair => pick(
    'Two matching tiles in the tray clear',
    'Две одинаковые в лотке снимаются',
  );
  String get coachTrayLimit => pick(
    'The tray holds 4 — fill it with no pair and you lose',
    'Лоток на 4 — если забьётся без пары, партия проиграна',
  );

  String coachMessage(String stepName) => switch (stepName) {
    'tapFree' => coachTapFree,
    'matchPair' => coachMatchPair,
    _ => coachTrayLimit,
  };
}
