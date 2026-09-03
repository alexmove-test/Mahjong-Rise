import 'dart:async';

import 'package:flutter/material.dart';

import 'locked_tile_dim_store.dart';

/// App-wide toggle: gray out covered tiles. Off until the player turns it on.
class LockedTileDimController extends ChangeNotifier {
  LockedTileDimController(this._store) : _enabled = _store.enabled;

  LockedTileDimStore _store;
  bool _enabled;
  bool _userOverride = false;

  bool get enabled => _enabled;

  void attachStore(LockedTileDimStore store) {
    _store = store;
    if (_userOverride) {
      unawaited(_store.setEnabled(_enabled));
      return;
    }
    final next = store.enabled;
    if (next == _enabled) return;
    _enabled = next;
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (value == _enabled) return;
    _enabled = value;
    _userOverride = true;
    await _store.setEnabled(value);
    notifyListeners();
  }
}

class LockedTileDimScope extends InheritedNotifier<LockedTileDimController> {
  const LockedTileDimScope({
    super.key,
    required LockedTileDimController controller,
    required super.child,
  }) : super(notifier: controller);

  LockedTileDimController get controller => notifier!;

  static LockedTileDimController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LockedTileDimScope>();
    assert(scope != null, 'LockedTileDimScope not found');
    return scope!.controller;
  }

  static LockedTileDimController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<LockedTileDimScope>()
        ?.controller;
  }
}
