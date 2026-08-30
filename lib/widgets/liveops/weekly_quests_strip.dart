import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/weekly_quests.dart';
import '../streak_lanterns.dart';

class WeeklyQuestsStrip extends StatelessWidget {
  const WeeklyQuestsStrip({
    super.key,
    required this.quests,
    required this.onClaim,
  });

  final List<QuestProgress> quests;
  final ValueChanged<QuestProgress> onClaim;

  static const _gold = Color(0xFFD4AF37);
  static const _goldSoft = Color(0xFFE8C96A);
  static const _ivory = Color(0xFFF8F1DE);
  static const _woodTop = Color(0xFF6B3E24);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: quests.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return _QuestCard(quest: quests[index], onClaim: onClaim);
        },
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.quest, required this.onClaim});

  final QuestProgress quest;
  final ValueChanged<QuestProgress> onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isStreak = quest.def.kind == QuestKind.streakHold;
    final glow = isStreak && (quest.canClaim || quest.claimed);
    return SizedBox(
      width: 168,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [WeeklyQuestsStrip._woodTop, Color(0xFF3A2012)],
          ),
          border: Border.all(
            color: WeeklyQuestsStrip._gold.withValues(
              alpha: glow ? 0.95 : 0.7,
            ),
            width: glow ? 1.5 : 1.2,
          ),
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: WeeklyQuestsStrip._gold.withValues(alpha: 0.28),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.questTitle(quest.def.id),
                maxLines: isStreak ? 1 : 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: WeeklyQuestsStrip._ivory,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  if (isStreak)
                    StreakLanterns(
                      litCount: quest.current.clamp(0, quest.target),
                      waitingNext: !quest.complete,
                      celebrate: quest.canClaim || quest.claimed,
                      size: 15,
                      gap: 4,
                      semanticLabel: '${quest.current}/${quest.target}',
                    )
                  else
                    Text(
                      '${quest.current}/${quest.target}',
                      style: const TextStyle(
                        color: WeeklyQuestsStrip._goldSoft,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  const Spacer(),
                  if (quest.claimed)
                    Text(
                      l10n.claimed,
                      style: TextStyle(
                        color: WeeklyQuestsStrip._ivory.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    )
                  else if (quest.canClaim)
                    GestureDetector(
                      onTap: () => onClaim(quest),
                      child: Text(
                        l10n.claim,
                        style: const TextStyle(
                          color: WeeklyQuestsStrip._gold,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
