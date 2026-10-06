import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/table_look.dart';
import 'package:mahjong/services/courtyard_reward_store.dart';
import 'package:mahjong/services/table_look_controller.dart';
import 'package:mahjong/services/table_look_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'table look stays premium until the player picks another look',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = await TableLookStore.open();
      expect(store.look, TableLook.premium);

      await store.setLook(TableLook.classic);
      expect(store.look, TableLook.classic);

      final again = await TableLookStore.open();
      expect(again.look, TableLook.classic);
    },
  );

  test('memory store stays premium and ignores writes', () async {
    final store = TableLookStore.memory();
    expect(store.look, TableLook.premium);
    await store.setLook(TableLook.classic);
    expect(store.look, TableLook.premium);
  });

  test('unknown stored values fall back to premium', () {
    expect(TableLook.parse(null), TableLook.premium);
    expect(TableLook.parse(''), TableLook.premium);
    expect(TableLook.parse('copper'), TableLook.premium);
    expect(TableLook.parse('classic'), TableLook.classic);
    expect(TableLook.parse('casual'), TableLook.casual);
    expect(TableLook.parse('premium'), TableLook.premium);
  });

  test('premium look round-trips through prefs', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await TableLookStore.open();
    await store.setLook(TableLook.premium);
    expect(store.look, TableLook.premium);
    expect(TableLook.premium.isPremium, isTrue);
    expect(TableLook.premium.isCasual, isFalse);
    expect(TableLook.classic.isPremium, isFalse);

    final again = await TableLookStore.open();
    expect(again.look, TableLook.premium);
  });

  test('controller hydrates from stored prefs', () async {
    SharedPreferences.setMockInitialValues({'app.tableLook': 'classic'});
    final controller = TableLookController(TableLookStore.memory());
    expect(controller.look, TableLook.premium);

    controller.attachStore(await TableLookStore.open());
    expect(controller.look, TableLook.classic);
    expect(controller.isCasual, isFalse);
  });

  test('a pick before hydrate wins over stored prefs', () async {
    SharedPreferences.setMockInitialValues({'app.tableLook': 'casual'});
    final controller = TableLookController(TableLookStore.memory());
    await controller.setLook(TableLook.classic);

    controller.attachStore(await TableLookStore.open());
    expect(controller.look, TableLook.classic);
    expect((await TableLookStore.open()).look, TableLook.classic);
  });

  test('classic and casual are available before any courtyard gift', () async {
    SharedPreferences.setMockInitialValues({});
    final rewards = await CourtyardRewardStore.open();
    final controller = TableLookController(await TableLookStore.open());
    await controller.attachRewards(rewards);

    expect(controller.look, TableLook.premium);
    expect(controller.isUnlocked(TableLook.premium), isTrue);
    expect(controller.isUnlocked(TableLook.casual), isTrue);
    expect(controller.isUnlocked(TableLook.classic), isTrue);

    await controller.setLook(TableLook.casual);
    expect(controller.look, TableLook.casual);
    expect(controller.settingsHintPending, isFalse);

    await controller.setLook(TableLook.classic);
    expect(controller.look, TableLook.classic);

    await controller.setLook(TableLook.premium, fromGift: true);
    expect(controller.look, TableLook.premium);
    expect(controller.settingsHintPending, isTrue);
    expect(controller.consumeSettingsHint(), isTrue);
    expect(controller.settingsHintPending, isFalse);
    expect(controller.consumeSettingsHint(), isFalse);
  });

  test('saved classic look can switch to casual immediately', () async {
    SharedPreferences.setMockInitialValues({'app.tableLook': 'classic'});
    final rewards = await CourtyardRewardStore.open();
    final controller = TableLookController(TableLookStore.memory());
    controller.attachStore(await TableLookStore.open());
    await controller.attachRewards(rewards);

    expect(controller.look, TableLook.classic);
    expect(controller.isUnlocked(TableLook.classic), isTrue);
    expect(controller.isUnlocked(TableLook.casual), isTrue);
    expect(rewards.legacyLooks, {TableLook.classic});
    await controller.setLook(TableLook.casual);
    expect(controller.look, TableLook.casual);
  });

  test('each game rolls another look until the player chooses one', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = TableLookController(await TableLookStore.open());
    final roll = _FixedRoll([0, 0, 0, 1, 0, 0]);
    final seen = <TableLook>[controller.look];

    for (var level = 1; level <= 6; level++) {
      await controller.applyEarlyShowcase(
        level,
        maxUnlocked: level,
        random: roll,
      );
      expect(controller.look, isNot(seen.last));
      seen.add(controller.look);
      expect(controller.settingsHintPending, level <= earlyTableLookLevels);
      expect(controller.consumeSettingsHint(), level <= earlyTableLookLevels);
    }

    expect(seen.toSet(), TableLook.values.toSet());

    final beforeReplay = controller.look;
    await controller.applyEarlyShowcase(
      2,
      maxUnlocked: 2,
      random: _FixedRoll([0]),
    );
    expect(controller.look, isNot(beforeReplay));
    expect(controller.settingsHintPending, isTrue);
  });

  test('a saved look is not replaced on early levels', () async {
    SharedPreferences.setMockInitialValues({'app.tableLook': 'casual'});
    final controller = TableLookController(await TableLookStore.open());

    await controller.applyEarlyShowcase(1, maxUnlocked: 1, random: Random(0));

    expect(controller.look, TableLook.casual);
    expect(controller.settingsHintPending, isFalse);
  });

  test('choosing the current early look stops the rotation', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = TableLookController(await TableLookStore.open());
    await controller.applyEarlyShowcase(1, maxUnlocked: 1, random: Random(0));
    final shown = controller.look;
    controller.consumeSettingsHint();

    await controller.setLook(shown);
    await controller.applyEarlyShowcase(2, maxUnlocked: 2, random: Random(0));

    expect(controller.look, shown);
    expect(controller.settingsHintPending, isFalse);

    final reloaded = TableLookController(await TableLookStore.open());
    await reloaded.applyEarlyShowcase(2, maxUnlocked: 2, random: Random(1));
    expect(reloaded.look, shown);
  });

  test('later games change the look and skip the hint', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = TableLookController(await TableLookStore.open());
    await controller.applyEarlyShowcase(1, maxUnlocked: 1, random: Random(0));
    final shown = controller.look;
    controller.consumeSettingsHint();

    await controller.applyEarlyShowcase(
      4,
      maxUnlocked: 4,
      random: _FixedRoll([0]),
    );

    expect(controller.look, isNot(shown));
    expect(controller.settingsHintPending, isFalse);
  });

  test('memory store does not sample an early look', () async {
    final controller = TableLookController(TableLookStore.memory());
    await controller.applyEarlyShowcase(1, maxUnlocked: 1, random: Random(0));
    expect(controller.look, TableLook.premium);
    expect(controller.settingsHintPending, isFalse);
  });
}

class _FixedRoll implements Random {
  _FixedRoll(this.values);

  final List<int> values;
  var index = 0;

  @override
  int nextInt(int max) => values[index++] % max;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}
