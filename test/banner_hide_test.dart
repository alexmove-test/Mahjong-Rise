import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/banner_hide_controller.dart';
import 'package:mahjong/services/banner_hide_store.dart';
import 'package:mahjong/services/rewarded_ad_service.dart';
import 'package:mahjong/widgets/banner_hide_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  test('hide lasts 24 hours on this device', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await BannerHideStore.open();
    var now = DateTime(2026, 10, 1, 12);
    final controller = BannerHideController(store, clock: () => now);

    expect(controller.isHidden, isFalse);
    await controller.grant();
    expect(controller.isHidden, isTrue);
    expect(controller.remaining, BannerHideStore.hideFor);

    final again = await BannerHideStore.open();
    expect(again.hiddenUntil, now.add(BannerHideStore.hideFor));

    now = now.add(const Duration(hours: 23, minutes: 59));
    controller.recheck();
    expect(controller.isHidden, isTrue);

    now = now.add(const Duration(minutes: 2));
    controller.recheck();
    expect(controller.isHidden, isFalse);
    controller.dispose();
  });

  test('a grant before prefs load is kept', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = BannerHideController(BannerHideStore.memory());
    await controller.grant();
    expect(controller.isHidden, isTrue);

    controller.attachStore(await BannerHideStore.open());
    expect(controller.isHidden, isTrue);
    expect((await BannerHideStore.open()).hiddenUntil, isNotNull);
    controller.dispose();
  });

  testWidgets('the button states the reward before the ad', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = BannerHideController(await BannerHideStore.open());
    await tester.pumpWidget(
      _host(
        controller,
        BannerHideButton(
          adsLive: true,
          showAd: (_) async => RewardedAdShowResult.skipped,
        ),
      ),
    );

    expect(find.text('24 hours'), findsOneWidget);
    await tester.tap(find.text('24 hours'));
    await tester.pumpAndSettle();

    expect(find.text('Hide the banner for 24 hours'), findsOneWidget);
    expect(
      find.text('Watch an ad. It stays off on this device.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(controller.isHidden, isFalse);

    await tester.tap(find.text('24 hours'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watch ad'));
    await tester.pumpAndSettle();

    expect(controller.isHidden, isFalse);
    expect(find.text('Reward not earned'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('a finished ad hides the banner and the button', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = BannerHideController(await BannerHideStore.open());
    await tester.pumpWidget(
      _host(
        controller,
        BannerHideButton(
          adsLive: true,
          showAd: (_) async => RewardedAdShowResult.earned,
        ),
      ),
    );

    await tester.tap(find.text('24 hours'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watch ad'));
    await tester.pumpAndSettle();

    expect(controller.isHidden, isTrue);
    expect(find.text('24 hours'), findsNothing);
    controller.dispose();
  });
}

Widget _host(BannerHideController controller, Widget child) {
  return BannerHideScope(
    controller: controller,
    child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: Scaffold(body: child)),
  );
}
