import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/q_mode_controller.dart';
import 'package:mahjong/services/q_mode_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('Q mode is off until the player turns it on', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await QModeStore.open();
    expect(store.enabled, isFalse);

    await store.setEnabled(true);
    expect(store.enabled, isTrue);

    final again = await QModeStore.open();
    expect(again.enabled, isTrue);
  });

  test('memory store stays disabled and ignores writes', () async {
    final store = QModeStore.memory();
    expect(store.enabled, isFalse);
    await store.setEnabled(true);
    expect(store.enabled, isFalse);
  });

  test('controller hydrates from stored prefs', () async {
    SharedPreferences.setMockInitialValues({'app.qModeEnabled': true});
    final controller = QModeController(QModeStore.memory());
    expect(controller.enabled, isFalse);
    expect(controller.magnetChargesForAd, 1);

    controller.attachStore(await QModeStore.open());
    expect(controller.enabled, isTrue);
    expect(controller.magnetChargesForAd, QModeController.magnetAdReward);
  });

  test('a toggle before hydrate wins over stored prefs', () async {
    SharedPreferences.setMockInitialValues({'app.qModeEnabled': false});
    final controller = QModeController(QModeStore.memory());
    await controller.setEnabled(true);

    controller.attachStore(await QModeStore.open());
    expect(controller.enabled, isTrue);
    expect((await QModeStore.open()).enabled, isTrue);
  });
}
