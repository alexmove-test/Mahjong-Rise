import 'package:shared_preferences/shared_preferences.dart';

/// Saved haptic preference. Disabled by default.
class HapticStore {
  HapticStore._(this._prefs);

  final SharedPreferences? _prefs;

  static const _kPref = 'app.hapticEnabled';

  static HapticStore memory() => HapticStore._(null);

  static Future<HapticStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return HapticStore._(prefs);
  }

  bool get enabled => _prefs?.getBool(_kPref) ?? false;

  Future<void> setEnabled(bool value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_kPref, value);
  }
}
