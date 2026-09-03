import 'package:shared_preferences/shared_preferences.dart';

/// Saved QA toggle. Off by default.
class QModeStore {
  QModeStore._(this._prefs);

  final SharedPreferences? _prefs;

  static const _kPref = 'app.qModeEnabled';

  static QModeStore memory() => QModeStore._(null);

  static Future<QModeStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return QModeStore._(prefs);
  }

  bool get enabled => _prefs?.getBool(_kPref) ?? false;

  Future<void> setEnabled(bool value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_kPref, value);
  }
}
