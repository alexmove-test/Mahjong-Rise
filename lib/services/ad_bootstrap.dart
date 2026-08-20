import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Инициализация AdMob (без падения приложения при ошибке).
class AdBootstrap {
  AdBootstrap._();

  static bool enabled = false;
  static String? initError;

  static Future<void> init() async {
    if (kIsWeb) {
      enabled = false;
      initError = 'AdMob недоступен в web';
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
