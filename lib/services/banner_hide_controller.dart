import 'dart:async';

import 'package:flutter/material.dart';

import 'banner_hide_store.dart';

/// Скрытие нижнего баннера на [BannerHideStore.hideFor] после ролика.
class BannerHideController extends ChangeNotifier {
  BannerHideController(BannerHideStore store, {DateTime Function()? clock})
    : _store = store,
      _clock = clock ?? DateTime.now,
      _until = store.hiddenUntil {
    _arm();
  }

  BannerHideStore _store;
  final DateTime Function() _clock;
  DateTime? _until;
  Timer? _timer;

  bool get isHidden {
    final until = _until;
    return until != null && _clock().isBefore(until);
  }

  Duration? get remaining {
    final until = _until;
    if (until == null) return null;
    final left = until.difference(_clock());
    if (left <= Duration.zero) return null;
    return left;
  }

  void attachStore(BannerHideStore store) {
    final local = _until;
    _store = store;
    final stored = store.hiddenUntil;
    if (local != null && (stored == null || local.isAfter(stored))) {
      _until = local;
      unawaited(store.setHiddenUntil(local));
    } else if (stored != null && _clock().isBefore(stored)) {
      _until = stored;
    } else {
      _until = null;
      if (stored != null) unawaited(store.setHiddenUntil(null));
    }
    _arm();
    notifyListeners();
  }

  Future<void> grant() async {
    _until = _clock().add(BannerHideStore.hideFor);
    await _store.setHiddenUntil(_until);
    _arm();
    notifyListeners();
  }

  /// Срок мог истечь, пока приложение было свёрнуто: таймер тогда не тикает.
  void recheck() {
    final until = _until;
    if (until != null && !_clock().isBefore(until)) {
      _until = null;
    }
    _arm();
    notifyListeners();
  }

  void _arm() {
    _timer?.cancel();
    _timer = null;
    final until = _until;
    if (until == null) return;
    final left = until.difference(_clock());
    if (left <= Duration.zero) {
      _until = null;
      return;
    }
    _timer = Timer(left, () {
      final end = _until;
      if (end != null && !_clock().isBefore(end)) {
        _until = null;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class BannerHideScope extends InheritedNotifier<BannerHideController> {
  const BannerHideScope({
    super.key,
    required BannerHideController controller,
    required super.child,
  }) : super(notifier: controller);

  BannerHideController get controller => notifier!;

  static BannerHideController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BannerHideScope>()
        ?.controller;
  }
}
