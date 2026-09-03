import 'package:shared_preferences/shared_preferences.dart';

/// Saved visual toggle. Off by default: covered tiles stay full color.
class LockedTileDimStore {
  LockedTileDimStore._(this._prefs);

  final SharedPreferences? _prefs;

  static const _kPref = 'app.dimLockedTiles';

  static LockedTileDimStore memory() => LockedTileDimStore._(null);

  static Future<LockedTileDimStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return LockedTileDimStore._(prefs);
  }

  bool get enabled => _prefs?.getBool(_kPref) ?? false;

  Future<void> setEnabled(bool value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_kPref, value);
  }
}
