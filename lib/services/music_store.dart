import 'package:shared_preferences/shared_preferences.dart';

/// Saved background-music preference. Enabled by default.
class MusicStore {
  MusicStore._(this._prefs);

  final SharedPreferences? _prefs;

  static const defaultVolume = 0.16;
  static const _kPref = 'app.musicEnabled';
  static const _kVolumePref = 'app.musicVolume';

  static MusicStore memory() => MusicStore._(null);

  static Future<MusicStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return MusicStore._(prefs);
  }

  bool get enabled => _prefs?.getBool(_kPref) ?? true;

  double get volume {
    final stored = _prefs?.getDouble(_kVolumePref);
    if (stored == null) return defaultVolume;
    return stored.clamp(0.0, 1.0);
  }

  Future<void> setEnabled(bool value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_kPref, value);
  }

  Future<void> setVolume(double value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setDouble(_kVolumePref, value.clamp(0.0, 1.0));
  }
}
