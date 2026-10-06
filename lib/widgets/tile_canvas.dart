import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'table_theme.dart';
import 'tile_glyph.dart';

/// Canvas-отрисовка кости по референсу: белое лицо, серая толщина,
/// коричневый кант, мягкая тень вниз-вправо, опциональный цветочный мотив.
class TileCanvas {
  TileCanvas._();

  /// Радиус скругления: 12% ширины плитки.
  static const cornerRadiusFactor = 0.12;

  /// Правая и нижняя боковины по кремовой грани `tile_base.png`.
  static const faceInsetRight = 0.07;
  static const faceInsetBottom = 0.078;

  /// Поля символа внутри грани. Окно вписывается в 3:4 — как [TileFaceArt].
  ///
  /// 14% — как до сжатия под 3:4: квадратные SVG (фрукты 80×88) не садятся
  /// на коричневый кант. Глифы маджонга остаются портретными.
  static const symbolInset = 0.14;
  static const symbolInsetX = symbolInset;
  static const symbolInsetTop = symbolInset;
  static const symbolInsetBottom = symbolInset;

  /// Толщина коричневого бордюра относительно ширины.
  static const strokeWidthFactor = 0.014;
  static const strokeWidthMin = 1.0;

  /// Тень вниз-вправо при опорной ширине 80.
  static const shadowOffsetXFactor = 0.055;
  static const shadowOffsetYFactor = 0.065;
  static const shadowBlurFactor = 0.055;
  static const shadowOpacity = 0.34;

  /// Символ занимает ~72% ширины белой грани (поля [symbolInset]).
  static const symbolFaceFraction = 1 - symbolInset * 2;

  static const faceWhite = Color(0xFFFEFDF9);
  static const faceWhiteLo = Color(0xFFF3EEE6);
  static const sideHi = Color(0xFFD5D0C6);
  static const sideMid = Color(0xFFC4BDB2);
  static const sideLo = Color(0xFFA89F92);
  static const strokeBrown = Color(0xFF5C3824);
  static const innerEdge = Color(0xFFD8D2C6);
  static const shadowColor = Color(0xFF1A120C);

  static const selectedFace = Color(0xFF3FCC14);
  static const selectedFaceLo = Color(0xFF32B10C);
  static const selectedSideHi = Color(0xFF2C9A12);
  static const selectedSideLo = Color(0xFF1E6E0A);
  static const selectedStroke = Color(0xFF16580A);

  static const specialTop = Color(0xFFD2C2EE);
  static const specialBottom = Color(0xFF8E6EBE);
  static const specialSideHi = Color(0xFFB09AD4);
  static const specialSideLo = Color(0xFF6E4E9A);

  // Тема «Новая» (premium): фарфоровая кость, тёплый торец, плотная тень.
  static const premiumFaceHi = Color(0xFFFFFEFA);
  static const premiumFaceLo = Color(0xFFF8F3E3);
  static const premiumFaceLocked = Color(0xFFE9E2D2);
  static const premiumFaceLockedLo = Color(0xFFD8CFBA);
  static const premiumSideHi = Color(0xFFEEE1C0);
  static const premiumSideMid = Color(0xFFCBAE78);
  static const premiumSideLo = Color(0xFF8C6B3C);
  static const premiumStroke = Color(0xFF6B3A20);
  static const premiumInnerEdge = Color(0xFFFFFBEF);
  static const premiumShadowColor = Color(0xFF200E04);

  static bool isSpecialSymbol(String symbol) {
    final id = symbol.toLowerCase();
    return id.contains('season');
  }

  static double cornerRadius(Size size) => size.width * cornerRadiusFactor;

  static Rect faceRectOf(Size size) {
    return Rect.fromLTWH(
      0,
      0,
      size.width * (1 - faceInsetRight),
      size.height * (1 - faceInsetBottom),
    );
  }

  static Rect symbolRectOf(Size size) {
    final face = faceRectOf(size);
    final padded = Rect.fromLTRB(
      face.left + face.width * symbolInsetX,
      face.top + face.height * symbolInsetTop,
      face.right - face.width * symbolInsetX,
      face.bottom - face.height * symbolInsetBottom,
    );
    return rectWithAspect(padded, TileFaceArt.widthOverHeight);
  }

  /// Радиус скругления кремовой грани (чуть меньше тела).
  static double faceCornerRadius(Size size) => cornerRadius(size) * 0.92;

  /// Угол [point] лежит внутри скруглённой кремовой грани.
  static bool containsFacePoint(Size size, Offset point) {
    return roundedRectContains(faceRectOf(size), faceCornerRadius(size), point);
  }

  /// Всё тело кости, включая боковину. Пустые углы скругления — нет.
  static bool containsBodyPoint(Size size, Offset point) {
    return roundedRectContains(Offset.zero & size, cornerRadius(size), point);
  }

  /// Прямоугольник заданного width/height внутри [box], по центру.
  static Rect rectWithAspect(Rect box, double widthOverHeight) {
    if (box.isEmpty || widthOverHeight <= 0) return box;
    final boxAspect = box.width / box.height;
    if (boxAspect > widthOverHeight) {
      final width = box.height * widthOverHeight;
      return Rect.fromCenter(
        center: box.center,
        width: width,
        height: box.height,
      );
    }
    final height = box.width / widthOverHeight;
    return Rect.fromCenter(
      center: box.center,
      width: box.width,
      height: height,
    );
  }

  /// Рисует плитку: тень → тело → лицо → кант → мотив (если special).
  static void drawTile(
    Canvas canvas,
    Size size, {
    bool isSpecial = false,
    bool isSelected = false,
    bool locked = false,
    bool lifted = false,
    bool drawShadow = false,
    int specialSeed = 0,
    String? symbol,
  }) {
    if (size.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final face = faceRectOf(size);
    final radius = cornerRadius(size);
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final faceRRect = RRect.fromRectAndRadius(
      face,
      Radius.circular(radius * 0.92),
    );
    final strokeW = math.max(strokeWidthMin, w * strokeWidthFactor);

    if (drawShadow) {
      _drawDropShadow(canvas, body, w, h, locked: locked, lifted: lifted);
    }

    _drawBody(
      canvas,
      size: size,
      body: body,
      face: face,
      isSelected: isSelected,
      isSpecial: isSpecial,
      locked: locked,
    );

    _drawFace(
      canvas,
      face: face,
      faceRRect: faceRRect,
      isSelected: isSelected,
      isSpecial: isSpecial,
      locked: locked,
      lifted: lifted,
    );

    drawOverlayArt(
      canvas,
      size,
      isSpecial: isSpecial,
      isSelected: isSelected,
      locked: locked,
      specialSeed: specialSeed,
      symbol: symbol,
    );

    canvas.drawRRect(
      faceRRect.deflate(0.7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9
        ..color =
            (isSelected
                    ? Colors.white
                    : isSpecial
                    ? const Color(0xFFE8DCF8)
                    : innerEdge)
                .withValues(alpha: locked ? 0.28 : (isSelected ? 0.35 : 0.55)),
    );

    canvas.drawRRect(
      body.deflate(strokeW * 0.35),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..color = (isSelected ? selectedStroke : strokeBrown).withValues(
          alpha: locked ? 0.55 : 0.88,
        ),
    );
  }

  /// Символ / сезонный мотив поверх тела кости (PNG или Canvas).
  static void drawOverlayArt(
    Canvas canvas,
    Size size, {
    bool isSpecial = false,
    bool isSelected = false,
    bool locked = false,
    bool casual = false,
    bool premium = false,
    int specialSeed = 0,
    String? symbol,
  }) {
    final face = premium
        ? PremiumTileLayout.faceRectOf(size)
        : (casual ? CasualTileLayout.faceRectOf(size) : faceRectOf(size));
    if (face.isEmpty) return;
    final radius = premium
        ? PremiumTileLayout.cornerRadius(size)
        : (casual ? CasualTileLayout.cornerRadius(size) : cornerRadius(size));
    final faceRRect = RRect.fromRectAndRadius(
      face,
      Radius.circular(radius * 0.92),
    );
    final symbolRect = premium
        ? PremiumTileLayout.symbolRectOf(size)
        : (casual ? CasualTileLayout.symbolRectOf(size) : symbolRectOf(size));

    if (isSpecial && !isSelected) {
      canvas.save();
      canvas.clipRRect(faceRRect);
      _drawSpecialMotif(canvas, face, specialSeed);
      canvas.restore();
    } else if (symbol != null && TileGlyph.paints(symbol)) {
      canvas.save();
      canvas.clipRRect(faceRRect);
      TileGlyph.draw(
        canvas,
        symbolRect,
        symbol: symbol,
        opacity: locked ? (premium ? 0.90 : (casual ? 0.72 : 0.78)) : 1.0,
        premium: premium,
      );
      canvas.restore();
    }
  }

  static void _drawDropShadow(
    Canvas canvas,
    RRect body,
    double w,
    double h, {
    required bool locked,
    required bool lifted,
  }) {
    final dx = w * shadowOffsetXFactor;
    final dy = h * shadowOffsetYFactor;
    final blur = w * shadowBlurFactor;
    final opacity =
        shadowOpacity * (locked ? 0.82 : 1.0) * (lifted ? 1.12 : 1.0);
    final paint = Paint()
      ..color = shadowColor.withValues(alpha: opacity.clamp(0.12, 0.55));
    if (!kIsWeb && blur > 0.35) {
      paint.maskFilter = ui.MaskFilter.blur(BlurStyle.normal, blur);
    }
    canvas.drawRRect(body.shift(Offset(dx, dy)), paint);
  }

  static void _drawBody(
    Canvas canvas, {
    required Size size,
    required RRect body,
    required Rect face,
    required bool isSelected,
    required bool isSpecial,
    required bool locked,
  }) {
    final w = size.width;
    final h = size.height;
    Color hi;
    Color mid;
    Color lo;
    if (isSelected) {
      hi = selectedSideHi;
      mid = selectedSideLo;
      lo = const Color(0xFF164F08);
    } else if (isSpecial) {
      hi = specialSideHi;
      mid = const Color(0xFF8A6AB0);
      lo = specialSideLo;
    } else {
      hi = sideHi;
      mid = sideMid;
      lo = sideLo;
    }
    if (locked) {
      hi = Color.lerp(hi, const Color(0xFF3D4A40), 0.28)!;
      mid = Color.lerp(mid, const Color(0xFF2C382F), 0.32)!;
      lo = Color.lerp(lo, const Color(0xFF1E2822), 0.36)!;
    }

    canvas.drawRRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.35, 0),
          Offset(w, h),
          [hi, mid, lo],
          const [0.0, 0.48, 1.0],
        ),
    );

    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(
      Rect.fromLTRB(face.right - 0.4, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(face.right, face.top),
          Offset(w, face.top),
          [mid.withValues(alpha: 0.12), lo.withValues(alpha: 0.55)],
        ),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, face.bottom - 0.4, w, h),
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, face.bottom), Offset(0, h), [
          mid.withValues(alpha: 0.08),
          lo.withValues(alpha: 0.72),
        ]),
    );
    canvas.restore();
  }

  static void _drawFace(
    Canvas canvas, {
    required Rect face,
    required RRect faceRRect,
    required bool isSelected,
    required bool isSpecial,
    required bool locked,
    required bool lifted,
  }) {
    final Color hi;
    final Color lo;
    if (isSelected) {
      hi = selectedFace;
      lo = selectedFaceLo;
    } else if (isSpecial) {
      hi = specialTop;
      lo = specialBottom;
    } else {
      hi = lifted ? const Color(0xFFFFFFF8) : faceWhite;
      lo = faceWhiteLo;
    }

    var top = hi;
    var bottom = lo;
    if (locked && !isSelected) {
      top = Color.lerp(top, const Color(0xFFC5C8C0), 0.22)!;
      bottom = Color.lerp(bottom, const Color(0xFFA8ADA6), 0.28)!;
    }

    canvas.drawRRect(
      faceRRect,
      Paint()
        ..shader = ui.Gradient.linear(face.topCenter, face.bottomCenter, [
          top,
          bottom,
        ]),
    );

    canvas.drawRRect(
      faceRRect,
      Paint()
        ..shader = ui.Gradient.radial(
          face.topLeft + Offset(face.width * 0.22, face.height * 0.16),
          face.shortestSide * 0.82,
          [
            Colors.white.withValues(
              alpha: isSelected
                  ? 0.22
                  : isSpecial
                  ? 0.28
                  : (locked ? 0.18 : 0.55),
            ),
            Colors.transparent,
          ],
        ),
    );
  }

  /// Фиолетовый витраж сверху и букет тюльпанов в горшке — свой мотив,
  /// не копия чужого арта.
  static void _drawSpecialMotif(Canvas canvas, Rect face, int seed) {
    final s = seed.abs();
    final w = face.width;
    final h = face.height;
    final origin = face.topLeft;

    _drawStainedArch(canvas, face, s);

    final potTop = origin.dy + h * 0.62;
    final potWidth = w * 0.38;
    final potLeft = origin.dx + (w - potWidth) / 2;
    final pot = Path()
      ..moveTo(potLeft + potWidth * 0.08, potTop)
      ..lineTo(potLeft + potWidth * 0.92, potTop)
      ..lineTo(potLeft + potWidth * 0.78, origin.dy + h * 0.92)
      ..lineTo(potLeft + potWidth * 0.22, origin.dy + h * 0.92)
      ..close();
    canvas.drawPath(
      pot,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(potLeft, potTop),
          Offset(potLeft + potWidth, origin.dy + h * 0.92),
          const [Color(0xFF7A4CB0), Color(0xFF4A2878)],
        ),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(origin.dx + w * 0.5, potTop),
        width: potWidth * 0.92,
        height: h * 0.055,
      ),
      Paint()..color = const Color(0xFF9B72D0),
    );

    const palettes = [
      [
        Color(0xFFE56B96),
        Color(0xFFE8883A),
        Color(0xFFD43B34),
        Color(0xFFE8C44A),
      ],
      [
        Color(0xFFEF7AA8),
        Color(0xFF8EC5F0),
        Color(0xFFF0A0C8),
        Color(0xFFF2D36A),
      ],
      [
        Color(0xFFD84A6A),
        Color(0xFFF0B24A),
        Color(0xFFC95AD8),
        Color(0xFFE87840),
      ],
    ];
    final colors = palettes[s % palettes.length];

    void tulip(Offset head, Color color, double scale, double lean) {
      final stem = Path()
        ..moveTo(origin.dx + w * 0.5, potTop + h * 0.01)
        ..quadraticBezierTo(
          head.dx + lean,
          (head.dy + potTop) / 2,
          head.dx,
          head.dy + h * 0.04,
        );
      canvas.drawPath(
        stem,
        Paint()
          ..color = const Color(0xFF3F8A4A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, w * 0.028)
          ..strokeCap = StrokeCap.round,
      );
      final petal = Path()
        ..moveTo(head.dx, head.dy + h * 0.055 * scale)
        ..cubicTo(
          head.dx - w * 0.09 * scale,
          head.dy + h * 0.01 * scale,
          head.dx - w * 0.07 * scale,
          head.dy - h * 0.06 * scale,
          head.dx,
          head.dy - h * 0.02 * scale,
        )
        ..cubicTo(
          head.dx + w * 0.07 * scale,
          head.dy - h * 0.06 * scale,
          head.dx + w * 0.09 * scale,
          head.dy + h * 0.01 * scale,
          head.dx,
          head.dy + h * 0.055 * scale,
        )
        ..close();
      canvas.drawPath(petal, Paint()..color = color);
      canvas.drawPath(
        petal,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7
          ..color = const Color(0xFF5A2040).withValues(alpha: 0.35),
      );
    }

    tulip(
      Offset(origin.dx + w * 0.34, origin.dy + h * 0.38),
      colors[0],
      1.0,
      -w * 0.08,
    );
    tulip(
      Offset(origin.dx + w * 0.50, origin.dy + h * 0.30),
      colors[1],
      1.12,
      0,
    );
    tulip(
      Offset(origin.dx + w * 0.66, origin.dy + h * 0.40),
      colors[2],
      0.95,
      w * 0.08,
    );
    tulip(
      Offset(origin.dx + w * 0.42, origin.dy + h * 0.48),
      colors[3],
      0.78,
      -w * 0.02,
    );
  }

  static void _drawStainedArch(Canvas canvas, Rect face, int seed) {
    final w = face.width;
    final h = face.height;
    final arch = Rect.fromLTWH(
      face.left + w * 0.08,
      face.top + h * 0.05,
      w * 0.84,
      h * 0.28,
    );
    final path = Path()
      ..moveTo(arch.left, arch.bottom)
      ..lineTo(arch.left, arch.center.dy)
      ..arcToPoint(
        Offset(arch.right, arch.center.dy),
        radius: Radius.elliptical(arch.width / 2, arch.height * 0.72),
        clockwise: true,
      )
      ..lineTo(arch.right, arch.bottom)
      ..close();

    canvas.save();
    canvas.clipPath(path);

    const panes = [
      Color(0xFFB9A0E0),
      Color(0xFF8EC6F0),
      Color(0xFFE8C86A),
      Color(0xFFC9B4F0),
      Color(0xFF7EB8E8),
      Color(0xFFF0D48A),
    ];
    final shift = seed % panes.length;
    final slice = arch.width / 5;
    for (var i = 0; i < 5; i++) {
      canvas.drawRect(
        Rect.fromLTWH(
          arch.left + i * slice,
          arch.top,
          slice + 0.5,
          arch.height,
        ),
        Paint()..color = panes[(i + shift) % panes.length],
      );
    }
    canvas.restore();

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, w * 0.018)
        ..color = const Color(0xFF6B3FA0).withValues(alpha: 0.85),
    );
  }

  /// Мягкий squircle: сплошное белое / золотое / серо-голубое лицо.
  static void drawCasualTile(
    Canvas canvas,
    Size size, {
    bool isSelected = false,
    bool locked = false,
    bool lifted = false,
  }) {
    if (size.isEmpty) return;

    final face = CasualTileLayout.faceRectOf(size);
    final radius = CasualTileLayout.cornerRadius(size);
    final body = RRect.fromRectAndRadius(face, Radius.circular(radius));
    final w = size.width;

    final shadow = Paint()
      ..color = Colors.black.withValues(
        alpha: locked ? 0.12 : (lifted ? 0.22 : 0.16),
      );
    if (!kIsWeb) {
      shadow.maskFilter = ui.MaskFilter.blur(
        BlurStyle.normal,
        math.max(2.4, w * 0.07),
      );
    }
    canvas.drawRRect(body.shift(Offset(0, lifted ? 2.8 : 2.0)), shadow);

    final Color fill;
    if (isSelected) {
      fill = TableUi.tileSelected;
    } else if (locked) {
      fill = TableUi.tileBlocked;
    } else {
      fill = TableUi.tileFace;
    }

    canvas.drawRRect(body, Paint()..color = fill);

    if (!locked) {
      final rim = math.max(1.6, face.height * 0.03);
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(face.left, face.bottom - rim, face.width, rim),
          bottomLeft: Radius.circular(radius),
          bottomRight: Radius.circular(radius),
        ),
        Paint()
          ..color = (isSelected
              ? const Color(0xFFC9A227)
              : const Color(0x14000000)),
      );
    }

    canvas.drawRRect(
      body.deflate(0.7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.15
        ..color = Colors.white.withValues(alpha: locked ? 0.22 : 0.55),
    );
  }
}

/// Исходник наклейки на грань. Портрет 3:4, не квадрат 512×512.
///
/// Слот [TileCanvas.symbolRectOf] имеет тот же аспект: `BoxFit.contain`
/// заполняет окно. В генератор: 384×512 или 768×1024, потом в 384×512.
abstract final class TileFaceArt {
  TileFaceArt._();

  static const widthPx = 384;
  static const heightPx = 512;
  static const widthOverHeight = widthPx / heightPx;
  static const size = Size(384, 512);
}

/// Квадратная белая кость как на casual-мокапе: без боковины и канта.
abstract final class CasualTileLayout {
  CasualTileLayout._();

  static const aspect = 1.0;
  static const cornerRadiusFactor = 0.24;

  /// Поле символа только для яркого матча. Классика — [TileCanvas.symbolInset].
  ///
  /// Кость квадратная, дуга r=24% режет углы сильнее портретной 3:4.
  /// Минимум, чтобы углы окна были внутри squircle:
  /// `r * (1 - 1/√2) ≈ 0.070`. PNG 512² заполняют кадр на ~84%, SVG-фрукты
  /// 80×100 — поэтому 22%, а не геометрический минимум.
  static const symbolInsetX = 0.22;
  static const symbolInsetTop = 0.22;
  static const symbolInsetBottom = 0.22;

  static double cornerRadius(Size size) => size.width * cornerRadiusFactor;

  static Rect faceRectOf(Size size) => Offset.zero & size;

  static Rect symbolRectOf(Size size) {
    final face = faceRectOf(size);
    return Rect.fromLTRB(
      face.left + face.width * symbolInsetX,
      face.top + face.height * symbolInsetTop,
      face.right - face.width * symbolInsetX,
      face.bottom - face.height * symbolInsetBottom,
    );
  }

  /// Угол [point] лежит внутри squircle лица (включая дуги).
  static bool containsPoint(Size size, Offset point) {
    return roundedRectContains(faceRectOf(size), cornerRadius(size), point);
  }
}

/// Точка внутри скруглённого прямоугольника, с допуском в долю пикселя.
bool roundedRectContains(Rect rect, double radius, Offset point) {
  if (!rect.inflate(0.05).contains(point)) return false;
  final r = radius.clamp(0.0, rect.shortestSide / 2);
  final inner = rect.deflate(r);
  if (point.dx >= inner.left && point.dx <= inner.right) {
    return point.dy >= rect.top && point.dy <= rect.bottom;
  }
  if (point.dy >= inner.top && point.dy <= inner.bottom) {
    return point.dx >= rect.left && point.dx <= rect.right;
  }
  final cx = point.dx < inner.left ? inner.left : inner.right;
  final cy = point.dy < inner.top ? inner.top : inner.bottom;
  return (point - Offset(cx, cy)).distance <= r + 0.05;
}

/// Геометрия кости темы «Новая»: толстый тёплый торец (13–15%), спокойное
/// скругление — как на референсе (белая пластина, не тонкая наклейка).
abstract final class PremiumTileLayout {
  PremiumTileLayout._();

  static const cornerRadiusFactor = 0.14;
  static const faceInsetRight = 0.11;
  static const faceInsetBottom = 0.13;
  // Меньше полей, чем у classic (0.14) — суты с частыми пипсами (бамбук/точки
  // 6-9) иначе сжимаются в нечитаемые чёрточки на premium-грани, которая и
  // так уже уже классической из-за более толстого торца.
  static const symbolInset = 0.08;
  static const strokeWidthFactor = 0.020;
  static const strokeWidthMin = 1.3;

  static double cornerRadius(Size size) => size.width * cornerRadiusFactor;

  static double faceCornerRadius(Size size) => cornerRadius(size) * 0.90;

  static Rect faceRectOf(Size size) {
    return Rect.fromLTWH(
      0,
      0,
      size.width * (1 - faceInsetRight),
      size.height * (1 - faceInsetBottom),
    );
  }

  static Rect symbolRectOf(Size size) {
    final face = faceRectOf(size);
    return Rect.fromLTRB(
      face.left + face.width * symbolInset,
      face.top + face.height * symbolInset,
      face.right - face.width * symbolInset,
      face.bottom - face.height * symbolInset,
    );
  }

  /// Всё тело, не только грань: боковина тоже видна и должна нажиматься.
  static bool containsPoint(Size size, Offset point) {
    return roundedRectContains(Offset.zero & size, cornerRadius(size), point);
  }
}

/// Тело кости темы «Новая»: без PNG-рамки и без tint — только Canvas.
/// Свет, торец и тень нарисованы так, чтобы кость читалась как физическая
/// фарфоровая пластина, а не наклейка (см. обсуждение качества визуала).
abstract final class PremiumTileCanvas {
  PremiumTileCanvas._();

  /// Тело + грань + кант, без символа (символ рисуется отдельным слоем).
  static void drawBody(
    Canvas canvas,
    Size size, {
    bool isSelected = false,
    bool locked = false,
    bool lifted = false,
  }) {
    if (size.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final face = PremiumTileLayout.faceRectOf(size);
    final radius = PremiumTileLayout.cornerRadius(size);
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final faceRRect = RRect.fromRectAndRadius(
      face,
      Radius.circular(PremiumTileLayout.faceCornerRadius(size)),
    );
    final strokeW = math.max(
      PremiumTileLayout.strokeWidthMin,
      w * PremiumTileLayout.strokeWidthFactor,
    );

    // Торец: тёплый тон, темнее и глуше на закрытой кости — без серого tint.
    var hi = TileCanvas.premiumSideHi;
    var mid = TileCanvas.premiumSideMid;
    var lo = TileCanvas.premiumSideLo;
    if (locked) {
      hi = Color.lerp(hi, const Color(0xFF9A8F78), 0.35)!;
      mid = Color.lerp(mid, const Color(0xFF7C7060), 0.35)!;
      lo = Color.lerp(lo, const Color(0xFF4A4438), 0.35)!;
    }

    canvas.drawRRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.30, 0),
          Offset(w, h),
          [hi, mid, lo],
          const [0.0, 0.5, 1.0],
        ),
    );

    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(
      Rect.fromLTRB(face.right - 0.4, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(Offset(face.right, 0), Offset(w, 0), [
          Color.lerp(hi, Colors.white, 0.25)!,
          lo,
        ]),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, face.bottom - 0.4, w, h),
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, face.bottom), Offset(0, h), [
          mid,
          Color.lerp(lo, Colors.black, 0.28)!,
        ]),
    );
    canvas.restore();

    // Грань: фарфор — почти белая сверху, тёплый крем к низу.
    final faceTop = locked
        ? TileCanvas.premiumFaceLocked
        : (isSelected
              ? Color.lerp(TileCanvas.premiumFaceHi, TableUi.gold, 0.10)!
              : (lifted ? TileCanvas.premiumFaceHi : TileCanvas.premiumFaceHi));
    final faceBottom = locked
        ? TileCanvas.premiumFaceLockedLo
        : TileCanvas.premiumFaceLo;

    canvas.drawRRect(
      faceRRect,
      Paint()
        ..shader = ui.Gradient.linear(face.topCenter, face.bottomCenter, [
          faceTop,
          faceBottom,
        ]),
    );

    canvas.save();
    canvas.clipRRect(faceRRect);
    canvas.drawRect(
      face,
      Paint()
        ..shader = ui.Gradient.radial(
          face.topLeft + Offset(face.width * 0.20, face.height * 0.14),
          face.shortestSide * 0.9,
          [
            Colors.white.withValues(alpha: locked ? 0.08 : 0.22),
            Colors.transparent,
          ],
        ),
    );
    canvas.drawRect(
      face,
      Paint()
        ..shader = ui.Gradient.linear(
          face.topLeft,
          face.bottomRight,
          [
            Colors.white.withValues(alpha: locked ? 0.04 : 0.10),
            Colors.transparent,
            Colors.black.withValues(alpha: locked ? 0.04 : 0.015),
          ],
          const [0.0, 0.5, 1.0],
        ),
    );
    canvas.restore();

    canvas.drawRRect(
      faceRRect.deflate(0.7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = TileCanvas.premiumInnerEdge.withValues(
          alpha: locked ? 0.30 : 0.65,
        ),
    );

    canvas.drawRRect(
      body.deflate(strokeW * 0.35),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW
        ..color = TileCanvas.premiumStroke.withValues(
          alpha: locked ? 0.42 : 0.80,
        ),
    );
  }
}

/// Мягкая контактная тень вниз-вправо (слой под костью).
class TileDropShadowPainter extends CustomPainter {
  const TileDropShadowPainter({
    required this.opacity,
    required this.blur,
    this.cornerRadius,
  });

  final double opacity;
  final double blur;
  final double? cornerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || opacity <= 0) return;
    final radius = cornerRadius ?? TileCanvas.cornerRadius(size);
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = TileCanvas.shadowColor.withValues(
        alpha: opacity.clamp(0.08, 0.62),
      );
    if (!kIsWeb && blur > 0.35) {
      paint.maskFilter = ui.MaskFilter.blur(BlurStyle.normal, blur);
    }
    canvas.drawRRect(body, paint);
  }

  @override
  bool shouldRepaint(covariant TileDropShadowPainter oldDelegate) {
    return oldDelegate.opacity != opacity ||
        oldDelegate.blur != blur ||
        oldDelegate.cornerRadius != cornerRadius;
  }
}
