import 'package:shared_preferences/shared_preferences.dart';

/// Имя игрока для таблицы рейтинга.
class PlayerProfileStore {
  PlayerProfileStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _kDisplayName = 'player.displayName';
  static const _kLastSyncedRating = 'player.lastSyncedRating';
  static const _kLastSyncedName = 'player.lastSyncedName';

  static Future<PlayerProfileStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return PlayerProfileStore._(prefs);
  }

  String get displayName =>
      _prefs.getString(_kDisplayName)?.trim().isNotEmpty == true
      ? _prefs.getString(_kDisplayName)!.trim()
      : 'Вы';

  int get lastSyncedRating => _prefs.getInt(_kLastSyncedRating) ?? 0;

  String get lastSyncedName => _prefs.getString(_kLastSyncedName) ?? '';

  Future<void> setDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      await _prefs.remove(_kDisplayName);
      return;
    }
    await _prefs.setString(_kDisplayName, trimmed);
  }

  Future<void> markSynced({required int rating, required String name}) async {
    await _prefs.setInt(_kLastSyncedRating, rating);
    await _prefs.setString(_kLastSyncedName, name);
  }
}
