import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mahjong/config/ad_config.dart';
import 'package:mahjong/services/ad_bootstrap.dart';
import 'package:mahjong/services/rewarded_ad_service.dart';

void main() {
  test('widget tests keep simulated ads while Play ads stay real', () {
    expect(AdConfig.useRealAds, isTrue);
    expect(AdConfig.debugSimulateAds, isTrue);
    expect(AdConfig.simulateAds, isTrue);
    expect(AdBootstrap.simulation, isTrue);
  });

  test('ensureInitialized is safe to await more than once', () async {
    await AdBootstrap.ensureInitialized();
    expect(AdBootstrap.initFinished, isTrue);
    expect(AdBootstrap.available, isTrue);
    await AdBootstrap.ensureInitialized();
    expect(AdBootstrap.available, isTrue);
  });

  test('shared rewarded service stays simulated in widget tests', () {
    expect(RewardedAdService.instance.isReady, isTrue);
  });

  test('UMP false does not block ads unless consent is required', () {
    expect(
      AdBootstrap.allowAdRequests(
        canRequestAds: true,
        status: ConsentStatus.required,
      ),
      isTrue,
    );
    expect(
      AdBootstrap.allowAdRequests(
        canRequestAds: false,
        status: ConsentStatus.unknown,
      ),
      isTrue,
    );
    expect(
      AdBootstrap.allowAdRequests(
        canRequestAds: false,
        status: ConsentStatus.notRequired,
      ),
      isTrue,
    );
    expect(
      AdBootstrap.allowAdRequests(
        canRequestAds: false,
        status: ConsentStatus.required,
      ),
      isFalse,
    );
  });
}
