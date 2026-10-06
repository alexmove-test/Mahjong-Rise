import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'points_coin.dart';

const pointsAwardBadgeKey = ValueKey('points-award-badge');

/// «+65 баллов» на празднике победы.
class PointsAwardBadge extends StatelessWidget {
  const PointsAwardBadge({
    super.key,
    required this.points,
    this.shine = 0,
    this.glow = 0,
  });

  final int points;

  /// Пробег блика по монете, синхронный с оверлеем победы.
  final double shine;

  /// Пульс золотого ореола.
  final double glow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      key: pointsAwardBadgeKey,
      liveRegion: true,
      label: l10n.pointsReward(points),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: const LinearGradient(
            colors: [Color(0xE66B3E24), Color(0xE62A1708)],
          ),
          border: Border.all(
            color: const Color(0xFFE8C96A).withValues(alpha: 0.85),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD86B).withValues(alpha: 0.28 * glow),
              blurRadius: 18,
              spreadRadius: 1,
            ),
            const BoxShadow(color: Color(0x73000000), blurRadius: 10),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              PointsCoin(size: 22, shine: shine, glow: glow),
              const SizedBox(width: 7),
              Text(
                l10n.pointsReward(points),
                style: const TextStyle(
                  color: Color(0xFFFFE9A8),
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  height: 1,
                  shadows: [Shadow(color: Color(0xCC000000), blurRadius: 6)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
