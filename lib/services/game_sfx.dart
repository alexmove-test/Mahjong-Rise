import 'dart:async';

import 'package:audioplayers/audioplayers.dart';

import 'haptic_controller.dart';
import 'sfx_controller.dart';

/// Звуки партии и тактильный отклик.
///
/// SFX идут через пул плееров, чтобы стук в лоток и нахождение пары
/// не глушили друг друга при быстрых тапах. Голос похвалы живёт на
/// отдельном плеере и смешивается с SFX (без захвата аудиофокуса).
class GameSfx {
  GameSfx();

  static const _poolSize = 8;
  static const _voiceDuck = 0.7;

  final List<AudioPlayer> _pool = List.generate(
    _poolSize,
    (_) => AudioPlayer(),
  );
  final AudioPlayer _voice = AudioPlayer();
  final AudioPlayer _fanfare = AudioPlayer();
  bool _ready = false;
  int _next = 0;

  bool get _voicePlaying => _voice.state == PlayerState.playing;

  Future<void> init() async {
    for (final player in _pool) {
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setPlayerMode(PlayerMode.lowLatency);
    }
    await _voice.setReleaseMode(ReleaseMode.stop);
    await _voice.setPlayerMode(PlayerMode.mediaPlayer);
    await _fanfare.setReleaseMode(ReleaseMode.stop);
    await _fanfare.setPlayerMode(PlayerMode.mediaPlayer);
    await _applyMixContext();
    SfxGate.onMute = _stopAll;
    _ready = true;
  }

  Future<void> _applyMixContext() async {
    try {
      final mix = AudioContextConfig(
        focus: AudioContextConfigFocus.mixWithOthers,
      ).build();
      await AudioPlayer.global.setAudioContext(mix);
      for (final player in _pool) {
        await player.setAudioContext(mix);
      }
      await _voice.setAudioContext(mix);
      await _fanfare.setAudioContext(mix);
    } catch (_) {
      // Web / тесты / платформа без AudioContext.
    }
  }

  Future<void> dispose() async {
    _ready = false;
    if (SfxGate.onMute == _stopAll) SfxGate.onMute = null;
    for (final player in _pool) {
      await player.dispose();
    }
    await _voice.dispose();
    await _fanfare.dispose();
  }

  void _stopAll() {
    for (final player in _pool) {
      if (player.state == PlayerState.playing) {
        unawaited(player.stop());
      }
    }
    if (_voice.state == PlayerState.playing) {
      unawaited(_voice.stop());
    }
    if (_fanfare.state == PlayerState.playing) {
      unawaited(_fanfare.stop());
    }
  }

  Future<void> _play(String asset, {double volume = 0.7}) async {
    if (!_ready || !SfxGate.enabled) return;
    final player = _idlePlayer();
    final gain = _voicePlaying ? volume * _voiceDuck : volume;
    try {
      if (player.state == PlayerState.playing) {
        await player.stop();
      }
      if (!SfxGate.enabled) return;
      await player.play(AssetSource(asset), volume: gain);
    } catch (_) {
      // На CI / без аудио-устройства — молча игнорируем.
    }
  }

  AudioPlayer _idlePlayer() {
    for (var i = 0; i < _pool.length; i++) {
      final index = (_next + i) % _pool.length;
      final player = _pool[index];
      if (player.state != PlayerState.playing) {
        _next = (index + 1) % _pool.length;
        return player;
      }
    }
    final player = _pool[_next];
    _next = (_next + 1) % _pool.length;
    return player;
  }

  /// Плитка ушла в лоток.
  Future<void> collect() async {
    HapticGate.light();
    await _play('sfx/collect.mp3', volume: 0.85);
  }

  static const _matchVolume = 0.82;

  /// Пара снята из лотка.
  Future<void> match() async {
    HapticGate.medium();
    await _play('sfx/match.mp3', volume: _matchVolume);
  }

  /// Редкий удар плиток друг о друга — обычный матч, на 20% громче.
  Future<void> smash() async {
    HapticGate.heavy();
    await _play('sfx/match.mp3', volume: (_matchVolume * 1.2).clamp(0.0, 1.0));
  }

  /// Лоток полон — проигрыш.
  Future<void> lose() async {
    HapticGate.heavy();
    await _play('sfx/lose.wav', volume: 0.72);
  }

  Future<void> win() async {
    HapticGate.heavy();
    if (!_ready || !SfxGate.enabled) return;
    try {
      if (_fanfare.state == PlayerState.playing) {
        await _fanfare.stop();
      }
      if (!SfxGate.enabled) return;
      await _fanfare.play(AssetSource('sfx/win.mp3'), volume: 0.9);
    } catch (_) {
      // На CI / без аудио-устройства — молча игнорируем.
    }
  }

  /// Ошибка UI: блок, лоток полон при тапе, нет ходов для подсказки.
  Future<void> error() async {
    HapticGate.error();
    await _play('sfx/error.wav', volume: 0.6);
  }

  /// Кнопки: shuffle.
  Future<void> tap() async {
    HapticGate.selection();
    await _play('sfx/tap.wav', volume: 0.45);
  }

  /// Отмена последнего действия.
  Future<void> undo() async {
    HapticGate.selection();
    await _play('sfx/undo.mp3', volume: 0.8);
  }

  /// Магнит: пара улетает с поля.
  Future<void> magnet() async {
    HapticGate.medium();
    await _play('sfx/magnet.mp3', volume: 0.85);
  }

  /// Подсказка.
  Future<void> select() async {
    HapticGate.selection();
    await _play('sfx/select.wav', volume: 0.55);
  }

  /// Голос похвалы за быстрые пары. Не обрывает уже идущую реплику и SFX.
  Future<void> praise(String asset) async {
    if (!_ready || !SfxGate.enabled) return;
    if (_voicePlaying) return;
    try {
      await _voice.play(AssetSource(asset), volume: 0.7);
    } catch (_) {
      // На CI / без аудио-устройства — молча игнорируем.
    }
  }
}
