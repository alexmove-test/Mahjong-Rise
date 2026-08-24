import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/week_event.dart';

class WeekEventBanner extends StatelessWidget {
  const WeekEventBanner({super.key, required this.event, required this.onTap});

  final WeekEvent event;
  final VoidCallback onTap;

  static const _gold = Color(0xFFD4AF37);
  static const _goldSoft = Color(0xFFE8C96A);
  static const _ivory = Color(0xFFF8F1DE);

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xCC3A2012),
            border: Border.all(color: _gold.withValues(alpha: 0.7), width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: _goldSoft, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weekEventTitle(event.id),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ivory,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      l10n.extraBoostThisWeek,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _ivory.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
