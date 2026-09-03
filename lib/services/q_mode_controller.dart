import 'dart:async';

import 'package:flutter/material.dart';

import 'q_mode_store.dart';

/// App-wide QA toggle. Magnet ads grant [magnetAdReward] charges when on.
class QModeController extends ChangeNotifier {
  QModeController(this._store) : _enabled = _store.enabled;

  QModeStore _store;
  bool _enabled;
  bool _userOverride = false;

  static const magnetAdReward = 50;

  bool get enabled => _enabled;

  int get magnetChargesForAd => enabled ? magnetAdReward : 1;

  void attachStore(QModeStore store) {
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

class QModeScope extends InheritedNotifier<QModeController> {
  const QModeScope({
    super.key,
    required QModeController controller,
    required super.child,
  }) : super(notifier: controller);

  QModeController get controller => notifier!;

  static QModeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<QModeScope>();
    assert(scope != null, 'QModeScope not found');
    return scope!.controller;
  }

  static QModeController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<QModeScope>()?.controller;
  }
}
