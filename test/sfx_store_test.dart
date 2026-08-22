import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/sfx_controller.dart';
import 'package:mahjong/services/sfx_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('sfx is on until the player turns it off', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await SfxStore.open();
    expect(store.enabled, isTrue);

    await store.setEnabled(false);
    expect(store.enabled, isFalse);

    final again = await SfxStore.open();
    expect(again.enabled, isFalse);
  });

  test('memory store stays enabled and ignores writes', () async {
    final store = SfxStore.memory();
    expect(store.enabled, isTrue);
    await store.setEnabled(false);
    expect(store.enabled, isTrue);
  });

  test('controller gates sfx until attached prefs load', () async {
    SharedPreferences.setMockInitialValues({'app.sfxEnabled': false});
    final controller = SfxController(SfxStore.memory());
    expect(controller.enabled, isTrue);
    expect(SfxGate.enabled, isTrue);

    controller.attachStore(await SfxStore.open());
    expect(controller.enabled, isFalse);
    expect(SfxGate.enabled, isFalse);
  });

  test('a toggle before hydrate wins over stored prefs', () async {
    SharedPreferences.setMockInitialValues({'app.sfxEnabled': true});
    final controller = SfxController(SfxStore.memory());
    await controller.setEnabled(false);

    controller.attachStore(await SfxStore.open());
    expect(controller.enabled, isFalse);
    expect(SfxGate.enabled, isFalse);
    expect((await SfxStore.open()).enabled, isFalse);
  });

  test('turning sound off notifies the mute callback', () async {
    var muted = 0;
    SfxGate.onMute = () => muted += 1;
    addTearDown(() => SfxGate.onMute = null);

    final controller = SfxController(SfxStore.memory());
    await controller.setEnabled(false);
    expect(muted, 1);
    expect(SfxGate.enabled, isFalse);
  });
}
