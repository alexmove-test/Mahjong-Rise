import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/widgets/courtyard/courtyard_estate.dart';
import 'package:mahjong/widgets/courtyard/courtyard_world.dart';
import 'package:mahjong/widgets/courtyard/home_upgrade_preview.dart';
import 'package:mahjong/widgets/courtyard/plot_stage_view.dart';
import 'package:mahjong/services/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the purchase card shows the next look, price and shortfall', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Future<void> show({
      required int state,
      required int balance,
      bool busy = false,
      Future<void> Function()? onBuy,
      bool reduceMotion = false,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: const [Locale('ru')],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(
                textScaler: const TextScaler.linear(1.5),
                disableAnimations: reduceMotion,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: HomeUpgradePreview(
                    state: state,
                    balance: balance,
                    busy: busy,
                    onBuy: onBuy,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    await show(state: 5, balance: 1000, onBuy: () async {});
    expect(find.text('Дом · 5/24'), findsNothing);
    expect(find.text('Улучшение дома — 300'), findsNothing);
    expect(find.byKey(const ValueKey('house-look-line')), findsNothing);
    expect(find.text('Улучшить за 300'), findsOneWidget);
    expect(find.textContaining('пруд'), findsNothing);
    final preview = find.byKey(const ValueKey('next-house-image'));
    expect(
      (tester.widget<Image>(preview).image as AssetImage).assetName,
      'assets/courtyard/builds/house/06.png',
    );
    final button = tester.getRect(
      find.byKey(const ValueKey('house-upgrade-button')),
    );
    expect(button.left, greaterThan(tester.getRect(preview).right));
    expect(button.right, lessThanOrEqualTo(308));

    await tester.tap(find.byKey(const ValueKey('house-upgrade-curtain')));
    await tester.pumpAndSettle();
    expect(find.text('Дом · 5/24'), findsOneWidget);
    expect(find.text('Улучшение дома — 300'), findsOneWidget);
    final price = tester.getRect(find.text('Улучшение дома — 300'));
    expect(price.right, lessThanOrEqualTo(308));
    final title = tester.getRect(find.text('Дом · 5/24'));
    final line = tester.getRect(find.byKey(const ValueKey('house-look-line')));
    expect(line.top, greaterThan(title.bottom));
    expect(line.right, lessThanOrEqualTo(308));
    expect(find.byKey(const ValueKey('house-look-built-5')), findsOneWidget);
    expect(find.byKey(const ValueKey('house-look-fog-6')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('house-upgrade-curtain')));
    await tester.pumpAndSettle();
    expect(find.text('Дом · 5/24'), findsNothing);
    expect(find.text('Улучшение дома — 300'), findsNothing);
    expect(find.byKey(const ValueKey('house-look-line')), findsNothing);
    expect(find.text('Улучшить за 300'), findsOneWidget);

    await show(state: 5, balance: 50, onBuy: () async {});
    expect(find.text('Не хватает 250 поинтов'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('house-upgrade-curtain')));
    await tester.pumpAndSettle();
    expect(find.text('Не хватает 250 поинтов'), findsOneWidget);
    expect(find.text('Играть в махджонг'), findsNothing);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('house-upgrade-button')),
          )
          .onPressed,
      isNull,
    );

    await show(state: 23, balance: 1200, onBuy: () async {});
    expect(find.text('Улучшить за 1\u2009200'), findsOneWidget);
    expect(
      (tester.widget<Image>(preview).image as AssetImage).assetName,
      'assets/courtyard/builds/house/24.png',
    );

    await show(state: 24, balance: 5000);
    expect(find.text('Дом полностью улучшен'), findsOneWidget);
    expect(find.byKey(const ValueKey('next-house-image')), findsNothing);
    expect(find.textContaining('пруд'), findsNothing);
    expect(find.byKey(const ValueKey('house-upgrade-button')), findsNothing);

    await show(state: 2, balance: 500, busy: true, onBuy: () async {});
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('house-upgrade-button')),
          )
          .onPressed,
      isNull,
    );

    var taps = 0;
    await show(
      state: 1,
      balance: 500,
      onBuy: () async {
        taps++;
        await Future<void>.delayed(const Duration(milliseconds: 30));
      },
    );
    await tester.tap(find.byKey(const ValueKey('house-upgrade-button')));
    await tester.tap(find.byKey(const ValueKey('house-upgrade-button')));
    await tester.pump();
    expect(taps, 1);
    await tester.pump(const Duration(milliseconds: 40));

    await show(state: 4, balance: 400, onBuy: () async {}, reduceMotion: true);
    await show(state: 5, balance: 100, onBuy: () async {}, reduceMotion: true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a bought step eases the house, and reduced motion skips it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'progress.maxUnlocked': 1});
    final store = await ProgressStore.open();

    Future<void> show(int home, {required bool reduceMotion}) async {
      await tester.pumpWidget(
        MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduceMotion),
            child: CourtyardWorld(
              to: CourtyardEstate.fromStore(store, purchasedHome: home),
              interactive: false,
            ),
          ),
        ),
      );
    }

    await show(1, reduceMotion: false);
    await tester.pump();
    await show(2, reduceMotion: false);
    await tester.pump(const Duration(milliseconds: 50));
    final blending = tester
        .widgetList<PlotStageView>(find.byType(PlotStageView))
        .firstWhere((view) => view.kind.name == 'house');
    expect(blending.stage, greaterThan(1));
    expect(blending.stage, lessThan(2));

    await show(1, reduceMotion: true);
    await tester.pump();
    await show(2, reduceMotion: true);
    await tester.pump();
    final jumped = tester
        .widgetList<PlotStageView>(find.byType(PlotStageView))
        .firstWhere((view) => view.kind.name == 'house');
    expect(jumped.stage, 2);
  });
}
