import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/plot_kind.dart';
import 'courtyard_lot_build.dart';

/// Модульный участок: каждая целая стадия добавляет или меняет одну деталь.
class LotBuildPainter extends CustomPainter {
  const LotBuildPainter({
    required this.kind,
    required this.stage,
    this.life = 0,
    this.festival = 0,
  });

  final PlotKind kind;
  final double stage;
  final double life;
  final double festival;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 2 || size.height < 2) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    switch (kind) {
      case PlotKind.house:
        _paintHouse(canvas, size);
      case PlotKind.pond:
        _paintPond(canvas, size);
      case PlotKind.pets:
        _paintPets(canvas, size);
      case PlotKind.guest:
        _paintInternet(canvas, size);
    }
    canvas.restore();
  }

  double _op(int layer) => CourtyardLotBuild.layerOpacity(stage, layer);

  void _withOpacity(Canvas canvas, double t, VoidCallback paint) {
    if (t < 0.01) return;
    if (t >= 0.995) {
      paint();
      return;
    }
    canvas.saveLayer(
      null,
      Paint()..color = Color.fromRGBO(255, 255, 255, t.clamp(0.0, 1.0)),
    );
    paint();
    canvas.restore();
  }

  Offset _pt(Size s, double x, double y) => Offset(s.width * x, s.height * y);

  Paint _fill(Color c) => Paint()
    ..color = c
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  void _contactShadow(
    Canvas canvas,
    Size s,
    Offset center,
    double rx,
    double ry,
  ) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      _fill(const Color(0x55000000)),
    );
  }

  void _ellipse(
    Canvas canvas,
    Size s,
    double x,
    double y,
    double w,
    double h,
    Color c,
  ) {
    canvas.drawOval(
      Rect.fromCenter(
        center: _pt(s, x, y),
        width: s.width * w,
        height: s.height * h,
      ),
      _fill(c),
    );
  }

  /// 3/4 корпус: фасад + бок + крыша.
  void _block({
    required Canvas canvas,
    required Size s,
    required double x,
    required double y,
    required double w,
    required double d,
    required double h,
    required Color front,
    required Color side,
    required Color top,
  }) {
    final origin = _pt(s, x, y);
    final fw = s.width * w;
    final fd = s.width * d * 0.45;
    final fh = s.height * h;
    final frontRect = Rect.fromLTWH(origin.dx, origin.dy - fh, fw, fh);
    final sidePath = Path()
      ..moveTo(frontRect.right, frontRect.top)
      ..lineTo(frontRect.right + fd, frontRect.top - fd * 0.35)
      ..lineTo(frontRect.right + fd, frontRect.bottom - fd * 0.35)
      ..lineTo(frontRect.right, frontRect.bottom)
      ..close();
    final topPath = Path()
      ..moveTo(frontRect.left, frontRect.top)
      ..lineTo(frontRect.right, frontRect.top)
      ..lineTo(frontRect.right + fd, frontRect.top - fd * 0.35)
      ..lineTo(frontRect.left + fd, frontRect.top - fd * 0.35)
      ..close();
    canvas.drawPath(topPath, _fill(top));
    canvas.drawPath(sidePath, _fill(side));
    canvas.drawRRect(
      RRect.fromRectAndRadius(frontRect, const Radius.circular(1.2)),
      _fill(front),
    );
  }

  void _roof({
    required Canvas canvas,
    required Size s,
    required double x,
    required double y,
    required double w,
    required double d,
    required double h,
    required Color color,
    required Color shade,
  }) {
    final origin = _pt(s, x, y);
    final fw = s.width * w;
    final fd = s.width * d * 0.45;
    final fh = s.height * h;
    final peak = Offset(origin.dx + fw * 0.5, origin.dy - fh);
    final left = Offset(origin.dx - fw * 0.08, origin.dy);
    final right = Offset(origin.dx + fw + fd * 0.15, origin.dy - fd * 0.2);
    final back = Offset(
      origin.dx + fw * 0.55 + fd,
      origin.dy - fh * 0.35 - fd * 0.2,
    );
    canvas.drawPath(
      Path()
        ..moveTo(peak.dx, peak.dy)
        ..lineTo(right.dx, right.dy)
        ..lineTo(back.dx, back.dy)
        ..close(),
      _fill(shade),
    );
    canvas.drawPath(
      Path()
        ..moveTo(peak.dx, peak.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
      _fill(color),
    );
  }

  void _pole(
    Canvas canvas,
    Size s,
    double x,
    double y1,
    double y2,
    Color c,
    double w,
  ) {
    canvas.drawLine(_pt(s, x, y1), _pt(s, x, y2), _stroke(c, s.width * w));
  }

  void _flag(Canvas canvas, Size s, double x, double y, Color c) {
    final p = _pt(s, x, y);
    canvas.drawPath(
      Path()
        ..moveTo(p.dx, p.dy)
        ..lineTo(p.dx + s.width * 0.08, p.dy + s.height * 0.025)
        ..lineTo(p.dx, p.dy + s.height * 0.05)
        ..close(),
      _fill(c),
    );
  }

  // --- House: clearing → residence -----------------------------------------

  void _paintHouse(Canvas canvas, Size s) {
    if (stage < 0.05) return;

    _withOpacity(canvas, _op(1), () {
      _contactShadow(
        canvas,
        s,
        _pt(s, 0.50, 0.86),
        s.width * 0.32,
        s.height * 0.08,
      );
    });
    _withOpacity(canvas, _op(2), () {
      final path = Path()
        ..moveTo(_pt(s, 0.18, 0.90).dx, _pt(s, 0.18, 0.90).dy)
        ..quadraticBezierTo(
          _pt(s, 0.42, 0.82).dx,
          _pt(s, 0.42, 0.82).dy,
          _pt(s, 0.72, 0.88).dx,
          _pt(s, 0.72, 0.88).dy,
        );
      canvas.drawPath(
        path,
        _stroke(const Color(0xFF6B5428), math.max(1.5, s.width * 0.018)),
      );
    });
    _withOpacity(canvas, _op(3), () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: _pt(s, 0.22, 0.80),
            width: s.width * 0.16,
            height: s.height * 0.08,
          ),
          const Radius.circular(2),
        ),
        _fill(const Color(0xFF8A5A2A)),
      );
    });

    // Lean-to / bodies. Later tiers cover earlier ones.
    _withOpacity(canvas, _op(4), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.38,
        y: 0.82,
        w: 0.22,
        d: 0.12,
        h: 0.10,
        front: const Color(0xFFC4A574),
        side: const Color(0xFF9C7A48),
        top: const Color(0xFFB08950),
      );
    });
    _withOpacity(canvas, _op(5), () {
      canvas.drawCircle(
        _pt(s, 0.28, 0.84),
        s.width * 0.03,
        _fill(const Color(0xFF5A3A22)),
      );
      canvas.drawCircle(
        _pt(s, 0.28, 0.82),
        s.width * 0.018,
        _fill(const Color(0xFFE07A3A)),
      );
    });
    _withOpacity(canvas, _op(7), () {
      _pole(canvas, s, 0.34, 0.84, 0.62, const Color(0xFF5C3B1E), 0.012);
    });
    _withOpacity(canvas, _op(8), () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: _pt(s, 0.70, 0.84),
            width: s.width * 0.12,
            height: s.height * 0.04,
          ),
          const Radius.circular(2),
        ),
        _fill(const Color(0xFF7A4E28)),
      );
    });

    _houseBody(canvas, s);
    _houseRoof(canvas, s);
    _houseTowers(canvas, s);
    _houseYard(canvas, s);
    _houseLife(canvas, s);
  }

  void _houseBody(Canvas canvas, Size s) {
    // Shack
    _withOpacity(canvas, _op(9), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.34,
        y: 0.84,
        w: 0.30,
        d: 0.16,
        h: 0.18,
        front: const Color(0xFFB08958),
        side: const Color(0xFF8C6840),
        top: const Color(0xFF9A7040),
      );
    });
    _withOpacity(canvas, _op(10), () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: _pt(s, 0.42, 0.78),
            width: s.width * 0.05,
            height: s.height * 0.08,
          ),
          const Radius.circular(1),
        ),
        _fill(const Color(0xFF3A2412)),
      );
    });
    _withOpacity(canvas, _op(13), () {
      canvas.drawRect(
        Rect.fromCenter(
          center: _pt(s, 0.54, 0.72),
          width: s.width * 0.04,
          height: s.height * 0.035,
        ),
        _fill(const Color(0xFF87C4D8)),
      );
    });
    _withOpacity(canvas, _op(16), () {
      canvas.drawRect(
        Rect.fromCenter(
          center: _pt(s, 0.48, 0.72),
          width: s.width * 0.035,
          height: s.height * 0.03,
        ),
        _fill(const Color(0xFF87C4D8)),
      );
    });

    // Hut — slightly larger, warmer
    _withOpacity(canvas, _op(17), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.32,
        y: 0.84,
        w: 0.34,
        d: 0.18,
        h: 0.22,
        front: const Color(0xFFC49A62),
        side: const Color(0xFF9A7344),
        top: const Color(0xFFA87C48),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: _pt(s, 0.42, 0.78),
            width: s.width * 0.055,
            height: s.height * 0.09,
          ),
          const Radius.circular(1.5),
        ),
        _fill(const Color(0xFF4A2C14)),
      );
    });
    _withOpacity(canvas, _op(18), () {
      canvas.drawRect(
        Rect.fromCenter(
          center: _pt(s, 0.52, 0.70),
          width: s.width * 0.045,
          height: s.height * 0.04,
        ),
        _fill(const Color(0xFF9FD4E6)),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: _pt(s, 0.60, 0.70),
          width: s.width * 0.045,
          height: s.height * 0.04,
        ),
        _fill(const Color(0xFF9FD4E6)),
      );
    });

    // Izba — log cabin
    _withOpacity(canvas, _op(25), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.30,
        y: 0.84,
        w: 0.36,
        d: 0.20,
        h: 0.24,
        front: const Color(0xFFB07238),
        side: const Color(0xFF8C5528),
        top: const Color(0xFF9A6030),
      );
    });
    _withOpacity(canvas, _op(27), () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            _pt(s, 0.38, 0.84).dx,
            _pt(s, 0.38, 0.78).dy,
            s.width * 0.10,
            s.height * 0.06,
          ),
          const Radius.circular(2),
        ),
        _fill(const Color(0xFF8A5A2A)),
      );
    });
    _withOpacity(canvas, _op(28), () {
      final w = s.width * 0.012;
      canvas.drawRect(
        Rect.fromCenter(
          center: _pt(s, 0.50, 0.68),
          width: s.width * 0.05,
          height: s.height * 0.04,
        ),
        _fill(const Color(0xFFA8D8E8)),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: _pt(s, 0.60, 0.68),
          width: s.width * 0.05,
          height: s.height * 0.04,
        ),
        _fill(const Color(0xFFA8D8E8)),
      );
      canvas.drawLine(
        _pt(s, 0.48, 0.68),
        _pt(s, 0.52, 0.68),
        _stroke(const Color(0xFF6A3A18), w),
      );
      canvas.drawLine(
        _pt(s, 0.58, 0.68),
        _pt(s, 0.62, 0.68),
        _stroke(const Color(0xFF6A3A18), w),
      );
    });
    _withOpacity(canvas, _op(29), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.30,
        y: 0.84,
        w: 0.36,
        d: 0.20,
        h: 0.24,
        front: const Color(0xFFE8D8C0),
        side: const Color(0xFFC8B498),
        top: const Color(0xFFD4C4A8),
      );
    });
    _withOpacity(canvas, _op(31), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.62,
        y: 0.84,
        w: 0.16,
        d: 0.12,
        h: 0.14,
        front: const Color(0xFFB07238),
        side: const Color(0xFF8C5528),
        top: const Color(0xFF9A6030),
      );
    });

    // House with stone base
    _withOpacity(canvas, _op(33), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.28,
        y: 0.86,
        w: 0.40,
        d: 0.18,
        h: 0.08,
        front: const Color(0xFF8A8680),
        side: const Color(0xFF6E6A64),
        top: const Color(0xFF7A7670),
      );
    });
    _withOpacity(canvas, _op(35), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.28,
        y: 0.78,
        w: 0.40,
        d: 0.22,
        h: 0.28,
        front: const Color(0xFFE6D2B0),
        side: const Color(0xFFC4B08C),
        top: const Color(0xFFD4C49C),
      );
    });
    _withOpacity(canvas, _op(36), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.34,
        y: 0.56,
        w: 0.28,
        d: 0.16,
        h: 0.10,
        front: const Color(0xFFE0CCAA),
        side: const Color(0xFFBCA888),
        top: const Color(0xFFD0BE96),
      );
    });
    _withOpacity(canvas, _op(37), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.64,
        y: 0.80,
        w: 0.16,
        d: 0.14,
        h: 0.18,
        front: const Color(0xFFE6D2B0),
        side: const Color(0xFFC4B08C),
        top: const Color(0xFFD4C49C),
      );
    });

    // Cottage two floors
    _withOpacity(canvas, _op(41), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.26,
        y: 0.82,
        w: 0.42,
        d: 0.24,
        h: 0.38,
        front: const Color(0xFFF0DCC0),
        side: const Color(0xFFC8B494),
        top: const Color(0xFFD8C8A4),
      );
    });
    _withOpacity(canvas, _op(42), () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: _pt(s, 0.48, 0.58),
            width: s.width * 0.16,
            height: s.height * 0.04,
          ),
          const Radius.circular(2),
        ),
        _fill(const Color(0xFF8A6840)),
      );
    });

    // Estate wings
    _withOpacity(canvas, _op(49), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.16,
        y: 0.82,
        w: 0.22,
        d: 0.16,
        h: 0.28,
        front: const Color(0xFFE8D4B4),
        side: const Color(0xFFC0AC8C),
        top: const Color(0xFFD4C29A),
      );
      _block(
        canvas: canvas,
        s: s,
        x: 0.58,
        y: 0.82,
        w: 0.22,
        d: 0.16,
        h: 0.28,
        front: const Color(0xFFE8D4B4),
        side: const Color(0xFFC0AC8C),
        top: const Color(0xFFD4C29A),
      );
      _block(
        canvas: canvas,
        s: s,
        x: 0.32,
        y: 0.82,
        w: 0.30,
        d: 0.20,
        h: 0.36,
        front: const Color(0xFFF2DEC0),
        side: const Color(0xFFC8B494),
        top: const Color(0xFFDCC8A4),
      );
    });
    _withOpacity(canvas, _op(50), () {
      canvas.drawPath(
        Path()
          ..moveTo(_pt(s, 0.40, 0.82).dx, _pt(s, 0.40, 0.82).dy)
          ..lineTo(_pt(s, 0.46, 0.74).dx, _pt(s, 0.46, 0.74).dy)
          ..lineTo(_pt(s, 0.56, 0.74).dx, _pt(s, 0.56, 0.74).dy)
          ..lineTo(_pt(s, 0.62, 0.82).dx, _pt(s, 0.62, 0.82).dy)
          ..close(),
        _fill(const Color(0xFFB8B0A4)),
      );
    });
    _withOpacity(canvas, _op(56), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.08,
        y: 0.84,
        w: 0.12,
        d: 0.10,
        h: 0.16,
        front: const Color(0xFFE0CCAA),
        side: const Color(0xFFBCA888),
        top: const Color(0xFFD0BE96),
      );
    });

    // Stone mansion
    _withOpacity(canvas, _op(57), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.18,
        y: 0.84,
        w: 0.58,
        d: 0.26,
        h: 0.40,
        front: const Color(0xFFC8C2B6),
        side: const Color(0xFFA8A298),
        top: const Color(0xFFB8B2A6),
      );
    });
    _withOpacity(canvas, _op(58), () {
      for (final x in [0.28, 0.40, 0.52, 0.64]) {
        canvas.drawRect(
          Rect.fromCenter(
            center: _pt(s, x, 0.78),
            width: s.width * 0.03,
            height: s.height * 0.16,
          ),
          _fill(const Color(0xFFD8D2C6)),
        );
      }
    });
    _withOpacity(canvas, _op(59), () {
      for (final x in [0.34, 0.46, 0.58]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: _pt(s, x, 0.62),
              width: s.width * 0.07,
              height: s.height * 0.08,
            ),
            const Radius.circular(2),
          ),
          _fill(const Color(0xFF9EC8DC)),
        );
      }
    });
    _withOpacity(canvas, _op(60), () {
      canvas.drawOval(
        Rect.fromCenter(
          center: _pt(s, 0.48, 0.40),
          width: s.width * 0.16,
          height: s.height * 0.10,
        ),
        _fill(const Color(0xFFC4B898)),
      );
    });
    _withOpacity(canvas, _op(63), () {
      canvas.drawCircle(
        _pt(s, 0.48, 0.54),
        s.width * 0.025,
        _fill(const Color(0xFFD4A84A)),
      );
    });
    _withOpacity(canvas, _op(64), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.12,
        y: 0.78,
        w: 0.14,
        d: 0.10,
        h: 0.12,
        front: const Color(0xFFC8C2B6),
        side: const Color(0xFFA8A298),
        top: const Color(0xFFB8B2A6),
      );
      _block(
        canvas: canvas,
        s: s,
        x: 0.70,
        y: 0.78,
        w: 0.14,
        d: 0.10,
        h: 0.12,
        front: const Color(0xFFC8C2B6),
        side: const Color(0xFFA8A298),
        top: const Color(0xFFB8B2A6),
      );
    });

    // Fortress / castle bodies
    _withOpacity(canvas, _op(65), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.16,
        y: 0.86,
        w: 0.62,
        d: 0.28,
        h: 0.36,
        front: const Color(0xFF9A968E),
        side: const Color(0xFF7A766E),
        top: const Color(0xFF8A8680),
      );
    });
    _withOpacity(canvas, _op(74), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.36,
        y: 0.78,
        w: 0.24,
        d: 0.18,
        h: 0.42,
        front: const Color(0xFFA8A49C),
        side: const Color(0xFF88847C),
        top: const Color(0xFF98948C),
      );
    });
    _withOpacity(canvas, _op(82), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.38,
        y: 0.74,
        w: 0.22,
        d: 0.16,
        h: 0.52,
        front: const Color(0xFFB0ACA4),
        side: const Color(0xFF908C84),
        top: const Color(0xFFA09C94),
      );
    });
    _withOpacity(canvas, _op(83), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.10,
        y: 0.84,
        w: 0.20,
        d: 0.14,
        h: 0.28,
        front: const Color(0xFF9A968E),
        side: const Color(0xFF7A766E),
        top: const Color(0xFF8A8680),
      );
      _block(
        canvas: canvas,
        s: s,
        x: 0.66,
        y: 0.84,
        w: 0.20,
        d: 0.14,
        h: 0.28,
        front: const Color(0xFF9A968E),
        side: const Color(0xFF7A766E),
        top: const Color(0xFF8A8680),
      );
    });
  }

  void _houseRoof(Canvas canvas, Size s) {
    _withOpacity(canvas, _op(12), () {
      _roof(
        canvas: canvas,
        s: s,
        x: 0.32,
        y: 0.66,
        w: 0.34,
        d: 0.16,
        h: 0.10,
        color: const Color(0xFF8A6A38),
        shade: const Color(0xFF6A4E28),
      );
    });
    _withOpacity(canvas, _op(11), () {
      canvas.drawRect(
        Rect.fromCenter(
          center: _pt(s, 0.58, 0.58),
          width: s.width * 0.04,
          height: s.height * 0.10,
        ),
        _fill(const Color(0xFF6A4A28)),
      );
    });
    _withOpacity(canvas, _op(19), () {
      canvas.drawRect(
        Rect.fromCenter(
          center: _pt(s, 0.58, 0.52),
          width: s.width * 0.045,
          height: s.height * 0.12,
        ),
        _fill(const Color(0xFF7A3A28)),
      );
    });
    _withOpacity(canvas, _op(26), () {
      _roof(
        canvas: canvas,
        s: s,
        x: 0.28,
        y: 0.60,
        w: 0.40,
        d: 0.20,
        h: 0.14,
        color: const Color(0xFFC8A050),
        shade: const Color(0xFFA08038),
      );
    });
    _withOpacity(canvas, _op(32), () {
      canvas.drawLine(
        _pt(s, 0.48, 0.46),
        _pt(s, 0.48, 0.40),
        _stroke(const Color(0xFF5A3A18), s.width * 0.01),
      );
    });
    _withOpacity(canvas, _op(34), () {
      _roof(
        canvas: canvas,
        s: s,
        x: 0.26,
        y: 0.50,
        w: 0.44,
        d: 0.22,
        h: 0.16,
        color: const Color(0xFFC45A3A),
        shade: const Color(0xFFA04428),
      );
    });
    _withOpacity(canvas, _op(47), () {
      canvas.drawLine(
        _pt(s, 0.48, 0.34),
        _pt(s, 0.48, 0.26),
        _stroke(const Color(0xFF4A4A4A), s.width * 0.01),
      );
      canvas.drawLine(
        _pt(s, 0.44, 0.28),
        _pt(s, 0.52, 0.28),
        _stroke(const Color(0xFF4A4A4A), s.width * 0.008),
      );
    });
    _withOpacity(canvas, _op(67), () {
      final y = _pt(s, 0.16, 0.50).dy;
      for (var i = 0; i < 8; i++) {
        final x = s.width * (0.18 + i * 0.08);
        canvas.drawRect(
          Rect.fromLTWH(x, y, s.width * 0.04, s.height * 0.04),
          _fill(const Color(0xFF8A8680)),
        );
      }
    });
    _withOpacity(canvas, _op(80), () {
      _roof(
        canvas: canvas,
        s: s,
        x: 0.20,
        y: 0.48,
        w: 0.52,
        d: 0.24,
        h: 0.14,
        color: const Color(0xFFB44A32),
        shade: const Color(0xFF8A3424),
      );
    });
    _withOpacity(canvas, _op(86), () {
      _roof(
        canvas: canvas,
        s: s,
        x: 0.36,
        y: 0.26,
        w: 0.26,
        d: 0.16,
        h: 0.12,
        color: const Color(0xFFD4A84A),
        shade: const Color(0xFFB08830),
      );
    });
    _withOpacity(canvas, _op(92), () {
      _roof(
        canvas: canvas,
        s: s,
        x: 0.18,
        y: 0.44,
        w: 0.56,
        d: 0.24,
        h: 0.10,
        color: const Color(0xFFE0B85A),
        shade: const Color(0xFFC09438),
      );
    });
    _withOpacity(canvas, _op(94), () {
      for (final x in [0.22, 0.48, 0.74]) {
        canvas.drawPath(
          Path()
            ..moveTo(_pt(s, x, 0.22).dx, _pt(s, x, 0.22).dy)
            ..lineTo(_pt(s, x - 0.03, 0.32).dx, _pt(s, x - 0.03, 0.32).dy)
            ..lineTo(_pt(s, x + 0.03, 0.32).dx, _pt(s, x + 0.03, 0.32).dy)
            ..close(),
          _fill(const Color(0xFFD8D0C4)),
        );
      }
    });
  }

  void _houseTowers(Canvas canvas, Size s) {
    _withOpacity(canvas, _op(66), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.12,
        y: 0.84,
        w: 0.12,
        d: 0.12,
        h: 0.40,
        front: const Color(0xFF8A8680),
        side: const Color(0xFF6A6660),
        top: const Color(0xFF7A7670),
      );
    });
    _withOpacity(canvas, _op(68), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.40,
        y: 0.86,
        w: 0.16,
        d: 0.12,
        h: 0.22,
        front: const Color(0xFF7A766E),
        side: const Color(0xFF5A564E),
        top: const Color(0xFF6A6660),
      );
    });
    _withOpacity(canvas, _op(69), () {
      _pole(canvas, s, 0.18, 0.44, 0.30, const Color(0xFF4A3020), 0.01);
      _flag(canvas, s, 0.18, 0.30, const Color(0xFFC43A3A));
    });
    _withOpacity(canvas, _op(72), () {
      for (final x in [0.30, 0.42, 0.54, 0.66]) {
        canvas.drawRect(
          Rect.fromCenter(
            center: _pt(s, x, 0.70),
            width: s.width * 0.02,
            height: s.height * 0.05,
          ),
          _fill(const Color(0xFF2A2824)),
        );
      }
    });
    _withOpacity(canvas, _op(73), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.72,
        y: 0.84,
        w: 0.12,
        d: 0.12,
        h: 0.40,
        front: const Color(0xFF8A8680),
        side: const Color(0xFF6A6660),
        top: const Color(0xFF7A7670),
      );
    });
    _withOpacity(canvas, _op(75), () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: _pt(s, 0.48, 0.82),
            width: s.width * 0.10,
            height: s.height * 0.12,
          ),
          const Radius.circular(2),
        ),
        _fill(const Color(0xFF2A241C)),
      );
    });
    _withOpacity(canvas, _op(77), () {
      _flag(canvas, s, 0.30, 0.36, const Color(0xFFC43A3A));
      _flag(canvas, s, 0.66, 0.36, const Color(0xFF3A5AA0));
    });
    _withOpacity(canvas, _op(78), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.62,
        y: 0.78,
        w: 0.12,
        d: 0.10,
        h: 0.18,
        front: const Color(0xFFD8D0C4),
        side: const Color(0xFFB8B0A4),
        top: const Color(0xFFC8C0B4),
      );
    });
    _withOpacity(canvas, _op(79), () {
      canvas.drawRect(
        Rect.fromCenter(
          center: _pt(s, 0.22, 0.48),
          width: s.width * 0.05,
          height: s.height * 0.08,
        ),
        _fill(const Color(0xFF9A968E)),
      );
    });
    _withOpacity(canvas, _op(81), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.08,
        y: 0.86,
        w: 0.10,
        d: 0.10,
        h: 0.34,
        front: const Color(0xFF8A8680),
        side: const Color(0xFF6A6660),
        top: const Color(0xFF7A7670),
      );
      _block(
        canvas: canvas,
        s: s,
        x: 0.78,
        y: 0.86,
        w: 0.10,
        d: 0.10,
        h: 0.34,
        front: const Color(0xFF8A8680),
        side: const Color(0xFF6A6660),
        top: const Color(0xFF7A7670),
      );
    });
    _withOpacity(canvas, _op(88), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.44,
        y: 0.70,
        w: 0.10,
        d: 0.10,
        h: 0.46,
        front: const Color(0xFFB8A878),
        side: const Color(0xFF988858),
        top: const Color(0xFFA89868),
      );
      _flag(canvas, s, 0.49, 0.18, const Color(0xFFD4A84A));
    });
    _withOpacity(canvas, _op(95), () {
      _pole(canvas, s, 0.50, 0.18, 0.08, const Color(0xFF4A3020), 0.012);
      _flag(canvas, s, 0.50, 0.08, const Color(0xFFE8C96A));
    });
  }

  void _houseYard(Canvas canvas, Size s) {
    _withOpacity(canvas, _op(14), () {
      canvas.drawLine(
        _pt(s, 0.16, 0.88),
        _pt(s, 0.16, 0.78),
        _stroke(const Color(0xFF6A4A28), s.width * 0.01),
      );
      canvas.drawLine(
        _pt(s, 0.20, 0.88),
        _pt(s, 0.20, 0.76),
        _stroke(const Color(0xFF6A4A28), s.width * 0.01),
      );
      canvas.drawLine(
        _pt(s, 0.16, 0.80),
        _pt(s, 0.20, 0.80),
        _stroke(const Color(0xFF6A4A28), s.width * 0.008),
      );
    });
    _withOpacity(canvas, _op(15), () {
      canvas.drawOval(
        Rect.fromCenter(
          center: _pt(s, 0.24, 0.86),
          width: s.width * 0.04,
          height: s.height * 0.03,
        ),
        _fill(const Color(0xFF5A6A70)),
      );
    });
    _withOpacity(canvas, _op(20), () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: _pt(s, 0.18, 0.90),
            width: s.width * 0.14,
            height: s.height * 0.05,
          ),
          const Radius.circular(2),
        ),
        _fill(const Color(0xFF4A7A38)),
      );
    });
    _withOpacity(canvas, _op(21), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.72,
        y: 0.88,
        w: 0.12,
        d: 0.08,
        h: 0.08,
        front: const Color(0xFF8A5A2A),
        side: const Color(0xFF6A4018),
        top: const Color(0xFF7A4A20),
      );
    });
    _withOpacity(canvas, _op(22), () {
      canvas.drawCircle(
        _pt(s, 0.78, 0.86),
        s.width * 0.035,
        _fill(const Color(0xFF8A8A88)),
      );
      canvas.drawCircle(
        _pt(s, 0.78, 0.86),
        s.width * 0.018,
        _fill(const Color(0xFF3A5070)),
      );
    });
    _withOpacity(canvas, _op(23), () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: _pt(s, 0.86, 0.84),
            width: s.width * 0.06,
            height: s.height * 0.08,
          ),
          const Radius.circular(1),
        ),
        _fill(const Color(0xFF6A4A28)),
      );
    });
    _withOpacity(canvas, _op(24), () {
      canvas.drawCircle(
        _pt(s, 0.30, 0.70),
        s.width * 0.018,
        _fill(const Color(0xFFE8C96A)),
      );
    });
    _withOpacity(canvas, _op(30), () {
      canvas.drawLine(
        _pt(s, 0.12, 0.90),
        _pt(s, 0.88, 0.90),
        _stroke(const Color(0xFF5A3A18), s.width * 0.012),
      );
    });
    _withOpacity(canvas, _op(38), () {
      canvas.drawLine(
        _pt(s, 0.10, 0.92),
        _pt(s, 0.90, 0.92),
        _stroke(const Color(0xFF7A7670), s.width * 0.02),
      );
    });
    _withOpacity(canvas, _op(39), () {
      canvas.drawRect(
        Rect.fromCenter(
          center: _pt(s, 0.50, 0.92),
          width: s.width * 0.08,
          height: s.height * 0.06,
        ),
        _fill(const Color(0xFF6A5A40)),
      );
    });
    _withOpacity(canvas, _op(40), () {
      canvas.drawCircle(
        _pt(s, 0.16, 0.78),
        s.width * 0.05,
        _fill(const Color(0xFF3A7A38)),
      );
      canvas.drawCircle(
        _pt(s, 0.84, 0.76),
        s.width * 0.045,
        _fill(const Color(0xFF2E6A30)),
      );
    });
    _withOpacity(canvas, _op(44), () {
      canvas.drawCircle(
        _pt(s, 0.12, 0.70),
        s.width * 0.07,
        _fill(const Color(0xFF2A6A28)),
      );
      canvas.drawCircle(
        _pt(s, 0.88, 0.68),
        s.width * 0.07,
        _fill(const Color(0xFF245A24)),
      );
    });
    _withOpacity(canvas, _op(45), () {
      canvas.drawLine(
        _pt(s, 0.50, 0.92),
        _pt(s, 0.50, 0.84),
        _stroke(const Color(0xFFA8A098), s.width * 0.03),
      );
    });
    _withOpacity(canvas, _op(46), () {
      canvas.drawCircle(
        _pt(s, 0.44, 0.88),
        s.width * 0.016,
        _fill(const Color(0xFFE8C96A)),
      );
      canvas.drawCircle(
        _pt(s, 0.56, 0.88),
        s.width * 0.016,
        _fill(const Color(0xFFE8C96A)),
      );
    });
    _withOpacity(canvas, _op(48), () {
      canvas.drawCircle(
        _pt(s, 0.22, 0.88),
        s.width * 0.02,
        _fill(const Color(0xFFD45A7A)),
      );
      canvas.drawCircle(
        _pt(s, 0.26, 0.90),
        s.width * 0.016,
        _fill(const Color(0xFFE8C44A)),
      );
    });
    _withOpacity(canvas, _op(51), () {
      for (final x in [0.14, 0.86]) {
        canvas.drawRect(
          Rect.fromCenter(
            center: _pt(s, x, 0.86),
            width: s.width * 0.04,
            height: s.height * 0.10,
          ),
          _fill(const Color(0xFFB8B0A4)),
        );
      }
    });
    _withOpacity(canvas, _op(53), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.02,
        y: 0.90,
        w: 0.12,
        d: 0.10,
        h: 0.12,
        front: const Color(0xFF8A6A44),
        side: const Color(0xFF6A4A2C),
        top: const Color(0xFF7A5A34),
      );
    });
    _withOpacity(canvas, _op(54), () {
      canvas.drawCircle(
        _pt(s, 0.48, 0.50),
        s.width * 0.03,
        _fill(const Color(0xFFD4A84A)),
      );
    });
    _withOpacity(canvas, _op(55), () {
      canvas.drawLine(
        _pt(s, 0.20, 0.94),
        _pt(s, 0.48, 0.84),
        _stroke(const Color(0xFF4A6A30), s.width * 0.04),
      );
    });
    _withOpacity(canvas, _op(61), () {
      canvas.drawCircle(
        _pt(s, 0.50, 0.90),
        s.width * 0.05,
        _fill(const Color(0xFF5AA0C4)),
      );
      canvas.drawCircle(
        _pt(s, 0.50, 0.90),
        s.width * 0.02,
        _fill(const Color(0xFFD8D8D4)),
      );
    });
    _withOpacity(canvas, _op(62), () {
      canvas.drawOval(
        Rect.fromCenter(
          center: _pt(s, 0.18, 0.92),
          width: s.width * 0.16,
          height: s.height * 0.05,
        ),
        _fill(const Color(0xFF3A8A3A)),
      );
    });
    _withOpacity(canvas, _op(71), () {
      canvas.drawOval(
        Rect.fromCenter(
          center: _pt(s, 0.50, 0.94),
          width: s.width * 0.70,
          height: s.height * 0.06,
        ),
        _fill(const Color(0xFF3A6A88)),
      );
    });
    _withOpacity(canvas, _op(76), () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: _pt(s, 0.48, 0.86),
            width: s.width * 0.22,
            height: s.height * 0.06,
          ),
          const Radius.circular(2),
        ),
        _fill(const Color(0xFFB8A070)),
      );
    });
    _withOpacity(canvas, _op(84), () {
      canvas.drawOval(
        Rect.fromCenter(
          center: _pt(s, 0.86, 0.78),
          width: s.width * 0.16,
          height: s.height * 0.10,
        ),
        _fill(const Color(0xFF2E6A34)),
      );
    });
    _withOpacity(canvas, _op(85), () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: _pt(s, 0.30, 0.88),
            width: s.width * 0.16,
            height: s.height * 0.05,
          ),
          const Radius.circular(2),
        ),
        _fill(const Color(0xFFC8B894)),
      );
    });
    _withOpacity(canvas, _op(87), () {
      canvas.drawLine(
        _pt(s, 0.72, 0.84),
        _pt(s, 0.86, 0.80),
        _stroke(const Color(0xFF8A8070), s.width * 0.02),
      );
    });
    _withOpacity(canvas, _op(89), () {
      for (var i = 0; i < 4; i++) {
        canvas.drawRect(
          Rect.fromCenter(
            center: _pt(s, 0.28 + i * 0.12, 0.94),
            width: s.width * 0.08,
            height: s.height * 0.03,
          ),
          _fill(i.isEven ? const Color(0xFF3A8A3A) : const Color(0xFFE8E0D0)),
        );
      }
    });
    _withOpacity(canvas, _op(90), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.78,
        y: 0.72,
        w: 0.14,
        d: 0.10,
        h: 0.12,
        front: const Color(0xFFB8D8C0),
        side: const Color(0xFF88B090),
        top: const Color(0xFF9EC8A4),
      );
    });
    _withOpacity(canvas, _op(91), () {
      canvas.drawOval(
        Rect.fromCenter(
          center: _pt(s, 0.20, 0.86),
          width: s.width * 0.18,
          height: s.height * 0.06,
        ),
        _fill(const Color(0xFF4A90B0)),
      );
    });
    _withOpacity(canvas, _op(96), () {
      canvas.drawCircle(
        _pt(s, 0.50, 0.48),
        s.width * 0.08,
        _fill(const Color(0x33E8C96A)),
      );
    });
  }

  void _houseLife(Canvas canvas, Size s) {
    final glow = (life * _op(93)).clamp(0.0, 1.0);
    if (glow > 0.05) {
      canvas.drawRect(
        Rect.fromCenter(
          center: _pt(s, 0.40, 0.62),
          width: s.width * 0.06,
          height: s.height * 0.06,
        ),
        _fill(Color.fromRGBO(255, 210, 120, 0.35 + 0.5 * glow)),
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: _pt(s, 0.56, 0.62),
          width: s.width * 0.06,
          height: s.height * 0.06,
        ),
        _fill(Color.fromRGBO(255, 210, 120, 0.35 + 0.5 * glow)),
      );
    }
    if (festival > 0.2 && stage >= 24) {
      canvas.drawCircle(
        _pt(s, 0.30, 0.36),
        s.width * 0.012,
        _fill(const Color(0xFFE85A5A)),
      );
      canvas.drawCircle(
        _pt(s, 0.70, 0.34),
        s.width * 0.012,
        _fill(const Color(0xFFE8C96A)),
      );
    }
  }

  // --- Pond ----------------------------------------------------------------

  void _paintPond(Canvas canvas, Size s) {
    if (stage < 0.05) return;
    _withOpacity(canvas, _op(1), () {
      _ellipse(canvas, s, 0.50, 0.62, 0.28, 0.12, const Color(0xFF6A5A38));
    });
    _withOpacity(canvas, _op(2), () {
      _ellipse(canvas, s, 0.50, 0.60, 0.22, 0.10, const Color(0xFF4A7A88));
    });
    _withOpacity(canvas, _op(5), () {
      _ellipse(canvas, s, 0.50, 0.60, 0.36, 0.16, const Color(0xFF3A6A7A));
    });
    _withOpacity(canvas, _op(9), () {
      _ellipse(canvas, s, 0.50, 0.58, 0.52, 0.22, const Color(0xFF2E6A80));
    });
    _withOpacity(canvas, _op(10), () {
      _ellipse(canvas, s, 0.50, 0.58, 0.44, 0.16, const Color(0xFF3A88A0));
    });
    for (final layer in [11, 12, 13, 14]) {
      _withOpacity(canvas, _op(layer), () {
        final i = layer - 11;
        canvas.drawLine(
          _pt(s, 0.22 + i * 0.08, 0.72),
          _pt(s, 0.20 + i * 0.08, 0.58),
          _stroke(const Color(0xFF3A6A30), s.width * 0.012),
        );
      });
    }
    _withOpacity(canvas, _op(17), () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: _pt(s, 0.32, 0.62),
            width: s.width * 0.28,
            height: s.height * 0.05,
          ),
          const Radius.circular(2),
        ),
        _fill(const Color(0xFF8A6A40)),
      );
    });
    _withOpacity(canvas, _op(21), () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: _pt(s, 0.32, 0.60),
            width: s.width * 0.32,
            height: s.height * 0.06,
          ),
          const Radius.circular(2),
        ),
        _fill(const Color(0xFFA08458)),
      );
    });
    _withOpacity(canvas, _op(25), () {
      canvas.drawCircle(
        _pt(s, 0.46, 0.58),
        s.width * 0.03,
        _fill(const Color(0xFFE07A3A)),
      );
      canvas.drawCircle(
        _pt(s, 0.58, 0.60),
        s.width * 0.025,
        _fill(const Color(0xFFE8C44A)),
      );
    });
    _withOpacity(canvas, _op(29), () {
      canvas.drawCircle(
        _pt(s, 0.40, 0.56),
        s.width * 0.022,
        _fill(const Color(0xFFD45A3A)),
      );
      canvas.drawCircle(
        _pt(s, 0.62, 0.54),
        s.width * 0.02,
        _fill(const Color(0xFFE8A03A)),
      );
    });
    _withOpacity(canvas, _op(33), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.62,
        y: 0.52,
        w: 0.18,
        d: 0.12,
        h: 0.12,
        front: const Color(0xFFD4C4A0),
        side: const Color(0xFFB0A080),
        top: const Color(0xFFC4B490),
      );
    });
    _withOpacity(canvas, _op(37), () {
      _roof(
        canvas: canvas,
        s: s,
        x: 0.60,
        y: 0.40,
        w: 0.22,
        d: 0.12,
        h: 0.10,
        color: const Color(0xFFC45A3A),
        shade: const Color(0xFFA04428),
      );
    });
    _withOpacity(canvas, _op(41), () {
      canvas.drawCircle(
        _pt(s, 0.28, 0.50),
        s.width * 0.04,
        _fill(const Color(0xFF3A8A3A)),
      );
      canvas.drawCircle(
        _pt(s, 0.72, 0.70),
        s.width * 0.035,
        _fill(const Color(0xFF2E6A30)),
      );
    });
    _withOpacity(canvas, _op(45), () {
      canvas.drawCircle(
        _pt(s, 0.44, 0.52),
        s.width * 0.03,
        _fill(const Color(0xFFE8E8E0)),
      );
      canvas.drawCircle(
        _pt(s, 0.56, 0.64),
        s.width * 0.025,
        _fill(const Color(0xFFE8E8E0)),
      );
    });
    _withOpacity(canvas, _op(49), () {
      canvas.drawArc(
        Rect.fromCenter(
          center: _pt(s, 0.50, 0.58),
          width: s.width * 0.62,
          height: s.height * 0.28,
        ),
        0.2,
        2.8,
        false,
        _stroke(const Color(0xFF8A8680), s.width * 0.03),
      );
    });
    _withOpacity(canvas, _op(53), () {
      canvas.drawCircle(
        _pt(s, 0.22, 0.58),
        s.width * 0.02,
        _fill(const Color(0xFFE8C96A)),
      );
      canvas.drawCircle(
        _pt(s, 0.78, 0.58),
        s.width * 0.02,
        _fill(const Color(0xFFE8C96A)),
      );
    });
    _withOpacity(canvas, _op(57), () {
      canvas.drawLine(
        _pt(s, 0.28, 0.70),
        _pt(s, 0.70, 0.48),
        _stroke(const Color(0xFF8A6A40), s.width * 0.03),
      );
    });
    _withOpacity(canvas, _op(61), () {
      canvas.drawLine(
        _pt(s, 0.28, 0.68),
        _pt(s, 0.70, 0.46),
        _stroke(const Color(0xFFB8B0A4), s.width * 0.04),
      );
    });
    _withOpacity(canvas, _op(65), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.18,
        y: 0.74,
        w: 0.10,
        d: 0.08,
        h: 0.10,
        front: const Color(0xFF9A968E),
        side: const Color(0xFF7A766E),
        top: const Color(0xFF8A8680),
      );
      _block(
        canvas: canvas,
        s: s,
        x: 0.72,
        y: 0.74,
        w: 0.10,
        d: 0.08,
        h: 0.10,
        front: const Color(0xFF9A968E),
        side: const Color(0xFF7A766E),
        top: const Color(0xFF8A8680),
      );
    });
    _withOpacity(canvas, _op(73), () {
      _ellipse(canvas, s, 0.50, 0.58, 0.70, 0.30, const Color(0xFF2A6880));
      _ellipse(canvas, s, 0.50, 0.58, 0.56, 0.22, const Color(0xFF3A88A0));
    });
    _withOpacity(canvas, _op(81), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.58,
        y: 0.48,
        w: 0.24,
        d: 0.16,
        h: 0.18,
        front: const Color(0xFFC8C2B6),
        side: const Color(0xFFA8A298),
        top: const Color(0xFFB8B2A6),
      );
    });
    _withOpacity(canvas, _op(89), () {
      canvas.drawCircle(
        _pt(s, 0.50, 0.58),
        s.width * 0.04,
        _fill(const Color(0xFFD4A84A)),
      );
    });
    _withOpacity(canvas, _op(96), () {
      canvas.drawCircle(
        _pt(s, 0.50, 0.50),
        s.width * 0.10,
        _fill(const Color(0x33E8C96A)),
      );
    });
    // Fill remaining pond stages with extra shore / fish / lanterns so each step shows.
    _pondExtras(canvas, s);
  }

  void _pondExtras(Canvas canvas, Size s) {
    for (var layer = 3; layer <= 96; layer++) {
      if (_op(layer) < 0.01) continue;
      if ({
        1,
        2,
        5,
        9,
        10,
        11,
        12,
        13,
        14,
        17,
        21,
        25,
        29,
        33,
        37,
        41,
        45,
        49,
        53,
        57,
        61,
        65,
        73,
        81,
        89,
        96,
      }.contains(layer)) {
        continue;
      }
      _withOpacity(canvas, _op(layer), () {
        final t = (layer % 8) / 8;
        final x = 0.30 + (layer % 5) * 0.10;
        final y = 0.48 + (layer % 3) * 0.08;
        if (layer < 24) {
          canvas.drawCircle(
            _pt(s, x, y + 0.2),
            s.width * (0.012 + t * 0.01),
            _fill(const Color(0xFF4A8A3A)),
          );
        } else if (layer < 48) {
          canvas.drawCircle(
            _pt(s, x, 0.58),
            s.width * 0.016,
            _fill(
              Color.lerp(const Color(0xFFE07A3A), const Color(0xFFE8C44A), t)!,
            ),
          );
        } else if (layer < 72) {
          canvas.drawCircle(
            _pt(s, x, 0.46),
            s.width * 0.012,
            _fill(const Color(0xFFE8C96A)),
          );
        } else {
          canvas.drawCircle(
            _pt(s, x, 0.70),
            s.width * 0.02,
            _fill(const Color(0xFF3A8A3A)),
          );
        }
      });
    }
  }

  // --- Pets ----------------------------------------------------------------

  void _paintPets(Canvas canvas, Size s) {
    if (stage < 0.05) return;
    _withOpacity(canvas, _op(1), () {
      _contactShadow(
        canvas,
        s,
        _pt(s, 0.50, 0.86),
        s.width * 0.28,
        s.height * 0.07,
      );
    });
    _withOpacity(canvas, _op(5), () {
      canvas.drawCircle(
        _pt(s, 0.38, 0.84),
        s.width * 0.028,
        _fill(const Color(0xFFD8C4A0)),
      );
      canvas.drawCircle(
        _pt(s, 0.46, 0.84),
        s.width * 0.022,
        _fill(const Color(0xFF7AA8C8)),
      );
    });
    _withOpacity(canvas, _op(9), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.36,
        y: 0.84,
        w: 0.22,
        d: 0.14,
        h: 0.14,
        front: const Color(0xFFB08958),
        side: const Color(0xFF8C6840),
        top: const Color(0xFF9A7040),
      );
    });
    _withOpacity(canvas, _op(17), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.32,
        y: 0.84,
        w: 0.34,
        d: 0.18,
        h: 0.22,
        front: const Color(0xFFC49A62),
        side: const Color(0xFF9A7344),
        top: const Color(0xFFA87C48),
      );
    });
    _withOpacity(canvas, _op(25), () {
      _roof(
        canvas: canvas,
        s: s,
        x: 0.30,
        y: 0.62,
        w: 0.38,
        d: 0.18,
        h: 0.12,
        color: const Color(0xFF5A8A3A),
        shade: const Color(0xFF3E6A28),
      );
    });
    _withOpacity(canvas, _op(33), () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: _pt(s, 0.42, 0.76),
            width: s.width * 0.07,
            height: s.height * 0.10,
          ),
          const Radius.circular(2),
        ),
        _fill(const Color(0xFF4A2C14)),
      );
    });
    _withOpacity(canvas, _op(41), () {
      canvas.drawCircle(
        _pt(s, 0.22, 0.86),
        s.width * 0.04,
        _fill(const Color(0xFFC8C4C0)),
      );
      canvas.drawCircle(
        _pt(s, 0.72, 0.86),
        s.width * 0.045,
        _fill(const Color(0xFFC08A48)),
      );
    });
    _withOpacity(canvas, _op(49), () {
      canvas.drawCircle(
        _pt(s, 0.78, 0.80),
        s.width * 0.035,
        _fill(const Color(0xFFD45A28)),
      );
    });
    _withOpacity(canvas, _op(57), () {
      canvas.drawLine(
        _pt(s, 0.16, 0.90),
        _pt(s, 0.84, 0.90),
        _stroke(const Color(0xFF6A4A28), s.width * 0.012),
      );
    });
    _withOpacity(canvas, _op(65), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.62,
        y: 0.84,
        w: 0.16,
        d: 0.12,
        h: 0.12,
        front: const Color(0xFFB08958),
        side: const Color(0xFF8C6840),
        top: const Color(0xFF9A7040),
      );
    });
    _withOpacity(canvas, _op(73), () {
      canvas.drawCircle(
        _pt(s, 0.28, 0.72),
        s.width * 0.05,
        _fill(const Color(0xFF2E6A30)),
      );
      canvas.drawCircle(
        _pt(s, 0.80, 0.70),
        s.width * 0.045,
        _fill(const Color(0xFF245A28)),
      );
    });
    _withOpacity(canvas, _op(81), () {
      canvas.drawCircle(
        _pt(s, 0.20, 0.78),
        s.width * 0.018,
        _fill(const Color(0xFFE8C96A)),
      );
      canvas.drawCircle(
        _pt(s, 0.84, 0.78),
        s.width * 0.018,
        _fill(const Color(0xFFE8C96A)),
      );
    });
    _withOpacity(canvas, _op(89), () {
      canvas.drawCircle(
        _pt(s, 0.50, 0.48),
        s.width * 0.06,
        _fill(const Color(0x33E8C96A)),
      );
    });
    _withOpacity(canvas, _op(96), () {
      canvas.drawCircle(
        _pt(s, 0.50, 0.50),
        s.width * 0.10,
        _fill(const Color(0x33E8C96A)),
      );
    });
  }

  // --- Internet ------------------------------------------------------------

  void _paintInternet(Canvas canvas, Size s) {
    if (stage < 0.05) return;
    _withOpacity(canvas, _op(1), () {
      _contactShadow(
        canvas,
        s,
        _pt(s, 0.50, 0.86),
        s.width * 0.20,
        s.height * 0.06,
      );
    });
    _withOpacity(canvas, _op(5), () {
      _pole(canvas, s, 0.42, 0.86, 0.36, const Color(0xFF5A4030), 0.025);
    });
    _withOpacity(canvas, _op(9), () {
      canvas.drawLine(
        _pt(s, 0.42, 0.40),
        _pt(s, 0.78, 0.52),
        _stroke(const Color(0xFF2A2A28), s.width * 0.01),
      );
    });
    _withOpacity(canvas, _op(13), () {
      canvas.drawLine(
        _pt(s, 0.42, 0.44),
        _pt(s, 0.18, 0.58),
        _stroke(const Color(0xFF2A2A28), s.width * 0.01),
      );
    });
    _withOpacity(canvas, _op(17), () {
      canvas.drawOval(
        Rect.fromCenter(
          center: _pt(s, 0.58, 0.48),
          width: s.width * 0.14,
          height: s.height * 0.10,
        ),
        _fill(const Color(0xFFC8C8C4)),
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: _pt(s, 0.58, 0.48),
          width: s.width * 0.08,
          height: s.height * 0.06,
        ),
        _fill(const Color(0xFF4A4A48)),
      );
    });
    _withOpacity(canvas, _op(25), () {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: _pt(s, 0.28, 0.70),
            width: s.width * 0.10,
            height: s.height * 0.08,
          ),
          const Radius.circular(2),
        ),
        _fill(const Color(0xFF3A4A5A)),
      );
    });
    _withOpacity(canvas, _op(33), () {
      canvas.drawCircle(
        _pt(s, 0.42, 0.38),
        s.width * 0.03,
        _fill(const Color(0xFFE8C96A)),
      );
    });
    _withOpacity(canvas, _op(41), () {
      canvas.drawCircle(
        _pt(s, 0.42, 0.34),
        s.width * 0.05,
        _fill(const Color(0x66A0D8E8)),
      );
    });
    _withOpacity(canvas, _op(49), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.46,
        y: 0.86,
        w: 0.14,
        d: 0.12,
        h: 0.28,
        front: const Color(0xFF8A8680),
        side: const Color(0xFF6A6660),
        top: const Color(0xFF7A7670),
      );
    });
    _withOpacity(canvas, _op(57), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.44,
        y: 0.86,
        w: 0.18,
        d: 0.14,
        h: 0.40,
        front: const Color(0xFF9A968E),
        side: const Color(0xFF7A766E),
        top: const Color(0xFF8A8680),
      );
    });
    _withOpacity(canvas, _op(65), () {
      canvas.drawOval(
        Rect.fromCenter(
          center: _pt(s, 0.54, 0.40),
          width: s.width * 0.22,
          height: s.height * 0.10,
        ),
        _fill(const Color(0xFFC8D0D8)),
      );
    });
    _withOpacity(canvas, _op(73), () {
      _block(
        canvas: canvas,
        s: s,
        x: 0.40,
        y: 0.86,
        w: 0.24,
        d: 0.16,
        h: 0.48,
        front: const Color(0xFFB8B8C4),
        side: const Color(0xFF9898A4),
        top: const Color(0xFFA8A8B4),
      );
    });
    _withOpacity(canvas, _op(81), () {
      canvas.drawCircle(
        _pt(s, 0.52, 0.28),
        s.width * 0.04,
        _fill(const Color(0xFFA8E0F0)),
      );
    });
    _withOpacity(canvas, _op(89), () {
      canvas.drawCircle(
        _pt(s, 0.52, 0.22),
        s.width * 0.06,
        _fill(const Color(0x66E8C96A)),
      );
      _pole(canvas, s, 0.52, 0.22, 0.12, const Color(0xFFD4A84A), 0.012);
    });
    _withOpacity(canvas, _op(96), () {
      canvas.drawCircle(
        _pt(s, 0.52, 0.40),
        s.width * 0.12,
        _fill(const Color(0x33A0D8E8)),
      );
    });
    _netExtras(canvas, s);
  }

  void _netExtras(Canvas canvas, Size s) {
    const major = {1, 5, 9, 13, 17, 25, 33, 41, 49, 57, 65, 73, 81, 89, 96};
    for (var layer = 2; layer <= 96; layer++) {
      if (major.contains(layer) || _op(layer) < 0.01) continue;
      _withOpacity(canvas, _op(layer), () {
        final x = 0.20 + (layer % 6) * 0.12;
        final y = 0.80 - (layer % 4) * 0.06;
        if (layer < 24) {
          canvas.drawCircle(
            _pt(s, x, y),
            s.width * 0.01,
            _fill(const Color(0xFF4A4A48)),
          );
        } else if (layer < 48) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: _pt(s, x, y),
                width: s.width * 0.05,
                height: s.height * 0.04,
              ),
              const Radius.circular(1),
            ),
            _fill(const Color(0xFF3A5A6A)),
          );
        } else if (layer < 72) {
          canvas.drawCircle(
            _pt(s, x, y - 0.1),
            s.width * 0.012,
            _fill(const Color(0xFFE8C96A)),
          );
        } else {
          canvas.drawCircle(
            _pt(s, x, 0.30),
            s.width * 0.018,
            _fill(const Color(0xFFA8E0F0)),
          );
        }
      });
    }
  }

  @override
  bool shouldRepaint(covariant LotBuildPainter oldDelegate) {
    return oldDelegate.kind != kind ||
        oldDelegate.stage != stage ||
        oldDelegate.life != life ||
        oldDelegate.festival != festival;
  }
}
