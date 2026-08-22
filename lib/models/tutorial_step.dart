/// Шаги короткого обучения на уровнях 1–3.
enum TutorialStep { collect, match, layers, boosts }

/// Куда якорить пузырь и подсветку.
enum TutorialAnchor { tileHint, tray, actions }

/// Снимок прогресса обучения (без I/O).
class TutorialSnapshot {
  const TutorialSnapshot({
    required this.collectDone,
    required this.matchDone,
    required this.layersDone,
    required this.boostsDone,
    required this.skipped,
    required this.forceReplay,
  });

  const TutorialSnapshot.empty()
    : collectDone = false,
      matchDone = false,
      layersDone = false,
      boostsDone = false,
      skipped = false,
      forceReplay = false;

  final bool collectDone;
  final bool matchDone;
  final bool layersDone;
  final bool boostsDone;
  final bool skipped;
  final bool forceReplay;

  bool get anyStepDone => collectDone || matchDone || layersDone || boostsDone;

  bool isDone(TutorialStep step) {
    return switch (step) {
      TutorialStep.collect => collectDone,
      TutorialStep.match => matchDone,
      TutorialStep.layers => layersDone,
      TutorialStep.boosts => boostsDone,
    };
  }

  TutorialSnapshot copyWith({
    bool? collectDone,
    bool? matchDone,
    bool? layersDone,
    bool? boostsDone,
    bool? skipped,
    bool? forceReplay,
  }) {
    return TutorialSnapshot(
      collectDone: collectDone ?? this.collectDone,
      matchDone: matchDone ?? this.matchDone,
      layersDone: layersDone ?? this.layersDone,
      boostsDone: boostsDone ?? this.boostsDone,
      skipped: skipped ?? this.skipped,
      forceReplay: forceReplay ?? this.forceReplay,
    );
  }
}

/// Один показ: текст + куда смотреть.
class TutorialLesson {
  const TutorialLesson({
    required this.step,
    required this.anchor,
    required this.text,
  });

  final TutorialStep step;
  final TutorialAnchor anchor;
  final String text;

  static const collect = TutorialLesson(
    step: TutorialStep.collect,
    anchor: TutorialAnchor.tileHint,
    text: 'Нажмите свободную плитку — она попадёт в лоток',
  );

  static const match = TutorialLesson(
    step: TutorialStep.match,
    anchor: TutorialAnchor.tray,
    text: 'Соберите две одинаковые — пара исчезнет. В лотке всего 4 места.',
  );

  static const layers = TutorialLesson(
    step: TutorialStep.layers,
    anchor: TutorialAnchor.tileHint,
    text: 'Нижнюю нельзя взять, пока она закрыта сверху.',
  );

  static const boosts = TutorialLesson(
    step: TutorialStep.boosts,
    anchor: TutorialAnchor.actions,
    text: 'Подсказка подсветит ход, магнит соберёт пару, отмена вернёт ход.',
  );

  static TutorialLesson of(TutorialStep step) {
    return switch (step) {
      TutorialStep.collect => collect,
      TutorialStep.match => match,
      TutorialStep.layers => layers,
      TutorialStep.boosts => boosts,
    };
  }

  /// Слои и бусты можно закрыть тапом по пузырю; collect/match — только игрой.
  bool get acknowledgeByTap =>
      step == TutorialStep.layers || step == TutorialStep.boosts;
}

/// Какой шаг показать прямо сейчас.
abstract final class TutorialGuide {
  TutorialGuide._();

  /// Автопоказ только на первых трёх уровнях.
  static const autoLevelMax = 3;

  static TutorialLesson? current({
    required int levelId,
    required TutorialSnapshot progress,
    required bool level1Completed,
    required bool trayEmpty,
    required bool blockedTap,
  }) {
    if (progress.skipped) return null;
    if (levelId < 1) return null;
    if (!progress.forceReplay && levelId > autoLevelMax) return null;

    final veteranSilent =
        !progress.forceReplay && level1Completed && !progress.anyStepDone;
    if (veteranSilent) return null;

    if (blockedTap && !progress.layersDone) {
      return TutorialLesson.layers;
    }

    if (!progress.collectDone && trayEmpty) {
      return TutorialLesson.collect;
    }
    if (!progress.matchDone) {
      return TutorialLesson.match;
    }
    if (levelId >= 2 && !progress.boostsDone) {
      return TutorialLesson.boosts;
    }
    return null;
  }
}
