/// Client-side filter for public leaderboard nicknames.
abstract final class DisplayNameFilter {
  static const _shortWords = {
    'ass',
    'cock',
    'cunt',
    'dick',
    'slut',
    'porn',
    'nazi',
  };

  static const _stems = [
    'fuck',
    'shit',
    'bitch',
    'nigger',
    'nigga',
    'faggot',
    'retard',
    'whore',
    'pussy',
    'asshole',
    'hitler',
    'rape',
    'хуе',
    'хуё',
    'хуя',
    'хуй',
    'пизд',
    'ебан',
    'ебат',
    'ебл',
    'бля',
    'сука',
    'мудак',
    'мудил',
    'пидор',
    'педик',
    'нигер',
    'наци',
    'порн',
    'изнасил',
    'залуп',
    'дроч',
    'мраз',
  ];

  static bool isAllowed(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return true;
    final compact = _compact(trimmed);
    for (final stem in _stems) {
      if (compact.contains(_compact(stem))) return false;
    }
    for (final word in _tokens(trimmed)) {
      if (_shortWords.contains(word)) return false;
    }
    return true;
  }

  /// Visible label: blocked language becomes a generic player tag.
  static String publicName(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty || !isAllowed(trimmed)) return 'Player';
    return trimmed;
  }

  static String _compact(String raw) {
    final lower = raw.toLowerCase().replaceAll('ё', 'е');
    final buffer = StringBuffer();
    String? last;
    var repeat = 0;
    for (final rune in lower.runes) {
      var ch = String.fromCharCode(rune);
      ch = switch (ch) {
        '@' || '4' => 'a',
        '0' => 'o',
        '1' || '!' => 'i',
        '3' => 'e',
        '5' || '\$' => 's',
        '7' => 't',
        _ => ch,
      };
      if (!RegExp(r'[a-zа-я]').hasMatch(ch)) continue;
      if (ch == last) {
        repeat++;
        if (repeat >= 2) continue;
      } else {
        last = ch;
        repeat = 0;
      }
      buffer.write(ch);
    }
    return buffer.toString();
  }

  static Iterable<String> _tokens(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('ё', 'е')
        .split(RegExp(r'[^a-zа-я0-9]+'))
        .map(_compact)
        .where((part) => part.isNotEmpty);
  }
}
