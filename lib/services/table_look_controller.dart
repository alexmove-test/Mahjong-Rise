import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/table_look.dart';
import 'courtyard_reward_store.dart';
import 'table_look_store.dart';

const tableLookSettingsHintKey = ValueKey('table-look-settings-hint');

/// First campaign levels mention that the table theme can be changed in the menu.
const earlyTableLookLevels = 3;

/// App-wide table skin. New (premium) until the player picks another look.
class TableLookController extends ChangeNotifier {
  TableLookController(this._store) : _look = _store.look;

  TableLookStore _store;
  TableLook _look;
  CourtyardRewardStore? _rewards;
  bool _gateLooks = false;
  bool _userOverride = false;
  bool _settingsHintPending = false;
  int _attachGen = 0;
  int _storeEpoch = 0;

  TableLook get look => _look;

  bool get isCasual => _look.isCasual;

  bool get looksGated => _gateLooks;

  bool get settingsHintPending => _settingsHintPending;

  /// Bumps when a durable store is attached, so a table can sample a look
  /// after preferences finish loading.
  int get storeEpoch => _storeEpoch;

  bool consumeSettingsHint() {
    if (!_settingsHintPending) return false;
    _settingsHintPending = false;
    return true;
  }

  /// Classic, casual, and premium are all in the menu from the first launch.
  bool isUnlocked(TableLook look) => true;

  void attachStore(TableLookStore store) {
    _store = store;
    if (store.canPersist) _storeEpoch++;
    if (_userOverride) {
      unawaited(_store.setLook(_look));
      unawaited(_store.markChosen());
      notifyListeners();
      return;
    }
    final next = store.look;
    final changed = next != _look;
    if (changed) _look = next;
    if (changed || store.canPersist) notifyListeners();
  }

  /// Each game rolls a different look until the player picks one in the menu.
  ///
  /// Levels 1–[earlyTableLookLevels], while the player is still on them, also
  /// ask the table to say that themes can be changed in the menu.
  Future<void> applyEarlyShowcase(
    int levelId, {
    required int maxUnlocked,
    math.Random? random,
  }) async {
    if (!_store.canPersist) return;
    if (levelId < 1) return;
    if (_userOverride || _store.playerChoseLook) return;

    final picked = _rollDifferent(random ?? math.Random());
    _settingsHintPending =
        levelId <= earlyTableLookLevels && maxUnlocked <= earlyTableLookLevels;
    if (picked != _look) {
      _look = picked;
      notifyListeners();
    }
    await _store.saveShowcaseLook(picked);
  }

  Future<void> attachRewards(CourtyardRewardStore store) async {
    _rewards = store;
    _gateLooks = true;
    await _grandfatherCurrent();
  }

  Future<void> _grandfatherCurrent() async {
    final gen = ++_attachGen;
    final rewards = _rewards;
    if (rewards == null) return;
    await rewards.grandfatherLook(_look);
    if (gen != _attachGen) return;
    notifyListeners();
  }

  Future<void> setLook(TableLook value, {bool fromGift = false}) async {
    if (!isUnlocked(value)) return;
    _userOverride = true;
    final changed = value != _look;
    if (changed) _look = value;
    if (fromGift) _settingsHintPending = true;
    await _store.markChosen();
    if (changed) await _store.setLook(value);
    if (changed || fromGift) notifyListeners();
  }

  TableLook _rollDifferent(math.Random random) {
    final others = [
      for (final look in TableLook.values)
        if (look != _look && isUnlocked(look)) look,
    ];
    if (others.isEmpty) return _look;
    return others[random.nextInt(others.length)];
  }
}

class TableLookScope extends InheritedNotifier<TableLookController> {
  const TableLookScope({
    super.key,
    required TableLookController controller,
    required super.child,
  }) : super(notifier: controller);

  TableLookController get controller => notifier!;

  static TableLookController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TableLookScope>();
    assert(scope != null, 'TableLookScope not found');
    return scope!.controller;
  }

  static TableLookController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<TableLookScope>()
        ?.controller;
  }

  static TableLook lookOf(BuildContext context) {
    return maybeOf(context)?.look ?? TableLook.defaultLook;
  }
}
