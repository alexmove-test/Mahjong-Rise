import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/ad_bootstrap.dart';
import 'package:mahjong/widgets/ads/banner_ad_slot.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  testWidgets('simulated ads keep the slot collapsed', (tester) async {
    expect(AdBootstrap.simulation, isTrue);
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(children: [Text('continue'), BannerAdSlot()]),
        ),
      ),
    );

    expect(find.text('continue'), findsOneWidget);
    expect(tester.getSize(find.byType(BannerAdSlot)).height, 0);
  });
}
