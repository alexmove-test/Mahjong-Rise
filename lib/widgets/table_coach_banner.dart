import 'package:flutter/material.dart';

/// Короткая подсказка на сукне: не перекрывает тапы по плиткам.
class TableCoachBanner extends StatelessWidget {
  const TableCoachBanner({super.key, required this.text});

  final String text;

  static const _gold = Color(0xFFD4AF37);
  static const _ivory = Color(0xFFF8F1DE);
  static const _wood = Color(0xE63A2012);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _wood,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _gold.withValues(alpha: 0.78), width: 1.3),
          boxShadow: const [
            BoxShadow(
              color: Color(0x88000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ivory,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.25,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}
