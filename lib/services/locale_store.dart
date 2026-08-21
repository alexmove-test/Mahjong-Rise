import 'package:shared_preferences/shared_preferences.dart';

enum LanguagePref { system, en, ru }

/// Saved language choice. [LanguagePref.system] follows the phone language.
class LocaleStore {
  LocaleStore._(this._prefs);

  final SharedPreferences? _prefs;

  static const _kPref = 'app.languagePref';

  static const supportedCodes = ['en', 'ru'];

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

  /// Resolves en/ru from an explicit choice or the device preferred-language list.
  static String resolve(LanguagePref pref, List<String> deviceLanguageCodes) {
    if (pref == LanguagePref.ru) return 'ru';
    if (pref == LanguagePref.en) return 'en';
    return resolveDevice(deviceLanguageCodes);
  }

  /// First supported code in the OS preferred list; otherwise English.
  static String resolveDevice(List<String> deviceLanguageCodes) {
    for (final raw in deviceLanguageCodes) {
      final code = raw.toLowerCase().split(RegExp(r'[-_]')).first;
      if (supportedCodes.contains(code)) return code;
    }
    return 'en';
  }
}
