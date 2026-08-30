import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Три фонаря двора — ритуал серии из трёх вечеров.
class StreakLanterns extends StatefulWidget {
  const StreakLanterns({
    super.key,
    required this.litCount,
    this.lights,
    this.waitingNext = false,
    this.atRisk = false,
    this.celebrate = false,
    this.size = 20,
    this.gap = 5,
    this.idle = true,
    this.semanticLabel,
  });

  factory StreakLanterns.forDaily({
    Key? key,
    required int streak,
    required bool completedToday,
    double size = 20,
    String? semanticLabel,
  }) {
    final lit = streak.clamp(0, 3);
    return StreakLanterns(
      key: key,
      litCount: lit,
      waitingNext: !completedToday && lit < 3,
      atRisk: !completedToday && streak > 0,
      celebrate: completedToday && streak >= 3,
      size: size,
      semanticLabel: semanticLabel,
    );
  }

  /// Сколько из трёх ночей уже зажжены (0–3). Игнорируется, если задан [lights].
  final int litCount;

  /// Яркость каждого фонаря 0..1. Для оверлея победы, когда свет зажигается по очереди.
  final List<double>? lights;

  /// Следующий незажжённый фонарь дышит — сегодня ещё можно сыграть.
  final bool waitingNext;

  /// Последний горящий мерцает: серия сгорит в полночь.
  final bool atRisk;

  /// Золотое кольцо, когда все три ночи сохранены.
  final bool celebrate;

  final double size;
  final double gap;
  final bool idle;
  final String? semanticLabel;

  @override
  State<StreakLanterns> createState() => _StreakLanternsState();
}

class _StreakLanternsState extends State<StreakLanterns>
    with SingleTickerProviderStateMixin {
  AnimationController? _idle;

  @override
  void initState() {
    super.initState();
    if (widget.idle) {
      _idle = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      )..repeat();
    }
  }

  @override
  void didUpdateWidget(covariant StreakLanterns oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.idle && _idle == null) {
      _idle = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1800),
      )..repeat();
    } else if (!widget.idle && _idle != null) {
      _idle!.dispose();
      _idle = null;
    }
  }

  @override
  void dispose() {
    _idle?.dispose();
    super.dispose();
  }

  List<double> get _lights {
    final given = widget.lights;
    if (given != null && given.length >= 3) {
      return [
        given[0].clamp(0.0, 1.0),
        given[1].clamp(0.0, 1.0),
        given[2].clamp(0.0, 1.0),
      ];
    }
    final lit = widget.litCount.clamp(0, 3);
    return [for (var i = 0; i < 3; i++) i < lit ? 1.0 : 0.0];
  }

  int get _waitingIndex {
    if (!widget.waitingNext) return -1;
    final lights = _lights;
    for (var i = 0; i < 3; i++) {
      if (lights[i] < 0.45) return i;
    }
    return -1;
  }

  int get _atRiskIndex {
    if (!widget.atRisk) return -1;
    final lights = _lights;
    for (var i = 2; i >= 0; i--) {
      if (lights[i] > 0.45) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.size * 3 + widget.gap * 2 + 8;
    final height = widget.size + 6;
    final paint = AnimatedBuilder(
      animation: _idle ?? const AlwaysStoppedAnimation(0.0),
      builder: (context, _) {
        final t = _idle?.value ?? 0.0;
        final pulse = 0.5 + 0.5 * math.sin(t * 2 * math.pi);
        final flicker =
            0.28 +
            0.72 *
                (0.55 + 0.45 * math.sin(t * 14 * math.pi)) *
                (0.55 + 0.45 * math.sin(t * 9.4 * math.pi + 0.7));
        return CustomPaint(
          painter: _StreakLanternsPainter(
            lights: _lights,
            waitingIndex: _waitingIndex,
            atRiskIndex: _atRiskIndex,
            celebrate: widget.celebrate,
            pulse: pulse,
            flicker: flicker,
            lanternSize: widget.size,
            gap: widget.gap,
          ),
        );
      },
    );

    final child = SizedBox(width: width, height: height, child: paint);
    final label = widget.semanticLabel;
    if (label == null || label.isEmpty) return child;
    return Semantics(label: label, child: child);
  }
}

class _StreakLanternsPainter extends CustomPainter {
  const _StreakLanternsPainter({
    required this.lights,
    required this.waitingIndex,
    required this.atRiskIndex,
    required this.celebrate,
    required this.pulse,
    required this.flicker,
    required this.lanternSize,
    required this.gap,
  });

  final List<double> lights;
  final int waitingIndex;
  final int atRiskIndex;
  final bool celebrate;
  final double pulse;
  final double flicker;
  final double lanternSize;
  final double gap;

  static const _gold = Color(0xFFD4AF37);
  static const _goldSoft = Color(0xFFE8C96A);
  static const _core = Color(0xFFFFF3C4);
  static const _glow = Color(0xFFFFD54F);
  static const _wood = Color(0xFF3A2012);
  static const _ember = Color(0xFFFFE08A);

  @override
  void paint(Canvas canvas, Size size) {
    final allLit = lights.every((light) => light > 0.82);
    if (celebrate && allLit) {
      final ring = RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1.5, size.width - 2, size.height - 3),
        Radius.circular(size.height / 2),
      );
      canvas.drawRRect(
        ring,
        Paint()
          ..color = _glow.withValues(alpha: 0.12 + 0.10 * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawRRect(
        ring,
        Paint()
          ..color = _gold.withValues(alpha: 0.72 + 0.18 * pulse)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.25,
      );
    }

    final originX =
        (size.width - (lanternSize * 3 + gap * 2)) / 2 + lanternSize / 2;
    final cy = size.height * 0.56;
    for (var i = 0; i < 3; i++) {
      var light = lights[i];
      final waiting = i == waitingIndex;
      if (i == atRiskIndex) light *= flicker;
      if (waiting) light = math.max(light, 0.06 + 0.10 * pulse);
      if (light > 0.55 && i != atRiskIndex) {
        light = (light * (0.92 + 0.08 * pulse)).clamp(0.0, 1.0);
      }
      _drawLantern(
        canvas,
        Offset(originX + i * (lanternSize + gap), cy),
        lanternSize,
        light,
        waiting: waiting,
      );
    }
  }

  void _drawLantern(
    Canvas canvas,
    Offset center,
    double size,
    double light, {
    required bool waiting,
  }) {
    final string = Paint()
      ..color = _goldSoft.withValues(alpha: 0.42 + 0.40 * light)
      ..strokeWidth = math.max(1.0, size * 0.055)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(center.dx, center.dy - size * 0.50),
      Offset(center.dx, center.dy - size * 0.30),
      string,
    );

    final bodyW = size * 0.40;
    final bodyH = size * 0.54;
    final top = Offset(center.dx, center.dy - bodyH * 0.42);
    final path = Path()
      ..moveTo(top.dx, top.dy)
      ..cubicTo(
        center.dx + bodyW,
        center.dy - bodyH * 0.12,
        center.dx + bodyW * 0.92,
        center.dy + bodyH * 0.32,
        center.dx,
        center.dy + bodyH * 0.48,
      )
      ..cubicTo(
        center.dx - bodyW * 0.92,
        center.dy + bodyH * 0.32,
        center.dx - bodyW,
        center.dy - bodyH * 0.12,
        top.dx,
        top.dy,
      );

    if (light > 0.04) {
      canvas.drawCircle(
        Offset(center.dx, center.dy + size * 0.02),
        size * (0.22 + 0.20 * light),
        Paint()
          ..color = _glow.withValues(alpha: 0.20 + 0.38 * light)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.28),
      );
    }

    final fill = Paint()
      ..shader = ui.Gradient.linear(
        Offset(center.dx, center.dy - bodyH * 0.4),
        Offset(center.dx, center.dy + bodyH * 0.5),
        [
          Color.lerp(_wood, _ember, light * 0.92)!,
          Color.lerp(const Color(0xFF2A160C), _goldSoft, light * 0.75)!,
        ],
      );
    canvas.drawPath(path, fill);
    canvas.drawPath(
      path,
      Paint()
        ..color = _gold.withValues(alpha: waiting ? 0.95 : 0.38 + 0.52 * light)
        ..style = PaintingStyle.stroke
        ..strokeWidth = waiting ? 1.55 : 1.05,
    );

    if (light > 0.08) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + size * 0.02),
          width: size * 0.18 * light,
          height: size * 0.22 * light,
        ),
        Paint()..color = _core.withValues(alpha: 0.50 + 0.50 * light),
      );
    }

    final cap = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, top.dy - size * 0.01),
        width: bodyW * 1.15,
        height: size * 0.09,
      ),
      const Radius.circular(2),
    );
    canvas.drawRRect(
      cap,
      Paint()..color = _gold.withValues(alpha: 0.62 + 0.32 * light),
    );
  }

  @override
  bool shouldRepaint(covariant _StreakLanternsPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.flicker != flicker ||
        oldDelegate.celebrate != celebrate ||
        oldDelegate.waitingIndex != waitingIndex ||
        oldDelegate.atRiskIndex != atRiskIndex ||
        oldDelegate.lanternSize != lanternSize ||
        oldDelegate.gap != gap ||
        oldDelegate.lights[0] != lights[0] ||
        oldDelegate.lights[1] != lights[1] ||
        oldDelegate.lights[2] != lights[2];
  }
}
