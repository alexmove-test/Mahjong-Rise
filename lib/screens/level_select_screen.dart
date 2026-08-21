import 'package:flutter/material.dart';

import '../debug_agent_log.dart';
import '../debug_boot_timer.dart';
import '../l10n/l10n.dart';
import '../models/levels.dart';
import '../services/progress_store.dart';
import '../widgets/language_picker.dart';
import 'game_screen.dart';
import 'leaderboard_screen.dart';

/// Карта уровней + прогресс (звёзды, разблокировка).
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  ProgressStore? _store;
  final ScrollController _gridScroll = ScrollController();
  bool _didAutoScroll = false;

  static const _fieldGreen = Color(0xFFD7EEDC);
  static const _crossAxisCount = 3;
  static const _gridSpacing = 12.0;
  static const _gridAspect = 0.92;
  static const _gridPaddingH = 32.0;

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
    // #region agent log
    agentDbg(
      location: 'level_select_screen.dart:_load',
      message: 'progress load done',
      hypothesisId: 'D',
      data: {'ms': agentBoot.elapsedMilliseconds},
    );
    // #endregion
    if (!mounted) return;
    setState(() => _store = store);
    _scrollToLevel(store.maxUnlocked);
  }

  void _scrollToLevel(int levelId, {bool force = false}) {
    if (!force && _didAutoScroll) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _store == null || !_gridScroll.hasClients) return;
      _didAutoScroll = true;

      final width = MediaQuery.sizeOf(context).width - _gridPaddingH;
      final tileW =
          (width - _gridSpacing * (_crossAxisCount - 1)) / _crossAxisCount;
      final tileH = tileW / _gridAspect;
      final row = (levelId - 1) ~/ _crossAxisCount;
      final target = row * (tileH + _gridSpacing);
      final maxScroll = _gridScroll.position.maxScrollExtent;

      _gridScroll.animateTo(
        target.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
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
    setState(() {});
    _scrollToLevel(_store!.maxUnlocked, force: true);
  }

  Future<void> _continueGame() async {
    final store = _store;
    if (store == null) return;
    await _openLevel(Levels.byId(store.lastPlayedLevel));
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
    final l10n = L10n.of(context);

    return Scaffold(
      backgroundColor: _fieldGreen,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const MahjongScreenBackdrop(vignetteCenter: Alignment(0, -0.2)),
          const AppVersionBadge(),
          SafeArea(
            child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'MAHJONG RISE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: const Color(0xFF1E5A3A),
                          shadows: [
                            Shadow(
                              color: Colors.white.withValues(alpha: 0.55),
                              offset: const Offset(0, 2),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.starsOpen(
                          store?.totalStars ?? 0,
                          store?.maxUnlocked ?? 1,
                          Levels.all.length,
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF3D6B52).withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF6B3E24),
                                  foregroundColor: const Color(0xFFE8C96A),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(
                                      color: const Color(
                                        0xFFD4AF37,
                                      ).withValues(alpha: 0.75),
                                      width: 1.4,
                                    ),
                                  ),
                                ),
                                onPressed: store == null ? null : _continueGame,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text(
                                  l10n.continueLevel(store?.lastPlayedLevel ?? 1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => showLanguagePicker(context),
                                borderRadius: BorderRadius.circular(14),
                                child: Ink(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(14),
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6B3E24),
                                        Color(0xFF3A2012),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFD4AF37,
                                      ).withValues(alpha: 0.75),
                                      width: 1.4,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.language_rounded,
                                    color: Color(0xFFE8C96A),
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
                                      colors: [
                                        Color(0xFF6B3E24),
                                        Color(0xFF3A2012),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFD4AF37,
                                      ).withValues(alpha: 0.75),
                                      width: 1.4,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.leaderboard_rounded,
                                    color: Color(0xFFE8C96A),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: GridView.builder(
                          controller: _gridScroll,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: _crossAxisCount,
                                mainAxisSpacing: _gridSpacing,
                                crossAxisSpacing: _gridSpacing,
                                childAspectRatio: _gridAspect,
                              ),
                          itemCount: Levels.all.length,
                          itemBuilder: (context, index) {
                            final level = Levels.all[index];
                            final unlocked =
                                store?.isUnlocked(level.id) ?? level.id == 1;
                            final stars = store?.stars(level.id) ?? 0;
                            final best = store?.bestScore(level.id) ?? 0;
                            return _LevelCard(
                              level: level,
                              unlocked: unlocked,
                              stars: stars,
                              bestScore: best,
                              completed: store?.isCompleted(level.id) ?? false,
                              inProgress: store?.hasSnapshotFor(level.id) ?? false,
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

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.unlocked,
    required this.stars,
    required this.bestScore,
    required this.completed,
    required this.inProgress,
    required this.onTap,
  });

  final LevelDef level;
  final bool unlocked;
  final int stars;
  final int bestScore;
  final bool completed;
  final bool inProgress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gold = const Color(0xFFD4AF37);
    final ivory = const Color(0xFFF8F1DE);
    final l10n = L10n.of(context);

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
                  '${level.id}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: unlocked ? gold : Colors.white38,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  level.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: unlocked
                        ? ivory.withValues(alpha: 0.9)
                        : Colors.white30,
                  ),
                ),
                Text(
                  '${l10n.difficulty(level)} · ${l10n.styleLabel(level)}',
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
                  Icon(Icons.lock_rounded, size: 18, color: Colors.white38)
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Icon(
                          i < stars
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 16,
                          color: i < stars ? gold : Colors.white24,
                        ),
                    ],
                  ),
                  if (inProgress)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        l10n.inProgress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: gold.withValues(alpha: 0.9),
                        ),
                      ),
                    )
                  else if (completed && bestScore > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        l10n.bestScore(bestScore),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: ivory.withValues(alpha: 0.72),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
