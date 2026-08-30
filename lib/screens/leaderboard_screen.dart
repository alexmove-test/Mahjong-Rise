import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/leaderboard_entry.dart';
import '../services/analytics_service.dart';
import '../services/firebase_bootstrap.dart';
import '../services/firebase_leaderboard_repository.dart';
import '../services/guest_name.dart';
import '../services/leaderboard_service.dart';
import '../services/player_profile_store.dart';
import '../services/progress_store.dart';
import '../services/weekly_leaderboard_repository.dart';
import 'game_screen.dart';

/// Общий рейтинг игроков.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.progress});

  final ProgressStore progress;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  PlayerProfileStore? _profile;
  late final TabController _tabs;
  List<LeaderboardEntry> _allEntries = const [];
  List<LeaderboardEntry> _weekEntries = const [];
  int? _allRank;
  int? _weekRank;
  bool _loading = true;
  bool _allOnline = false;
  bool _weekOnline = false;

  static const _fieldGreen = Color(0xFFD7EEDC);
  static const _woodTop = Color(0xFF6B3E24);
  static const _woodDeep = Color(0xFF3A2012);
  static const _gold = Color(0xFFD4AF37);
  static const _goldSoft = Color(0xFFE8C96A);
  static const _ivory = Color(0xFFF8F1DE);

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(_onTab);
    _load();
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTab);
    _tabs.dispose();
    super.dispose();
  }

  void _onTab() {
    if (_tabs.indexIsChanging) return;
    if (_tabs.index == 0) {
      AnalyticsService.log('weekly_open');
    }
    setState(() {});
  }

  bool get _weekly => _tabs.index == 0;

  bool get _tabOnline => _weekly ? _weekOnline : _allOnline;

  String? _tabError(L10n l10n) {
    if (_tabOnline || !FirebaseBootstrap.enabled) return null;
    return l10n.loadRankingFailed;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    final profile = await PlayerProfileStore.open();
    await widget.progress.ensureWeek();
    final all = await FirebaseLeaderboardRepository.fetchTop(
      progress: widget.progress,
      profile: profile,
    );
    final week = await WeeklyLeaderboardRepository.fetchTop(
      progress: widget.progress,
      profile: profile,
    );
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _allEntries = all.entries;
      _weekEntries = week.entries;
      _allRank = LeaderboardService.rankOf(all.entries);
      _weekRank = LeaderboardService.rankOf(week.entries);
      _allOnline = all.online;
      _weekOnline = week.online;
      _loading = false;
    });
    AnalyticsService.log('weekly_open');
  }

  Future<void> _editName() async {
    final profile = _profile;
    if (profile == null) return;

    final controller = TextEditingController(
      text: profile.hasCustomName ? profile.displayName : '',
    );
    final saved = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _woodDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: _gold.withValues(alpha: 0.7), width: 1.4),
          ),
          title: Text(
            L10n.of(context).yourName,
            style: TextStyle(color: _goldSoft, fontWeight: FontWeight.w800),
          ),
          content: TextField(
            controller: controller,
            maxLength: GuestName.maxLength,
            autofocus: true,
            style: const TextStyle(color: _ivory),
            decoration: InputDecoration(
              hintText: profile.displayName,
              hintStyle: TextStyle(color: _ivory.withValues(alpha: 0.45)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: _gold.withValues(alpha: 0.45)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _gold, width: 1.6),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(L10n.of(context).cancel, style: const TextStyle(color: _ivory)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _woodTop,
                foregroundColor: _goldSoft,
              ),
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(L10n.of(context).save),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (!mounted || saved == null) return;

    await profile.setDisplayName(saved);
    await _load();
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

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final entries = _weekly ? _weekEntries : _allEntries;
    final rank = _weekly ? _weekRank : _allRank;
    final current = entries.where((e) => e.isCurrentPlayer).firstOrNull;
    final l10n = L10n.of(context);
    final tabError = _tabError(l10n);

    return Scaffold(
      backgroundColor: _fieldGreen,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const MahjongScreenBackdrop(vignetteCenter: Alignment(0, -0.15)),
          SafeArea(
            child: profile == null
                ? const Center(child: CircularProgressIndicator(color: _gold))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: l10n.back,
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Color(0xFF1E5A3A),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                l10n.leaderboard,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E5A3A),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.refresh,
                              onPressed: _loading ? null : _load,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Color(0xFF1E5A3A),
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.changeName,
                              onPressed: _editName,
                              icon: const Icon(
                                Icons.edit_rounded,
                                color: Color(0xFF1E5A3A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: TabBar(
                          controller: _tabs,
                          labelColor: const Color(0xFF1E5A3A),
                          unselectedLabelColor: const Color(0xFF3D6B52),
                          indicatorColor: _gold,
                          tabs: [
                            Tab(text: l10n.thisWeek),
                            Tab(text: l10n.allTime),
                          ],
                        ),
                      ),
                      if (_loading)
                        const Expanded(
                          child: Center(
                            child: CircularProgressIndicator(color: _gold),
                          ),
                        )
                      else ...[
                        if (tabError != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: Text(
                              tabError,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            _tabOnline
                                ? l10n.onlineRanking(
                                    _weekly
                                        ? WeeklyLeaderboardRepository.fetchLimit
                                        : FirebaseLeaderboardRepository
                                              .fetchLimit,
                                  )
                                : FirebaseBootstrap.initError ??
                                      l10n.offlineRanking,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(
                                0xFF3D6B52,
                              ).withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (current != null && rank != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: _CurrentPlayerCard(
                              rank: rank,
                              entry: current,
                              ratingLabel: _formatRating(current.rating),
                              weekly: _weekly,
                              plotsOpened: LeaderboardService.plotsOpened(
                                current.levelsUnlocked,
                              ),
                              onEditName: _editName,
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            _weekly ? l10n.weeklyFormula : l10n.rankingFormula,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(
                                0xFF3D6B52,
                              ).withValues(alpha: 0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (!_weekly)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 28, 6),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                l10n.scorePlotsLegend,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: const Color(
                                    0xFF3D6B52,
                                  ).withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: RefreshIndicator(
                            color: _gold,
                            onRefresh: _load,
                            child: ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              itemCount: entries.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                return _LeaderboardRow(
                                  rank: index + 1,
                                  entry: entry,
                                  ratingLabel: _formatRating(entry.rating),
                                  weekly: _weekly,
                                  plotsOpened: LeaderboardService.plotsOpened(
                                    entry.levelsUnlocked,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _CurrentPlayerCard extends StatelessWidget {
  const _CurrentPlayerCard({
    required this.rank,
    required this.entry,
    required this.ratingLabel,
    required this.plotsOpened,
    required this.onEditName,
    this.weekly = false,
  });

  final int rank;
  final LeaderboardEntry entry;
  final String ratingLabel;
  final int plotsOpened;
  final VoidCallback onEditName;
  final bool weekly;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B3E24), Color(0xFF3A2012)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.85),
          width: 1.6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            _RankBadge(rank: rank, large: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L10n.of(context).displayName(entry.name),
                    style: const TextStyle(
                      color: Color(0xFFE8C96A),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weekly
                        ? L10n.of(context).weeklyStarsClearsDailies(
                            entry.totalStars,
                            entry.levelsUnlocked,
                            entry.weeklyDailies,
                          )
                        : L10n.of(context).starsLevel(
                            entry.totalStars,
                            entry.levelsUnlocked,
                          ),
                    style: TextStyle(
                      color: const Color(0xFFF8F1DE).withValues(alpha: 0.78),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (weekly)
                  Text(
                    ratingLabel,
                    style: const TextStyle(
                      color: Color(0xFFF8F1DE),
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  )
                else
                  _ScoreAndPlots(
                    ratingLabel: ratingLabel,
                    plotsOpened: plotsOpened,
                    color: const Color(0xFFF8F1DE),
                    separatorColor: const Color(0xFFE8C96A),
                    large: true,
                  ),
                TextButton(
                  onPressed: onEditName,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFE8C96A),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(L10n.of(context).name),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.rank,
    required this.entry,
    required this.ratingLabel,
    required this.plotsOpened,
    this.weekly = false,
  });

  final int rank;
  final LeaderboardEntry entry;
  final String ratingLabel;
  final int plotsOpened;
  final bool weekly;

  @override
  Widget build(BuildContext context) {
    final highlight = entry.isCurrentPlayer;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFF6B3E24).withValues(alpha: 0.92)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight
              ? const Color(0xFFD4AF37).withValues(alpha: 0.8)
              : const Color(0xFF7CB392).withValues(alpha: 0.35),
          width: highlight ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _RankBadge(rank: rank),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    L10n.of(context).displayName(entry.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: highlight
                          ? const Color(0xFFE8C96A)
                          : const Color(0xFF1E5A3A),
                    ),
                  ),
                  Text(
                    weekly
                        ? L10n.of(context).weeklyStarsClearsDailies(
                            entry.totalStars,
                            entry.levelsUnlocked,
                            entry.weeklyDailies,
                          )
                        : L10n.of(context).starsLevel(
                            entry.totalStars,
                            entry.levelsUnlocked,
                          ),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: highlight
                          ? const Color(0xFFF8F1DE).withValues(alpha: 0.72)
                          : const Color(0xFF3D6B52).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            if (weekly)
              Text(
                ratingLabel,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: highlight
                      ? const Color(0xFFF8F1DE)
                      : const Color(0xFF1E5A3A),
                ),
              )
            else
              _ScoreAndPlots(
                ratingLabel: ratingLabel,
                plotsOpened: plotsOpened,
                color: highlight
                    ? const Color(0xFFF8F1DE)
                    : const Color(0xFF1E5A3A),
                separatorColor: highlight
                    ? const Color(0xFFE8C96A)
                    : const Color(0xFF3D6B52),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScoreAndPlots extends StatelessWidget {
  const _ScoreAndPlots({
    required this.ratingLabel,
    required this.plotsOpened,
    required this.color,
    required this.separatorColor,
    this.large = false,
  });

  final String ratingLabel;
  final int plotsOpened;
  final Color color;
  final Color separatorColor;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 18.0 : 15.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          ratingLabel,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: size,
          ),
        ),
        Text(
          ' : ',
          style: TextStyle(
            color: separatorColor.withValues(alpha: 0.85),
            fontWeight: FontWeight.w700,
            fontSize: size,
          ),
        ),
        Text(
          '$plotsOpened',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: size,
          ),
        ),
      ],
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, this.large = false});

  final int rank;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final size = large ? 42.0 : 34.0;
    Color? medalColor;
    if (rank == 1) medalColor = const Color(0xFFFFD54F);
    if (rank == 2) medalColor = const Color(0xFFB0BEC5);
    if (rank == 3) medalColor = const Color(0xFFCD7F32);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: medalColor ?? const Color(0xFF1B5E3A).withValues(alpha: 0.12),
        border: Border.all(
          color: medalColor ?? const Color(0xFF1E5A3A).withValues(alpha: 0.25),
          width: 1.2,
        ),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: large ? 16 : 13,
          color: medalColor != null
              ? const Color(0xFF3A2012)
              : const Color(0xFF1E5A3A),
        ),
      ),
    );
  }
}
