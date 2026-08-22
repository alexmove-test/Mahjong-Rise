import 'board.dart';

/// Три подсказки на столе первого уровня — без диалогов.
enum TableCoachStep { tapFree, matchPair, trayLimit }

class FirstTableCoach {
  FirstTableCoach({required this.active});

  bool active;
  bool finished = false;
  TableCoachStep step = TableCoachStep.tapFree;

  static const tapFreeText = 'Take only a free top tile';
  static const matchPairText = 'A pair in the tray clears';
  static const trayLimitText =
      'The tray holds 4 — fill it with no pair and you lose';

  String get message => switch (step) {
    TableCoachStep.tapFree => tapFreeText,
    TableCoachStep.matchPair => matchPairText,
    TableCoachStep.trayLimit => trayLimitText,
  };

  /// Шаг про лоток — подсказка у ниши, остальные — над полем.
  bool get nearTray => step == TableCoachStep.trayLimit;

  Set<int> focusIds(Board board) {
    if (!active) return {};
    switch (step) {
      case TableCoachStep.tapFree:
        final free = board.freeTiles();
        if (free.isEmpty) return {};
        free.sort((a, b) => b.layer.compareTo(a.layer));
        return {free.first.id};
      case TableCoachStep.matchPair:
        final hint = board.findHint();
        if (hint == null) return {};
        return {hint.boardTile.id, hint.match.id};
      case TableCoachStep.trayLimit:
        return {};
    }
  }

  void onCollected() {
    if (!active) return;
    if (step == TableCoachStep.tapFree) {
      step = TableCoachStep.matchPair;
    } else if (step == TableCoachStep.trayLimit) {
      complete();
    }
  }

  void onMatched() {
    if (!active) return;
    if (step == TableCoachStep.tapFree || step == TableCoachStep.matchPair) {
      step = TableCoachStep.trayLimit;
    } else if (step == TableCoachStep.trayLimit) {
      complete();
    }
  }

  void onWin() => complete();

  void complete() {
    if (!active && finished) return;
    active = false;
    finished = true;
  }

  void resetIfActive() {
    if (!active) return;
    step = TableCoachStep.tapFree;
  }
}
