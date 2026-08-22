import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

/// Инициализация AdMob (без падения приложения при ошибке).
class AdBootstrap {
  AdBootstrap._();

  static bool enabled = false;
  static bool initFinished = false;
  static String? initError;

  /// Имитация ролика вместо AdMob (debug / web / desktop).
  static bool get simulation => AdConfig.simulateAds;

  /// Можно показать ролик: AdMob, имитация, или fallback после неудачного init.
  static bool get available => simulation || enabled || initFinished;

  static Future<void> init() async {
    if (AdConfig.simulateAds) {
      enabled = false;
      initFinished = true;
      initError = kDebugMode
          ? 'Simulated rewarded ads in debug'
          : kIsWeb
          ? 'AdMob is unavailable on web'
          : 'AdMob is unavailable on this platform';
      return;
    }
    try {
      await MobileAds.instance.initialize();
      enabled = true;
      initError = null;
    } catch (error) {
      enabled = false;
      initError = error.toString();
    } finally {
      initFinished = true;
    }
  }
}
