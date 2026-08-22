import 'dart:async';
import 'dart:math' as math show Random, cos, pi, sin;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_version.dart';
import '../config/app_links.dart';
import '../debug_agent_log.dart';
import '../debug_boot_timer.dart';
import '../l10n/praise_phrases.dart';
import '../models/board.dart';
import '../models/levels.dart';
import '../models/tile.dart';
import '../models/tutorial_step.dart';
import '../services/ad_bootstrap.dart';
import '../services/game_sfx.dart';
import '../services/firebase_leaderboard_repository.dart';
import '../services/player_profile_store.dart';
import '../services/progress_store.dart';
import '../services/rewarded_ad_service.dart';
import '../services/tutorial_store.dart';
import '../utils/tile_icons.dart';
import '../widgets/game_board.dart';
import '../widgets/premium_ui.dart';
import '../widgets/tutorial_coach.dart';
import '../widgets/tile_symbol_image.dart';
import '../widgets/tile_widget.dart';

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

/// Метка версии в углу экрана, чтобы не путать сборки.
class AppVersionBadge extends StatelessWidget {
  const AppVersionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 0, 8),
            child: Text(
              appVersionLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: const Color(0xFF2F6B4F).withValues(alpha: 0.72),
                shadows: [
                  Shadow(
                    color: Colors.white.withValues(alpha: 0.7),
                    offset: const Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Экран партии: счёт, тёмное поле, круглые действия с бейджами.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    required this.progress,
    this.onProgressChanged,
  });

  final LevelDef level;
  final ProgressStore progress;
  final VoidCallback? onProgressChanged;

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

class _GameScreenState extends State<GameScreen> {
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

  Set<int> _hintedIds = {};
  final List<_UndoEntry> _undoStack = [];
  final GameSfx _sfx = GameSfx();
  final FastMatchStreak _fastPraise = FastMatchStreak();
  final RewardedAdService _rewardedAds = RewardedAdService();
  bool _adBusy = false;

  TutorialStore? _tutorial;
  TutorialLesson? _lesson;
  bool _blockedTap = false;
  final LayerLink _trayLink = LayerLink();
  final LayerLink _actionsLink = LayerLink();

  LevelDef get _level => widget.level;
  bool get _adsAvailable => AdBootstrap.enabled && !_adBusy;

  @override
  void initState() {
    super.initState();
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
    _resetBoard();
    widget.progress.markPlayed(_level.id);
    unawaited(_initTutorial());
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _rewardedAds.dispose();
    _sfx.dispose();
    super.dispose();
  }

  void _resetBoard() {
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
    _hintedIds = {};
    _undoStack.clear();
    _fastPraise.reset();
  }

  void _startNewGame() {
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
    final trayTile = hint.trayTile;
    return {hint.boardTile.id, if (trayTile != null) trayTile.id};
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

    final scoreBefore = _score;
    final comboBefore = _combo;
    final result = _board.pick(tile);

    if (result == MatchResult.blocked) {
      _blockedTap = true;
      setState(() => _toast = 'Плитка заблокирована');
      _sfx.error();
      _syncTutorial();
      return;
    }
    if (result == MatchResult.trayFull) {
      setState(() => _toast = 'Лоток полон');
      _sfx.error();
      return;
    }

    _blockedTap = false;
    _hintTimer?.cancel();
    if (_lesson?.step != TutorialStep.collect && _hintedIds.isNotEmpty) {
      _hintedIds = {};
    }

    _sfx.collect();
    _applyTrayResolve(
      tileId: tile.id,
      scoreBefore: scoreBefore,
      comboBefore: comboBefore,
    );
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
          _toast = _board.hasMoves() ? null : 'Нет ходов — перемешайте';
          _sfx.match();
          final praise = _fastPraise.registerMatch(
            now: DateTime.now(),
            languageCode:
                WidgetsBinding.instance.platformDispatcher.locale.languageCode,
          );
          if (praise != null) _sfx.praise(praise);
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
          _toast = 'Победа!';
          _sfx.win();
          _fastPraise.reset();
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
    unawaited(_onTutorialAfterMove(resolve));
  }

  void _onTileRemoveComplete(Tile tile) {
    if (!mounted || !tile.removing) return;
    setState(() => _board.finishRemoval(tile));
  }

  void _shuffle() {
    if (_board.isWon || _board.isLost || _shufflesLeft <= 0) {
      return;
    }
    _hintTimer?.cancel();
    setState(() {
      _board.shuffleRemaining();
      _shufflesLeft -= 1;
      _combo = 0;
      _toast = _board.hasMoves() ? 'Перемешано' : 'Всё ещё нет ходов';
      if (_lesson?.step != TutorialStep.collect) {
        _hintedIds = {};
      }
    });
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
    if (_undosLeft > 0 && _undoStack.isNotEmpty) {
      _undo();
      unawaited(_completeBoostsIfNeeded());
    } else if (_adsAvailable && _undosLeft <= 0 && _undoStack.isNotEmpty) {
      unawaited(_watchAdForBoost(_RewardedBoost.undo));
    }
  }

  Future<void> _watchAdForBoost(_RewardedBoost boost) async {
    if (_adBusy || !AdBootstrap.enabled) return;

    setState(() {
      _adBusy = true;
      _toast = 'Загрузка рекламы…';
    });

    await _rewardedAds.preload();
    final earned = await _rewardedAds.show();
    if (!mounted) return;

    if (!earned) {
      setState(() {
        _adBusy = false;
        _toast = 'Реклама недоступна';
      });
      return;
    }

    setState(() {
      _adBusy = false;
      _toast = null;
      switch (boost) {
        case _RewardedBoost.shuffle:
          _shufflesLeft += 1;
        case _RewardedBoost.magnet:
          _magnetsLeft += 1;
        case _RewardedBoost.hint:
          _hintsLeft += 1;
        case _RewardedBoost.undo:
          _undosLeft += 1;
      }
    });

    switch (boost) {
      case _RewardedBoost.shuffle:
        _shuffle();
      case _RewardedBoost.magnet:
        _magnet();
      case _RewardedBoost.hint:
        _hint();
      case _RewardedBoost.undo:
        _undo();
    }
  }

  void _hint() {
    if (_board.isWon || _board.isLost || _hintsLeft <= 0) {
      return;
    }
    final hint = _board.findHint();
    if (hint == null) {
      setState(() => _toast = 'Нет полезных ходов');
      _sfx.error();
      return;
    }
    _hintTimer?.cancel();
    setState(() {
      _hintsLeft -= 1;
      _hintedIds = {
        hint.boardTile.id,
        if (hint.trayTile != null) hint.trayTile!.id,
      };
      _toast = null;
    });
    _sfx.select();
    _hintTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (_lesson?.step == TutorialStep.collect) {
        setState(() => _hintedIds = _tutorialHintIds());
        return;
      }
      setState(() => _hintedIds = {});
    });
  }

  void _undo() {
    if (_board.isWon || _board.isLost) return;
    _clearHint();

    if (_undosLeft <= 0 || _undoStack.isEmpty) return;
    final snap = _undoStack.removeLast();
    setState(() {
      if (snap.kind == _UndoKind.collect) {
        final tile = _board.tiles.firstWhere((t) => t.id == snap.tileId);
        _board.returnFromTray(tile);
      } else {
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
      _undosLeft -= 1;
      _toast = 'Ход отменён';
    });
    _sfx.tap();
  }

  void _magnet() {
    if (_board.isWon || _board.isLost || _magnetsLeft <= 0) {
      return;
    }
    final target = _board.findMagnetTarget();
    if (target == null) {
      setState(() => _toast = 'Нет подходящих плиток');
      _sfx.error();
      return;
    }
    _clearHint();
    setState(() => _magnetsLeft -= 1);
    _onTileTap(
      target,
      Rect.fromCenter(
        center: Offset.zero,
        width: GameBoard.traySlotW,
        height: GameBoard.traySlotH,
      ),
    );
    _sfx.select();
  }

  void _showMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _Ui.woodDeep,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh_rounded, color: _Ui.ivory),
              title: const Text('Заново', style: TextStyle(color: _Ui.ivory)),
              onTap: () {
                Navigator.pop(ctx);
                _startNewGame();
              },
            ),
            ListTile(
              leading: const Icon(Icons.map_rounded, color: _Ui.ivory),
              title: const Text(
                'К уровням',
                style: TextStyle(color: _Ui.ivory),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).maybePop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline_rounded, color: _Ui.ivory),
              title: const Text(
                'Как играть',
                style: TextStyle(color: _Ui.ivory),
              ),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(_replayTutorial());
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_rounded, color: _Ui.ivory),
              title: const Text(
                'Политика конфиденциальности',
                style: TextStyle(color: _Ui.ivory),
              ),
              onTap: () {
                Navigator.pop(ctx);
                unawaited(_openUrl(AppLinks.privacyPolicy));
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_rounded, color: _Ui.ivory),
              title: const Text(
                'About game',
                style: TextStyle(color: _Ui.ivory),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showAboutGame();
              },
            ),
          ],
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
          title: const Text(
            'About game',
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
                    const TextSpan(text: 'Иконки: Uicons от '),
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
              child: const Text(
                'Закрыть',
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
      setState(() => _toast = 'Не удалось открыть ссылку');
    }
  }

  Future<void> _onLevelWon() async {
    final result = await widget.progress.recordWin(
      level: _level,
      score: _score,
    );
    widget.onProgressChanged?.call();

    final profile = await PlayerProfileStore.open();
    await FirebaseLeaderboardRepository.syncProgress(
      progress: widget.progress,
      profile: profile,
    );

    if (!mounted) return;

    final stars = result.stars;
    final hasNext = _level.id < Levels.all.length;
    final nextUnlocked =
        result.unlockedNext || widget.progress.isUnlocked(_level.id + 1);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _WinDialog(
          levelId: _level.id,
          levelTitle: _level.title,
          score: _score,
          stars: stars,
          isNewBest: result.isNewBest,
          unlockedNext: result.unlockedNext,
          hasNext: hasNext,
          nextUnlocked: nextUnlocked,
          onMap: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pop();
          },
          onNext: () {
            Navigator.of(dialogContext).pop();
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
            Navigator.of(dialogContext).pop();
            _startNewGame();
          },
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
        return AlertDialog(
          backgroundColor: const Color(0xFF3A2012),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: _Ui.gold.withValues(alpha: 0.7),
              width: 1.6,
            ),
          ),
          title: const Text(
            'Лоток полон',
            textAlign: TextAlign.center,
            style: TextStyle(color: _Ui.goldSoft, fontWeight: FontWeight.w800),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _level.title,
                style: TextStyle(
                  color: _Ui.ivory.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Нет пары для совпадения.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _Ui.ivory.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Счёт: $_score',
                style: const TextStyle(
                  color: _Ui.ivory,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                'К уровням',
                style: TextStyle(color: _Ui.ivory),
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
              child: const Text('Заново'),
            ),
          ],
        );
      },
    );
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
                      safe.top + 188,
                      0,
                      safe.bottom + 80,
                    ),
                    child: GameBoard(
                      key: ValueKey(_boardGeneration),
                      introToken: _boardGeneration,
                      board: _board,
                      hintedIds: _hintedIds,
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
                            hintedIds: _hintedIds,
                            onRemoveComplete: _onTileRemoveComplete,
                          ),
                        ),
                      ),
                      _GoalBar(
                        removed: _board.tiles.where((t) => t.removed).length,
                        total: _board.tiles.length,
                        combo: _combo,
                        style: _level.style,
                      ),
                      SizedBox(
                        height: 18,
                        child: _toast == null
                            ? null
                            : Align(
                                alignment: Alignment.center,
                                child: Text(
                                  _toast!,
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
                    ],
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
                        canUndo: _undosLeft > 0 && _undoStack.isNotEmpty,
                        canUndoViaAd:
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
  static const progress = Color(0xFFE0C35A);
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
              tooltip: 'К уровням',
              onPressed: widget.onBack,
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 38, child: _scoreWithSpark()),
                  Text(
                    'Уровень ${widget.levelId}',
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
              tooltip: 'Меню',
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
    required this.hintedIds,
    required this.onRemoveComplete,
  });

  final List<Tile> tiles;
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
                        key: ValueKey('tray-slot-$i'),
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
      isSelected: !tile.removing && !isHinted,
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

class _GoalBar extends StatelessWidget {
  const _GoalBar({
    required this.removed,
    required this.total,
    required this.combo,
    required this.style,
  });

  final int removed;
  final int total;
  final int combo;
  final String? style;

  String get _multiplierLabel {
    final m = 1 + combo * 0.25;
    if (m == m.roundToDouble()) return '${m.toInt()}x';
    return '${m.toStringAsFixed(2).replaceAll('.', ',')}x';
  }

  String get _glyph {
    final ids = TileIcons.idsForStyle(style ?? 'mixed');
    return ids.isNotEmpty ? ids.first : 'fruit-01';
  }

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (removed / total).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            _GoalToken(symbol: _glyph),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Positioned.fill(
                      child: ColoredBox(color: _Ui.tableDeep),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        heightFactor: 1,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFF4E7A8),
                                _Ui.progress,
                                Color(0xFFB8963A),
                              ],
                              stops: [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '$removed/$total',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.95),
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.45),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 10,
                      child: Text(
                        _multiplierLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _Ui.gold,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalToken extends StatelessWidget {
  const _GoalToken({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _Ui.buttonDeep,
        border: Border.all(color: _Ui.gold.withValues(alpha: 0.8), width: 1.4),
        boxShadow: [
          BoxShadow(color: _Ui.gold.withValues(alpha: 0.42), blurRadius: 8),
          BoxShadow(
            color: _Ui.buttonTop.withValues(alpha: 0.35),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: TileSymbolImage(symbol: symbol),
    );
  }
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

  String _boostTooltip(String name, int left) {
    if (left > 0) return name;
    if (adsAvailable) return 'Реклама → $name';
    return 'нет использований';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.shuffle_rounded,
            tooltip: _boostTooltip('Перемешать', shufflesLeft),
            badge: shufflesLeft > 0 ? '$shufflesLeft' : '+',
            enabled: enabled && (shufflesLeft > 0 || adsAvailable),
            onPressed: onShuffle,
          ),
          _ActionButton(
            magnet: true,
            tooltip: _boostTooltip('Магнит', magnetsLeft),
            badge: magnetsLeft > 0 ? '$magnetsLeft' : '+',
            enabled: enabled && (magnetsLeft > 0 || adsAvailable),
            onPressed: onMagnet,
          ),
          _ActionButton(
            icon: Icons.lightbulb_rounded,
            tooltip: _boostTooltip('Подсказка', hintsLeft),
            badge: hintsLeft > 0 ? '$hintsLeft' : '+',
            enabled: enabled && (hintsLeft > 0 || adsAvailable),
            onPressed: onHint,
          ),
          _ActionButton(
            icon: Icons.undo_rounded,
            tooltip: canUndo
                ? 'Отмена'
                : (canUndoViaAd ? 'Реклама → отмена' : 'нет использований'),
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
    required this.tooltip,
    required this.badge,
    required this.enabled,
    required this.onPressed,
  }) : assert(magnet || icon != null);

  final IconData? icon;
  final bool magnet;
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
        ? MagnetGlyph(size: 26, color: iconColor)
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

class _WinDialog extends StatefulWidget {
  const _WinDialog({
    required this.levelId,
    required this.levelTitle,
    required this.score,
    required this.stars,
    required this.isNewBest,
    required this.unlockedNext,
    required this.hasNext,
    required this.nextUnlocked,
    required this.onMap,
    required this.onNext,
    required this.onRetry,
  });

  final int levelId;
  final String levelTitle;
  final int score;
  final int stars;
  final bool isNewBest;
  final bool unlockedNext;
  final bool hasNext;
  final bool nextUnlocked;
  final VoidCallback onMap;
  final VoidCallback onNext;
  final VoidCallback onRetry;

  @override
  State<_WinDialog> createState() => _WinDialogState();
}

class _WinDialogState extends State<_WinDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebrate;

  @override
  void initState() {
    super.initState();
    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();
  }

  @override
  void dispose() {
    _celebrate.dispose();
    super.dispose();
  }

  double _segment(double start, double end) {
    final t = _celebrate.value;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  double _starProgress(int index) =>
      _segment(0.14 + index * 0.16, 0.30 + index * 0.16);

  Widget _starIcon(int index) {
    final earned = index < widget.stars;
    if (!earned) {
      return const Icon(
        Icons.star_outline_rounded,
        color: Colors.white24,
        size: 36,
      );
    }

    final t = Curves.elasticOut.transform(_starProgress(index));
    return Transform.scale(
      scale: t,
      child: Icon(
        Icons.star_rounded,
        color: _Ui.gold,
        size: 36,
        shadows: [
          Shadow(
            color: _Ui.goldSoft.withValues(alpha: 0.55 * t),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _celebrate,
      builder: (context, _) {
        final scoreIn = Curves.easeOutBack.transform(_segment(0.04, 0.18));
        final recordIn = Curves.easeOut.transform(_segment(0.62, 0.82));
        final unlockIn = Curves.easeOut.transform(_segment(0.72, 0.92));

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
            'Уровень ${widget.levelId} пройден!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _Ui.goldSoft,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: SizedBox(
            width: 280,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _WinConfettiPainter(progress: _celebrate.value),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.levelTitle,
                      style: TextStyle(
                        color: _Ui.ivory.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          _starIcon(i),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Transform.scale(
                      scale: 0.92 + 0.08 * scoreIn,
                      child: Opacity(
                        opacity: scoreIn.clamp(0.0, 1.0),
                        child: Text(
                          'Счёт: ${widget.score}',
                          style: const TextStyle(
                            color: _Ui.ivory,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    if (widget.isNewBest)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Opacity(
                          opacity: recordIn,
                          child: Transform.scale(
                            scale: 0.85 + 0.15 * recordIn,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _Ui.gold.withValues(alpha: 0.35),
                                    _Ui.goldSoft.withValues(alpha: 0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _Ui.goldSoft.withValues(alpha: 0.75),
                                  width: 1.2,
                                ),
                              ),
                              child: const Text(
                                'Новый рекорд!',
                                style: TextStyle(
                                  color: _Ui.goldSoft,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (widget.unlockedNext)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Opacity(
                          opacity: unlockIn,
                          child: Text(
                            'Открыт уровень ${widget.levelId + 1}',
                            style: TextStyle(
                              color: _Ui.goldSoft.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: widget.onMap,
              child: const Text('Карта', style: TextStyle(color: _Ui.ivory)),
            ),
            if (widget.hasNext && widget.nextUnlocked)
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _Ui.woodTop,
                  foregroundColor: _Ui.goldSoft,
                ),
                onPressed: widget.onNext,
                child: const Text('Дальше'),
              )
            else
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _Ui.woodTop,
                  foregroundColor: _Ui.goldSoft,
                ),
                onPressed: widget.onRetry,
                child: const Text('Ещё раз'),
              ),
          ],
        );
      },
    );
  }
}

class _WinConfettiPainter extends CustomPainter {
  const _WinConfettiPainter({required this.progress});

  final double progress;

  static const _pieceCount = 42;
  static const _sparkCount = 14;

  static const _confettiColors = [
    _Ui.gold,
    _Ui.goldSoft,
    _Ui.ivory,
    Color(0xFFE84855),
    Color(0xFF4DA3FF),
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final fade = progress < 0.88
        ? 1.0
        : (1 - (progress - 0.88) / 0.12).clamp(0.0, 1.0);

    for (var i = 0; i < _pieceCount; i++) {
      final rng = math.Random(i * 29 + 11);
      final delay = rng.nextDouble() * 0.28;
      final local = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final x =
          rng.nextDouble() * size.width +
          math.sin(local * math.pi * 3 + i) * 14;
      final y = -8 + local * (size.height + 36);
      final rotation = local * math.pi * 3 + rng.nextDouble();
      final w = 3 + rng.nextDouble() * 4;
      final h = 5 + rng.nextDouble() * 6;
      final color = _confettiColors[i % _confettiColors.length].withValues(
        alpha: (0.55 + rng.nextDouble() * 0.4) * fade,
      );

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(1.2),
        ),
        Paint()..color = color,
      );
      canvas.restore();
    }

    final sparkCenter = Offset(size.width / 2, size.height * 0.38);
    final sparkT = ((progress - 0.12) / 0.55).clamp(0.0, 1.0);
    if (sparkT <= 0) return;

    for (var i = 0; i < _sparkCount; i++) {
      final angle = i / _sparkCount * math.pi * 2 - math.pi / 2;
      final dist = 24 + 52 * Curves.easeOut.transform(sparkT);
      final opacity = (1 - sparkT) * fade;
      final tip =
          sparkCenter +
          Offset(math.cos(angle) * dist, math.sin(angle) * dist * 0.75);
      canvas.drawLine(
        sparkCenter,
        tip,
        Paint()
          ..color = _Ui.goldSoft.withValues(alpha: 0.45 * opacity)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WinConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
