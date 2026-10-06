import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';

import 'display_name_filter.dart';
import 'guest_name.dart';

/// Имя игрока для таблицы рейтинга.
class PlayerProfileStore {
  PlayerProfileStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _kDisplayName = 'player.displayName';
  static const _kGuestName = 'player.guestName';
  static const _kLastSyncedRating = 'player.lastSyncedRating';
  static const _kLastSyncedName = 'player.lastSyncedName';
  static const _kLastSyncedWeekId = 'player.lastSyncedWeekId';
  static const _kLastSyncedWeeklyRating = 'player.lastSyncedWeeklyRating';
  static const _kLanguagePref = 'app.languagePref';

  static Future<PlayerProfileStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    final store = PlayerProfileStore._(prefs);
    await store._ensureGuestName();
    return store;
  }

  /// Своё имя, если игрок его задал, иначе случайное гостевое.
  String get displayName {
    final custom = _customName;
    if (custom != null) return _visible(custom);
    final guest = _prefs.getString(_kGuestName)?.trim();
    if (guest != null && guest.isNotEmpty) return _visible(guest);
    return 'You';
  }

  String _visible(String raw) =>
      DisplayNameFilter.publicName(GuestName.clamp(raw));

  bool get hasCustomName => _customName != null;

  String? get _customName {
    final value = _prefs.getString(_kDisplayName)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  int get lastSyncedRating => _prefs.getInt(_kLastSyncedRating) ?? 0;

  String get lastSyncedName => _prefs.getString(_kLastSyncedName) ?? '';

  String get lastSyncedWeekId => _prefs.getString(_kLastSyncedWeekId) ?? '';

  int get lastSyncedWeeklyRating =>
      _prefs.getInt(_kLastSyncedWeeklyRating) ?? 0;

  /// Empty name restores the guest label. Returns false if the name is blocked.
  Future<bool> setDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      await _prefs.remove(_kDisplayName);
      return true;
    }
    if (!DisplayNameFilter.isAllowed(trimmed)) return false;
    await _prefs.setString(_kDisplayName, GuestName.clamp(trimmed));
    return true;
  }

  Future<void> markSynced({required int rating, required String name}) async {
    await _prefs.setInt(_kLastSyncedRating, rating);
    await _prefs.setString(_kLastSyncedName, name);
  }

  Future<void> markWeeklySynced({
    required String weekId,
    required int rating,
    required String name,
  }) async {
    await _prefs.setString(_kLastSyncedWeekId, weekId);
    await _prefs.setInt(_kLastSyncedWeeklyRating, rating);
    await _prefs.setString(_kLastSyncedName, name);
  }

  Future<void> _ensureGuestName() async {
    final existing = _prefs.getString(_kGuestName)?.trim();
    if (existing != null && existing.isNotEmpty) {
      final clamped = GuestName.clamp(existing);
      if (clamped != existing) {
        await _prefs.setString(_kGuestName, clamped);
      }
      return;
    }
    await _prefs.setString(
      _kGuestName,
      GuestName.generate(language: _guestLanguage),
    );
  }

  String get _guestLanguage {
    switch (_prefs.getString(_kLanguagePref)) {
      case 'ru':
      case 'uk':
      case 'en':
      case 'th':
        return _prefs.getString(_kLanguagePref)!;
      default:
        final code = PlatformDispatcher.instance.locale.languageCode
            .toLowerCase();
        if (code == 'ru' || code == 'uk' || code == 'th') return code;
        return 'en';
    }
  }
}
