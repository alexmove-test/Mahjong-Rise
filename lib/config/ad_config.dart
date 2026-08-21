import 'package:flutter/foundation.dart';

/// AdMob-конфигурация.
abstract final class AdConfig {
  static const appId = 'ca-app-pub-1524654355170130~6121469025';

  static const productionRewardedUnitId =
      'ca-app-pub-1524654355170130/2046492641';

  /// Google test rewarded unit — для debug/profile.
  static const testRewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';

  static String get rewardedUnitId =>
      kDebugMode ? testRewardedUnitId : productionRewardedUnitId;

  /// Flip to `true` after the public Play/App Store release.
  static const useRealAds = false;

  /// AdMob works on Android/iOS only. Until [useRealAds], always simulate.
  static bool get simulateAds {
    if (!useRealAds) return true;
    if (kIsWeb) return true;
    return defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS;
  }
}
