import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/plot_kind.dart';
import 'courtyard_lot_build.dart';

/// Постройка участка с листа стадий: пустой лот, затем кадры 1…24.
class PlotStageView extends StatelessWidget {
  const PlotStageView({super.key, required this.kind, required this.stage});

  final PlotKind kind;
  final double stage;

  @override
  Widget build(BuildContext context) {
    final current = PlotStages.currentFrame(stage);
    final next = PlotStages.nextFrame(stage);
    final fade = PlotStages.nextOpacity(stage);
    if (current <= 0 && next <= 0) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (current > 0) _frame(current),
        if (next > 0 && next != current)
          Opacity(opacity: fade, child: _frame(next)),
      ],
    );
  }

  Widget _frame(int frame) {
    return Image(
      image: AssetImage(PlotStages.assetOf(kind, frame)),
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
  }
}

/// Шкала до следующего состояния участка: деления заполняются к новой картинке.
class PlotProgressMeter extends StatelessWidget {
  const PlotProgressMeter({super.key, required this.kind, required this.stage});

  final PlotKind kind;
  final double stage;

  static const _gold = Color(0xFFE8C96A);
  static const _wood = Color(0xCC3A2012);
  static const _pipEmpty = Color(0x553A2012);

  @override
  Widget build(BuildContext context) {
    final progress = PlotStages.frameProgress(stage);
    final remaining = PlotStages.remainingToNextFrame(stage);
    final maxed = PlotStages.isMaxFrame(stage);
    return Semantics(
      label: L10n.of(context).plotLookProgress(kind, remaining),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _wood,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: _gold.withValues(alpha: 0.78), width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x88000000),
              blurRadius: 5,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          child: Row(
            children: [
              for (var i = 0; i < PlotStages.stagesPerFrame; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: _pip(
                      fill: maxed
                          ? 1
                          : ((progress * PlotStages.stagesPerFrame) - i)
                              .clamp(0.0, 1.0),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pip({required double fill}) {
    return SizedBox(
      height: 8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _pipEmpty,
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fill <= 0 ? 0 : fill,
              heightFactor: 1,
              child: const ColoredBox(color: _gold),
            ),
          ),
        ),
      ),
    );
  }
}
