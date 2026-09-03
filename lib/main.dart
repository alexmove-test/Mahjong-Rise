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
import 'services/haptic_controller.dart';
import 'services/haptic_store.dart';
import 'services/locale_store.dart';
import 'services/local_reminder_service.dart';
import 'services/locked_tile_dim_controller.dart';
import 'services/locked_tile_dim_store.dart';
import 'services/music_controller.dart';
import 'services/music_store.dart';
import 'services/q_mode_controller.dart';
import 'services/q_mode_store.dart';
import 'services/sfx_controller.dart';
import 'services/sfx_store.dart';

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
  runApp(const MahjongApp());
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
  await LocalReminderService.init();
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
  const MahjongApp({super.key});

  @override
  State<MahjongApp> createState() => _MahjongAppState();
}

class _MahjongAppState extends State<MahjongApp> with WidgetsBindingObserver {
  late final LocaleController _controller;
  late final HapticController _haptic;
  late final SfxController _sfx;
  late final MusicController _music;
  late final QModeController _qMode;
  late final LockedTileDimController _lockedDim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = LocaleController(
      LocaleStore.memory(),
      deviceLocale: WidgetsBinding.instance.platformDispatcher.locale,
    );
    _haptic = HapticController(HapticStore.memory());
    _sfx = SfxController(SfxStore.memory());
    _music = MusicController(MusicStore.memory());
    _qMode = QModeController(QModeStore.memory());
    _lockedDim = LockedTileDimController(LockedTileDimStore.memory());
    _controller.addListener(_onLocale);
    unawaited(_music.init());
    unawaited(_hydratePrefs());
  }

  Future<void> _hydratePrefs() async {
    final localeStore = await LocaleStore.open();
    final hapticStore = await HapticStore.open();
    final sfxStore = await SfxStore.open();
    final musicStore = await MusicStore.open();
    final qModeStore = await QModeStore.open();
    final lockedDimStore = await LockedTileDimStore.open();
    if (!mounted) return;
    _controller.attachStore(localeStore);
    _haptic.attachStore(hapticStore);
    _sfx.attachStore(sfxStore);
    _music.attachStore(musicStore);
    _qMode.attachStore(qModeStore);
    _lockedDim.attachStore(lockedDimStore);
  }

  void _onLocale() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    final next =
        locales?.first ?? WidgetsBinding.instance.platformDispatcher.locale;
    _controller.updateDeviceLocale(next);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onLocale);
    _controller.dispose();
    _haptic.dispose();
    _sfx.dispose();
    _music.dispose();
    _qMode.dispose();
    _lockedDim.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _music.resumeFromBackground();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _music.pauseForBackground();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      controller: _controller,
      child: HapticScope(
        controller: _haptic,
        child: SfxScope(
          controller: _sfx,
          child: MusicScope(
            controller: _music,
            child: QModeScope(
              controller: _qMode,
              child: LockedTileDimScope(
                controller: _lockedDim,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
