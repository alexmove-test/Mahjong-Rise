import '../../models/levels.dart';
import '../../models/plot_kind.dart';
import '../../services/progress_store.dart';

/// Монотонный рост участка: 12 эпох × 8 шагов = 96 стадий на каждый PlotKind.
///
/// По умолчанию уровни качают участки по очереди. Стадия — число пройденных
/// уровней этого вида, с потолком [maxStage].
abstract final class CourtyardLotBuild {
  static const maxStage = 96;
  static const eraLength = 8;
  static const eraCount = 12;

  static double stageOf({required int maxUnlocked, required PlotKind kind}) {
    if (!Levels.plotReached(kind, maxUnlocked)) return 0;
    return Levels.completedStages(
      kind,
      maxUnlocked,
    ).clamp(0, maxStage).toDouble();
  }

  static double stageFromProgress(ProgressStore store, PlotKind kind) {
    if (!store.plotReached(kind)) return 0;
    return store.plotStage(kind).clamp(0, maxStage).toDouble();
  }

  /// 0–11. Стадия 0 (пустое поле) читается как начало первой эпохи.
  static int eraIndex(num stage) {
    if (stage <= 0) return 0;
    return ((stage - 1).floor() ~/ eraLength).clamp(0, eraCount - 1);
  }

  /// 0 на пустом поле, иначе 1–8 внутри эпохи.
  static int detailInEra(num stage) {
    if (stage <= 0) return 0;
    return ((stage - 1).floor() % eraLength) + 1;
  }

  /// Прозрачность слоя с номером [layer] (1…[maxStage]) при дробной стадии.
  /// Целая стадия N показывает слои 1…N полностью; дробная часть
  /// проявляет следующий слой — так работает победный lerp.
  static double layerOpacity(num stage, int layer) {
    if (layer <= 0) return 0;
    if (stage >= layer) return 1;
    if (stage <= layer - 1) return 0;
    return (stage.toDouble() - (layer - 1)).clamp(0.0, 1.0).toDouble();
  }

  /// 0 = пустой участок, 1 = домик с карты полностью виден.
  /// Первый круг из 24 уровней проявляет участок; дальше он остаётся собранным.
  static double revealOf({required double stage, required bool unlocked}) {
    if (!unlocked) return 0;
    return (stage / Levels.storyLength).clamp(0.0, 1.0);
  }

}

/// 24 кадра эволюции дома: следующий облик после каждого пройденного уровня.
abstract final class PlotStages {
  static const frameCount = 24;
  static const stagesPerFrame = 1;
  static const assetDir = 'assets/courtyard/builds';

  static String assetOf(PlotKind kind, int frame) {
    final n = frame.toString().padLeft(2, '0');
    return '$assetDir/${kind.buildFolder}/$n.png';
  }

  static List<String> assetsFor(PlotKind kind) {
    return [for (var i = 1; i <= frameCount; i++) assetOf(kind, i)];
  }

  static List<String> get allAssets => [
    for (final kind in PlotKind.order) ...assetsFor(kind),
  ];

  /// Сколько кадров есть на диске. У пруда их девять, не двадцать четыре.
  static int framesOf(PlotKind kind) => switch (kind) {
    PlotKind.house => frameCount,
    PlotKind.pond => 9,
    PlotKind.pets => 12,
    PlotKind.guest => frameCount,
  };

  /// 0 = пустой участок, иначе номер кадра в пределах [framesOf].
  static int currentFrame(double stage, {PlotKind kind = PlotKind.house}) {
    final cap = framesOf(kind);
    if (cap <= 0 || stage < 1) return 0;
    return (((stage - 1) / stagesPerFrame).floor() + 1).clamp(1, cap);
  }

  static int nextFrame(double stage, {PlotKind kind = PlotKind.house}) {
    if (stage <= 0) return 0;
    return currentFrame(stage.ceil().toDouble(), kind: kind);
  }

  static double nextOpacity(double stage, {PlotKind kind = PlotKind.house}) {
    if (stage <= 0) return 0;
    if (stage >= CourtyardLotBuild.maxStage) return 0;
    final current = currentFrame(stage, kind: kind);
    final next = nextFrame(stage, kind: kind);
    if (next <= current) return 0;
    return (stage - stage.floor()).clamp(0.0, 1.0);
  }

  static bool isMaxFrame(double stage, {PlotKind kind = PlotKind.house}) =>
      currentFrame(stage, kind: kind) >= framesOf(kind);

  /// Стадия, на которой сменится картинка. `null`, если кадр уже последний.
  static int? nextFrameStage(double stage, {PlotKind kind = PlotKind.house}) {
    if (isMaxFrame(stage, kind: kind)) return null;
    if (stage < 1) return 1;
    return currentFrame(stage, kind: kind) * stagesPerFrame + 1;
  }

  /// Сколько побед на этом участке до следующей картинки.
  static int remainingToNextFrame(
    double stage, {
    PlotKind kind = PlotKind.house,
  }) {
    return remainingExact(stage, kind: kind).ceil().clamp(0, stagesPerFrame);
  }

  /// Дробный остаток до следующей картинки — для lerp после победы.
  static double remainingExact(double stage, {PlotKind kind = PlotKind.house}) {
    final nextAt = nextFrameStage(stage, kind: kind);
    if (nextAt == null) return 0;
    return (nextAt - stage).clamp(0.0, stagesPerFrame.toDouble());
  }

  /// 0…1: сколько уже сделано из шагов до следующей картинки.
  static double frameProgress(double stage, {PlotKind kind = PlotKind.house}) {
    if (isMaxFrame(stage, kind: kind)) return 1;
    if (stage < 1) return stage.clamp(0.0, 1.0);
    return (1 - remainingExact(stage, kind: kind) / stagesPerFrame).clamp(
      0.0,
      1.0,
    );
  }
}
