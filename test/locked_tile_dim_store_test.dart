import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/locked_tile_dim_controller.dart';
import 'package:mahjong/services/locked_tile_dim_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('dimming covered tiles is off until the player turns it on', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await LockedTileDimStore.open();
    expect(store.enabled, isFalse);

    await store.setEnabled(true);
    expect(store.enabled, isTrue);

    final again = await LockedTileDimStore.open();
    expect(again.enabled, isTrue);
  });

  test('memory store stays disabled and ignores writes', () async {
    final store = LockedTileDimStore.memory();
    expect(store.enabled, isFalse);
    await store.setEnabled(true);
    expect(store.enabled, isFalse);
  });

  test('controller hydrates from stored prefs', () async {
    SharedPreferences.setMockInitialValues({'app.dimLockedTiles': true});
    final controller = LockedTileDimController(LockedTileDimStore.memory());
    expect(controller.enabled, isFalse);

    controller.attachStore(await LockedTileDimStore.open());
    expect(controller.enabled, isTrue);
  });

  test('a toggle before hydrate wins over stored prefs', () async {
    SharedPreferences.setMockInitialValues({'app.dimLockedTiles': false});
    final controller = LockedTileDimController(LockedTileDimStore.memory());
    await controller.setEnabled(true);

    controller.attachStore(await LockedTileDimStore.open());
    expect(controller.enabled, isTrue);
    expect((await LockedTileDimStore.open()).enabled, isTrue);
  });
}
