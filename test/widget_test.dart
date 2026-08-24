import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('first launch opens level 1 with a table coach', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MahjongApp());
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Take only a free top tile'), findsOneWidget);
    expect(find.textContaining('MAHJONG RISE'), findsNothing);
  });

  testWidgets('returning player sees the courtyard hub', (tester) async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 2,
      'progress.stars.1': 1,
      'progress.best.1': 400,
      'progress.lastPlayed': 1,
    });
    await tester.pumpWidget(const MahjongApp());
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('MAHJONG RISE'), findsNothing);
    expect(find.textContaining('Continue'), findsOneWidget);
    expect(find.text('Plot 1'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('Sprout'), findsNothing);
    expect(find.text('Bud'), findsNothing);
    expect(find.text('240'), findsNothing);
    expect(find.text('Take only a free top tile'), findsNothing);

    await tester.tap(find.text('Levels'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Sprout'), findsWidgets);
    expect(find.text('Bud'), findsOneWidget);
  });

  testWidgets('finished first plot offers a new courtyard', (tester) async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 25,
      'progress.stars.1': 1,
      'progress.stars.24': 1,
      'progress.best.24': 400,
      'progress.lastPlayed': 24,
    });
    await tester.pumpWidget(const MahjongApp());
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Plot 1'), findsOneWidget);
    expect(find.text('New plot'), findsOneWidget);

    await tester.tap(find.text('New plot'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Plot 2'), findsOneWidget);
    expect(find.text('A house will stand here.'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Image) return false;
        final image = widget.image;
        return image is AssetImage && image.assetName.contains('/plot2/');
      }),
      findsWidgets,
    );
  });

  testWidgets('Russian phone language shows Russian courtyard copy', (
    tester,
  ) async {
    tester.platformDispatcher.localeTestValue = const Locale('ru');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 2,
      'progress.stars.1': 1,
      'progress.best.1': 400,
      'progress.lastPlayed': 1,
    });
    await tester.pumpWidget(const MahjongApp());
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Участок 1'), findsOneWidget);
    expect(find.textContaining('Продолжить'), findsOneWidget);
    expect(find.text('Сегодня'), findsOneWidget);
    expect(find.text('Уровни'), findsOneWidget);
    expect(find.text('Росток'), findsNothing);

    await tester.tap(find.text('Уровни'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Росток'), findsWidgets);
  });

  testWidgets('language menu can switch the app to Russian', (tester) async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 2,
      'progress.stars.1': 1,
      'progress.best.1': 400,
      'progress.lastPlayed': 1,
    });
    await tester.pumpWidget(const MahjongApp());
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Haptic feedback'), findsOneWidget);

    await tester.tap(find.text('Русский'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Участок 1'), findsOneWidget);
    expect(find.textContaining('Продолжить'), findsOneWidget);
    expect(find.byTooltip('Настройки'), findsOneWidget);
  });

  testWidgets('settings can turn haptic feedback off', (tester) async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 2,
      'progress.stars.1': 1,
      'progress.best.1': 400,
      'progress.lastPlayed': 1,
    });
    await tester.pumpWidget(const MahjongApp());
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sound'), findsOneWidget);
    expect(find.text('Haptic feedback'), findsOneWidget);

    final hapticToggle = find.descendant(
      of: find.widgetWithText(SwitchListTile, 'Haptic feedback'),
      matching: find.byType(Switch),
    );
    expect(tester.widget<Switch>(hapticToggle).value, isTrue);

    await tester.tap(hapticToggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.widget<Switch>(hapticToggle).value, isFalse);

    await tester.tap(find.text('Русский'));
    await tester.pump();
    expect(find.text('Звук'), findsOneWidget);
    expect(find.text('Тактильный отклик'), findsOneWidget);
  });

  testWidgets('settings can turn sound off', (tester) async {
    SharedPreferences.setMockInitialValues({
      'progress.maxUnlocked': 2,
      'progress.stars.1': 1,
      'progress.best.1': 400,
      'progress.lastPlayed': 1,
    });
    await tester.pumpWidget(const MahjongApp());
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final soundToggle = find.descendant(
      of: find.widgetWithText(SwitchListTile, 'Sound'),
      matching: find.byType(Switch),
    );
    expect(tester.widget<Switch>(soundToggle).value, isTrue);

    await tester.tap(soundToggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.widget<Switch>(soundToggle).value, isFalse);
  });
}
