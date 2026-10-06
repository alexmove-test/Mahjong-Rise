import 'package:flutter/foundation.dart';

/// AdMob-конфигурация.
abstract final class AdConfig {
  static const appId = 'ca-app-pub-1561854396404271~8263443836';

  static const productionRewardedUnitId =
      'ca-app-pub-1561854396404271/4487850354';

  /// Google test rewarded unit — для debug/profile.
  static const testRewardedUnitId = 'ca-app-pub-3940256099942544/5224354917';

  static String get rewardedUnitId =>
      kDebugMode ? testRewardedUnitId : productionRewardedUnitId;

  static const productionBannerUnitId =
      'ca-app-pub-1561854396404271/7581590005';

  static const testBannerUnitIdAndroid =
      'ca-app-pub-3940256099942544/6300978111';
  static const testBannerUnitIdIos = 'ca-app-pub-3940256099942544/2934735716';

  static String get bannerUnitId => _unitId(
    production: productionBannerUnitId,
    testAndroid: testBannerUnitIdAndroid,
    testIos: testBannerUnitIdIos,
  );

  static String _unitId({
    required String production,
    required String testAndroid,
    required String testIos,
  }) {
    if (!kDebugMode && production.isNotEmpty) return production;
    return defaultTargetPlatform == TargetPlatform.iOS ? testIos : testAndroid;
  }

  static const useRealAds = true;

  /// Hashed device ids from logcat (`addTestDeviceHashedId`) so debug UMP
  /// geography works on a physical phone. Emulators often work without this.
  static const umpTestDeviceIds = <String>[];

  /// Widget tests stay on the in-app simulation; `flutter run` uses AdMob.
  @visibleForTesting
  static bool debugSimulateAds = false;

  /// Until [useRealAds], always simulate. Then AdMob on Android/iOS only.
  static bool get simulateAds {
    if (debugSimulateAds) return true;
    if (!useRealAds) return true;
    if (kIsWeb) return true;
    return defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS;
  }
}
