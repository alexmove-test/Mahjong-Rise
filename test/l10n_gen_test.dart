import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/l10n/l10n.dart';
import 'package:mahjong/l10n/locale_controller.dart';
import 'package:mahjong/services/locale_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('translations cover every English message and placeholder', () {
    final en =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
            as Map<String, dynamic>;
    final keys = en.keys.where((key) => !key.startsWith('@'));
    for (final code in ['ru', 'th']) {
      final translated =
          jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
              as Map<String, dynamic>;
      expect(
        translated.keys.where((key) => !key.startsWith('@')),
        keys,
        reason: code,
      );
      for (final key in keys) {
        final meta = en['@$key'];
        if (meta is! Map) continue;
        final placeholders = meta['placeholders'];
        if (placeholders is! Map) continue;
        final translatedMeta = translated['@$key'];
        expect(translatedMeta, isA<Map>(), reason: '$code $key');
        expect(
          (translatedMeta as Map)['placeholders'],
          placeholders,
          reason: '$code $key',
        );
      }
    }
  });

  test('language preference stays on the existing key', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocaleStore.open();
    await store.setPreference(LanguagePref.ru);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('app.languagePref'), 'ru');

    final again = await LocaleStore.open();
    expect(again.preference, LanguagePref.ru);
    expect(LocaleStore.resolve(again.preference, 'en'), 'ru');

    await again.setPreference(LanguagePref.system);
    expect(prefs.getString('app.languagePref'), isNull);
    expect(again.preference, LanguagePref.system);
  });

  test('unsupported and stored Ukrainian choices fall back to English', () async {
    SharedPreferences.setMockInitialValues({'app.languagePref': 'uk'});
    final store = await LocaleStore.open();
    expect(store.preference, LanguagePref.en);
    expect(LocaleStore.resolve(store.preference, 'uk'), 'en');
    expect(LocaleStore.resolve(LanguagePref.system, 'de'), 'en');
    expect(LocaleStore.resolve(LanguagePref.system, 'uk'), 'en');
    expect(LocaleStore.resolve(LanguagePref.system, 'th'), 'th');
  });

  test('a stored Thai choice stays Thai', () async {
    SharedPreferences.setMockInitialValues({'app.languagePref': 'th'});
    final store = await LocaleStore.open();
    expect(store.preference, LanguagePref.th);
    expect(LocaleStore.resolve(store.preference, 'en'), 'th');
  });

  test('Russian plurals use one, few, and many', () {
    final en = lookupAppLocalizations(const Locale('en'));
    final ru = lookupAppLocalizations(const Locale('ru'));

    expect(en.winsUntilHouseUpgrade(1), 'Your next win upgrades the house');
    expect(en.winsUntilHouseUpgrade(2), '2 wins until the house upgrade');
    expect(en.winsUntilHouseUpgrade(5), '5 wins until the house upgrade');
    expect(en.winsUntilHouseUpgrade(11), '11 wins until the house upgrade');
    expect(en.winsUntilHouseUpgrade(21), '21 wins until the house upgrade');

    expect(ru.winsUntilHouseUpgrade(1), 'Следующая победа улучшит дом');
    expect(ru.winsUntilHouseUpgrade(2), 'До улучшения дома — 2 победы');
    expect(ru.winsUntilHouseUpgrade(5), 'До улучшения дома — 5 побед');
    expect(ru.winsUntilHouseUpgrade(11), 'До улучшения дома — 11 побед');
    expect(ru.winsUntilHouseUpgrade(21), 'До улучшения дома — 21 победа');

    expect(ru.hubStarsUntilReward(1), 'ещё 1 звезда до награды');
    expect(ru.hubStarsUntilReward(2), 'ещё 2 звезды до награды');
    expect(ru.hubStarsUntilReward(5), 'ещё 5 звёзд до награды');
    expect(ru.hubStarsUntilReward(11), 'ещё 11 звёзд до награды');
    expect(ru.hubStarsUntilReward(21), 'ещё 21 звезда до награды');

    expect(en.pointsReward(1), '+1 point');
    expect(en.pointsReward(21), '+21 points');
    expect(ru.pointsReward(1), '+1 балл');
    expect(ru.pointsReward(2), '+2 балла');
    expect(ru.pointsReward(5), '+5 баллов');
    expect(ru.pointsReward(11), '+11 баллов');
    expect(ru.pointsReward(21), '+21 балл');
  });

  testWidgets('switching language updates visible text', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await LocaleStore.open();
    final controller = LocaleController(
      store,
      deviceLocale: const Locale('en'),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      LocaleScope(
        controller: controller,
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            return MaterialApp(
              locale: controller.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              localeResolutionCallback: (_, _) => controller.locale,
              home: Builder(
                builder: (context) {
                  return Text(AppLocalizations.of(context).settings);
                },
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);

    await controller.setPreference(LanguagePref.ru);
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);

    await controller.setPreference(LanguagePref.th);
    await tester.pumpAndSettle();
    expect(find.text('ตั้งค่า'), findsOneWidget);
  });

  testWidgets('an unsupported locale resolves to English', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Text(AppLocalizations.of(context).settings),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });
}
