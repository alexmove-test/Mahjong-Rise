import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';

/// Инициализация AdMob (без падения приложения при ошибке).
class AdBootstrap {
  AdBootstrap._();

  static bool enabled = false;
  static String? initError;

  /// Имитация ролика: web/desktop, флаг до публикации, либо debug без AdMob.
  static bool get simulation =>
      AdConfig.simulateAds || (kDebugMode && !enabled);

  static bool get available => enabled || simulation;

  static Future<void> init() async {
    if (AdConfig.simulateAds) {
      enabled = false;
      initError = kIsWeb
          ? 'AdMob is unavailable on web'
          : 'Using simulated ads until public release';
      return;
    }
    try {
      await MobileAds.instance.initialize();
      enabled = true;
      initError = null;
    } catch (error) {
      enabled = false;
      initError = error.toString();
    }
  }
}
