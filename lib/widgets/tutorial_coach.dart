import 'package:flutter/material.dart';

import '../models/tutorial_step.dart';
import 'premium_ui.dart';

/// Золотая пульсация рамки вокруг лотка или панели бустов.
class TutorialSpotlight extends StatefulWidget {
  const TutorialSpotlight({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<TutorialSpotlight> createState() => _TutorialSpotlightState();
}

class _TutorialSpotlightState extends State<TutorialSpotlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.active) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant TutorialSpotlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _pulse.repeat(reverse: true);
    } else if (!widget.active && oldWidget.active) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = _pulse.value;
        final glow = Color.lerp(
          EmbossedDecoration.gold,
          EmbossedDecoration.goldSoft,
          t,
        )!;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: glow.withValues(alpha: 0.45 + 0.45 * t),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: glow.withValues(alpha: 0.22 + 0.18 * t),
                blurRadius: 12 + 6 * t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Пузырь обучения: не перехватывает тапы по полю, только skip и сам пузырь.
class TutorialCoach extends StatelessWidget {
  const TutorialCoach({
    super.key,
    required this.lesson,
    required this.trayLink,
    required this.actionsLink,
    required this.onSkip,
    this.onAcknowledge,
  });

  final TutorialLesson lesson;
  final LayerLink trayLink;
  final LayerLink actionsLink;
  final VoidCallback onSkip;
  final VoidCallback? onAcknowledge;

  bool get _aboveActions => lesson.anchor == TutorialAnchor.actions;

  @override
  Widget build(BuildContext context) {
    final link = _aboveActions ? actionsLink : trayLink;
    final targetAnchor = _aboveActions
        ? Alignment.topCenter
        : Alignment.bottomCenter;
    final followerAnchor = _aboveActions
        ? Alignment.bottomCenter
        : Alignment.topCenter;
    final offset = _aboveActions ? const Offset(0, -10) : const Offset(0, 10);

    return Stack(
      children: [
        CompositedTransformFollower(
          link: link,
          showWhenUnlinked: false,
          targetAnchor: targetAnchor,
          followerAnchor: followerAnchor,
          offset: offset,
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: _TutorialBubble(
              lesson: lesson,
              tailUp: !_aboveActions,
              onSkip: onSkip,
              onAcknowledge: lesson.acknowledgeByTap ? onAcknowledge : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _TutorialBubble extends StatelessWidget {
  const _TutorialBubble({
    required this.lesson,
    required this.tailUp,
    required this.onSkip,
    this.onAcknowledge,
  });

  final TutorialLesson lesson;
  final bool tailUp;
  final VoidCallback onSkip;
  final VoidCallback? onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final maxWidth = (MediaQuery.sizeOf(context).width - 36).clamp(0.0, 360.0);

    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (tailUp) const _BubbleTail(up: true),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: EmbossedDecoration.panel(
                borderRadius: BorderRadius.circular(16),
                borderWidth: 1.5,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onAcknowledge,
                    behavior: HitTestBehavior.opaque,
                    child: Text(
                      lesson.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFF8F1DE),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(
                      foregroundColor: EmbossedDecoration.goldSoft,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                    ),
                    child: const Text(
                      'Пропустить',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!tailUp) const _BubbleTail(up: false),
          ],
        ),
      ),
    );
  }
}

class _BubbleTail extends StatelessWidget {
  const _BubbleTail({required this.up});

  final bool up;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(18, 8),
      painter: _TailPainter(up: up),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter({required this.up});

  final bool up;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (up) {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close();
    }
    canvas.drawPath(
      path,
      Paint()..color = EmbossedDecoration.woodTop,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = EmbossedDecoration.gold.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  @override
  bool shouldRepaint(covariant _TailPainter oldDelegate) =>
      oldDelegate.up != up;
}
