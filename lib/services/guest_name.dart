import 'dart:convert';
import 'dart:math';

/// Случайное имя для рейтинга, пока игрок не задал своё.
class GuestName {
  const GuestName._();

  /// Firestore `string.size()` в правилах — не больше этого (символы или UTF-8).
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

  /// Имя для Firestore: 1–20 единиц `size()`, иначе правила отклоняют запись.
  static String clamp(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Player';
    if (_fitsLimit(trimmed)) return trimmed;
    var result = trimmed;
    while (result.isNotEmpty && !_fitsLimit(result)) {
      result = result.substring(0, result.length - 1).trim();
    }
    return result.isEmpty ? 'Player' : result;
  }

  static bool _fitsLimit(String value) {
    return value.length <= maxLength && utf8.encode(value).length <= maxLength;
  }

  static String generate({required bool isRu, Random? random}) {
    final rng = random ?? Random();
    final adjectives = isRu ? _ruAdjectives : _enAdjectives;
    final nouns = isRu ? _ruNouns : _enNouns;
    final adjective = adjectives[rng.nextInt(adjectives.length)];
    final noun = nouns[rng.nextInt(nouns.length)];
    final number = rng.nextInt(90) + 10;
    final full = '$adjective $noun $number';
    if (_fitsLimit(full)) return full;
    final short = '$noun $number';
    if (_fitsLimit(short)) return short;
    return clamp(short);
  }
}
