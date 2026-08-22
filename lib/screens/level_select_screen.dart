import 'package:flutter/material.dart';

import '../debug_agent_log.dart';
import '../debug_boot_timer.dart';
import '../l10n/l10n.dart';
import '../models/game_snapshot.dart';
import '../models/levels.dart';
import '../services/progress_store.dart';
import '../widgets/app_settings.dart';
import '../widgets/courtyard/courtyard_progress.dart';
import '../widgets/courtyard/courtyard_scene.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';

/// Двор (хаб) + сетка уровней.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  ProgressStore? _store;
  final ScrollController _gridScroll = ScrollController();
  bool _didAutoScroll = false;
  bool _firstSessionCover = false;
  bool _didAutoOpenFirst = false;
  int _cycle = 0;

  static const _fieldGreen = Color(0xFFD7EEDC);
  static const _crossAxisCount = 3;
  static const _gridSpacing = 10.0;
  static const _gridAspect = 0.92;
  static const _gridPaddingH = 24.0;
  static const _gold = Color(0xFFD4AF37);
  static const _goldSoft = Color(0xFFE8C96A);
  static const _woodTop = Color(0xFF6B3E24);
  static const _woodDeep = Color(0xFF3A2012);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _gridScroll.dispose();
    super.dispose();
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
    await store.expireStreakIfNeeded();
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
        _cycle = 0;
        _firstSessionCover = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _openLevel(Levels.byId(1));
        if (!mounted) return;
        setState(() {
          _firstSessionCover = false;
          _cycle = Levels.cycleOf(_store!.lastPlayedLevel);
        });
        _scrollToLevel(_store!.lastPlayedLevel, force: true);
      });
      return;
    }

    setState(() {
      _store = store;
      _cycle = Levels.cycleOf(store.lastPlayedLevel);
    });
    _scrollToLevel(store.lastPlayedLevel);
  }

  List<LevelDef> get _cycleLevels => Levels.cycleLevels(_cycle);

  LevelDef _continueLevel(ProgressStore store) {
    final last = store.lastPlayedLevel;
    if (Levels.cycleOf(last) == _cycle) return Levels.byId(last);
    final start = Levels.cycleStartId(_cycle);
    return Levels.byId(start.clamp(1, store.maxUnlocked));
  }

  void _scrollToLevel(int levelId, {bool force = false}) {
    if (!force && _didAutoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _store == null || !_gridScroll.hasClients) return;
      _didAutoScroll = true;

      final local = Levels.cycleOf(levelId) == _cycle
          ? Levels.localId(levelId)
          : 1;
      final width = MediaQuery.sizeOf(context).width - _gridPaddingH;
      final tileW =
          (width - _gridSpacing * (_crossAxisCount - 1)) / _crossAxisCount;
      final tileH = tileW / _gridAspect;
      final row = (local - 1) ~/ _crossAxisCount;
      final target = row * (tileH + _gridSpacing);
      final maxScroll = _gridScroll.position.maxScrollExtent;

      _gridScroll.animateTo(
        target.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _selectCycle(int cycle) {
    final store = _store;
    if (store == null || !store.isCycleUnlocked(cycle)) return;
    setState(() {
      _cycle = cycle.clamp(0, Levels.cycleCount - 1);
      _didAutoScroll = false;
    });
    _scrollToLevel(_continueLevel(store).id, force: true);
  }

  Future<void> _openLevel(LevelDef level) async {
    final store = _store;
    if (store == null || !store.isUnlocked(level.id)) return;

    await store.markPlayed(level.id);

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          level: level,
          progress: store,
          onProgressChanged: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _cycle = Levels.cycleOf(_store!.lastPlayedLevel);
    });
    _scrollToLevel(_store!.lastPlayedLevel, force: true);
  }

  Future<void> _openDaily() async {
    final store = _store;
    if (store == null) return;
    await store.expireStreakIfNeeded();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => GameScreen(
          level: Levels.dailyFor(DateTime.now()),
          progress: store,
          isDaily: true,
          onProgressChanged: () {
            if (mounted) setState(() {});
          },
        ),
      ),
    );
    if (!mounted) return;
    setState(() {});
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
      return l10n.continueWith(l10n.levelTitle(Levels.byId(snap.levelId)));
    }
    return l10n.continueWith(l10n.levelTitle(_continueLevel(store)));
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

    return Scaffold(
      backgroundColor: _fieldGreen,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const MahjongScreenBackdrop(vignetteCenter: Alignment(0, -0.2)),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                _CourtyardHub(store: store, cycle: _cycle),
                const SizedBox(height: 10),
                _PlotBar(
                  cycle: _cycle,
                  store: store,
                  onPrev: _cycle > 0 && store.isCycleUnlocked(_cycle - 1)
                      ? () => _selectCycle(_cycle - 1)
                      : null,
                  onNext:
                      _cycle + 1 < Levels.cycleCount &&
                          store.isCycleUnlocked(_cycle + 1)
                      ? () => _selectCycle(_cycle + 1)
                      : null,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _woodTop,
                            foregroundColor: _goldSoft,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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
                            _continueLabel(store, L10n.of(context)),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Tooltip(
                        message: L10n.of(context).settings,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => showAppSettings(context),
                            borderRadius: BorderRadius.circular(14),
                            child: Ink(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [_woodTop, _woodDeep],
                                ),
                                border: Border.all(
                                  color: _gold.withValues(alpha: 0.75),
                                  width: 1.4,
                                ),
                              ),
                              child: const Icon(
                                Icons.settings_rounded,
                                color: _goldSoft,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _openLeaderboard,
                          borderRadius: BorderRadius.circular(14),
                          child: Ink(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: const LinearGradient(
                                colors: [_woodTop, _woodDeep],
                              ),
                              border: Border.all(
                                color: _gold.withValues(alpha: 0.75),
                                width: 1.4,
                              ),
                            ),
                            child: const Icon(
                              Icons.leaderboard_rounded,
                              color: _goldSoft,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                  child: _DailyStrip(
                    completedToday: store.isDailyCompletedOn(DateTime.now()),
                    streak: store.visibleStreak(),
                    onTap: _openDaily,
                  ),
                ),
                if (store.isCycleComplete(_cycle) &&
                    _cycle + 1 < Levels.cycleCount &&
                    store.isCycleUnlocked(_cycle + 1))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: _woodDeep,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => _selectCycle(_cycle + 1),
                      icon: const Icon(Icons.home_work_rounded),
                      label: Text(
                        L10n.of(context).newPlot,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Expanded(
                  child: GridView.builder(
                    controller: _gridScroll,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _crossAxisCount,
                          mainAxisSpacing: _gridSpacing,
                          crossAxisSpacing: _gridSpacing,
                          childAspectRatio: _gridAspect,
                        ),
                    itemCount: _cycleLevels.length,
                    itemBuilder: (context, index) {
                      final level = _cycleLevels[index];
                      return _LevelCard(
                        level: level,
                        unlocked: store.isUnlocked(level.id),
                        stars: store.stars(level.id),
                        inProgress: store.hasSnapshotFor(level.id),
                        onTap: () => _openLevel(level),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CourtyardHub extends StatelessWidget {
  const _CourtyardHub({required this.store, required this.cycle});

  final ProgressStore store;
  final int cycle;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final snapshot = CourtyardSnapshot.fromStore(store, cycle: cycle);
    final phrase = l10n.homePathPhrase(snapshot);
    final height = MediaQuery.sizeOf(context).height < 720 ? 200.0 : 248.0;
    final stars = store.starsInCycle(cycle);
    final unlocked = store.unlockedInCycle(cycle);

    return CourtyardFrame(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CourtyardScene(to: snapshot),
          const Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: Text(
              'MAHJONG RISE',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: Color(0xFF1E5A3A),
                shadows: [
                  Shadow(
                    color: Color(0xEEFFFFFF),
                    offset: Offset(0, 1),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF1A3D2E).withValues(alpha: 0.32),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      phrase,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFF8F1DE),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.25,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$stars ★ · ${l10n.openedProgress(unlocked, Levels.storyLength)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFF8F1DE).withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlotBar extends StatelessWidget {
  const _PlotBar({
    required this.cycle,
    required this.store,
    required this.onPrev,
    required this.onNext,
  });

  final int cycle;
  final ProgressStore store;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  static const _gold = Color(0xFFD4AF37);
  static const _woodDeep = Color(0xFF3A2012);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            tooltip: L10n.of(context).previousPlot,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: onPrev == null
                  ? _woodDeep.withValues(alpha: 0.2)
                  : _woodDeep,
            ),
          ),
          Expanded(
            child: Text(
              L10n.of(context).plot(cycle),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _woodDeep,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 0.4,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            tooltip: L10n.of(context).nextPlot,
            icon: Icon(
              Icons.chevron_right_rounded,
              color: onNext == null ? _gold.withValues(alpha: 0.35) : _gold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyStrip extends StatelessWidget {
  const _DailyStrip({
    required this.completedToday,
    required this.streak,
    required this.onTap,
  });

  final bool completedToday;
  final int streak;
  final VoidCallback onTap;

  static const _gold = Color(0xFFD4AF37);
  static const _goldSoft = Color(0xFFE8C96A);
  static const _woodTop = Color(0xFF6B3E24);
  static const _woodDeep = Color(0xFF3A2012);
  static const _ivory = Color(0xFFF8F1DE);

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final subtitle = completedToday
        ? l10n.clearedToday
        : streak > 0
        ? l10n.streak(streak)
        : l10n.newTableEveryDay;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [_woodTop, _woodDeep]),
            border: Border.all(
              color: _gold.withValues(alpha: 0.75),
              width: 1.3,
            ),
          ),
          child: Row(
            children: [
              Icon(
                completedToday
                    ? Icons.check_circle_rounded
                    : Icons.local_fire_department_rounded,
                color: completedToday ? _goldSoft : const Color(0xFFFF8A4C),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.today,
                      style: TextStyle(
                        color: _ivory,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _ivory.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (streak > 0)
                Text(
                  '$streak',
                  style: const TextStyle(
                    color: _goldSoft,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.inProgress,
    required this.onTap,
  });

  final LevelDef level;
  final bool unlocked;
  final int stars;
  final bool inProgress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final gold = const Color(0xFFD4AF37);
    final ivory = const Color(0xFFF8F1DE);
    final local = Levels.localId(level.id);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: unlocked ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: unlocked
                  ? const [Color(0xFF6B3E24), Color(0xFF3A2012)]
                  : const [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
            ),
            border: Border.all(
              color: unlocked ? gold.withValues(alpha: 0.7) : Colors.white24,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Column(
              children: [
                Text(
                  '$local',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: unlocked ? gold : Colors.white38,
                    height: 1,
                  ),
                ),
                if (inProgress)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: gold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: gold.withValues(alpha: 0.7),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  l10n.levelTitle(level),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: unlocked
                        ? ivory.withValues(alpha: 0.92)
                        : Colors.white30,
                  ),
                ),
                Text(
                  '${l10n.difficulty(level)} · ${l10n.style(level)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: unlocked
                        ? ivory.withValues(alpha: 0.55)
                        : Colors.white24,
                  ),
                ),
                const Spacer(),
                if (!unlocked)
                  const Icon(
                    Icons.lock_rounded,
                    size: 16,
                    color: Colors.white38,
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Icon(
                          i < stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 14,
                          color: i < stars ? gold : Colors.white24,
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
