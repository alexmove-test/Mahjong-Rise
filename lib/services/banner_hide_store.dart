import 'package:shared_preferences/shared_preferences.dart';

/// Когда баннер снова можно показать. Только на этом устройстве.
class BannerHideStore {
  BannerHideStore._(this._prefs);

  final SharedPreferences? _prefs;

  static const prefKey = 'ads.bannerHiddenUntilMs';

  /// Награда за один rewarded-ролик.
  static const hideFor = Duration(hours: 24);

  static BannerHideStore memory() => BannerHideStore._(null);

  static Future<BannerHideStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return BannerHideStore._(prefs);
  }

  DateTime? get hiddenUntil {
    final ms = _prefs?.getInt(prefKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setHiddenUntil(DateTime? until) async {
    final prefs = _prefs;
    if (prefs == null) return;
    if (until == null) {
      await prefs.remove(prefKey);
      return;
    }
    await prefs.setInt(prefKey, until.millisecondsSinceEpoch);
  }
}
