import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'debug_agent_log.dart';
import 'debug_boot_timer.dart';
import 'l10n/locale_controller.dart';
import 'screens/level_select_screen.dart';
import 'services/ad_bootstrap.dart';
import 'services/firebase_bootstrap.dart';
import 'services/locale_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  // #region agent log
  agentDbg(
    location: 'main.dart:start',
    message: 'boot start, UI first',
    hypothesisId: 'B',
    runId: 'post-fix',
    data: {'ms': agentBoot.elapsedMilliseconds, 'kIsWeb': kIsWeb},
  );
  // #endregion
  final localeStore = await LocaleStore.open();
  runApp(MahjongApp(localeStore: localeStore));
  // #region agent log
  agentDbg(
    location: 'main.dart:runApp',
    message: 'runApp called before firebase/ads',
    hypothesisId: 'B',
    runId: 'post-fix',
    data: {'ms': agentBoot.elapsedMilliseconds},
  );
  // #endregion
  unawaited(_initServices());
}

Future<void> _initServices() async {
  await FirebaseBootstrap.init();
  // #region agent log
  agentDbg(
    location: 'main.dart:firebase',
    message: 'after firebase',
    hypothesisId: 'B',
    runId: 'post-fix',
    data: {
      'ms': agentBoot.elapsedMilliseconds,
      'enabled': FirebaseBootstrap.enabled,
      'error': FirebaseBootstrap.initError,
    },
  );
  // #endregion
  await AdBootstrap.init();
  // #region agent log
  agentDbg(
    location: 'main.dart:ads',
    message: 'after ads',
    hypothesisId: 'C',
    runId: 'post-fix',
    data: {
      'ms': agentBoot.elapsedMilliseconds,
      'enabled': AdBootstrap.enabled,
      'error': AdBootstrap.initError,
    },
  );
  // #endregion
}

class MahjongApp extends StatefulWidget {
  const MahjongApp({super.key, this.localeStore});

  final LocaleStore? localeStore;

  @override
  State<MahjongApp> createState() => _MahjongAppState();
}

class _MahjongAppState extends State<MahjongApp> with WidgetsBindingObserver {
  late final LocaleController _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    _controller = LocaleController(
      widget.localeStore ?? LocaleStore.memory(),
      deviceLocales: dispatcher.locales.isEmpty
          ? [dispatcher.locale]
          : dispatcher.locales,
    );
    _controller.addListener(_onLocale);
    if (widget.localeStore == null) {
      unawaited(_hydrateLocale());
    }
  }

  Future<void> _hydrateLocale() async {
    final store = await LocaleStore.open();
    if (!mounted) return;
    _controller.attachStore(store);
  }

  void _onLocale() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    final next = (locales != null && locales.isNotEmpty)
        ? locales
        : (dispatcher.locales.isEmpty ? [dispatcher.locale] : dispatcher.locales);
    _controller.updateDeviceLocales(next);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onLocale);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      controller: _controller,
      child: MaterialApp(
        title: 'Mahjong Rise',
        locale: _controller.locale,
        supportedLocales: const [Locale('en'), Locale('ru')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        localeResolutionCallback: (_, _) => _controller.locale,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2F6B4F),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
          fontFamily: 'Segoe UI',
        ),
        home: const LevelSelectScreen(),
      ),
    );
  }
}
