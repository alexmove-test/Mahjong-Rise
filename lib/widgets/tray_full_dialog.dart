import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Проигрыш: лоток полон. Главное действие — продолжить за рекламу.
class TrayFullDialog extends StatelessWidget {
  const TrayFullDialog({
    super.key,
    required this.levelTitle,
    required this.score,
    required this.canContinue,
    required this.onContinue,
    required this.onRetry,
    required this.onMap,
  });

  final String levelTitle;
  final int score;
  final bool canContinue;
  final VoidCallback onContinue;
  final VoidCallback onRetry;
  final VoidCallback onMap;

  static const _gold = Color(0xFFD4AF37);
  static const _goldSoft = Color(0xFFE8C96A);
  static const _ivory = Color(0xFFF8F1DE);
  static const _woodTop = Color(0xFF6B3E24);
  static const _woodDeep = Color(0xFF3A2012);

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return AlertDialog(
      backgroundColor: _woodDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: _gold.withValues(alpha: 0.7), width: 1.6),
      ),
      title: Text(
        l10n.trayFull,
        textAlign: TextAlign.center,
        style: TextStyle(color: _goldSoft, fontWeight: FontWeight.w800),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            levelTitle,
            style: TextStyle(
              color: _ivory.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.trayFullHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ivory.withValues(alpha: 0.78),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.score(score),
            style: const TextStyle(
              color: _ivory,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Column(
          children: [
            if (canContinue)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _woodTop,
                    foregroundColor: _goldSoft,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: onContinue,
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  label: Text(
                    l10n.continueGame,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            if (canContinue) const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(
                l10n.retry,
                style: TextStyle(
                  color: canContinue ? _ivory : _goldSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton(
              onPressed: onMap,
              child: Text(
                l10n.courtyard,
                style: TextStyle(
                  color: _ivory.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
