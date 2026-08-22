import 'dart:async';

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
class HapticGate {
  HapticGate._();

  static bool enabled = true;

  static void light() => _run(HapticFeedback.lightImpact);
  static void medium() => _run(HapticFeedback.mediumImpact);
  static void heavy() => _run(HapticFeedback.heavyImpact);
  static void selection() => _run(HapticFeedback.selectionClick);
  static void error() => _run(HapticFeedback.vibrate);

  static void _run(Future<void> Function() feedback) {
    if (!enabled) return;
    try {
      unawaited(feedback());
    } catch (_) {
      // Desktop / tests / missing vibrator — ignore.
    }
  }
}
