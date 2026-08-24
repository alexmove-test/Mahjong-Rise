import 'package:shared_preferences/shared_preferences.dart';

/// Вкл/выкл локальных напоминаний. По умолчанию выключено, пока игрок не согласится.
class ReminderStore {
  ReminderStore._(this._prefs);

  final SharedPreferences? _prefs;

  static const _kEnabled = 'app.remindersEnabled';

  static ReminderStore memory() => ReminderStore._(null);

  static Future<ReminderStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderStore._(prefs);
  }

  bool get enabled => _prefs?.getBool(_kEnabled) ?? false;

  Future<void> setEnabled(bool value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_kEnabled, value);
  }
}
