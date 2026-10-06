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
import '../services/courtyard_reward_store.dart';
import '../services/game_sfx.dart';
import '../services/play_telemetry.dart';
import '../services/progress_store.dart';
import '../services/q_mode_controller.dart';
import '../services/rewarded_ad_service.dart';
import '../services/table_look_controller.dart';
import '../services/tutorial_store.dart';
import '../widgets/game_action_bar.dart';
import '../widgets/game_board.dart';
import '../widgets/game_hud.dart';
import '../widgets/game_table_menu.dart';
import '../widgets/score_popup.dart';
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
  Timer? _flightWatchdog;
  Timer? _lookHintTimer;
  String? _toast;
  var _lookHint = false;
  var _lookHintScheduled = false;
  int? _earlyApplyGen;
  int? _earlyApplyQueuedGen;
  bool _winHandled = false;
  bool _winCredited = false;
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
  final List<_ScoreFloat> _scoreFloats = [];
  int _flightSeq = 0;
  int _scoreFloatSeq = 0;
  final math.Random _smashRng = math.Random();
  int _shuffleToken = 0;
  bool _shuffleBusy = false;
  Timer? _shuffleBusyTimer;
  final GameSfx _sfx = GameSfx();
  bool _tableStarted = false;
  final FastMatchStreak _fastPraise = FastMatchStreak();
  final RewardedAdService _rewardedAds = RewardedAdService.instance;
  final PlayTelemetry _play = PlayTelemetry();
  late final FirstTableCoach _coach;
  bool _adBusy = false;

  TutorialStore? _tutorial;
  TutorialLesson? _lesson;
  bool _blockedTap = false;
  final LayerLink _trayLink = LayerLink();
  final LayerLink _actionsLink = LayerLink();

  Board get _board => _session.board;
  LevelDef get _level => widget.level;

  /// «+» остаётся живым, пока ролик не открыт: иначе кнопка молчит до конца init.
  bool get _adsAvailable => !_adBusy;
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
    unawaited(_prepareAds());
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
    _syncBoostBalances();
    if (!widget.isDaily) {
      widget.progress.markPlayed(_level.id);
    }
    unawaited(_initTutorial());
  }

  Future<void> _prepareAds() async {
    await AdBootstrap.prepareForAdRequest();
    if (!mounted) return;
    await _rewardedAds.preload();
    if (mounted) setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleEarlyLook();
    _scheduleLookHint();
  }

  void _scheduleEarlyLook() {
    final look = TableLookScope.maybeOf(context);
    if (look == null) return;
    final epoch = look.storeEpoch;
    if (_earlyApplyGen == epoch || _earlyApplyQueuedGen == epoch) return;
    _earlyApplyQueuedGen = epoch;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final controller = TableLookScope.maybeOf(context);
      if (controller == null) return;
      await controller.applyEarlyShowcase(
        _level.id,
        maxUnlocked: widget.progress.maxUnlocked,
      );
      if (!mounted) return;
      _earlyApplyGen = epoch;
      _scheduleLookHint();
    });
  }

  void _scheduleLookHint() {
    if (_lookHintScheduled) return;
    final look = TableLookScope.maybeOf(context);
    if (look == null || !look.settingsHintPending) return;
    _lookHintScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (TableLookScope.maybeOf(context)?.consumeSettingsHint() != true) {
        return;
      }
      _lookHintTimer?.cancel();
      setState(() => _lookHint = true);
      _lookHintTimer = Timer(const Duration(seconds: 5), () {
        if (!mounted) return;
        setState(() => _lookHint = false);
      });
    });
  }

  @override
  void dispose() {
    _lookHintTimer?.cancel();
    _flightWatchdog?.cancel();
    _flushFlightsForPersist();
    _leaveAttempt('exit');
    _syncBoostBalances();
    if (_session.isWon) {
      unawaited(_creditWinIfNeeded());
    } else {
      _persistSnapshot();
    }
    WidgetsBinding.instance.removeObserver(this);
    _hintTimer?.cancel();
    _shuffleBusyTimer?.cancel();
    _sfx.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _flushFlightsForPersist();
      _syncBoostBalances();
      if (_session.isWon) {
        unawaited(_creditWinIfNeeded());
      } else {
        _persistSnapshot();
      }
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
    _flightWatchdog?.cancel();
    _flights.clear();
    _smashes.clear();
    _scoreFloats.clear();
    _shuffleToken = 0;
    _shuffleBusy = false;
    _shuffleBusyTimer?.cancel();
    _fastPraise.reset();
    _tableStarted = true;
    _logLevelStart(PlayStartSource.resume);
  }

  void _syncBoostBalances() {
    if (widget.isDaily) return;
    unawaited(
      widget.progress.setBoostBalances(
        hints: _session.hintsLeft,
        shuffles: _session.shufflesLeft,
        magnets: _session.magnetsLeft,
        undos: _session.undosLeft,
      ),
    );
  }

  int? _carryBoost({
    required bool hasBalance,
    required int balance,
    required int fallback,
    int banked = 0,
  }) {
    if (widget.isDaily) return null;
    return (hasBalance ? balance : fallback) + banked;
  }

  void _persistSnapshot() {
    if (!_session.hasProgressToSave) {
      if (_session.isWon) unawaited(_clearSnapshot());
      return;
    }
    unawaited(widget.progress.saveSnapshot(_session.snapshotFor(_slotId)));
  }

  /// Перед снимком доигрываем зависший полёт, иначе после двора
  /// последняя кость снова лежит на столе, а пара — в лотке.
  void _flushFlightsForPersist() {
    final pending = List<TileFlight>.from(_flights);
    _flights.clear();
    _flightWatchdog?.cancel();
    for (final flight in pending) {
      flight.tile.flying = false;
      if (flight.returning) continue;
      if (flight.tile.inTray || flight.tile.removing || flight.tile.removed) {
        continue;
      }
      if (_session.isWon || _session.isLost) continue;
      _session.pickTile(flight.tile, force: flight.forcePick);
    }
    for (final tile in _board.tiles) {
      if (!tile.flying) continue;
      tile.flying = false;
      if (tile.inTray || tile.removing || tile.removed) continue;
      if (_session.isWon || _session.isLost) continue;
      _session.pickTile(tile);
    }
    if (!_session.isWon && !_session.isLost) {
      _session.board.resolveTray();
    }
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
    final retrying = _tableStarted && !widget.isDaily;
    final source = _tableStarted
        ? PlayStartSource.retry
        : PlayStartSource.newGame;
    _session.resetFromLevel(
      _level,
      hintsLeft: retrying
          ? _session.startHints
          : _carryBoost(
              hasBalance: widget.progress.hasHintBalance,
              balance: widget.progress.hintBalance,
              fallback: _level.hints,
              banked: bankHints,
            ),
      shufflesLeft: retrying
          ? _session.startShuffles
          : _carryBoost(
              hasBalance: widget.progress.hasShuffleBalance,
              balance: widget.progress.shuffleBalance,
              fallback: _level.shuffles,
              banked: bankShuffles,
            ),
      magnetsLeft: retrying
          ? _session.startMagnets
          : _carryBoost(
              hasBalance: widget.progress.hasMagnetBalance,
              balance: widget.progress.magnetBalance,
              fallback: _level.hints,
            ),
      undosLeft: retrying
          ? _session.startUndos
          : _carryBoost(
              hasBalance: widget.progress.hasUndoBalance,
              balance: widget.progress.undoBalance,
              fallback: _level.undos,
            ),
    );
    if (applyBanked && !widget.isDaily) {
      unawaited(widget.progress.consumeBankedBoosts());
    }
    _tableStarted = true;
    _syncBoostBalances();
    _toast = null;
    _winHandled = false;
    _loseHandled = false;
    _hintedIds = {};
    _flightWatchdog?.cancel();
    _flights.clear();
    _smashes.clear();
    _scoreFloats.clear();
    _shuffleToken = 0;
    _shuffleBusy = false;
    _shuffleBusyTimer?.cancel();
    _fastPraise.reset();
    _coach.resetIfActive();
    _logLevelStart(source);
  }

  void _logLevelStart(PlayStartSource source) {
    _play.start(
      levelId: _slotId,
      isDaily: widget.isDaily,
      layout: _level.layout,
      source: source,
      firstTry: !widget.isDaily && widget.progress.stars(_level.id) == 0,
      hints: _session.hintsLeft,
      shuffles: _session.shufflesLeft,
      magnets: _session.magnetsLeft,
      undos: _session.undosLeft,
      tilesLeft: _board.remaining,
    );
  }

  void _leaveAttempt(String reason) {
    _play.leave(
      reason: reason,
      tilesLeft: _board.remaining,
      score: _session.score,
    );
  }

  void _logBooster(String boost, {bool? useful}) {
    final chargesLeft = switch (boost) {
      'shuffle' => _session.shufflesLeft,
      'hint' => _session.hintsLeft,
      'magnet' => _session.magnetsLeft,
      'undo' => _session.undosLeft,
      _ => 0,
    };
    _play.booster(
      boost: boost,
      tilesLeft: _board.remaining,
      chargesLeft: chargesLeft,
      useful: useful,
    );
  }

  void _logAd(String placement, PlayAdResult result) {
    _play.ad(
      placement: placement,
      result: result,
      simulated: AdBootstrap.simulation,
    );
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
    if (tile.flying && tile.inTray) return;
    if (tile.flying) tile.flying = false;

    if (!tile.isOnBoard || !_board.isFree(tile)) {
      setState(() => _toast = AppLocalizations.of(context).tileLocked);
      _sfx.error();
      return;
    }
    if (_board.trayLiveCount >= Board.trayCapacity) {
      setState(() => _toast = AppLocalizations.of(context).trayFull);
      _sfx.error();
      return;
    }

    final scoreBefore = _session.score;
    final comboBefore = _session.combo;
    _sfx.collect();
    _commitPick(tile, scoreBefore: scoreBefore, comboBefore: comboBefore);
    if (!mounted ||
        _winHandled ||
        _session.isWon ||
        tile.removing ||
        tile.removed ||
        !tile.inTray) {
      _settleHiddenTiles();
      return;
    }
    // Последняя кость: не прячем её в полёте — иначе стол пустой, а победы нет.
    if (!_board.tiles.any((other) => other.isOnBoard)) {
      _settleHiddenTiles();
      return;
    }
    _launchCollectFlight(
      tile,
      fromRect,
      scoreBefore: scoreBefore,
      comboBefore: comboBefore,
    );
    _settleHiddenTiles();
  }

  bool _launchCollectFlight(
    Tile tile,
    Rect fromRect, {
    required int scoreBefore,
    required int comboBefore,
    bool force = false,
  }) {
    final slotIndex = _board.tray.indexWhere((t) => t.id == tile.id);
    if (slotIndex < 0 || slotIndex >= _traySlotKeys.length) return false;
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
    _armFlightWatchdog();
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
    _armFlightWatchdog();
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
    if (_flights.isEmpty) _flightWatchdog?.cancel();
    flight.tile.flying = false;
    if (flight.returning) {
      setState(() {});
      _settleHiddenTiles();
      return;
    }
    if (!flight.tile.inTray &&
        !flight.tile.removing &&
        !flight.tile.removed &&
        !flight.tile.flying) {
      _commitPick(
        flight.tile,
        scoreBefore: flight.scoreBefore,
        comboBefore: flight.comboBefore,
        force: flight.forcePick,
      );
    } else {
      setState(() {});
    }
    _settleHiddenTiles();
  }

  void _armFlightWatchdog() {
    _flightWatchdog?.cancel();
    if (_flights.isEmpty) return;
    _flightWatchdog = Timer(
      TileFlightOverlay.duration + const Duration(milliseconds: 180),
      () {
        if (!mounted) return;
        if (_flights.isNotEmpty) _commitPendingFlights();
        _settleHiddenTiles();
      },
    );
  }

  /// Полёт только рисует: сбор уже в лотке. Если тикер завис, кость
  /// всё равно должна быть в нише, а последняя пара — закрыть стол.
  void _settleHiddenTiles() {
    if (!mounted || _loseHandled) return;
    final boardEmpty = !_board.tiles.any((tile) => tile.isOnBoard);
    if (_flights.isNotEmpty && boardEmpty) {
      _commitPendingFlights();
    }
    final tracked = {for (final flight in _flights) flight.tile.id};
    for (final tile in List<Tile>.from(_board.tiles)) {
      if (!tile.flying) continue;
      if (!boardEmpty && tracked.contains(tile.id)) continue;
      tile.flying = false;
      if (tile.inTray || tile.removing || tile.removed) continue;
      if (_session.isWon || _session.isLost) continue;
      _commitPick(
        tile,
        scoreBefore: _session.score,
        comboBefore: _session.combo,
      );
    }
    if (_winHandled || !_session.isWon) return;
    _winHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_onLevelWon());
    });
  }

  void _commitPick(
    Tile tile, {
    required int scoreBefore,
    required int comboBefore,
    bool force = false,
  }) {
    tile.flying = false;
    if (tile.inTray || tile.removed || tile.removing) return;
    final result = _session.pickTile(tile, force: force);
    if (result == MatchResult.blocked) {
      _blockedTap = true;
      setState(() => _toast = AppLocalizations.of(context).tileLocked);
      _sfx.error();
      _syncTutorial();
      return;
    }
    if (result == MatchResult.trayFull) {
      setState(() => _toast = AppLocalizations.of(context).trayFull);
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
    _flightWatchdog?.cancel();
    final pending = List<TileFlight>.from(_flights);
    _flights.clear();
    for (final flight in pending) {
      flight.tile.flying = false;
      if (flight.returning) continue;
      if (flight.tile.inTray || flight.tile.removing || flight.tile.removed) {
        continue;
      }
      if (!mounted || _session.isWon || _session.isLost) continue;
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
            _toast = (_session.shuffleAllowed
                ? AppLocalizations.of(context).noMovesShuffle
                : AppLocalizations.of(context).noShuffleMoves);
          }
        case MatchResult.matched:
          _toast = outcome.noUsefulMove
              ? (_session.shuffleAllowed
                    ? AppLocalizations.of(context).noMovesShuffle
                    : AppLocalizations.of(context).noShuffleMoves)
              : null;
          if (smashes.length * 2 < outcome.matched.length) {
            _sfx.match();
          }
          _smashes.addAll(smashes);
          _spawnScoreFloat(scoreBefore: scoreBefore, won: false);
          _dropFlightsFor(outcome.matched);
          final praise = _fastPraise.registerMatch(
            now: DateTime.now(),
            languageCode: AppLocalizations.of(context).localeName,
          );
          if (praise != null) _sfx.praise(praise);
          _coach.onMatched();
        case MatchResult.win:
          if (outcome.matched.isNotEmpty) {
            _smashes.addAll(smashes);
            _spawnScoreFloat(scoreBefore: scoreBefore, won: true);
            _dropFlightsFor(outcome.matched);
          }
          _flights
            ..forEach((flight) => flight.tile.flying = false)
            ..clear();
          _flightWatchdog?.cancel();
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

  void _spawnScoreFloat({required int scoreBefore, required bool won}) {
    var pairGain = _session.score - scoreBefore;
    if (won) pairGain -= GameTableSession.winBonus;
    if (pairGain <= 0) return;
    _scoreFloats.add(
      _ScoreFloat(
        token: _scoreFloatSeq++,
        points: pairGain,
        combo: _session.combo,
      ),
    );
  }

  void _removeScoreFloat(_ScoreFloat float) {
    if (!_scoreFloats.remove(float) || !mounted) return;
    setState(() {});
  }

  void _dropFlightsFor(Iterable<Tile> tiles) {
    final ids = {for (final tile in tiles) tile.id};
    _flights.removeWhere((flight) {
      if (!ids.contains(flight.tile.id)) return false;
      flight.tile.flying = false;
      return true;
    });
    if (_flights.isEmpty) _flightWatchdog?.cancel();
  }

  void _persistCoachIfDone() {
    if (!_coach.finished || widget.progress.tableCoachDone) return;
    unawaited(widget.progress.markTableCoachDone());
  }

  void _onTileRemoveComplete(Tile tile) {
    if (!mounted || !tile.removing) return;
    setState(() => _board.finishRemoval(tile));
    _settleHiddenTiles();
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
        setState(() => _toast = AppLocalizations.of(context).noFreeTiles);
        _sfx.error();
      }
      return;
    }
    _shuffleBusyTimer?.cancel();
    setState(() {
      _shuffleToken += 1;
      _shuffleBusy = true;
      _toast = outcome.useful
          ? AppLocalizations.of(context).shuffled
          : AppLocalizations.of(context).stillNoMoves;
      if (_lesson?.step != TutorialStep.collect) {
        _hintedIds = {};
      }
    });
    _shuffleBusyTimer = Timer(TileWidget.shufflePlayDuration, () {
      if (!mounted) return;
      setState(() => _shuffleBusy = false);
    });
    _persistSnapshot();
    _syncBoostBalances();
    _fastPraise.reset();
    _sfx.tap();
    _logBooster('shuffle', useful: outcome.useful);
    if (_lesson?.step == TutorialStep.collect) {
      _syncTutorial();
    }
  }

  void _onShuffleTap() {
    if (!_session.shuffleAllowed) return;
    if (_session.isWon || _session.isLost || _adBusy || _shuffleBusy) return;
    if (_session.shufflesLeft > 0) {
      _shuffle();
      unawaited(_completeBoostsIfNeeded());
    } else {
      unawaited(_watchAdForBoost(RewardedBoost.shuffle));
    }
  }

  void _onHintTap() {
    if (_session.isWon || _session.isLost || _adBusy) return;
    if (_session.hintsLeft > 0) {
      _hint();
      unawaited(_completeBoostsIfNeeded());
    } else {
      unawaited(_watchAdForBoost(RewardedBoost.hint));
    }
  }

  void _onMagnetTap() {
    if (_session.isWon || _session.isLost || _adBusy) return;
    if (_session.magnetsLeft > 0) {
      _magnet();
      unawaited(_completeBoostsIfNeeded());
    } else {
      unawaited(_watchAdForBoost(RewardedBoost.magnet));
    }
  }

  void _onUndoTap() {
    if (_session.isWon || _session.isLost || _adBusy) return;
    if (_flights.isNotEmpty) {
      setState(() {
        final flight = _flights.removeLast();
        flight.tile.flying = false;
        if (!flight.returning && (flight.tile.inTray || flight.tile.removing)) {
          final snap = _session.takeUndo(fromLose: true);
          if (snap != null) {
            _session.applyInstantUndo(snap, fromLose: true);
          }
        }
      });
      if (_flights.isEmpty) _flightWatchdog?.cancel();
      _sfx.undo();
      return;
    }
    if (_session.canUndoCharge) {
      _undo();
      unawaited(_completeBoostsIfNeeded());
    } else if (_session.canUndoViaAd) {
      unawaited(_watchAdForBoost(RewardedBoost.undo));
    }
  }

  Future<void> _watchAdForBoost(RewardedBoost boost) async {
    if (boost == RewardedBoost.shuffle && !_session.shuffleAllowed) return;
    if (_adBusy) return;

    setState(() {
      _adBusy = true;
      _toast = AdBootstrap.simulation ? null : AppLocalizations.of(context).loadingAd;
    });

    try {
      if (!AdBootstrap.initFinished || !AdBootstrap.enabled) {
        await AdBootstrap.prepareForAdRequest();
      }
      if (!mounted) return;
      if (!AdBootstrap.available) {
        _logAd(PlayTelemetry.boostPlacement(boost.name), PlayAdResult.skip);
        setState(() => _toast = AppLocalizations.of(context).adUnavailable);
        return;
      }

      _logAd(PlayTelemetry.boostPlacement(boost.name), PlayAdResult.offer);
      await _rewardedAds.preload();
      if (!mounted) return;
      final result = await _rewardedAds.show(context: context);
      _logAd(
        PlayTelemetry.boostPlacement(boost.name),
        result == RewardedAdShowResult.earned
            ? PlayAdResult.complete
            : PlayAdResult.skip,
      );
      if (!mounted) return;

      if (result != RewardedAdShowResult.earned) {
        setState(() {
          _toast = result == RewardedAdShowResult.skipped
              ? AppLocalizations.of(context).rewardNotEarned
              : AppLocalizations.of(context).adUnavailable;
        });
        return;
      }

      final l10n = AppLocalizations.of(context);
      final count = boost == RewardedBoost.magnet
          ? (QModeScope.maybeOf(context)?.magnetChargesForAd ?? 1)
          : 1;
      setState(() {
        _session.grantBoost(boost, count: count);
        _toast = l10n.boostEarned(switch (boost) {
          RewardedBoost.shuffle => l10n.shuffle,
          RewardedBoost.magnet => l10n.magnet,
          RewardedBoost.hint => l10n.hint,
          RewardedBoost.undo => l10n.undo,
        }, count: count);
      });
      _persistSnapshot();
      _syncBoostBalances();
      _sfx.select();
      switch (boost) {
        case RewardedBoost.hint:
          _hint();
          unawaited(_completeBoostsIfNeeded());
        case RewardedBoost.shuffle:
          _shuffle();
          unawaited(_completeBoostsIfNeeded());
        case RewardedBoost.undo:
          _undo();
          unawaited(_completeBoostsIfNeeded());
        case RewardedBoost.magnet:
          break;
      }
    } catch (_) {
      if (!mounted) return;
      _logAd(PlayTelemetry.boostPlacement(boost.name), PlayAdResult.skip);
      setState(() => _toast = AppLocalizations.of(context).adUnavailable);
    } finally {
      _adBusy = false;
      if (mounted) setState(() {});
    }
  }

  void _hint() {
    _commitPendingFlights();
    final hint = _session.consumeHint();
    if (hint == null) {
      if (_session.isWon || _session.isLost || _session.hintsLeft <= 0) {
        return;
      }
      setState(() => _toast = AppLocalizations.of(context).noUsefulMoves);
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
    _syncBoostBalances();
    _logBooster('hint');
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
        _toast = AppLocalizations.of(context).moveUndone;
      });
      _persistSnapshot();
      _syncBoostBalances();
      _sfx.undo();
      _logBooster('undo');
      return;
    }

    setState(() {
      _session.applyInstantUndo(snap, fromLose: fromLose);
      _toast = fromLose
          ? AppLocalizations.of(context).continuing
          : AppLocalizations.of(context).moveUndone;
    });
    _persistSnapshot();
    _syncBoostBalances();
    if (fromLose) {
      _sfx.tap();
    } else {
      _sfx.undo();
      _logBooster('undo');
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
      setState(() => _toast = AppLocalizations.of(context).noMatchingTiles);
      _sfx.error();
      return;
    }

    final extra = pair.match.isOnBoard ? pair.match : null;
    _clearHint();
    final scoreBefore = _session.score;
    final comboBefore = _session.combo;
    setState(() => _session.consumeMagnetCharge());
    _syncBoostBalances();
    _sfx.magnet();
    _logBooster('magnet');

    final first = _session.pickTile(pair.boardTile, force: true);
    if (first == MatchResult.blocked || first == MatchResult.trayFull) {
      setState(() => _toast = AppLocalizations.of(context).noMatchingTiles);
      _sfx.error();
      return;
    }
    if (extra != null && extra.isOnBoard) {
      final second = _session.pickTile(extra, force: true);
      if (second == MatchResult.blocked || second == MatchResult.trayFull) {
        _board.returnFromTray(pair.boardTile);
        setState(() => _toast = AppLocalizations.of(context).noMatchingTiles);
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
        onCourtyard: () {
          _leaveAttempt('back');
          Navigator.of(context).maybePop();
        },
        onHowToPlay: () => unawaited(_replayTutorial()),
        onLinkFailed: (message) {
          if (mounted) setState(() => _toast = message);
        },
      ),
    );
  }

  Future<void> _creditWinIfNeeded() async {
    if (_winCredited || !_session.isWon) return;
    _winCredited = true;
    _winHandled = true;
    unawaited(_clearSnapshot());
    if (widget.isDaily) {
      await widget.progress.recordDailyWin();
    } else {
      final result = await widget.progress.recordWin(
        level: _level,
        score: _session.score,
      );
      if (result.firstClear) {
        final rewards = await CourtyardRewardStore.open();
        await rewards.recordFirstClear(_level.id);
      }
    }
    widget.onProgressChanged?.call();
  }

  Future<void> _onLevelWon() async {
    if (_winCredited) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    _winCredited = true;
    _play.end(
      success: true,
      tilesLeft: _board.remaining,
      score: _session.score,
      stars: _level.starsForScore(_session.score),
    );
    _syncBoostBalances();
    unawaited(_clearSnapshot());
    final reveal = widget.isDaily
        ? await GameOutcome.showDailyWin(
            context: context,
            progress: widget.progress,
            score: _session.score,
            stars: _level.starsForScore(_session.score),
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

    final canContinue = _adsAvailable && _session.undoStack.isNotEmpty;
    _play.end(
      success: false,
      tilesLeft: _board.remaining,
      score: _session.score,
      canContinue: canContinue,
    );
    await GameOutcome.showLose(
      context: context,
      levelTitle: AppLocalizations.of(context).levelTitle(
        _level,
        plotKind: widget.progress.plotKindForLevel(_level.id),
      ),
      score: _session.score,
      canContinue: canContinue,
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
    if (_adBusy || _session.undoStack.isEmpty) return;

    setState(() => _adBusy = true);
    try {
      await AdBootstrap.prepareForAdRequest();
      if (!mounted || !dialogContext.mounted) return;
      if (!AdBootstrap.available || _session.undoStack.isEmpty) {
        setState(() => _toast = AppLocalizations.of(context).adUnavailable);
        return;
      }

      _logAd(PlayTelemetry.placementLoseContinue, PlayAdResult.offer);
      await _rewardedAds.preload();
      if (!dialogContext.mounted) return;
      final result = await _rewardedAds.show(context: dialogContext);
      _logAd(
        PlayTelemetry.placementLoseContinue,
        result == RewardedAdShowResult.earned
            ? PlayAdResult.complete
            : PlayAdResult.skip,
      );
      if (!mounted) return;

      if (result != RewardedAdShowResult.earned) {
        setState(
          () => _toast = result == RewardedAdShowResult.skipped
              ? AppLocalizations.of(context).rewardNotEarned
              : AppLocalizations.of(context).adUnavailable,
        );
        return;
      }

      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
      _reviveFromLose();
    } catch (_) {
      if (!mounted) return;
      _logAd(PlayTelemetry.placementLoseContinue, PlayAdResult.skip);
      setState(() => _toast = AppLocalizations.of(context).adUnavailable);
    } finally {
      _adBusy = false;
      if (mounted) setState(() {});
    }
  }

  void _reviveFromLose() {
    if (_session.undoStack.isEmpty) {
      unawaited(_startNewGame());
      return;
    }
    _loseHandled = false;
    _play.continueAttempt();
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
                  onBack: () {
                    _leaveAttempt('back');
                    Navigator.of(context).maybePop();
                  },
                  onMenu: _showMenu,
                  backTooltip: AppLocalizations.of(context).courtyard,
                  menuTooltip: AppLocalizations.of(context).menu,
                ),
                CompositedTransformTarget(
                  link: _trayLink,
                  child: TutorialSpotlight(
                    active: _lesson?.anchor == TutorialAnchor.tray,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        TileTray(
                          targetTileIds: _board.targetTileIds,
                          tiles: _board.tray,
                          slotKeys: _traySlotKeys,
                          hintedIds: {
                            ..._hintedIds,
                            ..._coach.focusIds(_board),
                          },
                          smashingIds: {
                            for (final smash in _smashes) ...[
                              smash.left.id,
                              smash.right.id,
                            ],
                          },
                          onRemoveComplete: _onTileRemoveComplete,
                        ),
                        for (final pop in _scoreFloats)
                          Positioned(
                            top: 4,
                            child: ScorePopup(
                              key: ValueKey(pop.token),
                              points: pop.points,
                              combo: pop.combo,
                              onFinished: () => _removeScoreFloat(pop),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (AppLocalizations.of(context).challengeGoal(_board.challenge).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        AppLocalizations.of(context).challengeGoal(
                          _board.challenge,
                          cleared: _board.targetsCleared,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
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
                      if (_lookHint)
                        Align(
                          alignment: _coach.active && !_coach.nearTray
                              ? Alignment.topCenter
                              : Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            child: TableCoachBanner(
                              key: tableLookSettingsHintKey,
                              text: AppLocalizations.of(context).tableLookSettingsHint,
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
                              text: AppLocalizations.of(
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
                      shuffleAllowed: _session.shuffleAllowed,
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

class _ScoreFloat {
  const _ScoreFloat({
    required this.token,
    required this.points,
    required this.combo,
  });

  final int token;
  final int points;
  final int combo;
}
