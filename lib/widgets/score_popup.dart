import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'table_theme.dart';

/// Всплывающие очки у лотка: +100 и множитель комбо.
class ScorePopup extends StatefulWidget {
  const ScorePopup({
    super.key,
    required this.points,
    required this.combo,
    this.onFinished,
  });

  final int points;
  final int combo;
  final VoidCallback? onFinished;

  static const displayDuration = Duration(milliseconds: 900);

  @override
  State<ScorePopup> createState() => _ScorePopupState();
}

class _ScorePopupState extends State<ScorePopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  Timer? _done;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: ScorePopup.displayDuration,
    )..forward();
    _done = Timer(ScorePopup.displayDuration, () {
      widget.onFinished?.call();
    });
  }

  @override
  void dispose() {
    _done?.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showCombo = widget.combo >= 2;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final t = _anim.value;
          final rise = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
          final fade = t < 0.18
              ? t / 0.18
              : t > 0.62
              ? ((1 - t) / 0.38).clamp(0.0, 1.0)
              : 1.0;
          return Opacity(
            opacity: fade,
            child: Transform.translate(
              offset: Offset(0, -22 * rise),
              child: Semantics(
                liveRegion: true,
                label: showCombo
                    ? '${l10n.pointsGain(widget.points)} ${l10n.combo(widget.combo)}'
                    : l10n.pointsGain(widget.points),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.pointsGain(widget.points),
                      style: const TextStyle(
                        color: TableUi.goldSoft,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        height: 1,
                        shadows: [
                          Shadow(color: Color(0xCC000000), blurRadius: 8),
                          Shadow(color: Color(0x99000000), blurRadius: 3),
                        ],
                      ),
                    ),
                    if (showCombo) ...[
                      const SizedBox(width: 6),
                      Text(
                        l10n.combo(widget.combo),
                        style: const TextStyle(
                          color: Color(0xFFFFE7A3),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          height: 1,
                          shadows: [
                            Shadow(color: Color(0xCC000000), blurRadius: 8),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
