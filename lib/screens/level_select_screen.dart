import 'package:flutter/material.dart';

import '../debug_agent_log.dart';
import '../debug_boot_timer.dart';
import '../l10n/l10n.dart';
import '../models/game_snapshot.dart';
import '../models/levels.dart';
import '../models/week_event.dart';
import '../models/weekly_quests.dart';
import '../models/weekly_score.dart';
import '../services/analytics_service.dart';
import '../services/local_reminder_service.dart';
import '../services/progress_store.dart';
import '../services/quest_store.dart';
import '../widgets/app_settings.dart';
import '../widgets/courtyard/courtyard_progress.dart';
import '../widgets/courtyard/courtyard_scene.dart';
import '../widgets/liveops/week_event_banner.dart';
import '../widgets/liveops/weekly_quests_strip.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';

/// Двор на весь экран; сетка уровней открывается шторкой.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  ProgressStore? _store;
  QuestStore? _quests;
  final ScrollController _gridScroll = ScrollController();
  bool _didAutoScroll = false;
  bool _firstSessionCover = false;
  bool _didAutoOpenFirst = false;
  int _cycle = 0;

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
    final hadBrokenStreak =
        store.dailyStreak > 0 && store.visibleStreak() == 0;
    await store.ensureWeek();
    await store.expireStreakIfNeeded();
    if (hadBrokenStreak) {
      await AnalyticsService.log('streak_broken');
    }
    final quests = await QuestStore.open();
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
      _quests = quests;
      _cycle = Levels.cycleOf(store.lastPlayedLevel);
    });
    _scrollToLevel(store.lastPlayedLevel);
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
    if (!mounted) return;

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
    await _quests?.ensureWeek();
    setState(() {
      _cycle = Levels.cycleOf(_store!.lastPlayedLevel);
    });
    _scrollToLevel(_store!.lastPlayedLevel, force: true);
  }

  Future<void> _openDaily() async {
    final store = _store;
    if (store == null) return;
    await store.expireStreakIfNeeded();
    if (!mounted) return;
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
    await _quests?.ensureWeek();
    setState(() {});
  }

  Future<void> _claimQuest(QuestProgress quest) async {
    final store = _store;
    final quests = _quests;
    if (store == null || quests == null) return;
    final ok = await quests.claim(quest.def.id, store);
    if (!ok || !mounted) return;
    await AnalyticsService.log('quest_claim', {'quest_id': quest.def.id});
    if (!mounted) return;
    setState(() {});
    final l10n = L10n.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.questBonus)),
    );
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

  Future<void> _openLevels() async {
    final store = _store;
    if (store == null) return;
    _didAutoScroll = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.38),
      builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToLevel(_continueLevel(store).id, force: true);
        });
        return _LevelsSheet(
          height: MediaQuery.sizeOf(ctx).height * 0.62,
          store: store,
          cycle: _cycle,
          gridScroll: _gridScroll,
          onSelectLevel: (level) {
            Navigator.of(ctx).pop();
            _openLevel(level);
          },
        );
      },
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

    final l10n = L10n.of(context);
    final quests = _quests;
    final snapshot = CourtyardSnapshot.fromStore(
      store,
      cycle: _cycle,
      streak: store.visibleStreak(),
      festival: (quests?.claimedCount ?? 0) > 0,
    );
    final phrase = l10n.homePathPhrase(snapshot);
    final stars = store.starsInCycle(_cycle);
    final unlocked = store.unlockedInCycle(_cycle);
    final showNewPlot =
        store.isCycleComplete(_cycle) &&
        _cycle + 1 < Levels.cycleCount &&
        store.isCycleUnlocked(_cycle + 1);
    final event = WeekEvent.current();

    return Scaffold(
      backgroundColor: const Color(0xFF1A3D2E),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CourtyardScene(to: snapshot, cycle: _cycle),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PlotBar(
                          cycle: _cycle,
                          onPrev:
                              _cycle > 0 && store.isCycleUnlocked(_cycle - 1)
                              ? () => _selectCycle(_cycle - 1)
                              : null,
                          onNext:
                              _cycle + 1 < Levels.cycleCount &&
                                  store.isCycleUnlocked(_cycle + 1)
                              ? () => _selectCycle(_cycle + 1)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _HudIconButton(
                        tooltip: l10n.settings,
                        icon: Icons.settings_rounded,
                        onTap: () => showAppSettings(context),
                      ),
                      const SizedBox(width: 8),
                      _HudIconButton(
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
                        '$stars ★ · ${l10n.openedProgress(unlocked, Levels.storyLength)}',
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
                      if (showNewPlot) ...[
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _gold,
                            foregroundColor: _woodDeep,
                            minimumSize: const Size.fromHeight(46),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () => _selectCycle(_cycle + 1),
                          icon: const Icon(Icons.home_work_rounded),
                          label: Text(
                            l10n.newPlot,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      WeekEventBanner(event: event, onTap: _openDaily),
                      if (quests != null) ...[
                        const SizedBox(height: 8),
                        WeeklyQuestsStrip(
                          quests: quests.quests,
                          onClaim: _claimQuest,
                        ),
                      ],
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _DailyStrip(
                              completedToday: store.isDailyCompletedOn(
                                DateTime.now(),
                              ),
                              streak: store.visibleStreak(),
                              onTap: _openDaily,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: _LevelsButton(onTap: _openLevels)),
                        ],
                      ),
                    ],
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

class _HudIconButton extends StatelessWidget {
  const _HudIconButton({required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
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
          child: Icon(icon, color: const Color(0xFFE8C96A)),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

class _PlotBar extends StatelessWidget {
  const _PlotBar({
    required this.cycle,
    required this.onPrev,
    required this.onNext,
  });

  final int cycle;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

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
      child: Row(
        children: [
          IconButton(
            onPressed: onPrev,
            tooltip: L10n.of(context).previousPlot,
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.chevron_left_rounded,
              color: onPrev == null ? _ivory.withValues(alpha: 0.28) : _ivory,
            ),
          ),
          Expanded(
            child: Text(
              L10n.of(context).plot(cycle),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _ivory,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                letterSpacing: 0.4,
              ),
            ),
          ),
          IconButton(
            onPressed: onNext,
            tooltip: L10n.of(context).nextPlot,
            visualDensity: VisualDensity.compact,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

class _LevelsButton extends StatelessWidget {
  const _LevelsButton({required this.onTap});

  final VoidCallback onTap;

  static const _gold = Color(0xFFD4AF37);
  static const _goldSoft = Color(0xFFE8C96A);
  static const _woodTop = Color(0xFF6B3E24);
  static const _woodDeep = Color(0xFF3A2012);
  static const _ivory = Color(0xFFF8F1DE);

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.grid_view_rounded, color: _goldSoft),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  L10n.of(context).levels,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ivory,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelsSheet extends StatelessWidget {
  const _LevelsSheet({
    required this.height,
    required this.store,
    required this.cycle,
    required this.gridScroll,
    required this.onSelectLevel,
  });

  final double height;
  final ProgressStore store;
  final int cycle;
  final ScrollController gridScroll;
  final ValueChanged<LevelDef> onSelectLevel;

  static const _gold = Color(0xFFD4AF37);
  static const _ivory = Color(0xFFF8F1DE);
  static const _woodDeep = Color(0xFF3A2012);

  @override
  Widget build(BuildContext context) {
    final levels = Levels.cycleLevels(cycle);
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4A2C18), _woodDeep],
              ),
              border: Border(
                top: BorderSide(
                  color: _gold.withValues(alpha: 0.55),
                  width: 1.4,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _ivory.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Text(
                    L10n.of(context).plot(cycle),
                    style: const TextStyle(
                      color: _ivory,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    controller: gridScroll,
                    padding: EdgeInsets.fromLTRB(
                      12,
                      0,
                      12,
                      20 + MediaQuery.paddingOf(context).bottom,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              _LevelSelectScreenState._crossAxisCount,
                          mainAxisSpacing: _LevelSelectScreenState._gridSpacing,
                          crossAxisSpacing:
                              _LevelSelectScreenState._gridSpacing,
                          childAspectRatio: _LevelSelectScreenState._gridAspect,
                        ),
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      return _LevelCard(
                        level: level,
                        unlocked: store.isUnlocked(level.id),
                        stars: store.stars(level.id),
                        inProgress: store.hasSnapshotFor(level.id),
                        onTap: () => onSelectLevel(level),
                      );
                    },
                  ),
                ),
              ],
            ),
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
