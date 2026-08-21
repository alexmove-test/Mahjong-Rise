import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/widgets.dart';

import '../config/ad_config.dart';
import '../widgets/simulated_rewarded_ad.dart';
import 'ad_bootstrap.dart';

/// Загрузка и показ rewarded-рекламы за буст.
class RewardedAdService {
  RewardedAd? _ad;
  Future<void>? _loadFuture;

  bool get isReady => AdBootstrap.simulation || _ad != null;

  Future<void> preload() {
    if (AdBootstrap.simulation) return Future.value();
    if (!AdBootstrap.enabled) return Future.value();
    if (_ad != null) return Future.value();
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    final completer = Completer<void>();
    await RewardedAd.load(
      adUnitId: AdConfig.rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadFuture = null;
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (_) {
          _loadFuture = null;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    await completer.future;
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
    _loadFuture = null;
  }

  /// Показывает рекламу. Возвращает `true`, если игрок досмотрел до награды.
  Future<bool> show({BuildContext? context}) async {
    if (AdBootstrap.simulation) {
      if (context == null || !context.mounted) return false;
      return SimulatedRewardedAd.show(context);
    }
    if (!AdBootstrap.enabled) return false;

    if (_ad == null) {
      await preload();
      if (_ad == null) return false;
    }

    final ad = _ad!;
    _ad = null;

    final completer = Completer<bool>();
    var rewarded = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (d) {
        d.dispose();
        unawaited(preload());
        if (!completer.isCompleted) completer.complete(rewarded);
      },
      onAdFailedToShowFullScreenContent: (d, _) {
        d.dispose();
        unawaited(preload());
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await ad.show(
      onUserEarnedReward: (_, _) {
        rewarded = true;
      },
    );

    return completer.future;
  }
}
