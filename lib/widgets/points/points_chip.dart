import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/points_controller.dart';
import '../../utils/points_format.dart';

const _gold = Color(0xFFD4AF37);
const _goldSoft = Color(0xFFE8C96A);
const _ivory = Color(0xFFF8F1DE);

/// Баланс баллов из [PointsScope]: сам обновляется и празднует начисление.
class PointsChipLive extends StatelessWidget {
  const PointsChipLive({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final controller = PointsScope.maybeOf(context);
    if (controller == null) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) =>
          PointsChip(points: controller.balance, onTap: onTap),
    );
  }
}

/// Плашка баланса: звёздочка, счётчик с перемоткой и золотой блик при росте.
class PointsChip extends StatefulWidget {
  const PointsChip({super.key, required this.points, this.onTap});

  final int points;

  /// Есть обработчик — на плашке появляется «плюс»: открыть витрину.
  final VoidCallback? onTap;

  static const rollDuration = Duration(milliseconds: 820);

  @override
  State<PointsChip> createState() => _PointsChipState();
}

class _PointsChipState extends State<PointsChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _roll;
  late int _shown = widget.points;
  int _from = 0;

  @override
  void initState() {
    super.initState();
    _roll = AnimationController(vsync: this, duration: PointsChip.rollDuration)
      ..addListener(_tick)
      ..addStatusListener(_onStatus);
  }

  @override
  void didUpdateWidget(covariant PointsChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.points == oldWidget.points) return;
    _from = _shown;
    _roll.forward(from: 0);
  }

  void _tick() {
    final t = Curves.easeOutCubic.transform(_roll.value);
    final next = (_from + (widget.points - _from) * t).round();
    if (next != _shown) setState(() => _shown = next);
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_shown != widget.points) setState(() => _shown = widget.points);
  }

  @override
  void dispose() {
    _roll
      ..removeListener(_tick)
      ..removeStatusListener(_onStatus)
      ..dispose();
    super.dispose();
  }

  double _segment(double start, double end) {
    final t = _roll.value;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return (t - start) / (end - start);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tappable = widget.onTap != null;
    return Semantics(
      button: tappable,
      label: l10n.pointsBalance(widget.points),
      child: AnimatedBuilder(
        animation: _roll,
        builder: (context, _) {
          final pop = Curves.easeOut.transform(_segment(0.0, 0.34));
          final settle = Curves.easeInOut.transform(_segment(0.34, 1.0));
          final lift = pop - settle;
          final celebrate = _roll.isAnimating ? 1 - settle : 0.0;
          return Transform.scale(
            scale: 1 + 0.07 * lift,
            child: _frame(
              celebrate: celebrate,
              lift: lift,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10, 9, tappable ? 6 : 10, 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: _content(lift),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _content(double lift) {
    return [
      Transform.translate(
        offset: Offset(0, -2.5 * lift),
        child: Icon(
          Icons.star_rounded,
          color: _goldSoft,
          size: 22,
          shadows: [
            Shadow(
              color: const Color(0xFFFFD86B).withValues(alpha: 0.85 * lift),
              blurRadius: 8 * lift,
            ),
          ],
        ),
      ),
      const SizedBox(width: 6),
      Text(
        formatPoints(_shown),
        style: const TextStyle(
          color: _ivory,
          fontWeight: FontWeight.w800,
          fontSize: 15,
          fontFeatures: [FontFeature.tabularFigures()],
          shadows: [Shadow(color: Color(0x99000000), blurRadius: 4)],
        ),
      ),
      if (widget.onTap != null) ...[
        const SizedBox(width: 7),
        const _AddBadge(),
      ],
    ];
  }

  Widget _frame({
    required double celebrate,
    required double lift,
    required Widget child,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xCC6B3E24), Color(0xCC3A2012)],
        ),
        border: Border.all(
          color: Color.lerp(
            _gold.withValues(alpha: 0.7),
            const Color(0xFFFFE9A8),
            celebrate,
          )!,
          width: 1.3 + 0.5 * celebrate,
        ),
        boxShadow: celebrate > 0
            ? [
                BoxShadow(
                  color: const Color(
                    0xFFFFD86B,
                  ).withValues(alpha: 0.34 * celebrate),
                  blurRadius: 14 + 8 * lift,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            child,
            if (_roll.isAnimating)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ChipShinePainter(t: _segment(0.06, 0.78)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddBadge extends StatelessWidget {
  const _AddBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2BB57A), Color(0xFF0B6141)],
        ),
        border: Border.all(color: _goldSoft.withValues(alpha: 0.8), width: 1.1),
      ),
      child: const Icon(Icons.add_rounded, size: 14, color: _ivory),
    );
  }
}

class _ChipShinePainter extends CustomPainter {
  const _ChipShinePainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final fade = (1 - (t * 2 - 1).abs()).clamp(0.0, 1.0);
    final width = size.width * 0.34;
    final x = -width + (size.width + width * 2) * t;
    final band = Rect.fromLTWH(x, -size.height, width, size.height * 3);
    canvas.save();
    canvas.translate(x + width / 2, size.height / 2);
    canvas.rotate(-0.38);
    canvas.translate(-(x + width / 2), -size.height / 2);
    canvas.drawRect(
      band,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: 0.3 * fade),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(band),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ChipShinePainter oldDelegate) =>
      oldDelegate.t != t;
}
