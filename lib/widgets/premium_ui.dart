import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Затемнение по краям экрана поверх фона доски.
class BoardVignetteOverlay extends StatelessWidget {
  const BoardVignetteOverlay({
    super.key,
    this.center = const Alignment(0, -0.06),
    this.intensity = 1.0,
    this.dark = false,
  });

  final Alignment center;
  final double intensity;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final edge = dark ? const Color(0xFF010807) : const Color(0xFF1A3D2E);
    final mid = dark ? const Color(0xFF021B18) : const Color(0xFF4A7A62);
    final i = intensity.clamp(0.0, 1.5);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Радиальная виньетка (Canvas-аналог CSS radial-gradient).
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: center,
                radius: 1.18,
                colors: [
                  Colors.transparent,
                  mid.withValues(alpha: (dark ? 0.08 : 0.06) * i),
                  edge.withValues(alpha: (dark ? 0.62 : 0.34) * i),
                ],
                stops: const [0.42, 0.72, 1.0],
              ),
            ),
          ),
        ),
        // Линейное затемнение по четырём краям.
        Positioned.fill(
          child: CustomPaint(painter: _EdgeVignettePainter(intensity: i)),
        ),
      ],
    );
  }
}

class _EdgeVignettePainter extends CustomPainter {
  const _EdgeVignettePainter({this.intensity = 1.0});

  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final i = intensity.clamp(0.0, 1.5);

    void drawEdge({
      required Alignment begin,
      required Alignment end,
      required double alpha,
    }) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ui.Gradient.linear(
            begin.withinRect(rect),
            end.withinRect(rect),
            [Colors.black.withValues(alpha: alpha * i), Colors.transparent],
          ),
      );
    }

    drawEdge(begin: Alignment.topCenter, end: Alignment.center, alpha: 0.28);
    drawEdge(begin: Alignment.bottomCenter, end: Alignment.center, alpha: 0.38);
    drawEdge(begin: Alignment.centerLeft, end: Alignment.center, alpha: 0.22);
    drawEdge(begin: Alignment.centerRight, end: Alignment.center, alpha: 0.22);
  }

  @override
  bool shouldRepaint(covariant _EdgeVignettePainter oldDelegate) =>
      oldDelegate.intensity != intensity;
}

/// Декорация металло-деревянной вдавленной/объёмной плашки.
class EmbossedDecoration {
  EmbossedDecoration._();

  static const woodTop = Color(0xFF6B3E24);
  static const woodDeep = Color(0xFF3A2012);
  static const gold = Color(0xFFD4AF37);
  static const goldSoft = Color(0xFFE8C96A);

  static BoxDecoration panel({
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(16)),
    bool pressed = false,
    List<Color>? gradientColors,
    Color borderColor = gold,
    double borderWidth = 1.4,
  }) {
    final colors = gradientColors ?? const [woodTop, woodDeep];
    final depth = pressed ? 1.0 : 4.0;
    final blur = pressed ? 2.0 : 8.0;
    final spread = pressed ? 0.0 : 0.5;

    return BoxDecoration(
      borderRadius: borderRadius,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
      border: Border.all(
        color: borderColor.withValues(alpha: pressed ? 0.75 : 0.95),
        width: borderWidth,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: pressed ? 0.22 : 0.42),
          offset: Offset(0, depth),
          blurRadius: blur,
          spreadRadius: spread,
        ),
        BoxShadow(
          color: goldSoft.withValues(alpha: pressed ? 0.04 : 0.10),
          offset: Offset(0, pressed ? 0 : -1),
          blurRadius: pressed ? 1 : 3,
        ),
      ],
    );
  }

  static const buttonTop = Color(0xFF2BB57A);
  static const buttonMid = Color(0xFF1B9A6A);
  static const buttonDeep = Color(0xFF0B6141);

  static BoxDecoration circleFace({
    required bool enabled,
    bool exhausted = false,
  }) {
    final colors = !enabled
        ? (exhausted
              ? const [Color(0xFF5A5A5A), Color(0xFF3A3A3A), Color(0xFF2A2A2A)]
              : const [Color(0xFF1A8A60), Color(0xFF167A55), Color(0xFF0A3F2C)])
        : const [buttonTop, buttonMid, buttonDeep];

    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        stops: const [0.0, 0.42, 1.0],
      ),
      border: Border.all(
        color: Colors.black.withValues(alpha: 0.22),
        width: 0.8,
      ),
    );
  }

  static BoxDecoration goldBezel({
    required bool enabled,
    bool pressed = false,
    bool exhausted = false,
  }) {
    final colors = !enabled
        ? (exhausted
              ? const [Color(0xFFB0B0B0), Color(0xFF7A7A7A), Color(0xFF4A4A4A)]
              : const [Color(0xFFE6D48A), Color(0xFFB8963A), Color(0xFF6A5420)])
        : const [Color(0xFFFFF4C4), Color(0xFFE0C35A), Color(0xFF8A6814)];
    final depth = pressed ? 1.0 : 5.0;
    final blur = pressed ? 3.0 : 10.0;

    return BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
        stops: const [0.0, 0.45, 1.0],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: pressed ? 0.28 : 0.48),
          offset: Offset(0, depth),
          blurRadius: blur,
          spreadRadius: pressed ? 0 : 0.4,
        ),
        BoxShadow(
          color: goldSoft.withValues(alpha: pressed || !enabled ? 0.04 : 0.22),
          offset: Offset(0, pressed ? 0 : -1),
          blurRadius: pressed ? 1 : 5,
        ),
      ],
    );
  }
}

/// Объёмная плашка с inner-highlight (имитация inset shadow).
class EmbossedPanel extends StatelessWidget {
  const EmbossedPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.gradientColors,
  });

  final Widget child;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: EmbossedDecoration.panel(
        borderRadius: borderRadius,
        gradientColors: gradientColors,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            // Верхний блик — имитация inner-shadow highlight.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Нижняя внутренняя тень.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}

/// Кнопка с drop-shadow и микро-анимацией нажатия (translateY + уменьшение тени).
class PressableEmbossedButton extends StatefulWidget {
  const PressableEmbossedButton({
    super.key,
    required this.child,
    required this.tooltip,
    this.onPressed,
    this.enabled = true,
    this.exhausted = false,
    this.size = 50,
    this.shape = BoxShape.circle,
    this.borderRadius,
  });

  final Widget child;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool enabled;
  final bool exhausted;
  final double size;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  @override
  State<PressableEmbossedButton> createState() =>
      _PressableEmbossedButtonState();
}

class _PressableEmbossedButtonState extends State<PressableEmbossedButton> {
  static const _pressDuration = Duration(milliseconds: 90);

  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || widget.onPressed == null) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  BorderRadius get _radius =>
      widget.borderRadius ??
      (widget.shape == BoxShape.circle
          ? BorderRadius.circular(widget.size / 2)
          : BorderRadius.circular(12));

  @override
  Widget build(BuildContext context) {
    final canTap = widget.enabled && widget.onPressed != null;
    final isCircle = widget.shape == BoxShape.circle;
    final decoration = isCircle
        ? EmbossedDecoration.goldBezel(
            enabled: widget.enabled,
            pressed: _pressed,
            exhausted: widget.exhausted,
          )
        : EmbossedDecoration.panel(borderRadius: _radius, pressed: _pressed);
    final bezel = isCircle ? (_pressed ? 2.0 : 2.6) : 0.0;

    return Tooltip(
      message: widget.tooltip,
      child: Opacity(
        opacity: widget.enabled ? 1 : (widget.exhausted ? 0.55 : 0.7),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: canTap ? (_) => _setPressed(true) : null,
          onTapUp: canTap ? (_) => _setPressed(false) : null,
          onTapCancel: canTap ? () => _setPressed(false) : null,
          onTap: canTap ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: _pressDuration,
            curve: Curves.easeOut,
            width: widget.size,
            height: widget.size,
            padding: EdgeInsets.all(bezel),
            transform: Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
            transformAlignment: Alignment.topCenter,
            decoration: decoration,
            child: isCircle
                ? DecoratedBox(
                    decoration: EmbossedDecoration.circleFace(
                      enabled: widget.enabled,
                      exhausted: widget.exhausted,
                    ),
                    child: ClipOval(child: _faceStack(glossHeight: 0.44)),
                  )
                : ClipRRect(
                    borderRadius: _radius,
                    child: _faceStack(glossHeight: 0.34),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _faceStack({required double glossHeight}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.enabled && !_pressed)
          Positioned(
            left: 4,
            right: 4,
            top: 2,
            height: widget.size * glossHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(widget.size * 0.36),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.42),
                    Colors.white.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: widget.size * 0.38,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: _pressed ? 0.28 : 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Center(child: widget.child),
      ],
    );
  }
}

/// Сплошная иконка: заливка + утолщение + падающая тень.
class FilledGlyph extends StatelessWidget {
  const FilledGlyph({
    super.key,
    required this.icon,
    this.size = 26,
    this.color = const Color(0xFFF8F1DE),
  });

  final IconData icon;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      size: size,
      color: color,
      shadows: [
        Shadow(color: color, offset: const Offset(0.7, 0)),
        Shadow(color: color, offset: const Offset(-0.7, 0)),
        Shadow(color: color, offset: const Offset(0, 0.7)),
        Shadow(color: color, offset: const Offset(0, -0.7)),
        Shadow(
          color: Colors.black.withValues(alpha: 0.42),
          offset: const Offset(0, 1.2),
          blurRadius: 1.6,
        ),
      ],
    );
  }
}

/// Подкова-магнит: силовые линии и опилки, которые тянутся к полюсам.
class MagnetGlyph extends StatefulWidget {
  const MagnetGlyph({
    super.key,
    this.size = 26,
    this.color = const Color(0xFFF8F1DE),
    this.animate = true,
  });

  final double size;
  final Color color;
  final bool animate;

  @override
  State<MagnetGlyph> createState() => _MagnetGlyphState();
}

class _MagnetGlyphState extends State<MagnetGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    if (widget.animate) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant MagnetGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.animate && _ctrl.isAnimating) {
      _ctrl
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _MagnetGlyphPainter(
            color: widget.color,
            t: widget.animate ? _ctrl.value : 0,
          ),
        );
      },
    );
  }
}

class _MagnetGlyphPainter extends CustomPainter {
  const _MagnetGlyphPainter({required this.color, this.t = 0});

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = s * 0.28;
    final inset = stroke / 2 + s * 0.10;
    final rect = Rect.fromLTRB(inset, s * 0.10, s - inset, s - inset * 0.72);

    final path = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.left, rect.bottom - rect.width / 2)
      ..arcToPoint(
        Offset(rect.right, rect.bottom - rect.width / 2),
        radius: Radius.circular(rect.width / 2),
        clockwise: false,
      )
      ..lineTo(rect.right, rect.top);

    canvas.drawPath(
      path.shift(const Offset(0, 1.1)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.round,
    );

    if (t > 0) {
      final glow = 0.14 + 0.16 * (0.5 + 0.5 * math.sin(t * math.pi * 2));
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: glow)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 1.7
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.4),
      );
      _paintField(canvas, rect, s);
      _paintFilings(canvas, rect, s);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..strokeJoin = StrokeJoin.round,
    );

    final capH = s * 0.16;
    final capR = Radius.circular(stroke * 0.18);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(rect.left, rect.top + capH * 0.12),
          width: stroke,
          height: capH,
        ),
        capR,
      ),
      Paint()..color = color,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(rect.right, rect.top + capH * 0.12),
          width: stroke,
          height: capH,
        ),
        capR,
      ),
      Paint()..color = color,
    );
  }

  void _paintField(Canvas canvas, Rect rect, double s) {
    final left = Offset(rect.left, rect.top + s * 0.04);
    final right = Offset(rect.right, rect.top + s * 0.04);
    for (var i = 0; i < 3; i++) {
      final phase = (t + i * 0.28) % 1.0;
      final alpha = math.sin(phase * math.pi);
      if (alpha < 0.08) continue;
      final bulge = 0.20 + i * 0.13 + phase * 0.07;
      final field = Path()
        ..moveTo(left.dx, left.dy)
        ..quadraticBezierTo(
          s / 2,
          rect.top + s * bulge,
          right.dx,
          right.dy,
        );
      canvas.drawPath(
        field,
        Paint()
          ..color = color.withValues(alpha: alpha * 0.62)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.05
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintFilings(Canvas canvas, Rect rect, double s) {
    final mouth = Offset(s / 2, rect.top + s * 0.26);
    const seeds = <(double, double, double)>[
      (0.22, 0.02, 0.00),
      (0.78, 0.06, 0.22),
      (0.34, 0.38, 0.47),
      (0.68, 0.34, 0.63),
      (0.50, 0.00, 0.81),
    ];
    for (final seed in seeds) {
      final phase = (t + seed.$3) % 1.0;
      final start = Offset(s * seed.$1, s * seed.$2);
      final p = Offset.lerp(start, mouth, Curves.easeIn.transform(phase))!;
      final alpha = math.sin(phase * math.pi);
      if (alpha < 0.06) continue;
      canvas.drawCircle(
        p,
        0.85 + (1 - phase) * 0.55,
        Paint()..color = color.withValues(alpha: alpha * 0.9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MagnetGlyphPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.t != t;
}

/// Две стрелки shuffle: плитки меняются местами, стрелки прокручиваются.
class ShuffleGlyph extends StatefulWidget {
  const ShuffleGlyph({
    super.key,
    this.size = 28,
    this.color = const Color(0xFFF8F1DE),
    this.animate = true,
  });

  final double size;
  final Color color;
  final bool animate;

  @override
  State<ShuffleGlyph> createState() => _ShuffleGlyphState();
}

class _ShuffleGlyphState extends State<ShuffleGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.animate) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant ShuffleGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.animate && _ctrl.isAnimating) {
      _ctrl
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _ShuffleGlyphPainter(
            color: widget.color,
            t: widget.animate ? _ctrl.value : 0,
          ),
        );
      },
    );
  }
}

class _ShuffleGlyphPainter extends CustomPainter {
  const _ShuffleGlyphPainter({required this.color, this.t = 0});

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final topY = s * 0.32;
    final botY = s * 0.68;
    final top = _arrowPath(s, yStart: topY, yEnd: botY);
    final bottom = _arrowPath(s, yStart: botY, yEnd: topY);

    final stroke = s * 0.10;
    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(top.shift(Offset(0, s * 0.04)), shadow);
    canvas.drawPath(bottom.shift(Offset(0, s * 0.04)), shadow);

    if (t > 0) {
      final glow = 0.12 + 0.14 * (0.5 + 0.5 * math.sin(t * math.pi * 2));
      final glowPaint = Paint()
        ..color = color.withValues(alpha: glow)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke * 1.85
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2);
      canvas.drawPath(top, glowPaint);
      canvas.drawPath(bottom, glowPaint);
    }

    final body = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(top, body);
    canvas.drawPath(bottom, body);
    _paintHead(canvas, s, y: botY);
    _paintHead(canvas, s, y: topY);

    if (t > 0) {
      _paintFlow(canvas, top, s);
      _paintFlow(canvas, bottom, s, delay: 0.5);
      _paintChips(canvas, s);
    }
  }

  Path _arrowPath(double s, {required double yStart, required double yEnd}) {
    return Path()
      ..moveTo(s * 0.10, yStart)
      ..lineTo(s * 0.34, yStart)
      ..lineTo(s * 0.62, yEnd)
      ..lineTo(s * 0.82, yEnd);
  }

  void _paintHead(Canvas canvas, double s, {required double y}) {
    final tip = Offset(s * 0.94, y);
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(s * 0.78, y - s * 0.11)
      ..lineTo(s * 0.78, y + s * 0.11)
      ..close();
    canvas.drawPath(
      head.shift(Offset(0, s * 0.04)),
      Paint()..color = Colors.black.withValues(alpha: 0.42),
    );
    canvas.drawPath(head, Paint()..color = color);
  }

  void _paintFlow(Canvas canvas, Path path, double s, {double delay = 0}) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      final start = ((t + delay) % 1.0) * metric.length;
      final end = (start + metric.length * 0.28).clamp(0.0, metric.length);
      if (end <= start) continue;
      canvas.drawPath(
        metric.extractPath(start, end),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.045
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintChips(Canvas canvas, double s) {
    final swapT = ((t - 0.08) / 0.42).clamp(0.0, 1.0);
    final eased = Curves.easeInOutCubic.transform(swapT);
    final left = Offset(s * 0.22, s * 0.50);
    final right = Offset(s * 0.72, s * 0.50);
    final arc = math.sin(eased * math.pi) * s * 0.16;
    _chip(canvas, s, Offset.lerp(left, right, eased)! + Offset(0, -arc));
    _chip(canvas, s, Offset.lerp(right, left, eased)! + Offset(0, arc));
  }

  void _chip(Canvas canvas, double s, Offset center) {
    final rect = Rect.fromCenter(
      center: center,
      width: s * 0.20,
      height: s * 0.26,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.04));
    canvas.drawRRect(
      rrect.shift(Offset(0, s * 0.03)),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    canvas.drawRRect(rrect, Paint()..color = color.withValues(alpha: 0.95));
    canvas.drawCircle(
      center,
      s * 0.035,
      Paint()..color = const Color(0xFF3A2012).withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant _ShuffleGlyphPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.t != t;
}

/// Иконка undo: стрелка отматывает ход, плитка едет назад по дуге.
class UndoGlyph extends StatefulWidget {
  const UndoGlyph({
    super.key,
    this.size = 28,
    this.color = const Color(0xFFF8F1DE),
    this.animate = true,
  });

  final double size;
  final Color color;
  final bool animate;

  @override
  State<UndoGlyph> createState() => _UndoGlyphState();
}

class _UndoGlyphState extends State<UndoGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    if (widget.animate) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant UndoGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.animate && _ctrl.isAnimating) {
      _ctrl
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _UndoGlyphPainter(
            color: widget.color,
            t: widget.animate ? _ctrl.value : 0,
          ),
        );
      },
    );
  }
}

class _UndoGlyphPainter extends CustomPainter {
  const _UndoGlyphPainter({required this.color, this.t = 0});

  final Color color;
  final double t;

  static const _startAngle = 0.32 * math.pi;
  static const _sweep = -1.22 * math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(s * 0.56, s * 0.52);
    final radius = s * 0.30;
    final oval = Rect.fromCircle(center: center, radius: radius);
    final path = Path()..addArc(oval, _startAngle, _sweep);
    final stroke = s * 0.11;

    canvas.drawPath(
      path.shift(Offset(0, s * 0.04)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );

    if (t > 0) {
      final glow = 0.12 + 0.16 * (0.5 + 0.5 * math.sin(t * math.pi * 2));
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: glow)
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 1.8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
    _paintHead(canvas, center, radius, s);

    if (t > 0) {
      _paintFlow(canvas, path, s);
      _paintRewindChip(canvas, center, radius, s);
    }
  }

  void _paintHead(Canvas canvas, Offset center, double radius, double s) {
    final endAngle = _startAngle + _sweep;
    final tip =
        center + Offset(math.cos(endAngle), math.sin(endAngle)) * radius;
    final head = Path()
      ..moveTo(tip.dx - s * 0.10, tip.dy)
      ..lineTo(tip.dx + s * 0.10, tip.dy - s * 0.13)
      ..lineTo(tip.dx + s * 0.10, tip.dy + s * 0.13)
      ..close();
    canvas.drawPath(
      head.shift(Offset(0, s * 0.04)),
      Paint()..color = Colors.black.withValues(alpha: 0.42),
    );
    canvas.drawPath(head, Paint()..color = color);
  }

  void _paintFlow(Canvas canvas, Path path, double s) {
    for (final metric in path.computeMetrics()) {
      final head = (1 - t) * metric.length;
      final tail = (head - metric.length * 0.30).clamp(0.0, metric.length);
      if (head <= tail + 0.4) continue;
      canvas.drawPath(
        metric.extractPath(tail, head),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.72)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.045
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintRewindChip(
    Canvas canvas,
    Offset center,
    double radius,
    double s,
  ) {
    final rewind = Curves.easeInOutCubic.transform(
      ((t - 0.06) / 0.52).clamp(0.0, 1.0),
    );
    final fade = math.sin(rewind * math.pi);
    if (fade < 0.08) return;
    final angle = (_startAngle + _sweep) + (-_sweep) * rewind;
    final p =
        center + Offset(math.cos(angle), math.sin(angle)) * (radius * 0.92);
    final rect = Rect.fromCenter(
      center: p,
      width: s * 0.20,
      height: s * 0.26,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.04));
    canvas.drawRRect(
      rrect.shift(Offset(0, s * 0.03)),
      Paint()..color = Colors.black.withValues(alpha: 0.35 * fade),
    );
    canvas.drawRRect(
      rrect,
      Paint()..color = color.withValues(alpha: 0.95 * fade),
    );
    canvas.drawCircle(
      p,
      s * 0.035,
      Paint()
        ..color = const Color(0xFF3A2012).withValues(alpha: 0.45 * fade),
    );
  }

  @override
  bool shouldRepaint(covariant _UndoGlyphPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.t != t;
}

/// Лампочка-подсказка: лучи вспыхивают, внутри пульсирует свет.
class HintGlyph extends StatefulWidget {
  const HintGlyph({
    super.key,
    this.size = 28,
    this.color = const Color(0xFFF8F1DE),
    this.animate = true,
  });

  final double size;
  final Color color;
  final bool animate;

  @override
  State<HintGlyph> createState() => _HintGlyphState();
}

class _HintGlyphState extends State<HintGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.animate) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant HintGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.animate && _ctrl.isAnimating) {
      _ctrl
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _HintGlyphPainter(
            color: widget.color,
            t: widget.animate ? _ctrl.value : 0,
          ),
        );
      },
    );
  }
}

class _HintGlyphPainter extends CustomPainter {
  const _HintGlyphPainter({required this.color, this.t = 0});

  final Color color;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final bulb = Offset(s * 0.50, s * 0.40);
    final bulbR = s * 0.26;

    if (t > 0) {
      _paintRays(canvas, bulb, bulbR, s);
      final glow = 0.16 + 0.22 * (0.5 + 0.5 * math.sin(t * math.pi * 2));
      canvas.drawCircle(
        bulb,
        bulbR * 1.35,
        Paint()
          ..color = color.withValues(alpha: glow)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.2),
      );
    }

    _paintBulb(canvas, s, bulb, bulbR);
  }

  void _paintRays(Canvas canvas, Offset bulb, double bulbR, double s) {
    const angles = <double>[
      -math.pi * 0.72,
      -math.pi * 0.50,
      -math.pi * 0.28,
      -math.pi * 0.90,
      -math.pi * 0.10,
    ];
    for (var i = 0; i < angles.length; i++) {
      final phase = (t + i * 0.17) % 1.0;
      final pulse = math.sin(phase * math.pi);
      if (pulse < 0.08) continue;
      final dir = Offset(math.cos(angles[i]), math.sin(angles[i]));
      final inner = bulb + dir * (bulbR * 1.18);
      final outer = bulb + dir * (bulbR * (1.42 + 0.28 * pulse));
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = color.withValues(alpha: pulse * 0.88)
          ..strokeWidth = s * 0.055
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintBulb(Canvas canvas, double s, Offset bulb, double bulbR) {
    final neckTop = bulb.dy + bulbR * 0.62;
    final neckBot = s * 0.78;
    final neckW = s * 0.16;
    final body = Path()
      ..addOval(Rect.fromCircle(center: bulb, radius: bulbR))
      ..moveTo(bulb.dx - neckW * 0.42, neckTop)
      ..lineTo(bulb.dx - neckW * 0.55, neckBot)
      ..lineTo(bulb.dx + neckW * 0.55, neckBot)
      ..lineTo(bulb.dx + neckW * 0.42, neckTop)
      ..close();

    canvas.drawPath(
      body.shift(Offset(0, s * 0.04)),
      Paint()..color = Colors.black.withValues(alpha: 0.38),
    );
    canvas.drawPath(body, Paint()..color = color);

    if (t > 0) {
      final inner = 0.20 + 0.28 * (0.5 + 0.5 * math.sin(t * math.pi * 2));
      canvas.drawCircle(
        bulb.translate(0, -s * 0.02),
        bulbR * 0.46,
        Paint()..color = Colors.white.withValues(alpha: inner),
      );
    }

    final baseY = s * 0.82;
    final base = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(s * 0.50, baseY),
        width: s * 0.30,
        height: s * 0.10,
      ),
      Radius.circular(s * 0.03),
    );
    canvas.drawRRect(
      base.shift(Offset(0, s * 0.03)),
      Paint()..color = Colors.black.withValues(alpha: 0.38),
    );
    canvas.drawRRect(base, Paint()..color = color);
    canvas.drawLine(
      Offset(s * 0.40, s * 0.88),
      Offset(s * 0.60, s * 0.88),
      Paint()
        ..color = color
        ..strokeWidth = s * 0.055
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HintGlyphPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.t != t;
}

/// Объёмный счётчик / плюсик на кнопке буста.
class BoostCountBadge extends StatelessWidget {
  const BoostCountBadge({
    super.key,
    required this.label,
    this.enabled = true,
    this.color = const Color(0xFFE23B3B),
  });

  final String label;
  final bool enabled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final top = Color.lerp(const Color(0xFFFFF0EE), color, 0.55)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: enabled
              ? [top, color]
              : const [Color(0xFF9A9A9A), Color(0xFF5A5A5A)],
        ),
        border: Border.all(color: Colors.white, width: 1.35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.42),
            offset: const Offset(0, 2),
            blurRadius: 3,
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned(
                left: 1,
                right: 1,
                top: 0,
                height: 7,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  shadows: [
                    Shadow(
                      color: Color(0x66000000),
                      offset: Offset(0, 1),
                      blurRadius: 1,
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
