import '../../models/leaderboard_entry.dart';
import '../../models/levels.dart';
import '../../models/plot_kind.dart';
import '../../services/progress_store.dart';
import 'courtyard_lot_build.dart';
import 'courtyard_progress.dart';
import 'courtyard_world_layout.dart';

/// Снимок всего двора: четыре лота сразу, каждый — свой PlotKind.
class CourtyardEstate {
  const CourtyardEstate({
    required this.lots,
    this.festival = 0,
    this.streakLife = 0,
  });

  final Map<PlotKind, CourtyardLotView> lots;
  final double festival;
  final double streakLife;

  CourtyardLotView lot(PlotKind kind) => lots[kind]!;

  /// Тестовый/оверлейный двор с акцентом на один участок.
  factory CourtyardEstate.fromFocus(CourtyardSnapshot snapshot) {
    return CourtyardEstate(
      lots: {
        for (final kind in PlotKind.order)
          kind: CourtyardLotView(
            kind: kind,
            cycle: kind == snapshot.plotKind ? 0 : -1,
            unlocked: kind == snapshot.plotKind,
            snapshot: kind == snapshot.plotKind
                ? snapshot
                : CourtyardSnapshot.fromStep(
                    step: 0,
                    totalStars: 0,
                    plotKind: kind,
                  ),
            stage: kind == snapshot.plotKind ? snapshot.step : 0,
          ),
      },
      festival: snapshot.festival,
      streakLife: snapshot.streakLife,
    );
  }

  static CourtyardEstate fromStore(
    ProgressStore store, {
    int streak = 0,
    bool festival = false,
  }) {
    final lots = <PlotKind, CourtyardLotView>{
      for (final kind in PlotKind.order)
        kind: CourtyardLotView.fromStore(
          store,
          kind,
          streak: streak,
          festival: festival,
        ),
    };
    final sample = lots[PlotKind.house]!.snapshot;
    return CourtyardEstate(
      lots: lots,
      festival: festival ? 1 : 0,
      streakLife: sample.streakLife,
    );
  }

  /// Двор по кампании: хватает `levelsUnlocked` из рейтинга.
  static CourtyardEstate fromUnlocked(int maxUnlocked) {
    return CourtyardEstate(
      lots: {
        for (final kind in PlotKind.order)
          kind: CourtyardLotView.fromUnlocked(maxUnlocked, kind),
      },
    );
  }

  static CourtyardEstate lerp(CourtyardEstate a, CourtyardEstate b, double t) {
    final u = t.clamp(0.0, 1.0);
    return CourtyardEstate(
      lots: {
        for (final kind in PlotKind.order)
          kind: CourtyardLotView.lerp(a.lot(kind), b.lot(kind), u),
      },
      festival: a.festival + (b.festival - a.festival) * u,
      streakLife: a.streakLife + (b.streakLife - a.streakLife) * u,
    );
  }

  /// Есть ли уже уровень этого участка среди открытых.
  static int? latestUnlockedCycle(ProgressStore store, PlotKind kind) =>
      latestCycle(store.maxUnlocked, kind);

  static int? latestCycle(int maxUnlocked, PlotKind kind) {
    return Levels.plotReached(kind, maxUnlocked) ? 0 : null;
  }
}

/// Один лот на карте: прогресс последнего круга этого вида.
class CourtyardLotView {
  const CourtyardLotView({
    required this.kind,
    required this.cycle,
    required this.unlocked,
    required this.snapshot,
    required this.stage,
  });

  final PlotKind kind;
  final int cycle;
  final bool unlocked;
  final CourtyardSnapshot snapshot;

  /// 0–96, копится между кругами этого PlotKind. Дробная часть — появление
  /// следующего слоя при победном lerp.
  final double stage;

  int get loop => stage.floor() ~/ Levels.storyLength;

  int get era => CourtyardLotBuild.eraIndex(stage);

  static CourtyardLotView fromStore(
    ProgressStore store,
    PlotKind kind, {
    int streak = 0,
    bool festival = false,
  }) {
    final unlocked = store.plotReached(kind);
    final stage = CourtyardLotBuild.stageFromProgress(store, kind);
    final snapshot = CourtyardSnapshot.fromStep(
      step: stage.clamp(0, CourtyardSnapshot.maxStep),
      totalStars: 0,
      streak: streak,
      festival: festival,
      plotKind: kind,
    );
    return CourtyardLotView(
      kind: kind,
      cycle: unlocked ? 0 : -1,
      unlocked: unlocked,
      snapshot: snapshot,
      stage: stage,
    );
  }

  static CourtyardLotView fromUnlocked(int maxUnlocked, PlotKind kind) {
    final unlocked = Levels.plotReached(kind, maxUnlocked);
    final stage = CourtyardLotBuild.stageOf(
      maxUnlocked: maxUnlocked,
      kind: kind,
    );
    final snapshot = CourtyardSnapshot.fromStep(
      step: stage.clamp(0, CourtyardSnapshot.maxStep),
      totalStars: 0,
      plotKind: kind,
    );
    return CourtyardLotView(
      kind: kind,
      cycle: unlocked ? 0 : -1,
      unlocked: unlocked,
      snapshot: snapshot,
      stage: stage,
    );
  }

  static CourtyardLotView lerp(
    CourtyardLotView a,
    CourtyardLotView b,
    double t,
  ) {
    final u = t.clamp(0.0, 1.0);
    return CourtyardLotView(
      kind: u < 0.5 ? a.kind : b.kind,
      cycle: u < 0.5 ? a.cycle : b.cycle,
      unlocked: u < 0.5 ? a.unlocked : b.unlocked,
      snapshot: CourtyardSnapshot.lerp(a.snapshot, b.snapshot, u),
      stage: a.stage + (b.stage - a.stage) * u,
    );
  }
}

class NeighborYard {
  const NeighborYard({
    required this.slot,
    required this.estate,
    this.name,
    this.rating,
  });

  final int slot;
  final String? name;
  final int? rating;
  final CourtyardEstate estate;

  bool get named => name != null && name!.trim().isNotEmpty;

  /// Холмы: игроки рядом в рейтинге, двор из их `levelsUnlocked`.
  static List<NeighborYard> placed({
    required List<LeaderboardEntry> others,
    required bool online,
  }) {
    if (!online || others.isEmpty) return const [];
    final slots = CourtyardWorldLayout.neighborCount;
    final n = others.length < slots ? others.length : slots;
    return [
      for (var i = 0; i < n; i++)
        NeighborYard(
          slot: i,
          name: others[i].name,
          rating: others[i].rating,
          estate: CourtyardEstate.fromUnlocked(others[i].levelsUnlocked),
        ),
    ];
  }
}
