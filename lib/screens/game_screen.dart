import 'dart:async';
import 'dart:math' as math show Random;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_version.dart';
import '../config/app_links.dart';
import '../debug_agent_log.dart';
import '../debug_boot_timer.dart';
import '../l10n/l10n.dart';
import '../l10n/praise_phrases.dart';
import '../models/board.dart';
import '../models/first_table_coach.dart';
import '../models/game_snapshot.dart';
import '../models/levels.dart';
import '../models/tile.dart';
import '../models/tutorial_step.dart';
import '../services/ad_bootstrap.dart';
import '../services/analytics_service.dart';
import '../services/firebase_leaderboard_repository.dart';
import '../services/game_sfx.dart';
import '../services/haptic_controller.dart';
import '../services/local_reminder_service.dart';
import '../services/pet_store.dart';
import '../services/player_profile_store.dart';
import '../services/progress_store.dart';
import '../services/quest_store.dart';
import '../services/rewarded_ad_service.dart';
import '../services/sfx_controller.dart';
import '../services/tutorial_store.dart';
import '../services/weekly_leaderboard_repository.dart';
import '../widgets/app_settings.dart';
import '../widgets/courtyard/courtyard_progress.dart';
import '../widgets/courtyard/courtyard_win_overlay.dart';
import '../widgets/game_action_bar.dart';
import '../widgets/game_board.dart';
import '../widgets/game_hud.dart';
import '../widgets/match_smash.dart';
import '../widgets/premium_ui.dart';
import '../widgets/table_coach_banner.dart';
import '../widgets/tile_flight.dart';
import '../widgets/tile_widget.dart';
import '../widgets/tutorial_coach.dart';
import '../widgets/tray_full_dialog.dart';

/// Фон экранов: светлый damask для меню или сукно игрового стола.
class MahjongScreenBackdrop extends StatelessWidget {
  const MahjongScreenBackdrop({
    super.key,
    this.fieldGreen = const Color(0xFFD7EEDC),
    this.vignetteCenter = const Alignment(0, -0.08),
    this.dark = false,
  });

  final Color fieldGreen;
  final Alignment vignetteCenter;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (dark) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF052418),
                  Color(0xFF0B5C40),
                  Color(0xFF12855A),
                  Color(0xFF0B5C40),
                  Color(0xFF041C14),
                ],
                stops: [0.0, 0.18, 0.48, 0.78, 1.0],
              ),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/felt.png'),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  opacity: 0.42,
                ),
              ),
            ),
          ),
          const Positioned.fill(
            child: CustomPaint(painter: _DamaskPainter(dark: true)),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: vignetteCenter,
                  radius: 1.12,
                  colors: [
                    const Color(0xFFF8F1DE).withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.65],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BoardVignetteOverlay(
              center: vignetteCenter,
              intensity: 0.68,
              dark: true,
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: fieldGreen),
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF5FBF6),
                  Color(0xFFD7EEDC),
                  Color(0xFFB5D9C2),
                ],
                stops: [0.0, 0.46, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: vignetteCenter,
                radius: 1.08,
                colors: [
                  Colors.white.withValues(alpha: 0.55),
                  Colors.transparent,
                  const Color(0xFF7CB392).withValues(alpha: 0.28),
                ],
                stops: const [0.0, 0.52, 1.0],
              ),
            ),
          ),
        ),
        const Positioned.fill(child: CustomPaint(painter: _DamaskPainter())),
        Positioned.fill(
          child: BoardVignetteOverlay(
            center: vignetteCenter,
            intensity: 0.72,
            dark: false,
          ),
        ),
      ],
    );
  }
}

class _DamaskPainter extends CustomPainter {
  const _DamaskPainter({this.dark = false});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    const step = 52.0;
    final stroke = Paint()
      ..color = (dark ? const Color(0xFF1A4A34) : const Color(0xFF2F6B4F))
          .withValues(alpha: dark ? 0.34 : 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final fill = Paint()
      ..color = (dark ? const Color(0xFF0E3A28) : const Color(0xFF4C9A6E))
          .withValues(alpha: dark ? 0.22 : 0.06);

    for (var row = 0; row < size.height / step + 2; row++) {
      for (var col = 0; col < size.width / step + 2; col++) {
        final stagger = row.isOdd ? step * 0.5 : 0.0;
        final center = Offset(col * step + stagger, row * step);
        _rosette(canvas, center, step * 0.28, stroke, fill);
      }
    }
  }

  void _rosette(Canvas canvas, Offset c, double r, Paint stroke, Paint fill) {
    final path = Path()
      ..moveTo(c.dx, c.dy - r)
      ..lineTo(c.dx + r * 0.38, c.dy - r * 0.38)
      ..lineTo(c.dx + r, c.dy)
      ..lineTo(c.dx + r * 0.38, c.dy + r * 0.38)
      ..lineTo(c.dx, c.dy + r)
      ..lineTo(c.dx - r * 0.38, c.dy + r * 0.38)
      ..lineTo(c.dx - r, c.dy)
      ..lineTo(c.dx - r * 0.38, c.dy - r * 0.38)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    canvas.drawCircle(c, r * 0.16, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Экран партии: счёт, тёмное поле, круглые действия с бейджами.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    required this.progress,
    this.onProgressChanged,
    this.isDaily = false,
  });

  final LevelDef level;
  final ProgressStore progress;
  final VoidCallback? onProgressChanged;
  final bool isDaily;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _UndoEntry {
  const _UndoEntry.collect({
    required this.tileId,
    required this.scoreBefore,
    required this.comboBefore,
  }) : kind = _UndoKind.collect,
       matchedIds = const [];

  /// Матч после сбора [tileId]: undo возвращает пару в лоток, а [tileId] — на поле.
  const _UndoEntry.match({
    required this.tileId,
    required this.matchedIds,
    required this.scoreBefore,
    required this.comboBefore,
  }) : kind = _UndoKind.match;

  final _UndoKind kind;
  final int? tileId;
  final List<int> matchedIds;
  final int scoreBefore;
  final int comboBefore;
}

enum _UndoKind { collect, match }

enum _RewardedBoost { shuffle, magnet, hint, undo }

class _TileFlight {
  _TileFlight({
    required this.token,
    required this.tile,
    required this.from,
    required this.to,
    required this.scoreBefore,
    required this.comboBefore,
    this.returning = false,
    this.forcePick = false,
  });

  final int token;
  final Tile tile;
  final Rect from;
  final Rect to;
  final int scoreBefore;
  final int comboBefore;
  final bool returning;
  final bool forcePick;
}

class _SmashFlight {
  _SmashFlight({
    required this.token,
    required this.left,
    required this.right,
    required this.leftRect,
    required this.rightRect,
  });

  final int token;
  final Tile left;
  final Tile right;
  final Rect leftRect;
  final Rect rightRect;
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  static const _fieldGreen = _Ui.table;

  late Board _board;
  int _boardGeneration = 0;
  int _score = 0;
  int _combo = 0;
  Timer? _hintTimer;
  String? _toast;
  bool _winHandled = false;
  bool _loseHandled = false;

  late int _shufflesLeft;
  late int _hintsLeft;
  late int _undosLeft;
  late int _magnetsLeft;
  late int _startShuffles;
  late int _startHints;
  late int _startUndos;
  late int _startMagnets;

  Set<int> _hintedIds = {};
  final List<_UndoEntry> _undoStack = [];
  final GlobalKey _flightLayerKey = GlobalKey();
  final GlobalKey<GameBoardState> _boardViewKey = GlobalKey<GameBoardState>();
  final List<GlobalKey> _traySlotKeys = List<GlobalKey>.generate(
    Board.trayCapacity,
    (i) => GlobalKey(debugLabel: 'tray-slot-$i'),
  );
  final List<_TileFlight> _flights = [];
  final List<_SmashFlight> _smashes = [];
  int _flightSeq = 0;
  final math.Random _smashRng = math.Random();
  int _shuffleToken = 0;
  bool _shuffleBusy = false;
  Timer? _shuffleBusyTimer;
  final GameSfx _sfx = GameSfx();
  final FastMatchStreak _fastPraise = FastMatchStreak();
  final RewardedAdService _rewardedAds = RewardedAdService();
  late final FirstTableCoach _coach;
  bool _adBusy = false;

  TutorialStore? _tutorial;
  TutorialLesson? _lesson;
  bool _blockedTap = false;
  final LayerLink _trayLink = LayerLink();
  final LayerLink _actionsLink = LayerLink();

  LevelDef get _level => widget.level;
  bool get _adsAvailable => AdBootstrap.available && !_adBusy;
  int get _slotId => widget.isDaily ? GameSnapshot.dailyLevelId : _level.id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // #region agent log
    agentDbg(
      location: 'game_screen.dart:initState',
      message: 'game screen init',
      hypothesisId: 'E',
      data: {'ms': agentBoot.elapsedMilliseconds, 'level': _level.id},
    );
    // #endregion
    _sfx.init();
    unawaited(_rewardedAds.preload());
    _coach = FirstTableCoach(
      active:
          !widget.isDaily && _level.id == 1 && !widget.progress.tableCoachDone,
    );
    final snap = widget.progress.snapshotFor(_slotId);
    if (snap != null) {
      _restoreBoard(snap);
    } else {
      _resetBoard(applyBanked: true);
    }
    if (!widget.isDaily) {
      widget.progress.markPlayed(_level.id);
    }
    unawaited(_initTutorial());
  }

  @override
  void dispose() {
    _persistSnapshot();
    WidgetsBinding.instance.removeObserver(this);
    _hintTimer?.cancel();
    _shuffleBusyTimer?.cancel();
    _rewardedAds.dispose();
    _sfx.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _persistSnapshot();
    }
  }

  void _restoreBoard(GameSnapshot snap) {
    _hintTimer?.cancel();
    _boardGeneration++;
    _board = snap.toBoard();
    _score = snap.score;
    _combo = snap.combo;
    _toast = null;
    _winHandled = false;
    _loseHandled = false;
    _shufflesLeft = snap.shuffles;
    _hintsLeft = snap.hints;
    _undosLeft = snap.undos;
    _magnetsLeft = snap.magnets;
    _hintedIds = {};
    _undoStack.clear();
    _flights.clear();
    _smashes.clear();
    _shuffleToken = 0;
    _shuffleBusy = false;
    _shuffleBusyTimer?.cancel();
    _fastPraise.reset();
    _rememberBoostBaseline();
  }

  void _rememberBoostBaseline() {
    _startShuffles = _shufflesLeft;
    _startHints = _hintsLeft;
    _startUndos = _undosLeft;
    _startMagnets = _magnetsLeft;
  }

  bool get _hasProgressToSave {
    if (_board.isWon || _board.isLost) return false;
    if (_score != 0 || _combo != 0) return true;
    if (_board.trayLiveCount > 0) return true;
    if (_board.tiles.any((tile) => !tile.isOnBoard)) return true;
    if (_shufflesLeft != _startShuffles) return true;
    if (_hintsLeft != _startHints) return true;
    if (_undosLeft != _startUndos) return true;
    if (_magnetsLeft != _startMagnets) return true;
    return false;
  }

  void _persistSnapshot() {
    if (!_hasProgressToSave) return;
    unawaited(
      widget.progress.saveSnapshot(
        GameSnapshot.fromBoard(
          levelId: _slotId,
          board: _board,
          score: _score,
          combo: _combo,
          shuffles: _shufflesLeft,
          hints: _hintsLeft,
          undos: _undosLeft,
          magnets: _magnetsLeft,
        ),
      ),
    );
  }

  Future<void> _clearSnapshot() => widget.progress.clearSnapshot(_slotId);

  void _resetBoard({bool applyBanked = false}) {
    _hintTimer?.cancel();
    _boardGeneration++;
    _board = Board.fromLayout(
      _level.layout,
      style: _level.style,
      pairSize: _level.pairSize,
      uniqueCap: _level.uniqueCap,
      levelId: _level.id,
      guestTypes: _level.guestTileTypes,
    );
    _score = 0;
    _combo = 0;
    _toast = null;
    _winHandled = false;
    _loseHandled = false;
    _shufflesLeft = _level.shuffles;
    _hintsLeft = _level.hints;
    _undosLeft = _level.undos;
    _magnetsLeft = _level.hints;
    if (applyBanked && !widget.isDaily) {
      _hintsLeft += widget.progress.bankedHints;
      _shufflesLeft += widget.progress.bankedShuffles;
      unawaited(widget.progress.consumeBankedBoosts());
    }
    _hintedIds = {};
    _undoStack.clear();
    _flights.clear();
    _smashes.clear();
    _shuffleToken = 0;
    _shuffleBusy = false;
    _shuffleBusyTimer?.cancel();
    _fastPraise.reset();
    _coach.resetIfActive();
    _rememberBoostBaseline();
  }

  Future<void> _startNewGame() async {
    await _clearSnapshot();
    if (!mounted) return;
    _resetBoard();
    _blockedTap = false;
    _syncTutorial();
    if (mounted) setState(() {});
  }

  Future<void> _initTutorial() async {
    _tutorial = await TutorialStore.open();
    if (!mounted) return;
    _syncTutorial();
  }

  void _syncTutorial() {
    final store = _tutorial;
    if (store == null || !mounted) return;
    if (_coach.active && !store.forceReplay) {
      setState(() => _lesson = null);
      return;
    }
    final next = TutorialGuide.current(
      levelId: _level.id,
      progress: store.snapshot,
      level1Completed: widget.progress.isCompleted(1),
      trayEmpty: _board.trayLiveCount == 0,
      blockedTap: _blockedTap,
    );
    final wasCollect = _lesson?.step == TutorialStep.collect;
    setState(() {
      _lesson = next;
      if (next?.step == TutorialStep.collect) {
        _hintTimer?.cancel();
        _hintedIds = _tutorialHintIds();
      } else if (wasCollect) {
        _hintedIds = {};
      }
    });
  }

  Future<void> _skipTutorial() async {
    final store = _tutorial;
    if (store == null) return;
    await store.skipAll();
    _blockedTap = false;
    if (mounted) _syncTutorial();
  }

  Future<void> _replayTutorial() async {
    final store = _tutorial ?? await TutorialStore.open();
    _tutorial = store;
    await store.reset();
    _blockedTap = false;
    if (mounted) _syncTutorial();
  }

  Future<void> _acknowledgeTutorialStep() async {
    final store = _tutorial;
    final step = _lesson?.step;
    if (store == null || step == null) return;
    if (step != TutorialStep.layers && step != TutorialStep.boosts) {
      return;
    }
    await store.complete(step);
    _blockedTap = false;
    if (mounted) _syncTutorial();
  }

  Future<void> _completeBoostsIfNeeded() async {
    final store = _tutorial;
    if (store == null || _lesson?.step != TutorialStep.boosts) return;
    await store.complete(TutorialStep.boosts);
    if (mounted) _syncTutorial();
  }

  Future<void> _onTutorialAfterMove(MatchResult resolve) async {
    final store = _tutorial;
    if (store == null) return;
    final current = _lesson?.step;
    if (current == null) return;

    if (!store.isDone(TutorialStep.collect)) {
      await store.complete(TutorialStep.collect);
    }
    if (current == TutorialStep.layers && !store.isDone(TutorialStep.layers)) {
      await store.complete(TutorialStep.layers);
    }
    if (resolve == MatchResult.matched || resolve == MatchResult.win) {
      if (!store.isDone(TutorialStep.match)) {
        await store.complete(TutorialStep.match);
      }
    }
    if (current == TutorialStep.boosts) {
      await store.complete(TutorialStep.boosts);
    }
    if (!mounted) return;
    _syncTutorial();
  }

  Set<int> _tutorialHintIds() {
    final hint = _board.findHint();
    if (hint == null) return {};
    return {hint.boardTile.id, hint.match.id};
  }

  void _clearHint() {
    _hintTimer?.cancel();
    if (_lesson?.step == TutorialStep.collect) {
      setState(() => _hintedIds = _tutorialHintIds());
      return;
    }
    if (_hintedIds.isEmpty) return;
    setState(() => _hintedIds = {});
  }

  void _onTileTap(Tile tile, Rect fromRect) {
    if (_board.isWon || _board.isLost || _shuffleBusy) return;
    if (tile.flying) return;

    if (!tile.isOnBoard || !_board.isFree(tile)) {
      setState(() => _toast = L10n.of(context).tileLocked);
      _sfx.error();
      return;
    }
    if (_board.trayLiveCount + _flights.where((f) => !f.returning).length >=
        Board.trayCapacity) {
      setState(() => _toast = L10n.of(context).trayFull);
      _sfx.error();
      return;
    }

    final scoreBefore = _score;
    final comboBefore = _combo;
    _sfx.collect();
    if (!_launchCollectFlight(
      tile,
      fromRect,
      scoreBefore: scoreBefore,
      comboBefore: comboBefore,
    )) {
      _commitPick(tile, scoreBefore: scoreBefore, comboBefore: comboBefore);
    }
  }

  bool _launchCollectFlight(
    Tile tile,
    Rect fromRect, {
    required int scoreBefore,
    required int comboBefore,
    bool force = false,
  }) {
    final slotIndex =
        _board.trayLiveCount + _flights.where((f) => !f.returning).length;
    final fromLocal = _rectOnFlightLayer(fromRect);
    final toGlobal = _globalRectOf(_traySlotKeys[slotIndex]);
    final toLocal = toGlobal == null ? null : _rectOnFlightLayer(toGlobal);

    if (fromLocal == null || toLocal == null || fromRect == Rect.zero) {
      return false;
    }

    tile.flying = true;
    setState(() {
      _toast = null;
      _flights.add(
        _TileFlight(
          token: _flightSeq++,
          tile: tile,
          from: fromLocal,
          to: toLocal,
          scoreBefore: scoreBefore,
          comboBefore: comboBefore,
          forcePick: force,
        ),
      );
    });
    return true;
  }

  bool _launchReturnFlight(Tile tile, Rect fromRect, Rect toRect) {
    final fromLocal = _rectOnFlightLayer(fromRect);
    final toLocal = _rectOnFlightLayer(toRect);
    if (fromLocal == null || toLocal == null) return false;

    tile.inTray = false;
    tile.removing = false;
    tile.removed = false;
    tile.flying = true;
    _board.tray.removeWhere((t) => t.id == tile.id);
    setState(() {
      _flights.add(
        _TileFlight(
          token: _flightSeq++,
          tile: tile,
          from: fromLocal,
          to: toLocal,
          scoreBefore: _score,
          comboBefore: _combo,
          returning: true,
        ),
      );
    });
    return true;
  }

  Rect? _globalRectOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Rect? _rectOnFlightLayer(Rect global) {
    final box =
        _flightLayerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.globalToLocal(global.topLeft) & global.size;
  }

  void _onFlightArrived(_TileFlight flight) {
    if (!mounted) return;
    if (!_flights.remove(flight)) return;
    if (flight.returning) {
      flight.tile.flying = false;
      setState(() {});
      return;
    }
    _commitPick(
      flight.tile,
      scoreBefore: flight.scoreBefore,
      comboBefore: flight.comboBefore,
      force: flight.forcePick,
    );
  }

  void _commitPick(
    Tile tile, {
    required int scoreBefore,
    required int comboBefore,
    bool force = false,
  }) {
    tile.flying = false;
    final result = _board.pick(tile, force: force);
    if (result == MatchResult.blocked) {
      _blockedTap = true;
      setState(() => _toast = L10n.of(context).tileLocked);
      _sfx.error();
      _syncTutorial();
      return;
    }
    if (result == MatchResult.trayFull) {
      setState(() => _toast = L10n.of(context).trayFull);
      _sfx.error();
      return;
    }
    _blockedTap = false;
    _hintTimer?.cancel();
    if (_lesson?.step != TutorialStep.collect && _hintedIds.isNotEmpty) {
      _hintedIds = {};
    }

    _applyTrayResolve(
      tileId: tile.id,
      scoreBefore: scoreBefore,
      comboBefore: comboBefore,
    );
  }

  void _commitPendingFlights() {
    if (_flights.isEmpty) return;
    final pending = List<_TileFlight>.from(_flights);
    _flights.clear();
    for (final flight in pending) {
      if (!mounted || _board.isWon || _board.isLost) {
        flight.tile.flying = false;
        continue;
      }
      if (flight.returning) {
        flight.tile.flying = false;
        continue;
      }
      _commitPick(
        flight.tile,
        scoreBefore: flight.scoreBefore,
        comboBefore: flight.comboBefore,
        force: flight.forcePick,
      );
    }
  }

  void _applyTrayResolve({
    required int tileId,
    required int scoreBefore,
    required int comboBefore,
  }) {
    final resolve = _board.resolveTray();
    final matchedNow = List<Tile>.from(_board.lastMatched);
    final smashes =
        (resolve == MatchResult.matched || resolve == MatchResult.win)
        ? _planSmashes(matchedNow)
        : const <_SmashFlight>[];

    setState(() {
      _toast = null;

      switch (resolve) {
        case MatchResult.collected:
          _undoStack.add(
            _UndoEntry.collect(
              tileId: tileId,
              scoreBefore: scoreBefore,
              comboBefore: comboBefore,
            ),
          );
          _coach.onCollected();
        case MatchResult.matched:
          final matched = matchedNow;
          final pairs = matched.length ~/ 2;
          _undoStack.add(
            _UndoEntry.match(
              tileId: tileId,
              matchedIds: matched.map((t) => t.id).toList(),
              scoreBefore: scoreBefore,
              comboBefore: comboBefore,
            ),
          );
          _combo += pairs;
          _score += pairs * (100 + (_combo - 1) * 25);
          _toast = _board.hasUsefulMove()
              ? null
              : L10n.of(context).noMovesShuffle;
          if (smashes.length * 2 < matched.length) {
            _sfx.match();
          }
          _smashes.addAll(smashes);
          final praise = _fastPraise.registerMatch(
            now: DateTime.now(),
            languageCode: L10n.of(context).code,
          );
          if (praise != null) _sfx.praise(praise);
          _coach.onMatched();
        case MatchResult.win:
          final matched = matchedNow;
          if (matched.isNotEmpty) {
            _undoStack.add(
              _UndoEntry.match(
                tileId: tileId,
                matchedIds: matched.map((t) => t.id).toList(),
                scoreBefore: scoreBefore,
                comboBefore: comboBefore,
              ),
            );
            final pairs = matched.length ~/ 2;
            _combo += pairs;
            _score += pairs * (100 + (_combo - 1) * 25) + 500;
            _smashes.addAll(smashes);
          } else {
            _score += 500;
          }
          _toast = L10n.of(context).youWin;
          _sfx.win();
          _fastPraise.reset();
          _coach.onWin();
          if (!_winHandled) {
            _winHandled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _onLevelWon();
            });
          }
        case MatchResult.lose:
          _undoStack.add(
            _UndoEntry.collect(
              tileId: tileId,
              scoreBefore: scoreBefore,
              comboBefore: comboBefore,
            ),
          );
          _combo = 0;
          _toast = null;
          _sfx.lose();
          _fastPraise.reset();
          unawaited(_clearSnapshot());
          if (!_loseHandled) {
            _loseHandled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _onLevelLost();
            });
          }
        case MatchResult.blocked:
        case MatchResult.trayFull:
          break;
      }
    });
    _persistCoachIfDone();
    if (resolve == MatchResult.collected || resolve == MatchResult.matched) {
      _persistSnapshot();
    } else if (resolve == MatchResult.win) {
      unawaited(_clearSnapshot());
    }
    unawaited(_onTutorialAfterMove(resolve));
  }

  void _persistCoachIfDone() {
    if (!_coach.finished || widget.progress.tableCoachDone) return;
    unawaited(widget.progress.markTableCoachDone());
  }

  void _onTileRemoveComplete(Tile tile) {
    if (!mounted || !tile.removing) return;
    setState(() => _board.finishRemoval(tile));
  }

  List<_SmashFlight> _planSmashes(List<Tile> matched) {
    if (_lesson != null || matched.length < 2) return const [];
    final flights = <_SmashFlight>[];
    for (var i = 0; i + 1 < matched.length; i += 2) {
      if (!MatchSmash.roll(_smashRng)) continue;
      final a = matched[i];
      final b = matched[i + 1];
      final ia = _board.tray.indexWhere((t) => t.id == a.id);
      final ib = _board.tray.indexWhere((t) => t.id == b.id);
      final ra = ia < 0 ? null : _globalRectOf(_traySlotKeys[ia]);
      final rb = ib < 0 ? null : _globalRectOf(_traySlotKeys[ib]);
      if (ra == null || rb == null || ra == Rect.zero || rb == Rect.zero) {
        continue;
      }
      final la = _rectOnFlightLayer(ra);
      final lb = _rectOnFlightLayer(rb);
      if (la == null || lb == null) continue;
      flights.add(
        _SmashFlight(
          token: _flightSeq++,
          left: a,
          right: b,
          leftRect: la,
          rightRect: lb,
        ),
      );
    }
    return flights;
  }

  void _onSmashComplete(_SmashFlight smash) {
    if (!mounted) return;
    setState(() {
      _smashes.remove(smash);
      if (smash.left.removing) _board.finishRemoval(smash.left);
      if (smash.right.removing) _board.finishRemoval(smash.right);
    });
  }

  void _shuffle() {
    _commitPendingFlights();
    if (_board.isWon || _board.isLost || _shufflesLeft <= 0) {
      return;
    }
    _clearHint();
    if (_board.freeTiles().isEmpty) {
      setState(() => _toast = L10n.of(context).noFreeTiles);
      _sfx.error();
      return;
    }
    _shuffleBusyTimer?.cancel();
    setState(() {
      final useful = _board.shuffleRemaining();
      _shufflesLeft -= 1;
      _combo = 0;
      _shuffleToken += 1;
      _shuffleBusy = true;
      _toast = useful
          ? L10n.of(context).shuffled
          : L10n.of(context).stillNoMoves;
      if (_lesson?.step != TutorialStep.collect) {
        _hintedIds = {};
      }
    });
    _shuffleBusyTimer = Timer(TileWidget.shufflePlayDuration, () {
      if (!mounted) return;
      setState(() => _shuffleBusy = false);
    });
    _persistSnapshot();
    _fastPraise.reset();
    _sfx.tap();
    if (_lesson?.step == TutorialStep.collect) {
      _syncTutorial();
    }
  }

  void _onShuffleTap() {
    if (_board.isWon || _board.isLost || _adBusy || _shuffleBusy) return;
    if (_shufflesLeft > 0) {
      _shuffle();
      unawaited(_completeBoostsIfNeeded());
    } else if (_adsAvailable) {
      unawaited(_watchAdForBoost(_RewardedBoost.shuffle));
    }
  }

  void _onHintTap() {
    if (_board.isWon || _board.isLost || _adBusy) return;
    if (_hintsLeft > 0) {
      _hint();
      unawaited(_completeBoostsIfNeeded());
    } else if (_adsAvailable) {
      unawaited(_watchAdForBoost(_RewardedBoost.hint));
    }
  }

  void _onMagnetTap() {
    if (_board.isWon || _board.isLost || _adBusy) return;
    if (_magnetsLeft > 0) {
      _magnet();
      unawaited(_completeBoostsIfNeeded());
    } else if (_adsAvailable) {
      unawaited(_watchAdForBoost(_RewardedBoost.magnet));
    }
  }

  void _onUndoTap() {
    if (_board.isWon || _board.isLost || _adBusy) return;
    if (_flights.isNotEmpty) {
      setState(() {
        final flight = _flights.removeLast();
        flight.tile.flying = false;
      });
      _sfx.undo();
      return;
    }
    if (_undosLeft > 0 && _undoStack.isNotEmpty) {
      _undo();
      unawaited(_completeBoostsIfNeeded());
    } else if (_adsAvailable && _undosLeft <= 0 && _undoStack.isNotEmpty) {
      unawaited(_watchAdForBoost(_RewardedBoost.undo));
    }
  }

  Future<void> _watchAdForBoost(_RewardedBoost boost) async {
    if (_adBusy || !AdBootstrap.available) return;

    setState(() {
      _adBusy = true;
      _toast = AdBootstrap.simulation ? null : L10n.of(context).loadingAd;
    });

    await _rewardedAds.preload();
    final earned = await _rewardedAds.show(context: context);
    if (!mounted) return;

    if (!earned) {
      setState(() {
        _adBusy = false;
        _toast = AdBootstrap.simulation
            ? L10n.of(context).rewardNotEarned
            : L10n.of(context).adUnavailable;
      });
      return;
    }

    final l10n = L10n.of(context);
    setState(() {
      _adBusy = false;
      switch (boost) {
        case _RewardedBoost.shuffle:
          _shufflesLeft += 1;
          _toast = l10n.boostEarned(l10n.shuffle);
        case _RewardedBoost.magnet:
          _magnetsLeft += 1;
          _toast = l10n.boostEarned(l10n.magnet);
        case _RewardedBoost.hint:
          _hintsLeft += 1;
          _toast = l10n.boostEarned(l10n.hint);
        case _RewardedBoost.undo:
          _undosLeft += 1;
          _toast = l10n.boostEarned(l10n.undo);
      }
    });
    _persistSnapshot();
    _sfx.select();
  }

  void _hint() {
    _commitPendingFlights();
    if (_board.isWon || _board.isLost || _hintsLeft <= 0) {
      return;
    }
    final hint = _board.findHint();
    if (hint == null) {
      setState(() => _toast = L10n.of(context).noUsefulMoves);
      _sfx.error();
      return;
    }
    _hintTimer?.cancel();
    setState(() {
      _hintsLeft -= 1;
      _hintedIds = {hint.boardTile.id, hint.match.id};
      _toast = null;
    });
    _sfx.select();
    _persistSnapshot();
    _hintTimer = Timer(const Duration(seconds: 8), () {
      if (!mounted) return;
      if (_lesson?.step == TutorialStep.collect) {
        setState(() => _hintedIds = _tutorialHintIds());
        return;
      }
      setState(() => _hintedIds = {});
    });
  }

  void _undo({bool fromLose = false}) {
    if (_board.isWon) return;
    if (_board.isLost && !fromLose) return;
    _clearHint();
    _smashes.clear();

    if (_undoStack.isEmpty) return;
    if (!fromLose && _undosLeft <= 0) return;
    final snap = _undoStack.removeLast();

    if (!fromLose && _tryAnimateUndo(snap)) {
      setState(() {
        _score = snap.scoreBefore;
        _combo = snap.comboBefore;
        _undosLeft -= 1;
        _toast = L10n.of(context).moveUndone;
      });
      _persistSnapshot();
      _sfx.undo();
      return;
    }

    setState(() {
      if (snap.kind == _UndoKind.collect) {
        final tile = _board.tiles.firstWhere((t) => t.id == snap.tileId);
        if (fromLose) {
          _board.reviveFromTray(tile);
        } else {
          _board.returnFromTray(tile);
        }
      } else {
        _board.isLost = false;
        final matched = snap.matchedIds
            .map((id) => _board.tiles.firstWhere((t) => t.id == id))
            .toList();
        for (var i = 0; i + 1 < matched.length; i += 2) {
          _board.restoreMatchedToTray(matched[i], matched[i + 1]);
        }
        final picked = _board.tiles.firstWhere((t) => t.id == snap.tileId);
        _board.returnFromTray(picked);
      }
      _score = snap.scoreBefore;
      _combo = snap.comboBefore;
      if (!fromLose) _undosLeft -= 1;
      _toast = fromLose
          ? L10n.of(context).continuing
          : L10n.of(context).moveUndone;
    });
    _persistSnapshot();
    if (fromLose) {
      _sfx.tap();
    } else {
      _sfx.undo();
    }
  }

  bool _tryAnimateUndo(_UndoEntry snap) {
    late final Tile returning;
    if (snap.kind == _UndoKind.collect) {
      returning = _board.tiles.firstWhere((t) => t.id == snap.tileId);
    } else {
      _board.isLost = false;
      final matched = snap.matchedIds
          .map((id) => _board.tiles.firstWhere((t) => t.id == id))
          .toList();
      for (var i = 0; i + 1 < matched.length; i += 2) {
        _board.restoreMatchedToTray(matched[i], matched[i + 1]);
      }
      returning = _board.tiles.firstWhere((t) => t.id == snap.tileId);
    }

    final trayIndex = _board.tray.indexWhere((t) => t.id == returning.id);
    final fromRect = trayIndex < 0
        ? null
        : _globalRectOf(_traySlotKeys[trayIndex]);
    final toRect = _boardViewKey.currentState?.globalBoardRectOf(returning);
    if (fromRect != null &&
        toRect != null &&
        _launchReturnFlight(returning, fromRect, toRect)) {
      return true;
    }

    if (snap.kind == _UndoKind.match) {
      _board.returnFromTray(returning);
      return true;
    }
    return false;
  }

  void _magnet() {
    _commitPendingFlights();
    if (_board.isWon || _board.isLost || _magnetsLeft <= 0) {
      return;
    }
    final pair = _board.findMagnetPair();
    if (pair == null) {
      setState(() => _toast = L10n.of(context).noMatchingTiles);
      _sfx.error();
      return;
    }

    final extra = pair.match.isOnBoard ? pair.match : null;
    final firstRect = _boardViewKey.currentState?.globalBoardRectOf(
      pair.boardTile,
    );
    final extraRect = extra == null
        ? null
        : _boardViewKey.currentState?.globalBoardRectOf(extra);
    final canFly =
        firstRect != null &&
        firstRect != Rect.zero &&
        (extra == null || (extraRect != null && extraRect != Rect.zero));

    _clearHint();
    final scoreBefore = _score;
    final comboBefore = _combo;
    setState(() => _magnetsLeft -= 1);
    _sfx.magnet();

    if (canFly) {
      final flewFirst = _launchCollectFlight(
        pair.boardTile,
        firstRect!,
        scoreBefore: scoreBefore,
        comboBefore: comboBefore,
        force: true,
      );
      final flewExtra = extra == null
          ? true
          : _launchCollectFlight(
              extra,
              extraRect!,
              scoreBefore: scoreBefore,
              comboBefore: comboBefore,
              force: true,
            );
      if (flewFirst && flewExtra) {
        _persistSnapshot();
        return;
      }
      _commitPendingFlights();
    }

    final first = _board.pick(pair.boardTile, force: true);
    if (first == MatchResult.blocked || first == MatchResult.trayFull) {
      setState(() => _toast = L10n.of(context).noMatchingTiles);
      _sfx.error();
      return;
    }
    if (extra != null && extra.isOnBoard) {
      final second = _board.pick(extra, force: true);
      if (second == MatchResult.blocked || second == MatchResult.trayFull) {
        _board.returnFromTray(pair.boardTile);
        setState(() => _toast = L10n.of(context).noMatchingTiles);
        _sfx.error();
        return;
      }
    }

    _applyTrayResolve(
      tileId: extra?.id ?? pair.boardTile.id,
      scoreBefore: scoreBefore,
      comboBefore: comboBefore,
    );
  }

  void _showMenu() {
    final l10n = L10n.of(context);
    final haptic = HapticScope.maybeOf(context);
    final sfx = SfxScope.maybeOf(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Ui.woodDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            if (haptic != null) haptic,
            if (sfx != null) sfx,
          ]),
          builder: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.refresh_rounded, color: _Ui.ivory),
                title: Text(
                  l10n.retry,
                  style: const TextStyle(color: _Ui.ivory),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _startNewGame();
                },
              ),
              ListTile(
                leading: const Icon(Icons.home_rounded, color: _Ui.ivory),
                title: Text(
                  l10n.courtyard,
                  style: const TextStyle(color: _Ui.ivory),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).maybePop();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.help_outline_rounded,
                  color: _Ui.ivory,
                ),
                title: Text(
                  l10n.howToPlay,
                  style: const TextStyle(color: _Ui.ivory),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(_replayTutorial());
                },
              ),
              SfxSwitchTile(controller: sfx, l10n: l10n),
              HapticSwitchTile(controller: haptic, l10n: l10n),
              ListTile(
                leading: const Icon(Icons.language_rounded, color: _Ui.ivory),
                title: Text(
                  l10n.language,
                  style: const TextStyle(color: _Ui.ivory),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(showLanguagePicker(context));
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.privacy_tip_rounded,
                  color: _Ui.ivory,
                ),
                title: Text(
                  l10n.privacyPolicy,
                  style: const TextStyle(color: _Ui.ivory),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(_openUrl(AppLinks.privacyPolicy));
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_rounded, color: _Ui.ivory),
                title: Text(
                  l10n.aboutGame,
                  style: const TextStyle(color: _Ui.ivory),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAboutGame();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutGame() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3A2012),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: _Ui.gold.withValues(alpha: 0.7),
              width: 1.6,
            ),
          ),
          title: Text(
            L10n.of(dialogContext).aboutGame,
            textAlign: TextAlign.center,
            style: TextStyle(color: _Ui.goldSoft, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Mahjong Rise',
                style: TextStyle(
                  color: _Ui.ivory,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                appVersionLabel,
                style: TextStyle(
                  color: _Ui.ivory.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                L10n.of(dialogContext).builtAt(appBuildTime),
                style: TextStyle(
                  color: _Ui.ivory.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                L10n.of(dialogContext).close,
                style: TextStyle(
                  color: _Ui.goldSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      setState(() => _toast = L10n.of(context).couldNotOpenLink);
    }
  }

  Future<void> _onLevelWon() async {
    unawaited(_clearSnapshot());
    if (widget.isDaily) {
      await _onDailyWon();
      return;
    }
    final firstHome = !widget.progress.hasCompletedAny;
    final cycle = Levels.cycleOf(_level.id);
    final quests = await QuestStore.open();
    final courtyardFrom = CourtyardSnapshot.fromStore(
      widget.progress,
      cycle: cycle,
      streak: widget.progress.visibleStreak(),
      festival: quests.claimedCount > 0,
    );
    final result = await widget.progress.recordWin(
      level: _level,
      score: _score,
    );
    await quests.creditCampaignWin(
      starsGained: result.starsGained,
      firstClear: result.firstClear,
      threeStar: result.earnedStars >= 3,
    );
    final pets = await PetStore.open();
    final filled = await pets.satisfyMostUrgent();
    widget.onProgressChanged?.call();
    final courtyardTo = CourtyardSnapshot.fromStore(
      widget.progress,
      cycle: cycle,
      streak: widget.progress.visibleStreak(),
      festival: quests.claimedCount > 0,
    );
    if (!mounted) return;
    final l10n = L10n.of(context);
    final pathPhrase = firstHome
        ? l10n.firstHomePhraseFor(_level.plotKind)
        : l10n.winPathPhrase(from: courtyardFrom, to: courtyardTo);
    final carePhrase = filled == null
        ? null
        : l10n.petCareWinLine(filled.kind, filled.need);

    unawaited(_syncLeaderboard());

    final stars = result.stars;
    final hasNext = _level.id < Levels.maxLevelId;
    final nextUnlocked =
        result.unlockedNext || widget.progress.isUnlocked(_level.id + 1);

    await showCourtyardWinOverlay(
      context: context,
      stars: stars,
      hasNext: hasNext,
      nextUnlocked: nextUnlocked,
      courtyardFrom: courtyardFrom,
      courtyardTo: courtyardTo,
      pathPhrase: pathPhrase,
      cycle: cycle,
      carePhrase: carePhrase,
      onMap: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
      onNext: () {
        Navigator.of(context).pop();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => GameScreen(
              level: Levels.byId(_level.id + 1),
              progress: widget.progress,
              onProgressChanged: widget.onProgressChanged,
            ),
          ),
        );
      },
      onRetry: () {
        Navigator.of(context).pop();
        _startNewGame();
      },
    );
  }

  Future<void> _syncLeaderboard() async {
    final profile = await PlayerProfileStore.open();
    await FirebaseLeaderboardRepository.syncProgress(
      progress: widget.progress,
      profile: profile,
    );
    await WeeklyLeaderboardRepository.syncProgress(
      progress: widget.progress,
      profile: profile,
    );
    if (!mounted) return;
    await LocalReminderService.resync(l10n: L10n.of(context));
  }

  Future<void> _onDailyWon() async {
    final quests = await QuestStore.open();
    final cycle = Levels.cycleOf(widget.progress.lastPlayedLevel);
    final courtyardFrom = CourtyardSnapshot.fromStore(
      widget.progress,
      cycle: cycle,
      streak: widget.progress.visibleStreak(),
      festival: quests.claimedCount > 0,
    );
    final result = await widget.progress.recordDailyWin();
    if (result.counted) {
      await quests.creditDailyWin(streak: result.streak);
      AnalyticsService.log('daily_win', {'streak': result.streak});
    }
    final pets = await PetStore.open();
    final filled = await pets.satisfyMostUrgent();
    widget.onProgressChanged?.call();
    final courtyardTo = CourtyardSnapshot.fromStore(
      widget.progress,
      cycle: cycle,
      streak: widget.progress.visibleStreak(),
      festival: quests.claimedCount > 0,
    );
    if (!mounted) return;

    unawaited(_syncLeaderboard());
    final l10n = L10n.of(context);
    final carePhrase = filled == null
        ? null
        : l10n.petCareWinLine(filled.kind, filled.need);
    await showCourtyardWinOverlay(
      context: context,
      stars: 0,
      hasNext: false,
      nextUnlocked: false,
      courtyardFrom: courtyardFrom,
      courtyardTo: courtyardTo,
      pathPhrase: result.rewarded
          ? l10n.dailyBonus
          : l10n.winPathPhrase(from: courtyardFrom, to: courtyardTo),
      cycle: cycle,
      title: l10n.dailyComplete,
      subtitle: l10n.streakWinSubtitle(result.streak),
      carePhrase: carePhrase,
      showStars: false,
      streak: result.streak,
      streakFrom: result.counted
          ? (result.streak - 1).clamp(0, 3)
          : result.streak.clamp(0, 3),
      onMap: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
      onNext: () {},
      onRetry: () {
        Navigator.of(context).pop();
        _startNewGame();
      },
    );
  }

  Future<void> _onLevelLost() async {
    if (!mounted || !_board.isLost) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return TrayFullDialog(
          levelTitle: L10n.of(dialogContext).levelTitle(_level),
          score: _score,
          canContinue: _adsAvailable && _undoStack.isNotEmpty,
          onContinue: () => unawaited(_continueFromLose(dialogContext)),
          onRetry: () {
            Navigator.of(dialogContext).pop();
            _startNewGame();
          },
          onMap: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _continueFromLose(BuildContext dialogContext) async {
    if (_adBusy || !AdBootstrap.available || _undoStack.isEmpty) return;

    setState(() => _adBusy = true);
    await _rewardedAds.preload();
    if (!dialogContext.mounted) return;
    final earned = await _rewardedAds.show(context: dialogContext);
    if (!mounted) return;
    setState(() => _adBusy = false);

    if (!earned) {
      setState(() => _toast = L10n.of(context).rewardNotEarned);
      return;
    }

    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
    _reviveFromLose();
  }

  void _reviveFromLose() {
    if (_undoStack.isEmpty) {
      _startNewGame();
      return;
    }
    _loseHandled = false;
    _undo(fromLose: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fieldGreen,
      body: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(child: MahjongScreenBackdrop(dark: true)),
          SafeArea(
            child: Column(
              children: [
                GameHud(
                  onBack: () => Navigator.of(context).maybePop(),
                  onMenu: _showMenu,
                  backTooltip: L10n.of(context).courtyard,
                  menuTooltip: L10n.of(context).menu,
                ),
                CompositedTransformTarget(
                  link: _trayLink,
                  child: TutorialSpotlight(
                    active: _lesson?.anchor == TutorialAnchor.tray,
                    child: _TileTray(
                      tiles: _board.tray,
                      slotKeys: _traySlotKeys,
                      hintedIds: {..._hintedIds, ..._coach.focusIds(_board)},
                      smashingIds: {
                        for (final smash in _smashes) ...[
                          smash.left.id,
                          smash.right.id,
                        ],
                      },
                      onRemoveComplete: _onTileRemoveComplete,
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 0, 2, 0),
                        child: KeyedSubtree(
                          key: ValueKey(_boardGeneration),
                          child: GameBoard(
                            key: _boardViewKey,
                            introToken: _boardGeneration,
                            shuffleToken: _shuffleToken,
                            board: _board,
                            hintedIds: {
                              ..._hintedIds,
                              ..._coach.focusIds(_board),
                            },
                            onTileTap: _onTileTap,
                            onTileRemoveComplete: _onTileRemoveComplete,
                          ),
                        ),
                      ),
                      if (_coach.active && _lesson == null)
                        Align(
                          alignment: _coach.nearTray
                              ? Alignment.topCenter
                              : Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: TableCoachBanner(
                              text: L10n.of(
                                context,
                              ).coachMessage(_coach.step.name),
                            ),
                          ),
                        ),
                      if (_toast != null)
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                            child: IgnorePointer(
                              child: Text(
                                _toast!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _Ui.ivory.withValues(alpha: 0.92),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.45,
                                      ),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                CompositedTransformTarget(
                  link: _actionsLink,
                  child: TutorialSpotlight(
                    active: _lesson?.anchor == TutorialAnchor.actions,
                    child: GameActionBar(
                      shufflesLeft: _shufflesLeft,
                      magnetsLeft: _magnetsLeft,
                      hintsLeft: _hintsLeft,
                      undosLeft: _undosLeft,
                      enabled: !_board.isWon && !_board.isLost,
                      canUndo:
                          _flights.isNotEmpty ||
                          (_undosLeft > 0 && _undoStack.isNotEmpty),
                      canUndoViaAd:
                          _flights.isEmpty &&
                          _undosLeft <= 0 &&
                          _undoStack.isNotEmpty &&
                          _adsAvailable,
                      adsAvailable: _adsAvailable,
                      onShuffle: _onShuffleTap,
                      onMagnet: _onMagnetTap,
                      onHint: _onHintTap,
                      onUndo: _onUndoTap,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_lesson != null)
            Positioned.fill(
              child: SafeArea(
                child: TutorialCoach(
                  lesson: _lesson!,
                  trayLink: _trayLink,
                  actionsLink: _actionsLink,
                  onSkip: () => unawaited(_skipTutorial()),
                  onAcknowledge: () => unawaited(_acknowledgeTutorialStep()),
                ),
              ),
            ),
          Positioned.fill(
            key: _flightLayerKey,
            child: IgnorePointer(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final flight in _flights)
                    TileFlightOverlay(
                      key: ValueKey(flight.token),
                      tile: flight.tile,
                      from: flight.from,
                      to: flight.to,
                      onArrived: () => _onFlightArrived(flight),
                    ),
                  for (final smash in _smashes)
                    MatchSmashOverlay(
                      key: ValueKey(smash.token),
                      left: smash.left,
                      right: smash.right,
                      leftRect: smash.leftRect,
                      rightRect: smash.rightRect,
                      onImpact: () => unawaited(_sfx.smash()),
                      onComplete: () => _onSmashComplete(smash),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Палитра игрового экрана по референсу; mahogany остаётся для диалогов.
abstract final class _Ui {
  static const table = Color(0xFF0B5C40);
  static const tableDeep = Color(0xFF083528);
  static const buttonTop = Color(0xFF1B9A6A);
  static const buttonDeep = Color(0xFF0B6141);
  static const gold = Color(0xFFD4AF37);
  static const badge = Color(0xFFE23B3B);

  static const woodTop = Color(0xFF6B3E24);
  static const woodDeep = Color(0xFF3A2012);
  static const goldSoft = Color(0xFFE8C96A);
  static const ivory = Color(0xFFF8F1DE);
}

/// Лоток с четырьмя вдавленными нишами под плитки.
class _TileTray extends StatefulWidget {
  const _TileTray({
    required this.tiles,
    required this.slotKeys,
    required this.hintedIds,
    required this.smashingIds,
    required this.onRemoveComplete,
  });

  final List<Tile> tiles;
  final List<GlobalKey> slotKeys;
  final Set<int> hintedIds;
  final Set<int> smashingIds;
  final void Function(Tile tile) onRemoveComplete;

  @override
  State<_TileTray> createState() => _TileTrayState();
}

class _TileTrayState extends State<_TileTray>
    with SingleTickerProviderStateMixin {
  static const _slotW = GameBoard.traySlotW;
  static const _slotH = GameBoard.traySlotH;
  static const _padX = 8.0;
  static const _trayW = _padX * 2 + Board.trayCapacity * _slotW;

  late final AnimationController _matchPulse;

  bool get _isMatching => widget.tiles.any((t) => t.removing);

  @override
  void initState() {
    super.initState();
    _matchPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _syncMatchPulse();
  }

  @override
  void didUpdateWidget(_TileTray oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMatchPulse();
  }

  void _syncMatchPulse() {
    if (_isMatching) {
      if (!_matchPulse.isAnimating) {
        _matchPulse.repeat(reverse: true);
      }
    } else if (_matchPulse.isAnimating) {
      _matchPulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _matchPulse.dispose();
    super.dispose();
  }

  Tile? _slotTile(int i) {
    if (i >= widget.tiles.length) return null;
    return widget.tiles[i];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      child: AnimatedBuilder(
        animation: _matchPulse,
        builder: (context, _) {
          final matching = _isMatching;
          final t = matching ? _matchPulse.value : 0.0;
          final glow = matching
              ? Color.lerp(const Color(0xFF5CB0FF), const Color(0xFF9AD4FF), t)!
              : const Color(0xFF3D9CFF);

          return Center(
            child: SizedBox(
              width: _trayW,
              height: GameBoard.trayBarH,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF0A1630),
                  border: Border.all(
                    color: glow.withValues(alpha: matching ? 0.95 : 0.85),
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glow.withValues(alpha: matching ? 0.55 : 0.28),
                      blurRadius: matching ? 16 : 8,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: const _TrayNichesPainter(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < Board.trayCapacity; i++)
                        SizedBox(
                          key: widget.slotKeys[i],
                          width: _slotW,
                          height: _slotH,
                          child: _buildTrayTile(i),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrayTile(int index) {
    final tile = _slotTile(index);
    if (tile == null) return const SizedBox.shrink();
    if (widget.smashingIds.contains(tile.id)) return const SizedBox.shrink();

    final isHinted = widget.hintedIds.contains(tile.id);

    return TileWidget(
      key: ValueKey('tray-${tile.id}-${tile.removing}'),
      tile: tile,
      width: _slotW,
      height: _slotH,
      isSelected: isHinted,
      isFree: true,
      isHinted: isHinted,
      isRemoving: tile.removing,
      compact: true,
      onTap: null,
      onRemoveComplete: () => widget.onRemoveComplete(tile),
    );
  }
}

class _TrayNichesPainter extends CustomPainter {
  const _TrayNichesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const slotW = GameBoard.traySlotW;
    const slotH = GameBoard.traySlotH;
    const count = Board.trayCapacity;
    const gap = 3.0;
    final startX = (size.width - count * slotW) / 2;
    final startY = (size.height - slotH) / 2;

    for (var i = 0; i < count; i++) {
      final rect = Rect.fromLTWH(
        startX + i * slotW + gap,
        startY + 1,
        slotW - gap * 2,
        slotH - 2,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

      canvas.drawRRect(rrect, Paint()..color = _Ui.buttonDeep);

      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawRRect(
        rrect.shift(const Offset(0, 1.8)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.38)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8),
      );
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.bottom - 6, rect.width, 8),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
          ).createShader(rect),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
