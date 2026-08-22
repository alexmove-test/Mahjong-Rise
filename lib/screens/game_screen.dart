import 'dart:async';
import 'dart:math' as math show cos, pi, sin;

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
import '../services/firebase_leaderboard_repository.dart';
import '../services/game_sfx.dart';
import '../services/haptic_controller.dart';
import '../services/player_profile_store.dart';
import '../services/progress_store.dart';
import '../services/rewarded_ad_service.dart';
import '../services/sfx_controller.dart';
import '../services/tutorial_store.dart';
import '../widgets/app_settings.dart';
import '../widgets/courtyard/courtyard_progress.dart';
import '../widgets/courtyard/courtyard_win_overlay.dart';
import '../widgets/game_board.dart';
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
          const ColoredBox(color: _Ui.table),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/felt.png'),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ),
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
  const _DamaskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const step = 52.0;
    final stroke = Paint()
      ..color = const Color(0xFF2F6B4F).withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final fill = Paint()
      ..color = const Color(0xFF4C9A6E).withValues(alpha: 0.06);

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
  });

  final int token;
  final Tile tile;
  final Rect from;
  final Rect to;
  final int scoreBefore;
  final int comboBefore;
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
  int _scoreSparkTick = 0;

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
  final List<GlobalKey> _traySlotKeys = List<GlobalKey>.generate(
    Board.trayCapacity,
    (i) => GlobalKey(debugLabel: 'tray-slot-$i'),
  );
  final List<_TileFlight> _flights = [];
  int _flightSeq = 0;
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
    _scoreSparkTick = 0;
    _shufflesLeft = snap.shuffles;
    _hintsLeft = snap.hints;
    _undosLeft = snap.undos;
    _magnetsLeft = snap.magnets;
    _hintedIds = {};
    _undoStack.clear();
    _flights.clear();
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
    _scoreSparkTick = 0;
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
    if (_board.isWon || _board.isLost) return;
    if (tile.flying) return;

    if (!tile.isOnBoard || !_board.isFree(tile)) {
      setState(() => _toast = L10n.of(context).tileLocked);
      _sfx.error();
      return;
    }
    if (_board.trayLiveCount + _flights.length >= Board.trayCapacity) {
      setState(() => _toast = L10n.of(context).trayFull);
      _sfx.error();
      return;
    }

    final scoreBefore = _score;
    final comboBefore = _combo;
    final slotIndex = _board.trayLiveCount + _flights.length;
    final fromLocal = _rectOnFlightLayer(fromRect);
    final toGlobal = _globalRectOf(_traySlotKeys[slotIndex]);
    final toLocal = toGlobal == null ? null : _rectOnFlightLayer(toGlobal);

    _sfx.collect();
    if (fromLocal == null || toLocal == null || fromRect == Rect.zero) {
      _commitPick(tile, scoreBefore: scoreBefore, comboBefore: comboBefore);
      return;
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
        ),
      );
    });
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
    _commitPick(
      flight.tile,
      scoreBefore: flight.scoreBefore,
      comboBefore: flight.comboBefore,
    );
  }

  void _commitPick(
    Tile tile, {
    required int scoreBefore,
    required int comboBefore,
  }) {
    tile.flying = false;
    final result = _board.pick(tile);
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
      _commitPick(
        flight.tile,
        scoreBefore: flight.scoreBefore,
        comboBefore: flight.comboBefore,
      );
    }
  }

  void _applyTrayResolve({
    required int tileId,
    required int scoreBefore,
    required int comboBefore,
  }) {
    final resolve = _board.resolveTray();
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
          final matched = List<Tile>.from(_board.lastMatched);
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
          _scoreSparkTick++;
          _toast = _board.hasUsefulMove()
              ? null
              : L10n.of(context).noMovesShuffle;
          _sfx.match();
          final praise = _fastPraise.registerMatch(
            now: DateTime.now(),
            languageCode: L10n.of(context).code,
          );
          if (praise != null) _sfx.praise(praise);
          _coach.onMatched();
        case MatchResult.win:
          final matched = List<Tile>.from(_board.lastMatched);
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
    setState(() {
      final useful = _board.shuffleRemaining();
      _shufflesLeft -= 1;
      _combo = 0;
      _toast = useful
          ? L10n.of(context).shuffled
          : L10n.of(context).stillNoMoves;
      if (_lesson?.step != TutorialStep.collect) {
        _hintedIds = {};
      }
    });
    _persistSnapshot();
    _fastPraise.reset();
    _sfx.tap();
    if (_lesson?.step == TutorialStep.collect) {
      _syncTutorial();
    }
  }

  void _onShuffleTap() {
    if (_board.isWon || _board.isLost || _adBusy) return;
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
      _sfx.tap();
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

    if (_undoStack.isEmpty) return;
    if (!fromLose && _undosLeft <= 0) return;
    final snap = _undoStack.removeLast();
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
    _sfx.tap();
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
    final first = _board.pick(pair.boardTile);
    if (first == MatchResult.blocked || first == MatchResult.trayFull) {
      setState(() => _toast = L10n.of(context).noMatchingTiles);
      _sfx.error();
      return;
    }
    if (extra != null) {
      final second = _board.pick(extra);
      if (second == MatchResult.blocked || second == MatchResult.trayFull) {
        _board.returnFromTray(pair.boardTile);
        setState(() => _toast = L10n.of(context).noMatchingTiles);
        _sfx.error();
        return;
      }
    }

    _clearHint();
    final scoreBefore = _score;
    final comboBefore = _combo;
    setState(() => _magnetsLeft -= 1);
    _sfx.collect();
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
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: _Ui.ivory.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  children: [
                    TextSpan(text: L10n.of(dialogContext).iconsBy),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: GestureDetector(
                        onTap: () => unawaited(_openUrl(AppLinks.uicons)),
                        child: const Text(
                          'Flaticon',
                          style: TextStyle(
                            color: _Ui.goldSoft,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: _Ui.goldSoft,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
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
    final courtyardFrom = CourtyardSnapshot.fromStore(
      widget.progress,
      cycle: cycle,
    );
    final result = await widget.progress.recordWin(
      level: _level,
      score: _score,
    );
    widget.onProgressChanged?.call();
    final courtyardTo = CourtyardSnapshot.fromStore(
      widget.progress,
      cycle: cycle,
    );
    if (!mounted) return;
    final l10n = L10n.of(context);
    final pathPhrase = firstHome
        ? l10n.firstHomePhrase
        : l10n.winPathPhrase(from: courtyardFrom, to: courtyardTo);

    unawaited(_syncLeaderboard());

    final stars = result.stars;
    final hasNext = _level.id < Levels.all.length;
    final nextUnlocked =
        result.unlockedNext || widget.progress.isUnlocked(_level.id + 1);

    await showCourtyardWinOverlay(
      context: context,
      levelId: _level.id,
      levelTitle: L10n.of(context).levelTitle(_level),
      score: _score,
      stars: stars,
      isNewBest: result.isNewBest,
      unlockedNext: result.unlockedNext,
      hasNext: hasNext,
      nextUnlocked: nextUnlocked,
      courtyardFrom: courtyardFrom,
      courtyardTo: courtyardTo,
      pathPhrase: pathPhrase,
      firstHome: firstHome,
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
  }

  Future<void> _onDailyWon() async {
    final result = await widget.progress.recordDailyWin();
    widget.onProgressChanged?.call();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
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
            L10n.of(dialogContext).dailyComplete,
            textAlign: TextAlign.center,
            style: TextStyle(color: _Ui.goldSoft, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                L10n.of(dialogContext).streakLabel(result.streak),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _Ui.ivory,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                L10n.of(dialogContext).score(_score),
                style: TextStyle(
                  color: _Ui.ivory.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (result.rewarded) ...[
                const SizedBox(height: 10),
                Text(
                  L10n.of(dialogContext).dailyBonus,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _Ui.goldSoft.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: Text(
                L10n.of(dialogContext).courtyard,
                style: const TextStyle(color: _Ui.ivory),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _Ui.woodTop,
                foregroundColor: _Ui.goldSoft,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _startNewGame();
              },
              child: Text(L10n.of(dialogContext).playAgain),
            ),
          ],
        );
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
          Positioned.fill(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              removeLeft: true,
              removeRight: true,
              child: Builder(
                builder: (context) {
                  final safe = MediaQuery.paddingOf(context);
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      safe.top + 136,
                      0,
                      safe.bottom + 80,
                    ),
                    child: GameBoard(
                      key: ValueKey(_boardGeneration),
                      introToken: _boardGeneration,
                      board: _board,
                      hintedIds: {..._hintedIds, ..._coach.focusIds(_board)},
                      onTileTap: _onTileTap,
                      onTileRemoveComplete: _onTileRemoveComplete,
                    ),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TopBar(
                        levelId: _level.id,
                        score: _score,
                        scoreSparkTick: _scoreSparkTick,
                        onBack: () => Navigator.of(context).maybePop(),
                        onMenu: _showMenu,
                      ),
                      CompositedTransformTarget(
                        link: _trayLink,
                        child: TutorialSpotlight(
                          active: _lesson?.anchor == TutorialAnchor.tray,
                          child: _TileTray(
                            tiles: _board.tray,
                            slotKeys: _traySlotKeys,
                            hintedIds: {
                              ..._hintedIds,
                              ..._coach.focusIds(_board),
                            },
                            onRemoveComplete: _onTileRemoveComplete,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_coach.active && _lesson == null)
                  Positioned(
                    top: _coach.nearTray ? 108 : null,
                    bottom: _coach.nearTray ? null : 88,
                    left: 20,
                    right: 20,
                    child: TableCoachBanner(
                      text: L10n.of(context).coachMessage(_coach.step.name),
                    ),
                  ),
                if (_toast != null)
                  Positioned(
                    top: 128,
                    left: 16,
                    right: 16,
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
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: CompositedTransformTarget(
                    link: _actionsLink,
                    child: TutorialSpotlight(
                      active: _lesson?.anchor == TutorialAnchor.actions,
                      child: _ActionBar(
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
                ),
                if (_lesson != null)
                  Positioned.fill(
                    child: TutorialCoach(
                      lesson: _lesson!,
                      trayLink: _trayLink,
                      actionsLink: _actionsLink,
                      onSkip: () => unawaited(_skipTutorial()),
                      onAcknowledge: () =>
                          unawaited(_acknowledgeTutorialStep()),
                    ),
                  ),
              ],
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

class _TopBar extends StatefulWidget {
  const _TopBar({
    required this.levelId,
    required this.score,
    required this.scoreSparkTick,
    required this.onBack,
    required this.onMenu,
  });

  final int levelId;
  final int score;
  final int scoreSparkTick;
  final VoidCallback onBack;
  final VoidCallback onMenu;

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> with SingleTickerProviderStateMixin {
  static const _sparkCount = 8;

  late final AnimationController _sparkCtrl;

  @override
  void initState() {
    super.initState();
    _sparkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    );
  }

  @override
  void didUpdateWidget(_TopBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scoreSparkTick != oldWidget.scoreSparkTick &&
        widget.scoreSparkTick > 0) {
      _sparkCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _sparkCtrl.dispose();
    super.dispose();
  }

  TextStyle get _scoreStyle => TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: _Ui.goldSoft,
    height: 1.0,
    letterSpacing: 0.2,
    shadows: [
      Shadow(
        color: Colors.black.withValues(alpha: 0.55),
        offset: const Offset(0, 2),
        blurRadius: 4,
      ),
      Shadow(color: _Ui.gold.withValues(alpha: 0.55), blurRadius: 14),
      Shadow(color: _Ui.goldSoft.withValues(alpha: 0.28), blurRadius: 22),
    ],
  );

  List<Widget> _sparkParticles(double t) {
    final fade = (1 - t).clamp(0.0, 1.0);
    final burst = Curves.easeOutCubic.transform(t);
    return [
      for (var i = 0; i < _sparkCount; i++)
        Builder(
          builder: (context) {
            final angle = i / _sparkCount * 2 * math.pi - math.pi / 2;
            final dist = 18 + 34 * burst;
            return Transform.translate(
              offset: Offset(math.cos(angle) * dist, math.sin(angle) * dist),
              child: Transform.rotate(
                angle: angle + math.pi / 2,
                child: Opacity(
                  opacity: fade * 0.95,
                  child: Container(
                    width: 2.4,
                    height: 7 + 4 * (1 - t),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.95),
                          _Ui.goldSoft,
                          _Ui.gold.withValues(alpha: 0.2),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _Ui.gold.withValues(alpha: 0.55 * fade),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
    ];
  }

  Widget _scoreWithSpark() {
    return AnimatedBuilder(
      animation: _sparkCtrl,
      builder: (context, child) {
        final t = _sparkCtrl.value;
        final flashIn = Curves.easeOut.transform((t / 0.28).clamp(0.0, 1.0));
        final flashOut = Curves.easeIn.transform(
          ((t - 0.28) / 0.72).clamp(0.0, 1.0),
        );
        final flash = t > 0 ? flashIn * (1 - flashOut) : 0.0;
        final glow = (1 - t).clamp(0.0, 1.0);

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (t > 0)
              Opacity(
                opacity: glow * 0.55,
                child: Container(
                  width: 96 + 64 * t,
                  height: 44 + 28 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _Ui.goldSoft.withValues(alpha: 0.55),
                        _Ui.gold.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            if (t > 0) ..._sparkParticles(t),
            Transform.scale(
              scale: 1 + 0.08 * flash,
              child: DefaultTextStyle(
                style: flash > 0
                    ? _scoreStyle.copyWith(
                        shadows: [
                          ..._scoreStyle.shadows!,
                          Shadow(
                            color: _Ui.goldSoft.withValues(
                              alpha: 0.45 + 0.45 * flash,
                            ),
                            blurRadius: 12 + 10 * flash,
                          ),
                        ],
                      )
                    : _scoreStyle,
                child: child!,
              ),
            ),
          ],
        );
      },
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '${widget.score}',
          style: _scoreStyle,
          textAlign: TextAlign.center,
          maxLines: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            _RoundIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: L10n.of(context).courtyard,
              onPressed: widget.onBack,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 38, child: _scoreWithSpark()),
                  Text(
                    L10n.of(context).level(widget.levelId),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _RoundIconButton(
              icon: Icons.menu_rounded,
              tooltip: L10n.of(context).menu,
              onPressed: widget.onMenu,
            ),
          ],
        ),
      ),
    );
  }
}

/// Лоток с четырьмя вдавленными нишами под плитки.
class _TileTray extends StatefulWidget {
  const _TileTray({
    required this.tiles,
    required this.slotKeys,
    required this.hintedIds,
    required this.onRemoveComplete,
  });

  final List<Tile> tiles;
  final List<GlobalKey> slotKeys;
  final Set<int> hintedIds;
  final void Function(Tile tile) onRemoveComplete;

  @override
  State<_TileTray> createState() => _TileTrayState();
}

class _TileTrayState extends State<_TileTray>
    with SingleTickerProviderStateMixin {
  static const _slotW = GameBoard.traySlotW;
  static const _slotH = GameBoard.traySlotH;

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
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      child: AnimatedBuilder(
        animation: _matchPulse,
        builder: (context, _) {
          final matching = _isMatching;
          final t = matching ? _matchPulse.value : 0.0;
          final pulseColor = matching
              ? Color.lerp(
                  _Ui.gold,
                  _Ui.goldSoft,
                  t,
                )!.withValues(alpha: 0.45 + 0.35 * t)
              : null;

          return Center(
            child: Container(
              height: GameBoard.trayBarH,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _Ui.tableDeep,
                border: pulseColor == null
                    ? null
                    : Border.all(color: pulseColor, width: 1.6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    offset: const Offset(0, 3),
                    blurRadius: 8,
                  ),
                  if (matching)
                    BoxShadow(
                      color: Color.lerp(
                        _Ui.gold,
                        _Ui.goldSoft,
                        t,
                      )!.withValues(alpha: 0.28),
                      blurRadius: 12,
                    ),
                ],
              ),
              child: CustomPaint(
                painter: const _TrayNichesPainter(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
          );
        },
      ),
    );
  }

  Widget _buildTrayTile(int index) {
    final tile = _slotTile(index);
    if (tile == null) return const SizedBox.shrink();

    final isHinted = widget.hintedIds.contains(tile.id);

    return TileWidget(
      key: ValueKey('tray-${tile.id}-${tile.removing}'),
      tile: tile,
      width: _slotW,
      height: _slotH,
      isSelected: false,
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
    final totalW = slotW * count;
    final startX = (size.width - totalW) / 2;
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return PressableEmbossedButton(
      tooltip: tooltip,
      onPressed: onPressed,
      enabled: onPressed != null,
      size: 44,
      child: FilledGlyph(icon: icon, size: 22, color: _Ui.ivory),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.shufflesLeft,
    required this.magnetsLeft,
    required this.hintsLeft,
    required this.undosLeft,
    required this.enabled,
    required this.canUndo,
    required this.canUndoViaAd,
    required this.adsAvailable,
    required this.onShuffle,
    required this.onMagnet,
    required this.onHint,
    required this.onUndo,
  });

  final int shufflesLeft;
  final int magnetsLeft;
  final int hintsLeft;
  final int undosLeft;
  final bool enabled;
  final bool canUndo;
  final bool canUndoViaAd;
  final bool adsAvailable;
  final VoidCallback onShuffle;
  final VoidCallback onMagnet;
  final VoidCallback onHint;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            shuffle: true,
            tooltip: l10n.boostTooltip(
              l10n.shuffle,
              shufflesLeft,
              adsAvailable: adsAvailable,
            ),
            badge: shufflesLeft > 0 ? '$shufflesLeft' : '+',
            enabled: enabled && (shufflesLeft > 0 || adsAvailable),
            onPressed: onShuffle,
          ),
          _ActionButton(
            magnet: true,
            tooltip: l10n.boostTooltip(
              l10n.magnet,
              magnetsLeft,
              adsAvailable: adsAvailable,
            ),
            badge: magnetsLeft > 0 ? '$magnetsLeft' : '+',
            enabled: enabled && (magnetsLeft > 0 || adsAvailable),
            onPressed: onMagnet,
          ),
          _ActionButton(
            hint: true,
            tooltip: l10n.boostTooltip(
              l10n.hint,
              hintsLeft,
              adsAvailable: adsAvailable,
            ),
            badge: hintsLeft > 0 ? '$hintsLeft' : '+',
            enabled: enabled && (hintsLeft > 0 || adsAvailable),
            onPressed: onHint,
          ),
          _ActionButton(
            undo: true,
            tooltip: canUndo
                ? l10n.undo
                : (canUndoViaAd ? l10n.watchAd(l10n.undo) : l10n.noneLeft),
            badge: undosLeft > 0 ? '$undosLeft' : '+',
            enabled: enabled && (canUndo || canUndoViaAd),
            onPressed: onUndo,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    this.icon,
    this.magnet = false,
    this.shuffle = false,
    this.hint = false,
    this.undo = false,
    required this.tooltip,
    required this.badge,
    required this.enabled,
    required this.onPressed,
  }) : assert(magnet || shuffle || hint || undo || icon != null);

  final IconData? icon;
  final bool magnet;
  final bool shuffle;
  final bool hint;
  final bool undo;
  final String tooltip;
  final String badge;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final exhausted = !enabled && badge == '+';
    final iconColor = enabled
        ? _Ui.ivory
        : (exhausted ? Colors.white38 : _Ui.ivory.withValues(alpha: 0.35));
    final glyph = magnet
        ? MagnetGlyph(size: 26, color: iconColor, animate: enabled)
        : shuffle
        ? ShuffleGlyph(size: 28, color: iconColor, animate: enabled)
        : hint
        ? HintGlyph(size: 28, color: iconColor, animate: enabled)
        : undo
        ? UndoGlyph(size: 28, color: iconColor, animate: enabled)
        : FilledGlyph(icon: icon!, size: 28, color: iconColor);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        PressableEmbossedButton(
          tooltip: tooltip,
          onPressed: enabled ? onPressed : null,
          enabled: enabled,
          exhausted: exhausted,
          size: 58,
          child: glyph,
        ),
        Positioned(
          right: -2,
          top: -2,
          child: BoostCountBadge(
            label: badge,
            enabled: enabled,
            color: _Ui.badge,
          ),
        ),
      ],
    );
  }
}
