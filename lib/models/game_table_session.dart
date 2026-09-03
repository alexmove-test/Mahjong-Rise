import 'board.dart';
import 'game_snapshot.dart';
import 'levels.dart';
import 'tile.dart';

enum UndoKind { collect, match }

enum RewardedBoost { shuffle, magnet, hint, undo }

enum ShuffleFail { ended, noCharge, noFreeTiles }

class UndoEntry {
  const UndoEntry.collect({
    required this.tileId,
    required this.scoreBefore,
    required this.comboBefore,
  }) : kind = UndoKind.collect,
       matchedIds = const [];

  /// Матч после сбора [tileId]: undo возвращает пару в лоток, а [tileId] — на поле.
  const UndoEntry.match({
    required this.tileId,
    required this.matchedIds,
    required this.scoreBefore,
    required this.comboBefore,
  }) : kind = UndoKind.match;

  final UndoKind kind;
  final int? tileId;
  final List<int> matchedIds;
  final int scoreBefore;
  final int comboBefore;
}

class TrayResolveOutcome {
  const TrayResolveOutcome({
    required this.result,
    required this.matched,
    required this.noUsefulMove,
  });

  final MatchResult result;
  final List<Tile> matched;
  final bool noUsefulMove;
}

class ShuffleOutcome {
  const ShuffleOutcome({
    required this.applied,
    required this.useful,
    this.fail,
  });

  final bool applied;
  final bool useful;
  final ShuffleFail? fail;
}

/// Партия без Flutter: поле, счёт, бусты, undo и снепшот.
class GameTableSession {
  GameTableSession();

  static const winBonus = 500;

  late Board board;
  int score = 0;
  int combo = 0;
  int shufflesLeft = 0;
  int hintsLeft = 0;
  int undosLeft = 0;
  int magnetsLeft = 0;
  final List<UndoEntry> undoStack = [];

  int _startShuffles = 0;
  int _startHints = 0;
  int _startUndos = 0;
  int _startMagnets = 0;

  int get startHints => _startHints;

  bool get isWon => board.isWon;
  bool get isLost => board.isLost;
  bool get canUndoCharge => undosLeft > 0 && undoStack.isNotEmpty;
  bool get canUndoViaAd => undosLeft <= 0 && undoStack.isNotEmpty;

  Tile tileById(int id) => board.tiles.firstWhere((t) => t.id == id);

  static int pairPoints({required int comboAfter}) =>
      100 + (comboAfter - 1) * 25;

  void resetFromLevel(
    LevelDef level, {
    int bankedHints = 0,
    int bankedShuffles = 0,
    int? hintsLeft,
  }) {
    board = Board.fromLayout(
      level.layout,
      style: level.style,
      pairSize: level.pairSize,
      uniqueCap: level.uniqueCap,
      levelId: level.id,
      guestTypes: level.guestTileTypes,
    );
    score = 0;
    combo = 0;
    shufflesLeft = level.shuffles + bankedShuffles;
    this.hintsLeft = hintsLeft ?? (level.hints + bankedHints);
    undosLeft = level.undos;
    magnetsLeft = level.hints;
    undoStack.clear();
    _rememberBoostBaseline();
  }

  void restore(GameSnapshot snap) {
    board = snap.toBoard();
    score = snap.score;
    combo = snap.combo;
    shufflesLeft = snap.shuffles;
    hintsLeft = snap.hints;
    undosLeft = snap.undos;
    magnetsLeft = snap.magnets;
    undoStack.clear();
    _rememberBoostBaseline();
  }

  void attachBoard(Board next) {
    board = next;
    undoStack.clear();
    _rememberBoostBaseline();
  }

  void _rememberBoostBaseline() {
    _startShuffles = shufflesLeft;
    _startHints = hintsLeft;
    _startUndos = undosLeft;
    _startMagnets = magnetsLeft;
  }

  bool get hasProgressToSave {
    if (board.isWon || board.isLost) return false;
    if (score != 0 || combo != 0) return true;
    if (board.trayLiveCount > 0) return true;
    if (board.tiles.any((tile) => !tile.isOnBoard)) return true;
    if (shufflesLeft != _startShuffles) return true;
    if (hintsLeft != _startHints) return true;
    if (undosLeft != _startUndos) return true;
    if (magnetsLeft != _startMagnets) return true;
    return false;
  }

  GameSnapshot snapshotFor(int levelId) {
    return GameSnapshot.fromBoard(
      levelId: levelId,
      board: board,
      score: score,
      combo: combo,
      shuffles: shufflesLeft,
      hints: hintsLeft,
      undos: undosLeft,
      magnets: magnetsLeft,
    );
  }

  MatchResult pickTile(Tile tile, {bool force = false}) {
    return board.pick(tile, force: force);
  }

  TrayResolveOutcome resolveCollect({
    required int tileId,
    required int scoreBefore,
    required int comboBefore,
  }) {
    final result = board.resolveTray();
    final matched = List<Tile>.from(board.lastMatched);

    switch (result) {
      case MatchResult.collected:
        undoStack.add(
          UndoEntry.collect(
            tileId: tileId,
            scoreBefore: scoreBefore,
            comboBefore: comboBefore,
          ),
        );
      case MatchResult.matched:
        _recordMatch(
          tileId: tileId,
          matched: matched,
          scoreBefore: scoreBefore,
          comboBefore: comboBefore,
        );
      case MatchResult.win:
        if (matched.isNotEmpty) {
          _recordMatch(
            tileId: tileId,
            matched: matched,
            scoreBefore: scoreBefore,
            comboBefore: comboBefore,
            winBonus: true,
          );
        } else {
          score += winBonus;
        }
      case MatchResult.lose:
        undoStack.add(
          UndoEntry.collect(
            tileId: tileId,
            scoreBefore: scoreBefore,
            comboBefore: comboBefore,
          ),
        );
        combo = 0;
      case MatchResult.blocked:
      case MatchResult.trayFull:
        break;
    }

    final checkMoves =
        result == MatchResult.collected || result == MatchResult.matched;
    return TrayResolveOutcome(
      result: result,
      matched: matched,
      noUsefulMove: checkMoves && !board.hasUsefulMove(),
    );
  }

  void _recordMatch({
    required int tileId,
    required List<Tile> matched,
    required int scoreBefore,
    required int comboBefore,
    bool winBonus = false,
  }) {
    undoStack.add(
      UndoEntry.match(
        tileId: tileId,
        matchedIds: matched.map((t) => t.id).toList(),
        scoreBefore: scoreBefore,
        comboBefore: comboBefore,
      ),
    );
    final pairs = matched.length ~/ 2;
    combo += pairs;
    score += pairs * pairPoints(comboAfter: combo);
    if (winBonus) score += GameTableSession.winBonus;
  }

  ShuffleOutcome shuffle() {
    if (board.isWon || board.isLost) {
      return const ShuffleOutcome(
        applied: false,
        useful: false,
        fail: ShuffleFail.ended,
      );
    }
    if (shufflesLeft <= 0) {
      return const ShuffleOutcome(
        applied: false,
        useful: false,
        fail: ShuffleFail.noCharge,
      );
    }
    if (board.freeTiles().isEmpty) {
      return const ShuffleOutcome(
        applied: false,
        useful: false,
        fail: ShuffleFail.noFreeTiles,
      );
    }
    final useful = board.shuffleRemaining();
    shufflesLeft -= 1;
    combo = 0;
    return ShuffleOutcome(applied: true, useful: useful);
  }

  ({Tile boardTile, Tile match})? consumeHint() {
    if (board.isWon || board.isLost || hintsLeft <= 0) return null;
    final hint = board.findHint();
    if (hint == null) return null;
    hintsLeft -= 1;
    return hint;
  }

  bool consumeMagnetCharge() {
    if (board.isWon || board.isLost || magnetsLeft <= 0) return false;
    magnetsLeft -= 1;
    return true;
  }

  void grantBoost(RewardedBoost boost, {int count = 1}) {
    final n = count < 1 ? 1 : count;
    switch (boost) {
      case RewardedBoost.shuffle:
        shufflesLeft += n;
      case RewardedBoost.magnet:
        magnetsLeft += n;
      case RewardedBoost.hint:
        hintsLeft += n;
      case RewardedBoost.undo:
        undosLeft += n;
    }
  }

  UndoEntry? takeUndo({required bool fromLose}) {
    if (board.isWon) return null;
    if (board.isLost && !fromLose) return null;
    if (undoStack.isEmpty) return null;
    if (!fromLose && undosLeft <= 0) return null;
    return undoStack.removeLast();
  }

  void prepareMatchUndo(UndoEntry entry) {
    board.isLost = false;
    final matched = entry.matchedIds.map(tileById).toList();
    for (var i = 0; i + 1 < matched.length; i += 2) {
      board.restoreMatchedToTray(matched[i], matched[i + 1]);
    }
  }

  void applyScoreUndo(UndoEntry entry, {required bool fromLose}) {
    score = entry.scoreBefore;
    combo = entry.comboBefore;
    if (!fromLose) undosLeft -= 1;
  }

  void returnUndoTile(UndoEntry entry, {required bool fromLose}) {
    final tile = tileById(entry.tileId!);
    if (entry.kind == UndoKind.collect && fromLose) {
      board.reviveFromTray(tile);
      return;
    }
    board.returnFromTray(tile);
  }

  void applyInstantUndo(UndoEntry entry, {required bool fromLose}) {
    if (entry.kind == UndoKind.match) {
      prepareMatchUndo(entry);
    }
    returnUndoTile(entry, fromLose: fromLose);
    applyScoreUndo(entry, fromLose: fromLose);
  }
}
