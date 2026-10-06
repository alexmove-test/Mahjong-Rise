import 'package:shared_preferences/shared_preferences.dart';

enum LanguagePref { system, en, ru, th }

/// Saved language choice. [LanguagePref.system] follows the phone language.
class LocaleStore {
  LocaleStore._(this._prefs);

  final SharedPreferences? _prefs;

  static const _kPref = 'app.languagePref';

  static LocaleStore memory() => LocaleStore._(null);

  static Future<LocaleStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return LocaleStore._(prefs);
  }

  LanguagePref get preference {
    switch (_prefs?.getString(_kPref)) {
      case 'en':
        return LanguagePref.en;
      case 'ru':
        return LanguagePref.ru;
      case 'th':
        return LanguagePref.th;
      case 'uk':
        // Ukrainian was saved before it shipped. The interface falls back to English.
        return LanguagePref.en;
      default:
        return LanguagePref.system;
    }
  }

  Future<void> setPreference(LanguagePref pref) async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (pref == LanguagePref.system) {
      await prefs.remove(_kPref);
      return;
    }
    await prefs.setString(_kPref, pref.name);
  }

  static String resolve(LanguagePref pref, String deviceLanguageCode) {
    if (pref == LanguagePref.ru) return 'ru';
    if (pref == LanguagePref.en) return 'en';
    if (pref == LanguagePref.th) return 'th';
    final device = deviceLanguageCode.toLowerCase();
    if (device == 'ru') return 'ru';
    if (device == 'th') return 'th';
    return 'en';
  }
}
