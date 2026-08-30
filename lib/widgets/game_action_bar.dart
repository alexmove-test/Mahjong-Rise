import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'game_hud.dart';
import 'premium_ui.dart';

/// Нижний ряд бустов: четыре медных круга с белой иконкой и красным баджем.
class GameActionBar extends StatelessWidget {
  const GameActionBar({
    super.key,
    required this.shufflesLeft,
    required this.magnetsLeft,
    required this.hintsLeft,
    required this.undosLeft,
    required this.enabled,
    required this.canUndo,
    required this.canUndoViaAd,
    required this.adsAvailable,
    required this.onShuffle,
    required this.onMagnet,
    required this.onHint,
    required this.onUndo,
  });

  final int shufflesLeft;
  final int magnetsLeft;
  final int hintsLeft;
  final int undosLeft;
  final bool enabled;
  final bool canUndo;
  final bool canUndoViaAd;
  final bool adsAvailable;
  final VoidCallback onShuffle;
  final VoidCallback onMagnet;
  final VoidCallback onHint;
  final VoidCallback onUndo;

  static const buttonSize = 56.0;
  static const gap = 22.0;
  static const badgeColor = Color(0xFFD32F2F);

  static String badgeLabel(int count) => count > 0 ? '$count' : '+';

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GameActionButton(
            tooltip: l10n.boostTooltip(
              l10n.shuffle,
              shufflesLeft,
              adsAvailable: adsAvailable,
            ),
            icon: Icons.shuffle_rounded,
            badge: badgeLabel(shufflesLeft),
            enabled: enabled && (shufflesLeft > 0 || adsAvailable),
            onPressed: onShuffle,
          ),
          const SizedBox(width: gap),
          GameActionButton(
            tooltip: l10n.boostTooltip(
              l10n.magnet,
              magnetsLeft,
              adsAvailable: adsAvailable,
            ),
            child: const MagnetGlyph(size: 28, color: Colors.white),
            badge: badgeLabel(magnetsLeft),
            enabled: enabled && (magnetsLeft > 0 || adsAvailable),
            onPressed: onMagnet,
          ),
          const SizedBox(width: gap),
          GameActionButton(
            tooltip: l10n.boostTooltip(
              l10n.hint,
              hintsLeft,
              adsAvailable: adsAvailable,
            ),
            icon: Icons.lightbulb_outline_rounded,
            badge: badgeLabel(hintsLeft),
            enabled: enabled && (hintsLeft > 0 || adsAvailable),
            onPressed: onHint,
          ),
          const SizedBox(width: gap),
          GameActionButton(
            tooltip: canUndo
                ? l10n.undo
                : (canUndoViaAd ? l10n.watchAd(l10n.undo) : l10n.noneLeft),
            icon: Icons.undo_rounded,
            badge: badgeLabel(undosLeft),
            enabled: enabled && (canUndo || canUndoViaAd),
            onPressed: onUndo,
          ),
        ],
      ),
    );
  }
}

class GameActionButton extends StatefulWidget {
  const GameActionButton({
    super.key,
    required this.tooltip,
    required this.badge,
    required this.enabled,
    required this.onPressed,
    this.icon,
    this.child,
  }) : assert(icon != null || child != null);

  final String tooltip;
  final String badge;
  final bool enabled;
  final VoidCallback onPressed;
  final IconData? icon;
  final Widget? child;

  static const pressDuration = Duration(milliseconds: 160);

  @override
  State<GameActionButton> createState() => _GameActionButtonState();
}

class _GameActionButtonState extends State<GameActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: GameActionButton.pressDuration,
    );
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _handlePressed() {
    _press.forward(from: 0);
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _press,
      builder: (context, child) {
        final scale = 1.0 - 0.05 * math.sin(_press.value * math.pi);
        return Transform.scale(scale: scale, child: child);
      },
      child: SizedBox(
        width: GameActionBar.buttonSize + 6,
        height: GameActionBar.buttonSize + 6,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            GameHudCircleButton(
              icon: widget.icon,
              iconSize: 28,
              size: GameActionBar.buttonSize,
              tooltip: widget.tooltip,
              enabled: widget.enabled,
              onPressed: widget.enabled ? _handlePressed : null,
              child: widget.child,
            ),
            Positioned(
              right: 0,
              top: 0,
              child: _CountBadge(label: widget.badge, enabled: widget.enabled),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: enabled ? GameActionBar.badgeColor : const Color(0xFF7A7A7A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1.0,
        ),
      ),
    );
  }
}
