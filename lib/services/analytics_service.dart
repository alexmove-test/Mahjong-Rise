import 'package:firebase_analytics/firebase_analytics.dart';

import 'firebase_bootstrap.dart';

/// Тонкая обёртка: молчит, если Firebase выключен.
abstract final class AnalyticsService {
  AnalyticsService._();

  static Future<void> log(
    String name, [
    Map<String, Object>? parameters,
  ]) async {
    if (!FirebaseBootstrap.enabled) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (_) {}
  }
}
