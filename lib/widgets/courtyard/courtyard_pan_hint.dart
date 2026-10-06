import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

const courtyardPanHintKey = ValueKey('courtyard-pan-hint');

/// Жест «потяните карту»: стрелки и ладонь вместо текстового баннера.
class CourtyardPanHint extends StatefulWidget {
  const CourtyardPanHint({super.key});

  @override
  State<CourtyardPanHint> createState() => _CourtyardPanHintState();
}

class _CourtyardPanHintState extends State<CourtyardPanHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide;

  static const _gold = Color(0xFFE8C96A);
  static const _wood = Color(0xE63A2012);

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: courtyardPanHintKey,
      liveRegion: true,
      label: AppLocalizations.of(context).courtyardPanHint,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _slide,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_slide.value);
            return Transform.translate(
              offset: Offset((t - 0.5) * 22, 0),
              child: child,
            );
          },
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _wood,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.78),
                width: 1.3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x88000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left_rounded, color: _gold, size: 26),
                  SizedBox(width: 2),
                  Icon(Icons.swipe_rounded, color: _gold, size: 28),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, color: _gold, size: 26),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
