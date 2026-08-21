import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/locale_store.dart';

void main() {
  test('system follows the first supported device language', () {
    expect(LocaleStore.resolve(LanguagePref.system, ['ru']), 'ru');
    expect(LocaleStore.resolve(LanguagePref.system, ['en', 'ru']), 'en');
    expect(LocaleStore.resolve(LanguagePref.system, ['uk', 'ru']), 'ru');
    expect(LocaleStore.resolve(LanguagePref.system, ['de', 'fr']), 'en');
    expect(LocaleStore.resolve(LanguagePref.ru, ['en']), 'ru');
    expect(LocaleStore.resolve(LanguagePref.en, ['ru']), 'en');
  });

  test('strips region tags from device codes', () {
    expect(LocaleStore.resolveDevice(['ru_RU', 'en']), 'ru');
    expect(LocaleStore.resolveDevice(['zh-Hans', 'en-US']), 'en');
  });
}
