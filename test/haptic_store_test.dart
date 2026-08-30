import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/haptic_controller.dart';
import 'package:mahjong/services/haptic_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('haptic is off until the player turns it on', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await HapticStore.open();
    expect(store.enabled, isFalse);

    await store.setEnabled(true);
    expect(store.enabled, isTrue);

    final again = await HapticStore.open();
    expect(again.enabled, isTrue);
  });

  test('memory store stays disabled and ignores writes', () async {
    final store = HapticStore.memory();
    expect(store.enabled, isFalse);
    await store.setEnabled(true);
    expect(store.enabled, isFalse);
  });

  test('controller gates haptic until attached prefs load', () async {
    SharedPreferences.setMockInitialValues({'app.hapticEnabled': true});
    final controller = HapticController(HapticStore.memory());
    expect(controller.enabled, isFalse);
    expect(HapticGate.enabled, isFalse);

    controller.attachStore(await HapticStore.open());
    expect(controller.enabled, isTrue);
    expect(HapticGate.enabled, isTrue);
  });

  test('a toggle before hydrate wins over stored prefs', () async {
    SharedPreferences.setMockInitialValues({'app.hapticEnabled': false});
    final controller = HapticController(HapticStore.memory());
    await controller.setEnabled(true);

    controller.attachStore(await HapticStore.open());
    expect(controller.enabled, isTrue);
    expect(HapticGate.enabled, isTrue);
    expect((await HapticStore.open()).enabled, isTrue);
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
