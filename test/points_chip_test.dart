import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/points_controller.dart';
import 'package:mahjong/services/points_store.dart';
import 'package:mahjong/widgets/courtyard/courtyard_win_overlay.dart';
import 'package:mahjong/widgets/points/points_award_badge.dart';
import 'package:mahjong/widgets/points/points_chip.dart';
import 'package:mahjong/l10n/app_localizations.dart';

void main() {
  testWidgets('the chip groups thousands and offers a top-up', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      _host(PointsChip(points: 12450, onTap: () => tapped++)),
    );

    expect(find.text('12\u2009450'), findsOneWidget);
    await tester.tap(find.byType(PointsChip));
    expect(tapped, 1);
  });

  testWidgets('the counter rolls up to a new balance', (tester) async {
    await tester.pumpWidget(_host(const PointsChip(points: 100)));
    expect(find.text('100'), findsOneWidget);

    await tester.pumpWidget(_host(const PointsChip(points: 400)));
    await tester.pump(const Duration(milliseconds: 300));

    final rolling = int.parse(
      (tester.widget<Text>(find.byType(Text).first).data ?? '').replaceAll(
        '\u2009',
        '',
      ),
    );
    expect(rolling, greaterThan(100));
    expect(rolling, lessThan(400));

    await tester.pumpAndSettle();
    expect(find.text('400'), findsOneWidget);
  });

  testWidgets('the live chip follows the wallet', (tester) async {
    final controller = PointsController(PointsStore.memory());
    await tester.pumpWidget(
      PointsScope(
        controller: controller,
        child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: PointsChipLive())),
        ),
      ),
    );
    expect(find.text('0'), findsOneWidget);

    await controller.earn(65);
    await tester.pumpAndSettle();

    expect(find.text('65'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('the win badge spells out the reward', (tester) async {
    await tester.pumpWidget(_host(const PointsAwardBadge(points: 1)));
    expect(find.text('+1 point'), findsOneWidget);

    await tester.pumpWidget(_host(const PointsAwardBadge(points: 65)));
    expect(find.text('+65 points'), findsOneWidget);
  });

  testWidgets('the win celebration hands over the reward', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: CourtyardWinOverlay(score: 400, points: 90)),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byKey(pointsAwardBadgeKey), findsOneWidget);
    expect(find.text('+90 points'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,home: CourtyardWinOverlay(score: 400)),
    );
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(pointsAwardBadgeKey), findsNothing);
  });
}

Widget _host(Widget child) {
  return MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Center(child: child)),
  );
}
