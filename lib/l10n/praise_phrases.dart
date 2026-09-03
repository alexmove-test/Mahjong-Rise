/// Spoken praise for fast consecutive matches. Clips live in `assets/sfx/praise/`.
const praiseWindow = Duration(seconds: 3);
const praiseMinMatches = 3;
const praiseCooldown = Duration(seconds: 10);

const praiseLanguages = {'en', 'ru'};

const praisePhrases = <String, List<String>>{
  'ru': [
    'Всё получится!',
    'Всё получится!',
  ],
  'en': [
    'Great!',
    'Nice!',
    'Super!',
    'Yes!',
    'Beautiful!',
    'Well done!',
    'Awesome!',
    'Keep it up!',
  ],
};

String resolvePraiseLanguage(String languageCode) {
  final lang = languageCode.toLowerCase();
  if (praiseLanguages.contains(lang)) return lang;
  return 'en';
}

int praiseClipCount(String languageCode) {
  final lang = resolvePraiseLanguage(languageCode);
  return praisePhrases[lang]!.length;
}

/// [phraseIndex] is 0-based and wraps over the language's clip count.
String praiseClipAsset(String languageCode, int phraseIndex) {
  final lang = resolvePraiseLanguage(languageCode);
  final n = phraseIndex % praiseClipCount(lang) + 1;
  return 'sfx/praise/${lang}_$n.mp3';
}

/// Consecutive matches within [window] can unlock a praise clip.
class FastMatchStreak {
  FastMatchStreak({
    this.window = praiseWindow,
    this.minMatches = praiseMinMatches,
    this.cooldown = praiseCooldown,
  });

  final Duration window;
  final int minMatches;
  final Duration cooldown;
  DateTime? _lastMatchAt;
  DateTime? _lastPraiseAt;
  int _count = 0;
  int _phraseIndex = 0;

  int get count => _count;

  void reset() {
    _lastMatchAt = null;
    _count = 0;
  }

  /// Asset path relative to `assets/`, or null if this match stays silent.
  String? registerMatch({
    required DateTime now,
    required String languageCode,
  }) {
    if (_lastMatchAt == null || now.difference(_lastMatchAt!) > window) {
      _count = 1;
    } else {
      _count += 1;
    }
    _lastMatchAt = now;

    if (_count < minMatches) return null;
    if (_lastPraiseAt != null && now.difference(_lastPraiseAt!) < cooldown) {
      return null;
    }

    final asset = praiseClipAsset(languageCode, _phraseIndex);
    _phraseIndex = (_phraseIndex + 1) % praiseClipCount(languageCode);
    _lastPraiseAt = now;
    return asset;
  }
}
