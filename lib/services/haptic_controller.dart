import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'haptic_store.dart';

/// App-wide haptic toggle. [GameSfx] and UI read [enabled].
class HapticController extends ChangeNotifier {
  HapticController(this._store) : _enabled = _store.enabled {
    HapticGate.enabled = _enabled;
  }

  HapticStore _store;
  bool _enabled;
  bool _userOverride = false;

  bool get enabled => _enabled;

  void attachStore(HapticStore store) {
    _store = store;
    if (_userOverride) {
      unawaited(_store.setEnabled(_enabled));
      return;
    }
    final next = store.enabled;
    if (next == _enabled) return;
    _enabled = next;
    HapticGate.enabled = _enabled;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    _userOverride = true;
    HapticGate.enabled = value;
    if (value) HapticGate.preview();
    await _store.setEnabled(value);
    notifyListeners();
  }
}

class HapticScope extends InheritedNotifier<HapticController> {
  const HapticScope({
    super.key,
    required HapticController controller,
    required super.child,
  }) : super(notifier: controller);

  HapticController get controller => notifier!;

  static HapticController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HapticScope>();
    assert(scope != null, 'HapticScope not found');
    return scope!.controller;
  }

  static HapticController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<HapticScope>()
        ?.controller;
  }
}

/// Fire-and-forget platform haptics. No-ops when disabled or unsupported.
///
/// Android [HapticFeedback] is a keyboard tick and follows the system
/// "touch vibration" setting, so many phones stay silent. We drive the
/// vibrator motor instead, then fall back to [HapticFeedback] if needed.
class HapticGate {
  HapticGate._();

  static const _channel = MethodChannel('com.rise.mahjong/haptics');

  static bool enabled = false;

  static void light() => _pulse(androidMs: 55, androidAmplitude: 255);
  static void medium() => _pulse(androidMs: 90, androidAmplitude: 255);
  static void heavy() => _pulse(androidMs: 140, androidAmplitude: 255);
  static void selection() => _pulse(androidMs: 45, androidAmplitude: 255);
  static void error() => _pulse(androidMs: 110, androidAmplitude: 255);
  static void preview() => _pulse(androidMs: 160, androidAmplitude: 255);

  static void _pulse({required int androidMs, required int androidAmplitude}) {
    if (!enabled) return;
    unawaited(_run(androidMs: androidMs, androidAmplitude: androidAmplitude));
  }

  static Future<void> _run({
    required int androidMs,
    required int androidAmplitude,
  }) async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _channel.invokeMethod<void>('vibrate', {
          'duration': androidMs,
          'amplitude': androidAmplitude,
        });
        return;
      }
      await HapticFeedback.mediumImpact();
    } catch (_) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {
        // Desktop / tests / missing vibrator — ignore.
      }
    }
  }
}
