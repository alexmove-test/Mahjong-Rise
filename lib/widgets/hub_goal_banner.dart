import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/hub_goal.dart';
import '../models/plot_kind.dart';

const hubGoalBannerKey = ValueKey('hub-goal-banner');

const _gold = Color(0xFFD4AF37);
const _goldSoft = Color(0xFFE8C96A);
const _ivory = Color(0xFFF8F1DE);
const _wood = Color(0xE63A2012);

/// Одна ближайшая цель мета-игры над кнопкой «Продолжить».
class HubGoalBanner extends StatelessWidget {
  const HubGoalBanner({super.key, required this.goal, this.onTap});

  final HubGoal goal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context).hubGoalText(goal);
    final child = DecoratedBox(
      decoration: BoxDecoration(
        color: _wood,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.78), width: 1.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x88000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        child: Row(
          children: [
            Icon(_icon, color: _goldSoft, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _ivory,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Semantics(
      key: hubGoalBannerKey,
      button: onTap != null,
      liveRegion: true,
      label: text,
      child: onTap == null
          ? child
          : GestureDetector(onTap: onTap, child: child),
    );
  }

  IconData get _icon {
    return switch (goal.kind) {
      HubGoalKind.plotUnlock => (goal.plot ?? PlotKind.house).emblem,
      HubGoalKind.plotLook => (goal.plot ?? PlotKind.house).emblem,
      HubGoalKind.dailyReward => Icons.wb_sunny_rounded,
      HubGoalKind.questRemain || HubGoalKind.questClaim => Icons.flag_rounded,
      HubGoalKind.petUnlock => Icons.pets_rounded,
    };
  }
}
