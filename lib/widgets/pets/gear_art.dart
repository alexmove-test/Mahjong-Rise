import 'package:flutter/material.dart';

import '../../models/pet_combat.dart';

const gearGold = Color(0xFFD4AF37);
const gearIvory = Color(0xFFF8F1DE);
const gearWood = Color(0xFF3A2012);

/// Предмет экипировки, нарисованный в палитре двора. Отдельного файла картинки нет.
class GearArt extends StatelessWidget {
  const GearArt({super.key, required this.def, this.size = 46});

  final GearDef def;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GearPainter(def: def),
      ),
    );
  }
}

class _GearPainter extends CustomPainter {
  const _GearPainter({required this.def});

  final GearDef def;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final attack = def.role == PetRole.attacker;
    final fill = Paint()
      ..color = attack ? const Color(0xFF8C3A2F) : const Color(0xFF2F5C45);
    final trim = Paint()
      ..color = gearGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.045;
    final plate = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: side * 0.78,
        height: side * 0.62,
      ),
      Radius.circular(side * 0.16),
    );
    canvas.drawRRect(plate, fill);
    canvas.drawRRect(plate, trim);
    final mark = Paint()..color = gearIvory;
    if (def.slot == GearSlot.main) {
      if (attack) {
        final path = Path()
          ..moveTo(center.dx, center.dy - side * 0.16)
          ..lineTo(center.dx + side * 0.14, center.dy + side * 0.12)
          ..lineTo(center.dx - side * 0.14, center.dy + side * 0.12)
          ..close();
        canvas.drawPath(path, mark);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center,
              width: side * 0.34,
              height: side * 0.28,
            ),
            Radius.circular(side * 0.06),
          ),
          mark,
        );
      }
    } else if (attack) {
      canvas.drawCircle(center, side * 0.1, mark);
    } else {
      canvas.drawCircle(center, side * 0.12, Paint()..color = gearGold);
      canvas.drawCircle(center, side * 0.05, mark);
    }
    final pip = Paint()..color = gearGold;
    for (var i = 0; i < def.rank; i++) {
      canvas.drawCircle(
        Offset(center.dx - side * 0.16 + i * side * 0.16, center.dy + side * 0.22),
        side * 0.035,
        pip,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GearPainter oldDelegate) =>
      oldDelegate.def.id != def.id;
}
