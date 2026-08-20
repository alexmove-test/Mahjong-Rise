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

/// Подкова-магнит сплошной заливкой (буст «Магнит»).
class MagnetGlyph extends StatelessWidget {
  const MagnetGlyph({
    super.key,
    this.size = 26,
    this.color = const Color(0xFFF8F1DE),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MagnetGlyphPainter(color: color),
    );
  }
}

class _MagnetGlyphPainter extends CustomPainter {
  const _MagnetGlyphPainter({required this.color});

  final Color color;

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

  @override
  bool shouldRepaint(covariant _MagnetGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
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
