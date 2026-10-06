import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';
import '../widgets/simulated_rewarded_ad.dart';
import 'ad_bootstrap.dart';
import 'analytics_service.dart';

enum RewardedAdShowResult { earned, skipped, failed }

/// Загрузка и показ rewarded-рекламы за буст.
class RewardedAdService {
  RewardedAdService._();

  static final instance = RewardedAdService._();

  static const _loadTimeout = Duration(seconds: 15);
  static const _retries = 3;
  static const _retryDelay = Duration(milliseconds: 700);

  /// Тестовый креатив показывает «вознаграждение получено» на карточке,
  /// а `onUserEarnedReward` на Android часто приходит уже после закрытия.
  /// Раньше dispose в dismiss выбрасывал этот колбэк, и буст не начислялся.
  static const _rewardGrace = Duration(milliseconds: 700);

  RewardedAd? _ad;
  Future<void>? _loadFuture;
  String? lastError;

  bool get isReady => AdBootstrap.simulation || _ad != null;

  Future<void> preload() {
    if (AdBootstrap.simulation || !AdBootstrap.enabled) {
      return Future.value();
    }
    if (_ad != null) return Future.value();
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    try {
      for (var attempt = 0; attempt < _retries; attempt++) {
        if (await _loadOnce()) return;
        if (attempt < _retries - 1) {
          await Future<void>.delayed(_retryDelay);
        }
      }
    } finally {
      _loadFuture = null;
    }
  }

  Future<bool> _loadOnce() async {
    final completer = Completer<bool>();
    void finish(bool loaded) {
      if (!completer.isCompleted) completer.complete(loaded);
    }

    try {
      await RewardedAd.load(
        adUnitId: AdConfig.rewardedUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _ad = ad;
            lastError = null;
            debugPrint('RewardedAd loaded ${AdConfig.rewardedUnitId}');
            finish(true);
          },
          onAdFailedToLoad: (error) {
            lastError = '${error.code} ${error.message}';
            debugPrint('RewardedAd failed: $lastError');
            unawaited(
              AnalyticsService.log('ad_load_fail', {
                'code': error.code,
                'msg': error.message.length <= 99
                    ? error.message
                    : error.message.substring(0, 99),
              }),
            );
            finish(false);
          },
        ),
      );
      return await completer.future.timeout(
        _loadTimeout,
        onTimeout: () {
          lastError ??= 'timeout';
          return false;
        },
      );
    } catch (error) {
      lastError = error.toString();
      debugPrint('RewardedAd load threw: $lastError');
      return false;
    }
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
    _loadFuture = null;
  }

  /// Показывает рекламу. Имитация только на web/desktop и в тестах.
  Future<RewardedAdShowResult> show({BuildContext? context}) async {
    if (AdBootstrap.simulation) {
      return _showSimulated(context);
    }
    if (!AdBootstrap.enabled) return RewardedAdShowResult.failed;
    if (_ad == null) await preload();
    if (_ad == null) return RewardedAdShowResult.failed;
    return _showReal();
  }

  Future<RewardedAdShowResult> _showSimulated(BuildContext? context) async {
    if (context == null || !context.mounted) {
      return RewardedAdShowResult.failed;
    }
    final earned = await SimulatedRewardedAd.show(context);
    return earned ? RewardedAdShowResult.earned : RewardedAdShowResult.skipped;
  }

  Future<RewardedAdShowResult> _showReal() async {
    final ad = _ad!;
    _ad = null;

    final completer = Completer<RewardedAdShowResult>();
    var rewarded = false;
    var finished = false;
    Timer? grace;

    void finish(RewardedAdShowResult result) {
      if (finished) return;
      finished = true;
      grace?.cancel();
      grace = null;
      unawaited(() async {
        await ad.dispose();
        unawaited(preload());
        if (!completer.isCompleted) completer.complete(result);
      }());
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        debugPrint('RewardedAd dismissed rewarded=$rewarded');
        if (rewarded) {
          finish(RewardedAdShowResult.earned);
          return;
        }
        // Не dispose сразу: поздний onUserEarnedReward иначе теряется,
        // потому что id объявления уже снят с учёта.
        grace = Timer(_rewardGrace, () {
          finish(
            rewarded
                ? RewardedAdShowResult.earned
                : RewardedAdShowResult.skipped,
          );
        });
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        debugPrint('RewardedAd failed to show: $error');
        finish(RewardedAdShowResult.failed);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (_, reward) {
          rewarded = true;
          debugPrint('RewardedAd earned ${reward.amount} ${reward.type}');
          if (grace != null) finish(RewardedAdShowResult.earned);
        },
      );
    } catch (error) {
      debugPrint('RewardedAd show threw: $error');
      finish(RewardedAdShowResult.failed);
    }

    return completer.future;
  }
}
