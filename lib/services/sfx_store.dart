import 'package:shared_preferences/shared_preferences.dart';

/// Saved sound preference. Enabled by default.
class SfxStore {
  SfxStore._(this._prefs);

  final SharedPreferences? _prefs;

  static const _kPref = 'app.sfxEnabled';

  static SfxStore memory() => SfxStore._(null);

  static Future<SfxStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return SfxStore._(prefs);
  }

  bool get enabled => _prefs?.getBool(_kPref) ?? true;

  Future<void> setEnabled(bool value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_kPref, value);
  }
}
