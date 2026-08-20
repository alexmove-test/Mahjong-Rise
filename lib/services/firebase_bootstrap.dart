import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';

/// Инициализация Firebase (без падения приложения при ошибке).
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool enabled = false;
  static String? initError;

  static Future<void> init() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      enabled = false;
      initError = 'Firebase не настроен. Запустите flutterfire configure.';
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      enabled = true;
      initError = null;
    } catch (error) {
      enabled = false;
      initError = error.toString();
    }
  }

  static Future<User?> ensureSignedIn() async {
    if (!enabled) return null;

    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) return auth.currentUser;

    final credential = await auth.signInAnonymously();
    return credential.user;
  }
}
