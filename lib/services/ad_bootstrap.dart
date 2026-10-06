import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/ad_config.dart';
import 'analytics_service.dart';

/// Инициализация AdMob (без падения приложения при ошибке).
class AdBootstrap {
  AdBootstrap._();

  static bool enabled = false;
  static bool initFinished = false;
  static String? initError;

  /// Имитация ролика вместо AdMob (debug / web / desktop).
  static bool get simulation => AdConfig.simulateAds;

  /// Можно показать ролик: AdMob или имитация на web/desktop.
  static bool get available => simulation || enabled;

  static Future<void>? _initFuture;

  static Future<void> init() => _initFuture ??= _init();

  /// Тот же старт, что и [init]: стол может ждать рекламу, не дублируя SDK.
  static Future<void> ensureInitialized() => init();

  /// Consent + SDK. Если первый заход не включил рекламу — пробуем ещё раз.
  static Future<void> prepareForAdRequest() async {
    await init();
    if (simulation || enabled) return;
    _initFuture = null;
    initFinished = false;
    await init();
  }

  static Future<void> _init() async {
    if (AdConfig.simulateAds) {
      enabled = false;
      initFinished = true;
      initError = kDebugMode
          ? 'Simulated rewarded ads in debug'
          : kIsWeb
          ? 'AdMob is unavailable on web'
          : 'AdMob is unavailable on this platform';
      return;
    }
    try {
      await _gatherConsent().timeout(const Duration(seconds: 12));
    } catch (_) {}

    var canRequest = true;
    var status = ConsentStatus.unknown;
    try {
      canRequest = await ConsentInformation.instance.canRequestAds();
      status = await ConsentInformation.instance.getConsentStatus();
    } catch (_) {}

    // UMP often reports canRequestAds=false before the update finishes, or
    // when the form fails to load. That must not skip SDK init — otherwise
    // AdMob sees zero requests and never reviews the app.
    final allowRequests = allowAdRequests(
      canRequestAds: canRequest,
      status: status,
    );

    try {
      await MobileAds.instance.initialize();
      enabled = true;
      initError = allowRequests ? null : 'consent_$status';
    } catch (error) {
      enabled = false;
      initError = error.toString();
      _initFuture = null;
    } finally {
      initFinished = true;
      debugPrint(
        'AdBootstrap enabled=$enabled canRequest=$canRequest '
        'status=$status error=$initError',
      );
      unawaited(
        AnalyticsService.log('ad_init', {
          'ok': enabled ? 1 : 0,
          'can_request': canRequest ? 1 : 0,
          'status': status.name,
          if (initError != null) 'error': _clip(initError!),
        }),
      );
    }
  }

  /// Load unless the user is in a consent-required region and has not answered.
  @visibleForTesting
  static bool allowAdRequests({
    required bool canRequestAds,
    required ConsentStatus status,
  }) {
    if (canRequestAds) return true;
    return status != ConsentStatus.required;
  }

  static String _clip(String value) =>
      value.length <= 99 ? value : value.substring(0, 99);

  static Future<bool> privacyOptionsRequired() async {
    if (AdConfig.simulateAds) return false;
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> showPrivacyOptions() async {
    if (AdConfig.simulateAds) return null;
    try {
      FormError? error;
      await ConsentForm.showPrivacyOptionsForm((formError) {
        error = formError;
      });
      return error?.message;
    } catch (error) {
      return error.toString();
    }
  }

  static Future<void> _gatherConsent() {
    final completer = Completer<void>();
    void done() {
      if (!completer.isCompleted) completer.complete();
    }

    // Force EEA only when a hashed test device is set; otherwise a physical
    // phone never gets the debug geography and can look "broken" in debug.
    final debugSettings = kDebugMode && AdConfig.umpTestDeviceIds.isNotEmpty
        ? ConsentDebugSettings(
            debugGeography: DebugGeography.debugGeographyEea,
            testIdentifiers: AdConfig.umpTestDeviceIds,
          )
        : null;

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(
          tagForUnderAgeOfConsent: false,
          consentDebugSettings: debugSettings,
        ),
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((_) => done());
        },
        (_) => done(),
      );
    } catch (_) {
      done();
    }
    return completer.future;
  }
}
