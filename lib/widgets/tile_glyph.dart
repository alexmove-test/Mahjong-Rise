import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Классические лица маджонга: path / circle / line / text по референсу.
class TileGlyph {
  TileGlyph._();

  static const navy = Color(0xFF1A3A68);
  static const bambooGreen = Color(0xFF1F8A4A);
  static const bambooRed = Color(0xFFC4282A);
  static const plumRed = Color(0xFFD4222A);
  static const plumYellow = Color(0xFFF0C42A);
  static const ringBlue = Color(0xFF1E4A8C);
  static const lampRed = Color(0xFFC41E24);
  static const spoolGreen = Color(0xFF2A9A48);

  static bool paints(String symbol) {
    final kind = kindOf(symbol);
    return kind != null && kind.suit != TileSuit.bonus;
  }

  static TileKind? kindOf(String symbol) {
    var s = symbol.toLowerCase();
    if (s.startsWith('set1-')) s = s.substring(5);
    switch (s) {
      case 'wind-east':
        return const TileKind(TileSuit.wind, 1);
      case 'wind-south':
        return const TileKind(TileSuit.wind, 2);
      case 'wind-west':
        return const TileKind(TileSuit.wind, 3);
      case 'wind-north':
        return const TileKind(TileSuit.wind, 4);
      case 'season-fall':
        return const TileKind(TileSuit.bonus, 1);
      case 'season-spring':
        return const TileKind(TileSuit.bonus, 2);
      case 'season-summer':
        return const TileKind(TileSuit.bonus, 3);
      case 'season-winter':
        return const TileKind(TileSuit.bonus, 4);
    }
    final match = RegExp(
      r'^(character|bamboo|dot|dots|dragon|wind|flower|season)-(\d+)$',
    ).firstMatch(s);
    if (match == null) return null;
    final rank = int.tryParse(match.group(2)!);
    if (rank == null) return null;
    switch (match.group(1)) {
      case 'character':
        return rank >= 1 && rank <= 9
            ? TileKind(TileSuit.character, rank)
            : null;
      case 'bamboo':
        return rank >= 1 && rank <= 9 ? TileKind(TileSuit.bamboo, rank) : null;
      case 'dot':
      case 'dots':
        return rank >= 1 && rank <= 9 ? TileKind(TileSuit.dots, rank) : null;
      case 'dragon':
        return rank >= 1 && rank <= 3 ? TileKind(TileSuit.dragon, rank) : null;
      case 'wind':
        return rank >= 1 && rank <= 4 ? TileKind(TileSuit.wind, rank) : null;
      case 'flower':
        return rank >= 1 && rank <= 4 ? TileKind(TileSuit.plum, rank) : null;
      case 'season':
        return rank >= 1 && rank <= 4 ? TileKind(TileSuit.bonus, rank) : null;
    }
    return null;
  }

  static void draw(
    Canvas canvas,
    Rect rect, {
    required String symbol,
    double opacity = 1,
  }) {
    if (rect.isEmpty) return;
    final kind = kindOf(symbol);
    if (kind == null || kind.suit == TileSuit.bonus) return;

    canvas.save();
    if (opacity < 0.999) {
      canvas.saveLayer(
        rect,
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    }

    switch (kind.suit) {
      case TileSuit.plum:
        _plum(canvas, rect, kind.rank);
      case TileSuit.bamboo:
        _bamboo(canvas, rect, kind.rank);
      case TileSuit.character:
        _character(canvas, rect, kind.rank);
      case TileSuit.dots:
        _dots(canvas, rect, kind.rank);
      case TileSuit.dragon:
        _dragon(canvas, rect, kind.rank);
      case TileSuit.wind:
        _text(
          canvas,
          rect,
          const ['東', '南', '西', '北'][kind.rank - 1],
          navy,
        );
      case TileSuit.bonus:
        break;
    }

    if (opacity < 0.999) canvas.restore();
    canvas.restore();
  }

  static void _plum(Canvas canvas, Rect rect, int variant) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final r = rect.shortestSide * 0.42;
    const palettes = [
      plumRed,
      Color(0xFFE85A8C),
      Color(0xFFC45A2A),
      Color(0xFFB42860),
    ];
    final petalColor = palettes[(variant - 1).clamp(0, 3)];
    final petal = Path()
      ..moveTo(0, -r)
      ..cubicTo(r * 0.58, -r * 0.72, r * 0.52, -r * 0.12, 0, r * 0.14)
      ..cubicTo(-r * 0.52, -r * 0.12, -r * 0.58, -r * 0.72, 0, -r)
      ..close();

    for (var i = 0; i < 5; i++) {
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(-math.pi / 2 + i * 2 * math.pi / 5);
      canvas.drawPath(petal, Paint()..color = petalColor);
      canvas.drawPath(
        petal,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, r * 0.055)
          ..color = const Color(0xFFFFF8F0),
      );
      canvas.restore();
    }
    canvas.drawCircle(Offset(cx, cy), r * 0.22, Paint()..color = plumYellow);
    canvas.drawCircle(
      Offset(cx, cy),
      r * 0.22,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.045)
        ..color = const Color(0xFFB8860A),
    );
  }

  static void _bamboo(Canvas canvas, Rect rect, int count) {
    final layout = _bambooLayout(count);
    final cols = layout.fold<int>(0, (m, p) => math.max(m, p.$1 + 1));
    final rows = layout.fold<int>(0, (m, p) => math.max(m, p.$2 + 1));
    final cellW = rect.width / cols;
    final cellH = rect.height / rows;
    for (final (c, r, red) in layout) {
      final slot = Rect.fromLTWH(
        rect.left + c * cellW + cellW * 0.12,
        rect.top + r * cellH + cellH * 0.06,
        cellW * 0.76,
        cellH * 0.88,
      );
      _bambooStick(canvas, slot, red ? bambooRed : bambooGreen);
    }
  }

  static List<(int col, int row, bool red)> _bambooLayout(int n) {
    switch (n) {
      case 1:
        return const [(0, 0, false)];
      case 2:
        return const [(0, 0, false), (1, 0, false)];
      case 3:
        return const [(0, 0, false), (1, 0, true), (2, 0, false)];
      case 4:
        return const [
          (0, 0, false),
          (1, 0, false),
          (0, 1, false),
          (1, 1, false),
        ];
      case 5:
        return const [
          (0, 0, false),
          (2, 0, false),
          (1, 1, true),
          (0, 2, false),
          (2, 2, false),
        ];
      case 6:
        return const [
          (0, 0, false),
          (1, 0, false),
          (0, 1, false),
          (1, 1, true),
          (0, 2, false),
          (1, 2, false),
        ];
      case 7:
        return const [
          (0, 0, false),
          (1, 0, false),
          (2, 0, false),
          (1, 1, true),
          (0, 2, false),
          (1, 2, false),
          (2, 2, false),
        ];
      case 8:
        return const [
          (0, 0, false),
          (1, 0, false),
          (0, 1, false),
          (1, 1, true),
          (0, 2, false),
          (1, 2, false),
          (0, 3, false),
          (1, 3, false),
        ];
      default:
        return const [
          (0, 0, false),
          (1, 0, true),
          (2, 0, false),
          (0, 1, false),
          (1, 1, true),
          (2, 1, false),
          (0, 2, false),
          (1, 2, true),
          (2, 2, false),
        ];
    }
  }

  static void _bambooStick(Canvas canvas, Rect slot, Color color) {
    final cx = slot.center.dx;
    final top = slot.top + slot.height * 0.04;
    final bot = slot.bottom - slot.height * 0.04;
    final w = slot.width * 0.42;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTRB(cx - w / 2, top, cx + w / 2, bot),
      Radius.circular(w * 0.48),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(Offset(cx - w, top), Offset(cx + w, bot), [
          Color.lerp(color, Colors.white, 0.22)!,
          color,
          Color.lerp(color, Colors.black, 0.18)!,
        ], const [0.0, 0.45, 1.0]),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, slot.width * 0.06)
        ..color = Color.lerp(color, Colors.black, 0.28)!,
    );
    final knot = Paint()
      ..color = Color.lerp(color, Colors.white, 0.45)!
      ..strokeWidth = math.max(1.1, slot.height * 0.045)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - w * 0.38, top + (bot - top) * 0.33),
      Offset(cx + w * 0.38, top + (bot - top) * 0.33),
      knot,
    );
    canvas.drawLine(
      Offset(cx - w * 0.38, top + (bot - top) * 0.66),
      Offset(cx + w * 0.38, top + (bot - top) * 0.66),
      knot,
    );
  }

  static const _chars = ['一', '二', '三', '四', '伍', '六', '七', '八', '九'];

  static void _character(Canvas canvas, Rect rect, int rank) {
    if (rank <= 3) {
      _wanStrokes(canvas, rect, rank);
      return;
    }
    _text(canvas, rect, _chars[rank - 1], navy);
  }

  static void _wanStrokes(Canvas canvas, Rect rect, int bars) {
    final paint = Paint()
      ..color = navy
      ..strokeWidth = math.max(2.4, rect.shortestSide * 0.14)
      ..strokeCap = StrokeCap.square;
    final left = rect.left + rect.width * 0.08;
    final right = rect.right - rect.width * 0.08;
    final span = rect.height * 0.46;
    final start = rect.center.dy - span / 2;
    final step = bars == 1 ? 0.0 : span / (bars - 1);
    for (var i = 0; i < bars; i++) {
      final y = bars == 1 ? rect.center.dy : start + i * step;
      canvas.drawLine(Offset(left, y), Offset(right, y), paint);
    }
  }

  static void _text(Canvas canvas, Rect rect, String char, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: char,
        style: TextStyle(
          color: color,
          fontSize: rect.shortestSide * 0.86,
          fontWeight: FontWeight.w800,
          height: 1.0,
          fontFamily: 'serif',
          fontFamilyFallback: const [
            'Noto Serif CJK SC',
            'Source Han Serif SC',
            'Songti SC',
            'STSong',
            'SimSun',
            'Microsoft YaHei',
            'PingFang SC',
            'Noto Sans SC',
            'Noto Sans CJK SC',
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: rect.width);
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }

  static void _dots(Canvas canvas, Rect rect, int count) {
    final spots = _dotLayout(count);
    final maxX = spots.fold<double>(0, (m, p) => math.max(m, p.$1));
    final maxY = spots.fold<double>(0, (m, p) => math.max(m, p.$2));
    final r = rect.shortestSide / (math.max(maxX, maxY) + 2.15) * 0.48;
    for (final (nx, ny, red) in spots) {
      final c = Offset(
        rect.left + rect.width * ((nx + 0.5) / (maxX + 1)),
        rect.top + rect.height * ((ny + 0.5) / (maxY + 1)),
      );
      _pip(canvas, c, r, red: red);
    }
  }

  static List<(double x, double y, bool red)> _dotLayout(int n) {
    switch (n) {
      case 1:
        return const [(0, 0, true)];
      case 2:
        return const [(0, 0, false), (1, 1, false)];
      case 3:
        return const [(0, 0, false), (1, 1, true), (2, 2, false)];
      case 4:
        return const [
          (0, 0, false),
          (1, 0, false),
          (0, 1, false),
          (1, 1, false),
        ];
      case 5:
        return const [
          (0, 0, false),
          (2, 0, false),
          (1, 1, true),
          (0, 2, false),
          (2, 2, false),
        ];
      case 6:
        return const [
          (0, 0, false),
          (1, 0, false),
          (0, 1, true),
          (1, 1, true),
          (0, 2, false),
          (1, 2, false),
        ];
      case 7:
        return const [
          (0, 0, false),
          (1, 0, false),
          (2, 0, false),
          (1, 1, true),
          (0, 2, false),
          (1, 2, false),
          (2, 2, false),
        ];
      case 8:
        return const [
          (0, 0, false),
          (1, 0, false),
          (0, 1, false),
          (1, 1, true),
          (0, 2, true),
          (1, 2, false),
          (0, 3, false),
          (1, 3, false),
        ];
      default:
        return const [
          (0, 0, false),
          (1, 0, false),
          (2, 0, false),
          (0, 1, false),
          (1, 1, true),
          (2, 1, false),
          (0, 2, false),
          (1, 2, false),
          (2, 2, false),
        ];
    }
  }

  static void _pip(Canvas canvas, Offset c, double r, {required bool red}) {
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFE8EEF6));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.6, r * 0.34)
        ..color = ringBlue,
    );
    canvas.drawCircle(
      c,
      r * 0.38,
      Paint()..color = red ? bambooRed : ringBlue,
    );
  }

  static void _dragon(Canvas canvas, Rect rect, int rank) {
    switch (rank) {
      case 1:
        _lamp(canvas, rect);
      case 2:
        _spool(canvas, rect);
      default:
        _eye(canvas, rect);
    }
  }

  static void _eye(Canvas canvas, Rect rect) {
    final c = rect.center;
    final r = rect.shortestSide * 0.40;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFE8F0FA));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.18
        ..color = ringBlue,
    );
    canvas.drawCircle(c, r * 0.62, Paint()..color = const Color(0xFF3A6FB0));
    canvas.drawCircle(c, r * 0.34, Paint()..color = bambooRed);
    canvas.drawCircle(c, r * 0.16, Paint()..color = const Color(0xFF1A1020));
    canvas.drawCircle(
      c + Offset(-r * 0.16, -r * 0.18),
      r * 0.10,
      Paint()..color = Colors.white,
    );
  }

  static void _lamp(Canvas canvas, Rect rect) {
    final cx = rect.center.dx;
    final w = rect.width;
    final h = rect.height;
    final paint = Paint()..color = lampRed;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, rect.top + h * 0.86),
          width: w * 0.42,
          height: h * 0.10,
        ),
        Radius.circular(w * 0.04),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(cx, rect.top + h * 0.78),
      Offset(cx + w * 0.10, rect.top + h * 0.42),
      Paint()
        ..color = lampRed
        ..strokeWidth = w * 0.08
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(cx + w * 0.10, rect.top + h * 0.42),
      Offset(cx - w * 0.02, rect.top + h * 0.28),
      Paint()
        ..color = lampRed
        ..strokeWidth = w * 0.08
        ..strokeCap = StrokeCap.round,
    );
    final shade = Path()
      ..moveTo(cx - w * 0.28, rect.top + h * 0.28)
      ..lineTo(cx + w * 0.22, rect.top + h * 0.22)
      ..lineTo(cx + w * 0.12, rect.top + h * 0.08)
      ..lineTo(cx - w * 0.18, rect.top + h * 0.12)
      ..close();
    canvas.drawPath(shade, paint);
  }

  static void _spool(Canvas canvas, Rect rect) {
    final cx = rect.center.dx;
    final cy = rect.center.dy;
    final w = rect.width * 0.62;
    final h = rect.height * 0.70;
    final paint = Paint()..color = spoolGreen;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy - h * 0.38),
          width: w,
          height: h * 0.22,
        ),
        Radius.circular(h * 0.08),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy + h * 0.38),
          width: w,
          height: h * 0.22,
        ),
        Radius.circular(h * 0.08),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: w * 0.34,
          height: h * 0.72,
        ),
        Radius.circular(w * 0.06),
      ),
      paint,
    );
  }
}

enum TileSuit { character, bamboo, dots, dragon, wind, plum, bonus }

class TileKind {
  const TileKind(this.suit, this.rank);

  final TileSuit suit;
  final int rank;
}
