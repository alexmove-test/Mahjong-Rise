import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/guest_name.dart';
import 'package:mahjong/services/player_profile_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('guest names stay within the ranking cap', () {
    for (var i = 0; i < 200; i++) {
      final en = GuestName.generate(isRu: false, random: Random(i));
      final ru = GuestName.generate(isRu: true, random: Random(i));
      expect(en.length, inInclusiveRange(1, GuestName.maxLength));
      expect(ru.length, inInclusiveRange(1, GuestName.maxLength));
      expect(en, isNot(anyOf('You', 'Player', '')));
      expect(ru, isNot(anyOf('Вы', 'Игрок', '')));
    }
  });

  test('seeded guest names are stable', () {
    expect(
      GuestName.generate(isRu: false, random: Random(42)),
      GuestName.generate(isRu: false, random: Random(42)),
    );
    expect(
      GuestName.generate(isRu: true, random: Random(42)),
      GuestName.generate(isRu: true, random: Random(42)),
    );
  });

  test('fresh profile gets a guest name until the player sets one', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await PlayerProfileStore.open();

    expect(first.hasCustomName, isFalse);
    expect(first.displayName, isNot(anyOf('You', 'Вы', '')));
    expect(first.displayName.length, inInclusiveRange(1, GuestName.maxLength));

    final again = await PlayerProfileStore.open();
    expect(again.displayName, first.displayName);

    await again.setDisplayName('Mila');
    expect(again.hasCustomName, isTrue);
    expect(again.displayName, 'Mila');

    await again.setDisplayName('  ');
    expect(again.hasCustomName, isFalse);
    expect(again.displayName, first.displayName);
  });

  test('saved custom name is not replaced by a guest name', () async {
    SharedPreferences.setMockInitialValues({
      'player.displayName': 'Ren',
    });
    final profile = await PlayerProfileStore.open();
    expect(profile.hasCustomName, isTrue);
    expect(profile.displayName, 'Ren');
  });
}
