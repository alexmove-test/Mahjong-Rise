import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/main.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/widgets/courtyard/courtyard_estate.dart';
import 'package:mahjong/widgets/courtyard/courtyard_progress.dart';
import 'package:mahjong/widgets/courtyard/courtyard_win_overlay.dart';
import 'package:mahjong/widgets/courtyard/courtyard_world.dart';
import 'package:mahjong/widgets/game_hud.dart';
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
    expect(find.byType(GameHud), findsOneWidget);
    expect(
      find.text('Take a free tile — open on top and one side'),
      findsOneWidget,
    );
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
    expect(find.text(Levels.plotKindOf(1).titleEn), findsOneWidget);
    expect(find.text('Today'), findsNothing);
    expect(find.text('Levels'), findsNothing);
    expect(find.text('Pet'), findsNothing);
    expect(find.text('A friend is waiting'), findsOneWidget);
    expect(find.text('Garden week'), findsNothing);
    expect(find.text('Courtyard week'), findsNothing);
    expect(find.text('Lantern week'), findsNothing);
    expect(find.text('Myth week'), findsNothing);
    expect(find.text('Harvest week'), findsNothing);
    expect(find.text('Earn 8 stars'), findsNothing);
    expect(find.text('Clear 4 campaign levels'), findsNothing);
    expect(find.text('Keep three nights lit'), findsNothing);
    expect(find.text('Sprout'), findsNothing);
    expect(find.text('Bud'), findsNothing);
    expect(find.text('240'), findsNothing);
    expect(
      find.text('Take a free tile — open on top and one side'),
      findsNothing,
    );

    await tester.tap(find.text('A friend is waiting'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 420));
    expect(find.text('Choose a companion'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 340));

    expect(find.text(Levels.plotKindOf(1).titleEn), findsOneWidget);
  });

  testWidgets('courtyard hub shows a one-shot pan hint until a gesture', (
    tester,
  ) async {
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

    expect(find.text('Drag to look around the courtyard'), findsOneWidget);

    tester
        .widget<CourtyardWorld>(find.byType(CourtyardWorld))
        .onPanHint!
        .call();
    await tester.pump();

    expect(find.text('Drag to look around the courtyard'), findsNothing);
  });

  testWidgets('courtyard pan hint hides after a few seconds', (tester) async {
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

    expect(find.text('Drag to look around the courtyard'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));

    expect(find.text('Drag to look around the courtyard'), findsNothing);
  });

  testWidgets(
    'courtyard pan hint returns after a win until the map is dragged',
    (tester) async {
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

      expect(find.text('Drag to look around the courtyard'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('Drag to look around the courtyard'), findsNothing);

      await tester.tap(find.textContaining('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));
      expect(find.byType(GameHud), findsOneWidget);

      final from = CourtyardEstate.fromFocus(
        CourtyardSnapshot.fromStep(step: 2, totalStars: 3),
      );
      final to = CourtyardEstate.fromFocus(
        CourtyardSnapshot.fromStep(step: 3, totalStars: 5),
      );
      Navigator.of(
        tester.element(find.byType(GameHud)),
      ).pop(CourtyardWinReveal(estateFrom: from, estateTo: to));
      await tester.pump();
      expect(find.byType(CourtyardWinOverlay), findsOneWidget);
      expect(find.text('Drag to look around the courtyard'), findsNothing);

      await tester.pump(CourtyardWinOverlay.displayDuration);
      expect(find.byType(CourtyardWinOverlay), findsNothing);
      expect(find.text('Drag to look around the courtyard'), findsOneWidget);

      tester
          .widget<CourtyardWorld>(find.byType(CourtyardWorld))
          .onPanHint!
          .call();
      await tester.pump();
      expect(find.text('Drag to look around the courtyard'), findsNothing);

      await tester.tap(find.textContaining('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 280));
      Navigator.of(
        tester.element(find.byType(GameHud)),
      ).pop(CourtyardWinReveal(estateFrom: from, estateTo: to));
      await tester.pump();
      await tester.pump(CourtyardWinOverlay.displayDuration);
      expect(find.text('Drag to look around the courtyard'), findsNothing);
    },
  );

  testWidgets(
    'campaign hub shows the last played plot, not a new-plot button',
    (tester) async {
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

      expect(find.text(Levels.plotKindOf(24).titleEn), findsOneWidget);
      expect(find.text('New plot'), findsNothing);
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is! Image) return false;
          final image = widget.image;
          return image is AssetImage &&
              image.assetName.endsWith('world/country_base.png');
        }),
        findsWidgets,
      );
    },
  );

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

    expect(find.text(Levels.plotKindOf(1).titleRu), findsOneWidget);
    expect(find.textContaining('Продолжить'), findsOneWidget);
    expect(find.text('Сегодня'), findsNothing);
    expect(find.text('Уровни'), findsNothing);
    expect(find.text('Друг ждёт тебя'), findsOneWidget);
    expect(find.text('Росток'), findsNothing);
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
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Haptic feedback'), findsOneWidget);

    await tester.ensureVisible(find.text('Русский'));
    await tester.pump();
    await tester.tap(find.text('Русский'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(Levels.plotKindOf(1).titleRu), findsOneWidget);
    expect(find.textContaining('Продолжить'), findsOneWidget);
    expect(find.byTooltip('Настройки'), findsOneWidget);
  });

  testWidgets('settings can turn haptic feedback on', (tester) async {
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
    expect(find.text('Music'), findsOneWidget);
    expect(find.text('Haptic feedback'), findsOneWidget);
    expect(find.text('Q mode'), findsOneWidget);
    expect(find.text('Dim covered tiles'), findsOneWidget);

    final hapticToggle = find.descendant(
      of: find.widgetWithText(SwitchListTile, 'Haptic feedback'),
      matching: find.byType(Switch),
    );
    expect(tester.widget<Switch>(hapticToggle).value, isFalse);

    await tester.tap(hapticToggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.widget<Switch>(hapticToggle).value, isTrue);

    await tester.ensureVisible(find.text('Русский'));
    await tester.pump();
    await tester.tap(find.text('Русский'));
    await tester.pump();
    expect(find.text('Звук'), findsOneWidget);
    expect(find.text('Музыка'), findsOneWidget);
    expect(find.text('Тактильный отклик'), findsOneWidget);
    expect(find.text('Режим Q'), findsOneWidget);
    expect(find.text('Затемнять закрытые'), findsOneWidget);
  });

  testWidgets('settings can turn Q mode on', (tester) async {
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

    final qToggle = find.descendant(
      of: find.widgetWithText(SwitchListTile, 'Q mode'),
      matching: find.byType(Switch),
    );
    expect(tester.widget<Switch>(qToggle).value, isFalse);

    await tester.tap(qToggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.widget<Switch>(qToggle).value, isTrue);
  });

  testWidgets('settings can turn covered-tile dimming on', (tester) async {
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

    final dimToggle = find.descendant(
      of: find.widgetWithText(SwitchListTile, 'Dim covered tiles'),
      matching: find.byType(Switch),
    );
    expect(tester.widget<Switch>(dimToggle).value, isFalse);

    await tester.tap(dimToggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.widget<Switch>(dimToggle).value, isTrue);

    await tester.ensureVisible(find.text('Русский'));
    await tester.pump();
    await tester.tap(find.text('Русский'));
    await tester.pump();
    expect(find.text('Затемнять закрытые'), findsOneWidget);
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

  testWidgets('settings can turn music off', (tester) async {
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

    final musicToggle = find.descendant(
      of: find.widgetWithText(SwitchListTile, 'Music'),
      matching: find.byType(Switch),
    );
    expect(tester.widget<Switch>(musicToggle).value, isTrue);

    await tester.tap(musicToggle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.widget<Switch>(musicToggle).value, isFalse);
  });

  testWidgets('settings can change music volume', (tester) async {
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

    final slider = find.byType(Slider);
    expect(slider, findsOneWidget);
    expect(tester.widget<Slider>(slider).value, 0.16);

    tester.widget<Slider>(slider).onChanged!(0.6);
    await tester.pump();
    expect(tester.widget<Slider>(slider).value, closeTo(0.6, 0.001));
  });

  testWidgets('win returns to the courtyard celebration without a win screen', (
    tester,
  ) async {
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

    await tester.tap(find.textContaining('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 280));
    expect(find.byType(GameHud), findsOneWidget);

    final from = CourtyardEstate.fromFocus(
      CourtyardSnapshot.fromStep(step: 2, totalStars: 3),
    );
    final to = CourtyardEstate.fromFocus(
      CourtyardSnapshot.fromStep(step: 3, totalStars: 5),
    );
    Navigator.of(
      tester.element(find.byType(GameHud)),
    ).pop(CourtyardWinReveal(estateFrom: from, estateTo: to));
    await tester.pump();

    expect(find.byType(GameHud), findsNothing);
    expect(find.byType(CourtyardWinOverlay), findsOneWidget);
    expect(find.text('Drag to look around the courtyard'), findsNothing);
    expect(find.text('You win!'), findsOneWidget);
    expect(find.text('Next'), findsNothing);
    expect(find.text('Play again'), findsNothing);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! Image) return false;
        final image = widget.image;
        return image is AssetImage &&
            image.assetName.endsWith('world/country_base.png');
      }),
      findsWidgets,
    );
  });
}
