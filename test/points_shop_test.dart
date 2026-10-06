import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/points_pack.dart';
import 'package:mahjong/services/points_controller.dart';
import 'package:mahjong/services/points_purchase.dart';
import 'package:mahjong/services/points_store.dart';
import 'package:mahjong/services/rewarded_ad_service.dart';
import 'package:mahjong/widgets/points/points_shop_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  testWidgets('the shelf shows every pack with its price', (tester) async {
    final controller = PointsController(PointsStore.memory());
    await tester.pumpWidget(_host(controller, const _Backend()));

    for (final pack in PointsPack.catalog) {
      expect(find.text(pack.priceTag), findsOneWidget);
    }
    expect(find.text('+10% bonus'), findsOneWidget);
    expect(find.text('Best value'), findsOneWidget);
    expect(
      find.text('Payments are not wired up yet — the pack lands right away.'),
      findsOneWidget,
    );
    controller.dispose();
  });

  testWidgets('a paid pack lands in the wallet', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = PointsController(await PointsStore.open());
    const backend = _Backend();
    await tester.pumpWidget(_host(controller, backend));

    await _tap(tester, find.text(r'$0.03'));

    expect(controller.balance, 165);
    expect((await PointsStore.open()).purchased, 165);
    expect(find.text('Credited +165'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('a cancelled purchase leaves the wallet alone', (tester) async {
    final controller = PointsController(PointsStore.memory());
    await tester.pumpWidget(
      _host(
        controller,
        const _Backend(result: PointsPurchaseResult.cancelled()),
      ),
    );

    await _tap(tester, find.text(r'$0.01'));

    expect(controller.balance, 0);
    expect(find.text('Purchase cancelled'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('a finished ad pays a free handful', (tester) async {
    final controller = PointsController(PointsStore.memory());
    await tester.pumpWidget(
      _host(
        controller,
        const _Backend(),
        showAd: (_) async => RewardedAdShowResult.earned,
      ),
    );

    await _tap(tester, find.text('Watch ad'));

    expect(controller.balance, PointsShopSheet.adReward);
    expect(find.text('Credited +50'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('a skipped ad pays nothing', (tester) async {
    final controller = PointsController(PointsStore.memory());
    await tester.pumpWidget(
      _host(
        controller,
        const _Backend(),
        showAd: (_) async => RewardedAdShowResult.skipped,
      ),
    );

    await _tap(tester, find.text('Watch ad'));

    expect(controller.balance, 0);
    expect(find.text('Reward not earned'), findsOneWidget);
    controller.dispose();
  });
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Widget _host(
  PointsController controller,
  PointsPurchaseBackend backend, {
  Future<RewardedAdShowResult> Function(BuildContext context)? showAd,
}) {
  return PointsScope(
    controller: controller,
    child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: PointsShopSheet(backend: backend, showAd: showAd),
      ),
    ),
  );
}

class _Backend implements PointsPurchaseBackend {
  const _Backend({this.result});

  final PointsPurchaseResult? result;

  @override
  bool get isLive => false;

  @override
  String priceLabel(PointsPack pack) => pack.priceTag;

  @override
  Future<PointsPurchaseResult> buy(PointsPack pack) async {
    return result ??
        PointsPurchaseResult(
          PointsPurchaseStatus.purchased,
          points: pack.total,
        );
  }
}
