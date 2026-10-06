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

  static const _ukAdjectives = [
    'Тихий',
    'Ясний',
    'Сміливий',
    'Швидкий',
    'Золотий',
    'Місячний',
    'Гірський',
    'Річковий',
    'Теплий',
    'Лагідний',
  ];

  static const _ukNouns = [
    'Короп',
    'Лисиця',
    'Журавель',
    'Лотос',
    'Сосна',
    'Вітер',
    'Пік',
    'Ліхтар',
    'Сад',
    'Дракон',
  ];

  /// Short words so adjective + noun + number stays within the UTF-8 name limit.
  static const _thAdjectives = [
    'ทอง',
    'ขาว',
    'แดง',
    'ดี',
    'สด',
    'สูง',
    'มืด',
    'อุ่น',
  ];

  static const _thNouns = [
    'ลม',
    'นก',
    'ดาว',
    'บัว',
    'ปลา',
    'แมว',
    'สวน',
    'ไผ่',
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

  static String generate({
    bool isRu = false,
    String language = '',
    Random? random,
  }) {
    final rng = random ?? Random();
    final lang = language.isNotEmpty ? language : (isRu ? 'ru' : 'en');
    final adjectives = switch (lang) {
      'ru' => _ruAdjectives,
      'uk' => _ukAdjectives,
      'th' => _thAdjectives,
      _ => _enAdjectives,
    };
    final nouns = switch (lang) {
      'ru' => _ruNouns,
      'uk' => _ukNouns,
      'th' => _thNouns,
      _ => _enNouns,
    };
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
