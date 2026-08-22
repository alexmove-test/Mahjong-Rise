import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/haptic_controller.dart';
import 'package:mahjong/services/haptic_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('haptic is on until the player turns it off', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await HapticStore.open();
    expect(store.enabled, isTrue);

    await store.setEnabled(false);
    expect(store.enabled, isFalse);

    final again = await HapticStore.open();
    expect(again.enabled, isFalse);
  });

  test('memory store stays enabled and ignores writes', () async {
    final store = HapticStore.memory();
    expect(store.enabled, isTrue);
    await store.setEnabled(false);
    expect(store.enabled, isTrue);
  });

  test('controller gates haptic until attached prefs load', () async {
    SharedPreferences.setMockInitialValues({'app.hapticEnabled': false});
    final controller = HapticController(HapticStore.memory());
    expect(controller.enabled, isTrue);
    expect(HapticGate.enabled, isTrue);

    controller.attachStore(await HapticStore.open());
    expect(controller.enabled, isFalse);
    expect(HapticGate.enabled, isFalse);
  });

  test('a toggle before hydrate wins over stored prefs', () async {
    SharedPreferences.setMockInitialValues({'app.hapticEnabled': true});
    final controller = HapticController(HapticStore.memory());
    await controller.setEnabled(false);

    controller.attachStore(await HapticStore.open());
    expect(controller.enabled, isFalse);
    expect(HapticGate.enabled, isFalse);
    expect((await HapticStore.open()).enabled, isFalse);
  });

  test('haptic pulses do not throw without a platform channel', () {
    HapticGate.enabled = true;
    HapticGate.light();
    HapticGate.medium();
    HapticGate.heavy();
    HapticGate.selection();
    HapticGate.error();
    HapticGate.preview();
  });
}
