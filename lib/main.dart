import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'debug_agent_log.dart';
import 'debug_boot_timer.dart';
import 'package:mahjong/l10n/app_localizations.dart';

import 'l10n/locale_controller.dart';
import 'screens/level_select_screen.dart';
import 'widgets/ads/banner_ad_slot.dart';
import 'widgets/banner_hide_button.dart';
import 'services/ad_bootstrap.dart';
import 'services/banner_hide_controller.dart';
import 'services/banner_hide_store.dart';
import 'services/firebase_bootstrap.dart';
import 'services/rewarded_ad_service.dart';
import 'services/haptic_controller.dart';
import 'services/haptic_store.dart';
import 'services/locale_store.dart';
import 'services/local_reminder_service.dart';
import 'services/locked_tile_dim_controller.dart';
import 'services/locked_tile_dim_store.dart';
import 'services/music_controller.dart';
import 'services/music_store.dart';
import 'services/points_controller.dart';
import 'services/points_store.dart';
import 'services/q_mode_controller.dart';
import 'services/q_mode_store.dart';
import 'services/sfx_controller.dart';
import 'services/sfx_store.dart';
import 'services/courtyard_reward_store.dart';
import 'services/table_look_controller.dart';
import 'services/table_look_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
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
  await Future.wait([FirebaseBootstrap.init(), AdBootstrap.init()]);
  unawaited(RewardedAdService.instance.preload());
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
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final LocaleController _controller;
  late final HapticController _haptic;
  late final SfxController _sfx;
  late final MusicController _music;
  late final QModeController _qMode;
  late final LockedTileDimController _lockedDim;
  late final TableLookController _tableLook;
  late final BannerHideController _bannerHide;
  late final PointsController _points;

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
    _tableLook = TableLookController(TableLookStore.memory());
    _bannerHide = BannerHideController(BannerHideStore.memory());
    _points = PointsController(PointsStore.memory());
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
    final tableLookStore = await TableLookStore.open();
    final courtyardRewards = await CourtyardRewardStore.open();
    final bannerHideStore = await BannerHideStore.open();
    final pointsStore = await PointsStore.open();
    if (!mounted) return;
    _controller.attachStore(localeStore);
    _haptic.attachStore(hapticStore);
    _sfx.attachStore(sfxStore);
    _music.attachStore(musicStore);
    _qMode.attachStore(qModeStore);
    _lockedDim.attachStore(lockedDimStore);
    _tableLook.attachStore(tableLookStore);
    unawaited(_tableLook.attachRewards(courtyardRewards));
    _bannerHide.attachStore(bannerHideStore);
    _points.attachStore(pointsStore);
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
    _tableLook.dispose();
    _bannerHide.dispose();
    _points.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _music.resumeFromBackground();
        _bannerHide.recheck();
        _points.noteClock();
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
                child: TableLookScope(
                  controller: _tableLook,
                  child: BannerHideScope(
                    controller: _bannerHide,
                    child: PointsScope(
                      controller: _points,
                      child: MaterialApp(
                        navigatorKey: _navigatorKey,
                        title: 'Mahjong Rise',
                        locale: _controller.locale,
                        supportedLocales: AppLocalizations.supportedLocales,
                        localizationsDelegates:
                            AppLocalizations.localizationsDelegates,
                        localeResolutionCallback: (_, _) => _controller.locale,
                        debugShowCheckedModeBanner: false,
                        builder: (context, child) {
                          final media = MediaQuery.of(context);
                          final hide = BannerHideScope.maybeOf(context);
                          return ListenableBuilder(
                            listenable: hide ?? const _IdleListenable(),
                            builder: (context, _) {
                              final offer =
                                  hide != null &&
                                  !AdBootstrap.simulation &&
                                  !hide.isHidden;
                              final lifted = media.removePadding(
                                removeBottom: true,
                              );
                              return Column(
                                children: [
                                  Expanded(
                                    child: MediaQuery(
                                      data: lifted,
                                      child: Stack(
                                        children: [
                                          child ?? const SizedBox.shrink(),
                                          if (offer)
                                            Positioned(
                                              left: 0,
                                              right: 0,
                                              bottom: 14,
                                              child: Center(
                                                child: BannerHideButton(
                                                  navigatorKey: _navigatorKey,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: media.padding.bottom,
                                    ),
                                    child: const BannerAdSlot(),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        theme: ThemeData(
                          colorScheme: ColorScheme.fromSeed(
                            seedColor: const Color(0xFF2F6B4F),
                            brightness: Brightness.dark,
                          ),
                          useMaterial3: true,
                          fontFamily: 'Segoe UI',
                          fontFamilyFallback: const ['Noto Sans Thai'],
                        ),
                        home: const LevelSelectScreen(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdleListenable implements Listenable {
  const _IdleListenable();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}
