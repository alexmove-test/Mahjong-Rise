import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/music_controller.dart';
import 'package:mahjong/services/music_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('music is on until the player turns it off', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await MusicStore.open();
    expect(store.enabled, isTrue);
    expect(store.volume, MusicStore.defaultVolume);

    await store.setEnabled(false);
    expect(store.enabled, isFalse);

    final again = await MusicStore.open();
    expect(again.enabled, isFalse);
  });

  test('volume is half the old default and persists', () async {
    SharedPreferences.setMockInitialValues({});
    final store = await MusicStore.open();
    expect(store.volume, 0.16);

    await store.setVolume(0.7);
    expect(store.volume, 0.7);

    final again = await MusicStore.open();
    expect(again.volume, 0.7);
  });

  test('stored volume is clamped', () async {
    SharedPreferences.setMockInitialValues({'app.musicVolume': 2.5});
    final store = await MusicStore.open();
    expect(store.volume, 1.0);

    await store.setVolume(-0.4);
    expect(store.volume, 0.0);
  });

  test('memory store stays enabled and ignores writes', () async {
    final store = MusicStore.memory();
    expect(store.enabled, isTrue);
    expect(store.volume, MusicStore.defaultVolume);
    await store.setEnabled(false);
    await store.setVolume(0.9);
    expect(store.enabled, isTrue);
    expect(store.volume, MusicStore.defaultVolume);
  });

  test('controller gates music until attached prefs load', () async {
    SharedPreferences.setMockInitialValues({'app.musicEnabled': false});
    final controller = MusicController(MusicStore.memory());
    expect(controller.enabled, isTrue);

    controller.attachStore(await MusicStore.open());
    expect(controller.enabled, isFalse);
  });

  test('a toggle before hydrate wins over stored prefs', () async {
    SharedPreferences.setMockInitialValues({'app.musicEnabled': true});
    final controller = MusicController(MusicStore.memory());
    await controller.setEnabled(false);

    controller.attachStore(await MusicStore.open());
    expect(controller.enabled, isFalse);
    expect((await MusicStore.open()).enabled, isFalse);
  });

  test('volume before hydrate wins over stored prefs', () async {
    SharedPreferences.setMockInitialValues({'app.musicVolume': 0.9});
    final controller = MusicController(MusicStore.memory());
    expect(controller.volume, MusicController.defaultVolume);
    await controller.setVolume(0.4);

    controller.attachStore(await MusicStore.open());
    expect(controller.volume, closeTo(0.4, 0.001));
    expect((await MusicStore.open()).volume, closeTo(0.4, 0.001));
  });

  test('controller hydrates stored volume', () async {
    SharedPreferences.setMockInitialValues({'app.musicVolume': 0.55});
    final controller = MusicController(MusicStore.memory());
    expect(controller.volume, MusicController.defaultVolume);

    controller.attachStore(await MusicStore.open());
    expect(controller.volume, closeTo(0.55, 0.001));
  });

  test('background pause is a no-op before init', () {
    final controller = MusicController(MusicStore.memory());
    controller.pauseForBackground();
    controller.resumeFromBackground();
    controller.dispose();
  });
}
