import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/points_controller.dart';

const _gold = Color(0xFFD4AF37);
const _goldSoft = Color(0xFFE8C96A);
const _ivory = Color(0xFFF8F1DE);

/// Счётчик собранных растений. Открывает тот же склад, что и здание на карте.
class PlantChipLive extends StatelessWidget {
  const PlantChipLive({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final controller = PointsScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) =>
          PlantChip(count: controller.plantCount, onTap: onTap),
    );
  }
}

class PlantChip extends StatelessWidget {
  const PlantChip({super.key, required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: onTap != null,
      label: l10n.plantsButton(count),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('plant-counter'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xCC6B3E24), Color(0xCC3A2012)],
              ),
              border: Border.all(
                color: _gold.withValues(alpha: 0.7),
                width: 1.3,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.yard_rounded, color: _goldSoft, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: _ivory,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
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
