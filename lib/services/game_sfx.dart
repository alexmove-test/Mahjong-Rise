import 'package:audioplayers/audioplayers.dart';

import 'haptic_controller.dart';

/// Звуки партии и тактильный отклик.
///
/// SFX идут через пул плееров, чтобы стук в лоток и нахождение пары
/// не глушили друг друга при быстрых тапах.
class GameSfx {
  GameSfx();

  static const _poolSize = 8;

  final List<AudioPlayer> _pool = List.generate(
    _poolSize,
    (_) => AudioPlayer(),
  );
  final AudioPlayer _voice = AudioPlayer();
  bool _ready = false;
  int _next = 0;
  int _collectIndex = 0;

  Future<void> init() async {
    for (final player in _pool) {
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setPlayerMode(PlayerMode.lowLatency);
    }
    await _voice.setReleaseMode(ReleaseMode.stop);
    _ready = true;
  }

  Future<void> dispose() async {
    _ready = false;
    for (final player in _pool) {
      await player.dispose();
    }
    await _voice.dispose();
  }

  Future<void> _play(String asset, {double volume = 0.7}) async {
    if (!_ready) return;
    final player = _idlePlayer();
    try {
      if (player.state == PlayerState.playing) {
        await player.stop();
      }
      await player.play(AssetSource(asset), volume: volume);
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
    final useBucket = _collectIndex.isOdd;
    _collectIndex += 1;
    if (useBucket) {
      await _play('sfx/collect2.wav', volume: 0.8);
    } else {
      await _play('sfx/collect.wav', volume: 0.85);
    }
  }

  /// Пара снята из лотка.
  Future<void> match() async {
    HapticGate.medium();
    await _play('sfx/match.wav', volume: 0.78);
  }

  /// Лоток полон — проигрыш.
  Future<void> lose() async {
    HapticGate.heavy();
    await _play('sfx/lose.wav', volume: 0.72);
  }

  Future<void> win() async {
    HapticGate.heavy();
    await _play('sfx/win.wav', volume: 0.85);
  }

  /// Ошибка UI: блок, лоток полон при тапе, нет ходов для подсказки.
  Future<void> error() async {
    HapticGate.error();
    await _play('sfx/error.wav', volume: 0.6);
  }

  /// Кнопки: shuffle, undo.
  Future<void> tap() async {
    HapticGate.selection();
    await _play('sfx/tap.wav', volume: 0.45);
  }

  /// Подсказка.
  Future<void> select() async {
    HapticGate.selection();
    await _play('sfx/select.wav', volume: 0.55);
  }

  /// Голос похвалы за быстрые пары. Не обрывает уже идущую реплику и SFX.
  Future<void> praise(String asset) async {
    if (!_ready) return;
    if (_voice.state == PlayerState.playing) return;
    try {
      await _voice.play(AssetSource(asset), volume: 0.7);
    } catch (_) {
      // На CI / без аудио-устройства — молча игнорируем.
    }
  }
}
