import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/seed_catalog.dart';

/// Рисованный знак семени в палитре двора. Вид читается по силуэту.
class SeedGlyph extends StatelessWidget {
  const SeedGlyph({
    super.key,
    required this.size,
    this.species,
    this.unknown = false,
  });

  final double size;
  final SeedSpecies? species;
  final bool unknown;

  @override
  Widget build(BuildContext context) {
    final kind = unknown ? null : species;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        key: ValueKey(
          unknown ? 'seed-glyph-unknown' : 'seed-glyph-${kind?.name}',
        ),
        painter: _SeedMarkPainter(
          species: kind,
          unknown: unknown || kind == null,
        ),
      ),
    );
  }
}

class _SeedMarkPainter extends CustomPainter {
  const _SeedMarkPainter({required this.species, required this.unknown});

  final SeedSpecies? species;
  final bool unknown;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = side * 0.46;
    final disc = Paint()..color = const Color(0xFF3A2012);
    canvas.drawCircle(center, radius, disc);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side * 0.06
        ..color = const Color(0xFFE8C96A),
    );
    if (unknown || species == null) {
      _jar(canvas, center, side);
      return;
    }
    switch (species!) {
      case SeedSpecies.amberbell:
        _bell(
          canvas,
          center,
          side,
          const Color(0xFFE2A53A),
          const Color(0xFFFFF1C9),
        );
      case SeedSpecies.mistfern:
        _fern(
          canvas,
          center,
          side,
          const Color(0xFFB7E0C2),
          const Color(0xFF2F5C45),
        );
      case SeedSpecies.glassreed:
        _reeds(
          canvas,
          center,
          side,
          const Color(0xFFD7F4FB),
          const Color(0xFF1E6C7C),
        );
      case SeedSpecies.crimsonplum:
        _plum(
          canvas,
          center,
          side,
          const Color(0xFFB44A55),
          const Color(0xFFFFE4E0),
        );
      case SeedSpecies.nightlotus:
        _lotus(
          canvas,
          center,
          side,
          const Color(0xFFC9B6F2),
          const Color(0xFF3A2A66),
        );
      case SeedSpecies.starbamboo:
        _bamboo(
          canvas,
          center,
          side,
          const Color(0xFF7DDEBE),
          const Color(0xFFFFE7A3),
        );
    }
  }

  void _jar(Canvas canvas, Offset center, double side) {
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center.translate(0, side * 0.04),
        width: side * 0.42,
        height: side * 0.46,
      ),
      Radius.circular(side * 0.08),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFC4A574));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: center.translate(0, -side * 0.22),
          width: side * 0.48,
          height: side * 0.12,
        ),
        Radius.circular(side * 0.04),
      ),
      Paint()..color = const Color(0xFFE8C96A),
    );
  }

  void _bell(
    Canvas canvas,
    Offset center,
    double side,
    Color body,
    Color light,
  ) {
    final path = Path()
      ..moveTo(center.dx, center.dy - side * 0.24)
      ..quadraticBezierTo(
        center.dx + side * 0.28,
        center.dy,
        center.dx + side * 0.2,
        center.dy + side * 0.22,
      )
      ..lineTo(center.dx - side * 0.2, center.dy + side * 0.22)
      ..quadraticBezierTo(
        center.dx - side * 0.28,
        center.dy,
        center.dx,
        center.dy - side * 0.24,
      );
    canvas.drawPath(path, Paint()..color = body);
    canvas.drawCircle(
      center.translate(0, side * 0.16),
      side * 0.05,
      Paint()..color = light,
    );
  }

  void _fern(
    Canvas canvas,
    Offset center,
    double side,
    Color leaf,
    Color stem,
  ) {
    final paint = Paint()
      ..color = leaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.045
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center.translate(0, side * 0.22),
      center.translate(0, -side * 0.24),
      Paint()
        ..color = stem
        ..strokeWidth = side * 0.04
        ..strokeCap = StrokeCap.round,
    );
    for (final dy in [-0.08, 0.02, 0.12]) {
      canvas.drawLine(
        center.translate(0, side * dy),
        center.translate(side * 0.16, side * (dy - 0.08)),
        paint,
      );
      canvas.drawLine(
        center.translate(0, side * dy),
        center.translate(-side * 0.16, side * (dy - 0.08)),
        paint,
      );
    }
  }

  void _reeds(
    Canvas canvas,
    Offset center,
    double side,
    Color glass,
    Color line,
  ) {
    final paint = Paint()
      ..color = glass
      ..strokeWidth = side * 0.055
      ..strokeCap = StrokeCap.round;
    for (final dx in [-0.12, 0.0, 0.12]) {
      canvas.drawLine(
        center.translate(side * dx, side * 0.22),
        center.translate(side * dx * 0.4, -side * 0.24),
        paint,
      );
    }
    canvas.drawCircle(
      center.translate(0, -side * 0.02),
      side * 0.06,
      Paint()..color = line.withValues(alpha: 0.85),
    );
  }

  void _plum(
    Canvas canvas,
    Offset center,
    double side,
    Color fruit,
    Color shine,
  ) {
    canvas.drawCircle(center, side * 0.22, Paint()..color = fruit);
    canvas.drawCircle(
      center.translate(-side * 0.06, -side * 0.06),
      side * 0.06,
      Paint()..color = shine,
    );
    canvas.drawLine(
      center.translate(0, -side * 0.2),
      center.translate(side * 0.08, -side * 0.3),
      Paint()
        ..color = const Color(0xFF2F5C45)
        ..strokeWidth = side * 0.035
        ..strokeCap = StrokeCap.round,
    );
  }

  void _lotus(
    Canvas canvas,
    Offset center,
    double side,
    Color petal,
    Color heart,
  ) {
    final paint = Paint()..color = petal;
    for (var i = 0; i < 6; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * 3.14159 / 3);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -side * 0.12),
          width: side * 0.12,
          height: side * 0.28,
        ),
        paint,
      );
      canvas.restore();
    }
    canvas.drawCircle(center, side * 0.07, Paint()..color = heart);
  }

  void _bamboo(
    Canvas canvas,
    Offset center,
    double side,
    Color cane,
    Color star,
  ) {
    final paint = Paint()..color = cane;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: side * 0.16, height: side * 0.5),
      Radius.circular(side * 0.08),
    );
    canvas.drawRRect(rect, paint);
    final band = Paint()..color = const Color(0xFF14382F);
    for (final dy in [-0.12, 0.02, 0.16]) {
      canvas.drawLine(
        center.translate(-side * 0.08, side * dy),
        center.translate(side * 0.08, side * dy),
        band..strokeWidth = side * 0.025,
      );
    }
    _star(
      canvas,
      center.translate(side * 0.16, -side * 0.16),
      side * 0.08,
      star,
    );
  }

  void _star(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final spike = i.isEven ? radius : radius * 0.42;
      final angle = -math.pi / 2 + i * math.pi / 4;
      final point =
          center + Offset(spike * math.cos(angle), spike * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SeedMarkPainter oldDelegate) =>
      oldDelegate.species != species || oldDelegate.unknown != unknown;
}
