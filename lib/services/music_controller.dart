import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'music_store.dart';

/// App-wide looping background music, independent of SFX.
class MusicController extends ChangeNotifier {
  MusicController(this._store)
    : _enabled = _store.enabled,
      _volume = _store.volume;

  static const asset = 'music/bgm.mp3';
  static const defaultVolume = MusicStore.defaultVolume;

  MusicStore _store;
  bool _enabled;
  double _volume;
  bool _enabledOverride = false;
  bool _volumeOverride = false;
  bool _ready = false;
  bool _pausedByLifecycle = false;
  AudioPlayer? _player;

  bool get enabled => _enabled;
  double get volume => _volume;

  Future<void> init() async {
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setPlayerMode(PlayerMode.mediaPlayer);
    await player.setVolume(_volume);
    try {
      final mix = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build();
      await player.setAudioContext(mix);
    } catch (_) {
      // Web / тесты / платформа без AudioContext.
    }
    _player = player;
    _ready = true;
    if (_enabled) await _play();
  }

  void attachStore(MusicStore store) {
    _store = store;
    var changed = false;
    if (_enabledOverride) {
      unawaited(_store.setEnabled(_enabled));
    } else {
      final next = store.enabled;
      if (next != _enabled) {
        _enabled = next;
        if (_enabled) {
          unawaited(_play());
        } else {
          unawaited(_stop());
        }
        changed = true;
      }
    }
    if (_volumeOverride) {
      unawaited(_store.setVolume(_volume));
    } else {
      final next = store.volume;
      if ((next - _volume).abs() >= 0.001) {
        _volume = next;
        unawaited(_applyVolume());
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    _enabledOverride = true;
    _pausedByLifecycle = false;
    if (value) {
      await _play();
    } else {
      await _stop();
    }
    await _store.setEnabled(value);
    notifyListeners();
  }

  Future<void> setVolume(double value) async {
    final next = value.clamp(0.0, 1.0);
    if ((next - _volume).abs() < 0.001) return;
    _volume = next;
    _volumeOverride = true;
    await _applyVolume();
    await _store.setVolume(next);
    notifyListeners();
  }

  void pauseForBackground() {
    if (!_enabled || !_ready) return;
    final player = _player;
    if (player == null || player.state != PlayerState.playing) return;
    _pausedByLifecycle = true;
    unawaited(player.pause());
  }

  void resumeFromBackground() {
    if (!_enabled || !_ready || !_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    unawaited(_player?.resume());
  }

  Future<void> _applyVolume() async {
    try {
      await _player?.setVolume(_volume);
    } catch (_) {}
  }

  Future<void> _play() async {
    if (!_ready || !_enabled) return;
    final player = _player;
    if (player == null) return;
    try {
      if (player.state == PlayerState.playing) return;
      if (player.state == PlayerState.paused) {
        await player.setVolume(_volume);
        await player.resume();
        return;
      }
      await player.play(AssetSource(asset), volume: _volume);
    } catch (_) {
      // На CI / без аудио-устройства — молча игнорируем.
    }
  }

  Future<void> _stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _ready = false;
    final player = _player;
    _player = null;
    unawaited(player?.dispose());
    super.dispose();
  }
}

class MusicScope extends InheritedNotifier<MusicController> {
  const MusicScope({
    super.key,
    required MusicController controller,
    required super.child,
  }) : super(notifier: controller);

  MusicController get controller => notifier!;

  static MusicController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<MusicScope>();
    assert(scope != null, 'MusicScope not found');
    return scope!.controller;
  }

  static MusicController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MusicScope>()?.controller;
  }
}
