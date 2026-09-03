import 'dart:async';

import 'package:flutter/material.dart';

import '../debug_agent_log.dart';
import '../debug_boot_timer.dart';
import '../l10n/l10n.dart';
import '../models/game_snapshot.dart';
import '../models/levels.dart';
import '../models/plot_kind.dart';
import '../models/weekly_score.dart';
import '../services/analytics_service.dart';
import '../services/firebase_leaderboard_repository.dart';
import '../services/leaderboard_service.dart';
import '../services/local_reminder_service.dart';
import '../services/pet_store.dart';
import '../services/player_profile_store.dart';
import '../services/progress_store.dart';
import '../services/quest_store.dart';
import '../widgets/app_settings.dart';
import '../widgets/courtyard/courtyard_estate.dart';
import '../widgets/courtyard/courtyard_lot_build.dart';
import '../widgets/courtyard/courtyard_win_overlay.dart';
import '../widgets/courtyard/courtyard_world.dart';
import '../widgets/courtyard/courtyard_world_layout.dart';
import '../widgets/pets/courtyard_pet_invite.dart';
import '../widgets/pets/pet_page.dart';
import '../widgets/table_coach_banner.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';

/// Р”РІРѕСЂ РЅР° РІРµСЃСЊ СЌРєСЂР°РЅ; СЃРµС‚РєР° СѓСЂРѕРІРЅРµР№ РѕС‚РєСЂС‹РІР°РµС‚СЃСЏ С€С‚РѕСЂРєРѕР№.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  ProgressStore? _store;
  QuestStore? _quests;
  PetStore? _pets;
  bool _firstSessionCover = false;
  bool _didAutoOpenFirst = false;
  int _cycle = 0;
  PlotKind? _focusKind;
  PlotKind? _inspectKind;
  CourtyardWinReveal? _winReveal;
  Timer? _panHintTimer;
  var _panHintDismissed = false;
  List<NeighborYard> _neighbors = NeighborYard.placed(
    others: const [],
    online: false,
  );

  static const _panHintDuration = Duration(seconds: 6);

  static const _gold = Color(0xFFD4AF37);
  static const _goldSoft = Color(0xFFE8C96A);
  static const _woodTop = Color(0xFF6B3E24);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensurePanHintTimer();
  }

  @override
  void dispose() {
    _panHintTimer?.cancel();
    super.dispose();
  }

  bool get _panHintPending {
    final store = _store;
    return store != null && !store.courtyardPanHintDone && !_firstSessionCover;
  }

  bool get _showPanHint =>
      _panHintPending && !_panHintDismissed && _winReveal == null;

  /// Таймер прячет баннер только на этот заход во двор.
  void _hidePanHintBanner() {
    _panHintTimer?.cancel();
    _panHintTimer = null;
    if (_panHintDismissed) return;
    _panHintDismissed = true;
    if (mounted) setState(() {});
  }

  /// Игрок сдвинул обзор — больше не напоминаем.
  void _markPanHintLearned() {
    _panHintTimer?.cancel();
    _panHintTimer = null;
    _panHintDismissed = true;
    final store = _store;
    if (store != null && !store.courtyardPanHintDone) {
      unawaited(store.markCourtyardPanHintDone());
    }
    if (mounted) setState(() {});
  }

  void _armPanHintAfterWin() {
    final store = _store;
    if (store == null || store.courtyardPanHintDone) return;
    _panHintTimer?.cancel();
    _panHintTimer = null;
    _panHintDismissed = false;
  }

  void _ensurePanHintTimer() {
    if (!_showPanHint) {
      _panHintTimer?.cancel();
      _panHintTimer = null;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_showPanHint) {
        _panHintTimer?.cancel();
        _panHintTimer = null;
        return;
      }
      if (!(ModalRoute.of(context)?.isCurrent ?? true)) return;
      _panHintTimer ??= Timer(_panHintDuration, _hidePanHintBanner);
    });
  }

  Future<void> _load() async {
    // #region agent log
    agentDbg(
      location: 'level_select_screen.dart:_load',
      message: 'progress load start',
      hypothesisId: 'D',
      data: {'ms': agentBoot.elapsedMilliseconds},
    );
    // #endregion
    final store = await ProgressStore.open();
    final hadBrokenStreak = store.dailyStreak > 0 && store.visibleStreak() == 0;
    await store.ensureWeek();
    await store.expireStreakIfNeeded();
    if (hadBrokenStreak) {
      await AnalyticsService.log('streak_broken');
    }
    final quests = await QuestStore.open();
    final pets = await PetStore.open();
    // #region agent log
    agentDbg(
      location: 'level_select_screen.dart:_load',
      message: 'progress load done',
      hypothesisId: 'D',
      data: {'ms': agentBoot.elapsedMilliseconds},
    );
    // #endregion
    if (!mounted) return;

    if (!store.hasCompletedAny && !_didAutoOpenFirst) {
      _didAutoOpenFirst = true;
      setState(() {
        _store = store;
        _quests = quests;
        _pets = pets;
        _cycle = 0;
        _focusKind = store.plotKindForLevel(1);
        _firstSessionCover = true;
      });
      unawaited(_loadNeighbors());
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _openLevel(Levels.byId(1));
      });
      return;
    }

    setState(() {
      _store = store;
      _quests = quests;
      _pets = pets;
      _cycle = Levels.cycleOf(store.lastPlayedLevel);
      _focusKind = store.plotKindForLevel(store.lastPlayedLevel);
    });
    unawaited(_loadNeighbors());
    _ensurePanHintTimer();
    _afterHubReady();
  }

  Future<void> _afterHubReady() async {
    if (!mounted) return;
    await LocalReminderService.resync(l10n: L10n.of(context));
    if (!mounted) return;
    final summary = await _store?.consumeSeasonSheet();
    if (!mounted || summary == null) return;
    await _showSeasonClosed(summary);
  }

  Future<void> _showSeasonClosed(WeekSeasonSummary summary) async {
    final l10n = L10n.of(context);
    final rating = _formatRating(summary.rating);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3A2012),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
              width: 1.6,
            ),
          ),
          title: Text(
            l10n.seasonClosed,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE8C96A),
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (summary.rank != null)
                Text(
                  l10n.lastWeekPlace(summary.rank!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF8F1DE),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                l10n.lastWeekScore(rating),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFFF8F1DE).withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                l10n.done,
                style: const TextStyle(color: Color(0xFFF8F1DE)),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatRating(int rating) {
    final text = rating.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final posFromEnd = text.length - i;
      buffer.write(text[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write(' ');
    }
    return buffer.toString();
  }

  LevelDef _continueLevel(ProgressStore store) {
    final last = store.lastPlayedLevel;
    if (Levels.cycleOf(last) != _cycle) {
      final start = Levels.cycleStartId(_cycle);
      return Levels.byId(start.clamp(1, store.maxUnlocked));
    }
    final nextId = last + 1;
    if (store.isCompleted(last) &&
        nextId <= Levels.maxLevelId &&
        store.isUnlocked(nextId) &&
        Levels.cycleOf(nextId) == _cycle) {
      return Levels.byId(nextId);
    }
    return Levels.byId(last);
  }

  Future<void> _loadNeighbors() async {
    final store = _store;
    if (store == null) return;
    final profile = await PlayerProfileStore.open();
    final fetch = await FirebaseLeaderboardRepository.fetchTop(
      progress: store,
      profile: profile,
    );
    if (!mounted) return;
    final nearby = LeaderboardService.nearbyOthers(
      fetch.entries,
      count: CourtyardWorldLayout.neighborCount,
    );
    setState(() {
      _neighbors = NeighborYard.placed(others: nearby, online: fetch.online);
    });
  }

  Future<void> _selectPlotKind(PlotKind kind) async {
    final store = _store;
    if (store == null) return;
    await store.selectPlot(kind);
    if (!mounted) return;
    setState(() {
      _inspectKind = kind;
      _focusKind = kind;
    });
  }

  Future<void> _openLevel(LevelDef level) async {
    final store = _store;
    if (store == null || !store.isUnlocked(level.id)) return;
    if (_winReveal != null) setState(() => _winReveal = null);

    await store.markPlayed(level.id);
    if (!mounted) return;

    final reveal = await _pushTable(
      GameScreen(
        level: level,
        progress: store,
        onProgressChanged: () {
          if (mounted) setState(() {});
        },
      ),
    );
    if (!mounted) return;
    unawaited(_quests?.ensureWeek());
    setState(() {
      _firstSessionCover = false;
      _cycle = reveal?.cycle ?? Levels.cycleOf(_store!.lastPlayedLevel);
      _focusKind = _store!.plotKindForLevel(_store!.lastPlayedLevel);
      _winReveal = reveal;
      if (reveal != null) {
        _armPanHintAfterWin();
      }
    });
    _ensurePanHintTimer();
  }

  Future<void> _openDaily() async {
    final store = _store;
    if (store == null) return;
    if (_winReveal != null) setState(() => _winReveal = null);
    await store.expireStreakIfNeeded();
    if (!mounted) return;
    final reveal = await _pushTable(
      GameScreen(
        level: Levels.dailyFor(DateTime.now()),
        progress: store,
        isDaily: true,
        onProgressChanged: () {
          if (mounted) setState(() {});
        },
      ),
    );
    if (!mounted) return;
    unawaited(_quests?.ensureWeek());
    setState(() {
      _winReveal = reveal;
      if (reveal != null) {
        _cycle = reveal.cycle;
        _focusKind = _store!.plotKindForLevel(_store!.lastPlayedLevel);
        _armPanHintAfterWin();
      }
    });
    _ensurePanHintTimer();
  }

  Future<CourtyardWinReveal?> _pushTable(GameScreen screen) {
    final pushed = Navigator.of(
      context,
    ).push<CourtyardWinReveal>(GameScreen.route(screen));
    if (_firstSessionCover) {
      setState(() => _firstSessionCover = false);
    }
    return pushed;
  }

  Future<void> _continueGame() async {
    final store = _store;
    if (store == null) return;
    final snap = store.savedSnapshot;
    if (snap != null && snap.levelId == GameSnapshot.dailyLevelId) {
      await _openDaily();
      return;
    }
    if (snap != null) {
      await _openLevel(Levels.byId(snap.levelId));
      return;
    }
    await _openLevel(_continueLevel(store));
  }

  String _continueLabel(ProgressStore store, L10n l10n) {
    final snap = store.savedSnapshot;
    if (snap != null && snap.levelId == GameSnapshot.dailyLevelId) {
      return l10n.continueWith(l10n.today);
    }
    if (snap != null) {
      return l10n.continueWith(
        l10n.levelTitle(
          Levels.byId(snap.levelId),
          plotKind: store.plotKindForLevel(snap.levelId),
        ),
      );
    }
    final next = _continueLevel(store);
    return l10n.continueWith(
      l10n.levelTitle(next, plotKind: store.plotKindForLevel(next.id)),
    );
  }

  Future<void> _openLeaderboard() async {
    final store = _store;
    if (store == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => LeaderboardScreen(progress: store)),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openPets() async {
    final pets = _pets;
    if (pets == null) return;
    await AnalyticsService.log('pet_visit');
    await openPetPage(context, pets: pets);
    if (!mounted) return;
    setState(() {});
  }

  void _dismissWinReveal() {
    if (_winReveal == null) return;
    setState(() => _winReveal = null);
    _ensurePanHintTimer();
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    if (store == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B5C40),
        body: Stack(
          fit: StackFit.expand,
          children: [MahjongScreenBackdrop(dark: true)],
        ),
      );
    }
    if (_firstSessionCover) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B5C40),
        body: Stack(
          fit: StackFit.expand,
          children: [MahjongScreenBackdrop(dark: true)],
        ),
      );
    }

    final l10n = L10n.of(context);
    final quests = _quests;
    final estate = CourtyardEstate.fromStore(
      store,
      streak: store.visibleStreak(),
      festival: (quests?.claimedCount ?? 0) > 0,
    );
    final focus = _focusKind ?? store.plotKindForLevel(store.lastPlayedLevel);
    final lot = estate.lot(focus);
    final phrase = l10n.homePathPhrase(lot.snapshot, stage: lot.stage);
    final stars = store.totalStars;
    final unlocked = lot.stage.floor();

    return Scaffold(
      backgroundColor: const Color(0xFF1A3D2E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Semantics(
            image: true,
            label: l10n.courtyardSemanticKind(focus),
            child: CourtyardWorld(
              from: _winReveal?.estateFrom,
              to: _winReveal?.estateTo ?? estate,
              animate: _winReveal != null,
              neighbors: _neighbors,
              inspectKind: _inspectKind,
              onSelectLot: (kind) {
                _dismissWinReveal();
                _selectPlotKind(kind);
              },
              onLockedLot: (kind) {
                _dismissWinReveal();
                _selectPlotKind(kind);
              },
              onPanHint: _panHintPending ? _markPanHintLearned : null,
            ),
          ),
          const Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x99081410),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0xB3141A12),
                    ],
                    stops: [0, 0.22, 0.52, 1],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                      child: Row(
                        children: [
                          Expanded(child: _PlotTitle(kind: focus)),
                          const SizedBox(width: 8),
                          _HudIconButton(
                            tooltip: l10n.settings,
                            icon: Icons.settings_rounded,
                            onTap: () => showAppSettings(context),
                          ),
                          const SizedBox(width: 8),
                          _HudIconButton(
                            tooltip: l10n.leaderboard,
                            icon: Icons.leaderboard_rounded,
                            onTap: _openLeaderboard,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        children: [
                          if (_showPanHint) ...[
                            TableCoachBanner(text: l10n.courtyardPanHint),
                            const SizedBox(height: 10),
                          ],
                          Text(
                            phrase,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFF8F1DE),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              height: 1.25,
                              shadows: [
                                Shadow(color: Colors.black87, blurRadius: 8),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$stars ★ · ${l10n.openedProgress(unlocked, CourtyardLotBuild.maxStage)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(
                                0xFFF8F1DE,
                              ).withValues(alpha: 0.86),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              shadows: const [
                                Shadow(color: Colors.black87, blurRadius: 8),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: _woodTop,
                              foregroundColor: _goldSoft,
                              minimumSize: const Size.fromHeight(48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(
                                  color: _gold.withValues(alpha: 0.75),
                                  width: 1.4,
                                ),
                              ),
                            ),
                            onPressed: _continueGame,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              _continueLabel(store, l10n),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 4,
                  bottom: 64,
                  child: CourtyardPetInvite(pets: _pets, onTap: _openPets),
                ),
              ],
            ),
          ),
          if (_winReveal != null)
            CourtyardWinOverlay(onFinished: _dismissWinReveal),
        ],
      ),
    );
  }
}

class _HudIconButton extends StatelessWidget {
  const _HudIconButton({required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip ?? '',
        excludeFromSemantics: true,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6B3E24), Color(0xFF3A2012)],
                ),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.75),
                  width: 1.4,
                ),
              ),
              child: ExcludeSemantics(
                child: Icon(icon, color: const Color(0xFFE8C96A)),
              ),
            ),
          ),
        ),
      ),
    );
    return button;
  }
}

class _PlotTitle extends StatelessWidget {
  const _PlotTitle({required this.kind});

  final PlotKind kind;

  static const _gold = Color(0xFFD4AF37);
  static const _ivory = Color(0xFFF8F1DE);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xCC6B3E24), Color(0xCC3A2012)],
        ),
        border: Border.all(color: _gold.withValues(alpha: 0.7), width: 1.3),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          L10n.of(context).plotTitle(kind),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ivory,
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}
