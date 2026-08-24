import 'dart:math';

/// Случайное имя для рейтинга, пока игрок не задал своё.
class GuestName {
  const GuestName._();

  static const maxLength = 20;

  static const _enAdjectives = [
    'Jade',
    'Gold',
    'Lucky',
    'Silent',
    'Swift',
    'Mist',
    'Calm',
    'Bold',
    'Amber',
    'Ivory',
  ];

  static const _enNouns = [
    'Koi',
    'Fox',
    'Crane',
    'Lotus',
    'Pine',
    'Wind',
    'Peak',
    'Lantern',
    'Garden',
    'Dragon',
  ];

  static const _ruAdjectives = [
    'Тихий',
    'Алый',
    'Ясный',
    'Смелый',
    'Быстрый',
    'Золотой',
    'Удачный',
    'Лунный',
    'Горный',
    'Речной',
  ];

  static const _ruNouns = [
    'Карп',
    'Лиса',
    'Журавль',
    'Лотос',
    'Сосна',
    'Ветер',
    'Пик',
    'Фонарь',
    'Сад',
    'Дракон',
  ];

  static String generate({required bool isRu, Random? random}) {
    final rng = random ?? Random();
    final adjectives = isRu ? _ruAdjectives : _enAdjectives;
    final nouns = isRu ? _ruNouns : _enNouns;
    final adjective = adjectives[rng.nextInt(adjectives.length)];
    final noun = nouns[rng.nextInt(nouns.length)];
    final number = rng.nextInt(90) + 10;
    final full = '$adjective $noun $number';
    if (full.length <= maxLength) return full;
    final short = '$noun $number';
    if (short.length <= maxLength) return short;
    return short.substring(0, maxLength);
  }
}
