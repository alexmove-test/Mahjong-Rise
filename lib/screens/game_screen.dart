import 'dart:async';
import 'dart:math' as math show Random;

import 'package:flutter/material.dart';

import '../debug_agent_log.dart';
import '../debug_boot_timer.dart';
import '../l10n/l10n.dart';
import '../l10n/praise_phrases.dart';
import '../models/board.dart';
import '../models/first_table_coach.dart';
import '../models/game_snapshot.dart';
import '../models/game_table_session.dart';
import '../models/levels.dart';
import '../models/tile.dart';
import '../models/tutorial_step.dart';
import '../services/ad_bootstrap.dart';
import '../services/game_sfx.dart';
import '../services/progress_store.dart';
import '../services/q_mode_controller.dart';
import '../services/rewarded_ad_service.dart';
import '../services/tutorial_store.dart';
import '../widgets/game_action_bar.dart';
import '../widgets/game_board.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_table_menu.dart';
import '../widgets/mahjong_backdrop.dart';
import '../widgets/match_smash.dart';
import '../widgets/table_coach_banner.dart';
import '../widgets/table_flights.dart';
import '../widgets/table_theme.dart';
import '../widgets/tile_flight.dart';
import '../widgets/tile_tray.dart';
import '../widgets/tile_widget.dart';
import '../widgets/tutorial_coach.dart';
import 'game_outcome.dart';

export '../widgets/mahjong_backdrop.dart';

/// Экран партии: полёты, реклама и оверлеи над [GameTableSession].
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

  /// Стол накрывает двор. Обратный переход нулевой — победа сразу показывает двор.
  static PageRoute<T> route<T extends Object?>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final GameTableSession _session = GameTableSession();
  int _boardGeneration = 0;
  Timer? _hintTimer;
  String? _toast;
  bool _winHandled = false;
  bool _loseHandled = false;

  Set<int> _hintedIds = {};
  final GlobalKey _flightLayerKey = GlobalKey();
  final GlobalKey<GameBoardState> _boardViewKey = GlobalKey<GameBoardState>();
  final List<GlobalKey> _traySlotKeys = List<GlobalKey>.generate(
    Board.trayCapacity,
    (i) => GlobalKey(debugLabel: 'tray-slot-$i'),
  );
  final List<TileFlight> _flights = [];
  final List<SmashFlight> _smashes = [];
  int _flightSeq = 0;
  final math.Random _smashRng = math.Random();
  int _shuffleToken = 0;
  bool _shuffleBusy = false;
  Timer? _shuffleBusyTimer;
  final GameSfx _sfx = GameSfx();
  bool _tableStarted = false;
  final FastMatchStreak _fastPraise = FastMatchStreak();
  final RewardedAdService _rewardedAds = RewardedAdService();
  late final FirstTableCoach _coach;
  bool _adBusy = false;

  TutorialStore? _tutorial;
  TutorialLesson? _lesson;
  bool _blockedTap = false;
  final LayerLink _trayLink = LayerLink();
  final LayerLink _actionsLink = LayerLink();

  Board get _board => _session.board;
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
    _syncHintBalance();
    if (!widget.isDaily) {
      widget.progress.markPlayed(_level.id);
    }
    unawaited(_initTutorial());
  }

  @override
  void dispose() {
    _syncHintBalance();
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
      _syncHintBalance();
      _persistSnapshot();
    }
  }

  void _restoreBoard(GameSnapshot snap) {
    _hintTimer?.cancel();
    _boardGeneration++;
    _session.restore(snap);
    _toast = null;
    _winHandled = false;
    _loseHandled = false;
    _hintedIds = {};
    _flights.clear();
    _smashes.clear();
    _shuffleToken = 0;
    _shuffleBusy = false;
    _shuffleBusyTimer?.cancel();
    _fastPraise.reset();
    _tableStarted = true;
  }

  void _syncHintBalance() {
    if (widget.isDaily) return;
    unawaited(widget.progress.setHintBalance(_session.hintsLeft));
  }

  void _persistSnapshot() {
    if (!_session.hasProgressToSave) return;
    unawaited(widget.progress.saveSnapshot(_session.snapshotFor(_slotId)));
  }

  Future<void> _clearSnapshot() => widget.progress.clearSnapshot(_slotId);

  void _resetBoard({bool applyBanked = false}) {
    _hintTimer?.cancel();
    _boardGeneration++;
    final bankHints = applyBanked && !widget.isDaily
        ? widget.progress.bankedHints
        : 0;
    final bankShuffles = applyBanked && !widget.isDaily
        ? widget.progress.bankedShuffles
        : 0;
    final retryHints = _tableStarted && !widget.isDaily
        ? _session.startHints
        : null;
    int? campaignHints;
    if (!widget.isDaily && retryHints == null) {
      campaignHints = widget.progress.hasHintBalance
          ? widget.progress.hintBalance + bankHints
          : _level.hints + bankHints;
    }
    _session.resetFromLevel(
      _level,
      bankedShuffles: bankShuffles,
      hintsLeft: retryHints ?? campaignHints,
    );
    if (applyBanked && !widget.isDaily) {
      unawaited(widget.progress.consumeBankedBoosts());
    }
    _tableStarted = true;
    _syncHintBalance();
    _toast = null;
    _winHandled = false;
    _loseHandled = false;
    _hintedIds = {};
    _flights.clear();
    _smashes.clear();
    _shuffleToken = 0;
    _shuffleBusy = false;
    _shuffleBusyTimer?.cancel();
    _fastPraise.reset();
    _coach.resetIfActive();
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
    final hint = _board.findPlayableHint();
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
    if (_session.isWon || _session.isLost || _shuffleBusy) return;
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

    final scoreBefore = _session.score;
    final comboBefore = _session.combo;
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
        TileFlight(
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
        TileFlight(
          token: _flightSeq++,
          tile: tile,
          from: fromLocal,
          to: toLocal,
          scoreBefore: _session.score,
          comboBefore: _session.combo,
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

  void _onFlightArrived(TileFlight flight) {
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
    final result = _session.pickTile(tile, force: force);
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
    final pending = List<TileFlight>.from(_flights);
    _flights.clear();
    for (final flight in pending) {
      if (!mounted || _session.isWon || _session.isLost) {
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
    final outcome = _session.resolveCollect(
      tileId: tileId,
      scoreBefore: scoreBefore,
      comboBefore: comboBefore,
    );
    final resolve = outcome.result;
    final smashes =
        (resolve == MatchResult.matched || resolve == MatchResult.win)
        ? _planSmashes(outcome.matched)
        : const <SmashFlight>[];

    setState(() {
      _toast = null;

      switch (resolve) {
        case MatchResult.collected:
          _coach.onCollected();
          if (outcome.noUsefulMove) {
            _toast = L10n.of(context).noMovesShuffle;
          }
        case MatchResult.matched:
          _toast = outcome.noUsefulMove
              ? L10n.of(context).noMovesShuffle
              : null;
          if (smashes.length * 2 < outcome.matched.length) {
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
          if (outcome.matched.isNotEmpty) {
            _smashes.addAll(smashes);
          }
          _toast = null;
          _fastPraise.reset();
          _coach.onWin();
          if (!_winHandled) {
            _winHandled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) unawaited(_onLevelWon());
            });
          }
        case MatchResult.lose:
          _toast = null;
          _sfx.lose();
          _fastPraise.reset();
          unawaited(_clearSnapshot());
          if (!_loseHandled) {
            _loseHandled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) unawaited(_onLevelLost());
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

  List<SmashFlight> _planSmashes(List<Tile> matched) {
    if (_lesson != null || matched.length < 2) return const [];
    final flights = <SmashFlight>[];
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
        SmashFlight(
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

  void _onSmashComplete(SmashFlight smash) {
    if (!mounted) return;
    setState(() {
      _smashes.remove(smash);
      if (smash.left.removing) _board.finishRemoval(smash.left);
      if (smash.right.removing) _board.finishRemoval(smash.right);
    });
  }

  void _shuffle() {
    _commitPendingFlights();
    if (_session.isWon || _session.isLost || _session.shufflesLeft <= 0) {
      return;
    }
    _clearHint();
    final outcome = _session.shuffle();
    if (!outcome.applied) {
      if (outcome.fail == ShuffleFail.noFreeTiles) {
        setState(() => _toast = L10n.of(context).noFreeTiles);
        _sfx.error();
      }
      return;
    }
    _shuffleBusyTimer?.cancel();
    setState(() {
      _shuffleToken += 1;
      _shuffleBusy = true;
      _toast = outcome.useful
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
    if (_session.isWon || _session.isLost || _adBusy || _shuffleBusy) return;
    if (_session.shufflesLeft > 0) {
      _shuffle();
      unawaited(_completeBoostsIfNeeded());
    } else if (_adsAvailable) {
      unawaited(_watchAdForBoost(RewardedBoost.shuffle));
    }
  }

  void _onHintTap() {
    if (_session.isWon || _session.isLost || _adBusy) return;
    if (_session.hintsLeft > 0) {
      _hint();
      unawaited(_completeBoostsIfNeeded());
    } else if (_adsAvailable) {
      unawaited(_watchAdForBoost(RewardedBoost.hint));
    }
  }

  void _onMagnetTap() {
    if (_session.isWon || _session.isLost || _adBusy) return;
    if (_session.magnetsLeft > 0) {
      _magnet();
      unawaited(_completeBoostsIfNeeded());
    } else if (_adsAvailable) {
      unawaited(_watchAdForBoost(RewardedBoost.magnet));
    }
  }

  void _onUndoTap() {
    if (_session.isWon || _session.isLost || _adBusy) return;
    if (_flights.isNotEmpty) {
      setState(() {
        final flight = _flights.removeLast();
        flight.tile.flying = false;
      });
      _sfx.undo();
      return;
    }
    if (_session.canUndoCharge) {
      _undo();
      unawaited(_completeBoostsIfNeeded());
    } else if (_adsAvailable && _session.canUndoViaAd) {
      unawaited(_watchAdForBoost(RewardedBoost.undo));
    }
  }

  Future<void> _watchAdForBoost(RewardedBoost boost) async {
    if (_adBusy || !AdBootstrap.available) return;

    setState(() {
      _adBusy = true;
      _toast = AdBootstrap.simulation ? null : L10n.of(context).loadingAd;
    });

    await _rewardedAds.preload();
    if (!mounted) return;
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
    final count = boost == RewardedBoost.magnet
        ? (QModeScope.maybeOf(context)?.magnetChargesForAd ?? 1)
        : 1;
    setState(() {
      _adBusy = false;
      _session.grantBoost(boost, count: count);
      _toast = l10n.boostEarned(switch (boost) {
        RewardedBoost.shuffle => l10n.shuffle,
        RewardedBoost.magnet => l10n.magnet,
        RewardedBoost.hint => l10n.hint,
        RewardedBoost.undo => l10n.undo,
      }, count: count);
    });
    _persistSnapshot();
    _syncHintBalance();
    _sfx.select();
  }

  void _hint() {
    _commitPendingFlights();
    final hint = _session.consumeHint();
    if (hint == null) {
      if (_session.isWon || _session.isLost || _session.hintsLeft <= 0) {
        return;
      }
      setState(() => _toast = L10n.of(context).noUsefulMoves);
      _sfx.error();
      return;
    }
    _hintTimer?.cancel();
    setState(() {
      _hintedIds = {hint.boardTile.id, hint.match.id};
      _toast = null;
    });
    _sfx.select();
    _persistSnapshot();
    _syncHintBalance();
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
    _clearHint();
    _smashes.clear();

    final snap = _session.takeUndo(fromLose: fromLose);
    if (snap == null) return;

    if (!fromLose && _tryAnimateUndo(snap)) {
      setState(() {
        _session.applyScoreUndo(snap, fromLose: false);
        _toast = L10n.of(context).moveUndone;
      });
      _persistSnapshot();
      _sfx.undo();
      return;
    }

    setState(() {
      _session.applyInstantUndo(snap, fromLose: fromLose);
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

  bool _tryAnimateUndo(UndoEntry snap) {
    late final Tile returning;
    if (snap.kind == UndoKind.collect) {
      returning = _session.tileById(snap.tileId!);
    } else {
      _session.prepareMatchUndo(snap);
      returning = _session.tileById(snap.tileId!);
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

    if (snap.kind == UndoKind.match) {
      _board.returnFromTray(returning);
      return true;
    }
    return false;
  }

  void _magnet() {
    _commitPendingFlights();
    if (_session.isWon || _session.isLost || _session.magnetsLeft <= 0) {
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
    final scoreBefore = _session.score;
    final comboBefore = _session.combo;
    setState(() => _session.consumeMagnetCharge());
    _sfx.magnet();

    if (canFly) {
      final flyFrom = firstRect!;
      final flewFirst = _launchCollectFlight(
        pair.boardTile,
        flyFrom,
        scoreBefore: scoreBefore,
        comboBefore: comboBefore,
        force: true,
      );
      final flewExtra = extra == null || extraRect == null
          ? extra == null
          : _launchCollectFlight(
              extra,
              extraRect,
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

    final first = _session.pickTile(pair.boardTile, force: true);
    if (first == MatchResult.blocked || first == MatchResult.trayFull) {
      setState(() => _toast = L10n.of(context).noMatchingTiles);
      _sfx.error();
      return;
    }
    if (extra != null && extra.isOnBoard) {
      final second = _session.pickTile(extra, force: true);
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
    unawaited(
      showGameTableMenu(
        context,
        onRetry: () => unawaited(_startNewGame()),
        onCourtyard: () => Navigator.of(context).maybePop(),
        onHowToPlay: () => unawaited(_replayTutorial()),
        onLinkFailed: (message) {
          if (mounted) setState(() => _toast = message);
        },
      ),
    );
  }

  Future<void> _onLevelWon() async {
    _syncHintBalance();
    unawaited(_clearSnapshot());
    final reveal = widget.isDaily
        ? await GameOutcome.showDailyWin(
            context: context,
            progress: widget.progress,
            onProgressChanged: widget.onProgressChanged,
          )
        : await GameOutcome.showCampaignWin(
            context: context,
            level: _level,
            progress: widget.progress,
            score: _session.score,
            onProgressChanged: widget.onProgressChanged,
          );
    if (!mounted) return;
    Navigator.of(context).pop(reveal);
  }

  Future<void> _onLevelLost() async {
    if (!mounted || !_session.isLost) return;

    await GameOutcome.showLose(
      context: context,
      levelTitle: L10n.of(context).levelTitle(
        _level,
        plotKind: widget.progress.plotKindForLevel(_level.id),
      ),
      score: _session.score,
      canContinue: _adsAvailable && _session.undoStack.isNotEmpty,
      onContinue: (dialogContext) =>
          unawaited(_continueFromLose(dialogContext)),
      onRetry: () {
        Navigator.of(context).pop();
        unawaited(_startNewGame());
      },
      onMap: () {
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
    );
  }

  Future<void> _continueFromLose(BuildContext dialogContext) async {
    if (_adBusy || !AdBootstrap.available || _session.undoStack.isEmpty) {
      return;
    }

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
    if (_session.undoStack.isEmpty) {
      unawaited(_startNewGame());
      return;
    }
    _loseHandled = false;
    _undo(fromLose: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TableUi.table,
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
                    child: TileTray(
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
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  _toast!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: TableUi.ivory.withValues(
                                      alpha: 0.92,
                                    ),
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
                        ),
                    ],
                  ),
                ),
                CompositedTransformTarget(
                  link: _actionsLink,
                  child: TutorialSpotlight(
                    active: _lesson?.anchor == TutorialAnchor.actions,
                    child: GameActionBar(
                      shufflesLeft: _session.shufflesLeft,
                      magnetsLeft: _session.magnetsLeft,
                      hintsLeft: _session.hintsLeft,
                      undosLeft: _session.undosLeft,
                      enabled: !_session.isWon && !_session.isLost,
                      canUndo: _flights.isNotEmpty || _session.canUndoCharge,
                      canUndoViaAd:
                          _flights.isEmpty &&
                          _session.canUndoViaAd &&
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
