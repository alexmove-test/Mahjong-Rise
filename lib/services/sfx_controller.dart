import 'dart:async';

import 'package:flutter/material.dart';

import 'sfx_store.dart';

/// App-wide sound toggle. [GameSfx] reads [SfxGate.enabled].
class SfxController extends ChangeNotifier {
  SfxController(this._store) : _enabled = _store.enabled {
    SfxGate.enabled = _enabled;
  }

  SfxStore _store;
  bool _enabled;
  bool _userOverride = false;

  bool get enabled => _enabled;

  void attachStore(SfxStore store) {
    _store = store;
    if (_userOverride) {
      unawaited(_store.setEnabled(_enabled));
      return;
    }
    final next = store.enabled;
    if (next == _enabled) return;
    _enabled = next;
    SfxGate.enabled = _enabled;
    if (!_enabled) SfxGate.mute();
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    _userOverride = true;
    SfxGate.enabled = value;
    if (!value) SfxGate.mute();
    await _store.setEnabled(value);
    notifyListeners();
  }
}

class SfxScope extends InheritedNotifier<SfxController> {
  const SfxScope({
    super.key,
    required SfxController controller,
    required super.child,
  }) : super(notifier: controller);

  SfxController get controller => notifier!;

  static SfxController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SfxScope>();
    assert(scope != null, 'SfxScope not found');
    return scope!.controller;
  }

  static SfxController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SfxScope>()?.controller;
  }
}

/// Fire-and-forget mute gate. No-ops when sound is on.
class SfxGate {
  SfxGate._();

  static bool enabled = true;
  static VoidCallback? onMute;

  static void mute() => onMute?.call();
}
