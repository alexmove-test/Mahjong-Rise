import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Конфигурация Firebase.
///
/// Замените значения после `flutterfire configure` или вручную из Firebase Console.
/// Пока `projectId == REPLACE_ME`, онлайн-рейтинг отключён.
class DefaultFirebaseOptions {
  static const placeholderProjectId = 'REPLACE_ME';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web Firebase options are not configured.');
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => ios,
      _ => throw UnsupportedError(
        'Firebase is not configured for $defaultTargetPlatform.',
      ),
    };
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD16bmVZXRuOlJqTzkUGvCluMXqvLF1rJI',
    appId: '1:872111737653:android:8076b70a6edf1e36131a7c',
    messagingSenderId: '872111737653',
    projectId: 'mahjong-rise',
    storageBucket: 'mahjong-rise.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: 'REPLACE_ME',
    messagingSenderId: 'REPLACE_ME',
    projectId: placeholderProjectId,
    storageBucket: 'REPLACE_ME',
    iosBundleId: 'com.mahjong.mahjong',
  );

  static bool get isConfigured {
    try {
      return currentPlatform.projectId != placeholderProjectId;
    } catch (_) {
      return false;
    }
  }
}
