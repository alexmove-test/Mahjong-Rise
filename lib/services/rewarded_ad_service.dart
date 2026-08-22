import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';
import '../widgets/simulated_rewarded_ad.dart';
import 'ad_bootstrap.dart';

enum _RealAdResult { earned, skipped, failed }

/// Загрузка и показ rewarded-рекламы за буст.
class RewardedAdService {
  RewardedAd? _ad;
  Future<void>? _loadFuture;

  bool get isReady => AdBootstrap.simulation || _ad != null;

  Future<void> preload() {
    if (AdBootstrap.simulation || !AdBootstrap.enabled) {
      return Future.value();
    }
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
    if (!AdBootstrap.simulation && AdBootstrap.enabled) {
      if (_ad == null) await preload();
      if (_ad != null) {
        final result = await _showReal();
        if (result != _RealAdResult.failed) {
          return result == _RealAdResult.earned;
        }
      }
    }
    return _showSimulated(context);
  }

  Future<bool> _showSimulated(BuildContext? context) async {
    if (context == null || !context.mounted) return false;
    return SimulatedRewardedAd.show(context);
  }

  Future<_RealAdResult> _showReal() async {
    final ad = _ad!;
    _ad = null;

    final completer = Completer<_RealAdResult>();
    var rewarded = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (d) {
        d.dispose();
        unawaited(preload());
        if (!completer.isCompleted) {
          completer.complete(
            rewarded ? _RealAdResult.earned : _RealAdResult.skipped,
          );
        }
      },
      onAdFailedToShowFullScreenContent: (d, _) {
        d.dispose();
        unawaited(preload());
        if (!completer.isCompleted) completer.complete(_RealAdResult.failed);
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
