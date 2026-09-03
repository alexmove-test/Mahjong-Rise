import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'tile_canvas.dart';

/// Разметка кости: геометрия лица, символа и скругления из [TileCanvas].
class TileBaseLayout {
  TileBaseLayout._();

  static const baseAsset = 'assets/tile_base.png';
  static const shadowAsset = 'assets/tile_shadow.png';

  /// Кадр уже обрезан по видимой кости.
  static const spriteLeft = 0.0;
  static const spriteTop = 0.0;
  static const spriteWidth = 1.0;
  static const spriteHeight = 1.0;
  /// Высота / ширина видимой кости. Физическая плитка ~1.33–1.38, не квадрат.
  static const spriteAspect = 709 / 514;

  static const faceInsetRight = TileCanvas.faceInsetRight;
  static const faceInsetBottom = TileCanvas.faceInsetBottom;

  /// Смещённое вверх-влево лицо: справа и снизу видна толщина тела.
  static Rect faceRectOf(Size size) => TileCanvas.faceRectOf(size);

  /// Прямоугольник грани внутри спрайта, если спрайт растянут в [size].
  static Rect spriteRectOf(Size size) {
    return Rect.fromLTWH(
      size.width * spriteLeft,
      size.height * spriteTop,
      size.width * spriteWidth,
      size.height * spriteHeight,
    );
  }

  static Rect symbolRectOf(Size size) => TileCanvas.symbolRectOf(size);

  static double cornerRadius(Size size) => TileCanvas.cornerRadius(size);

  /// Совместимость с расчётом поля.
  static double edgeX(double width) => width * 0.12;

  static double edgeY(double width) => width * 0.11;
}

/// Рисует спрайт так, чтобы видимая грань заполнила [tileSize].
class TileMappedSprite extends StatelessWidget {
  const TileMappedSprite({
    super.key,
    required this.asset,
    required this.tileSize,
    this.filterQuality = FilterQuality.high,
    this.color,
    this.colorBlendMode,
    this.errorBuilder,
  });

  final String asset;
  final Size tileSize;
  final FilterQuality filterQuality;
  final Color? color;
  final BlendMode? colorBlendMode;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    final radius = TileBaseLayout.cornerRadius(tileSize);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        asset,
        width: tileSize.width,
        height: tileSize.height,
        fit: BoxFit.fill,
        filterQuality: filterQuality,
        color: color,
        colorBlendMode: colorBlendMode,
        errorBuilder: errorBuilder,
      ),
    );
  }
}

/// Тело кости: PNG [TileBaseLayout.baseAsset], Canvas — только если спрайт
/// не загрузился. Символ рисуется снаружи.
class TileBodySprite extends StatelessWidget {
  const TileBodySprite({
    super.key,
    required this.size,
    this.locked = false,
    this.lifted = false,
    this.isSelected = false,
    this.isSpecial = false,
    this.specialSeed = 0,
    this.symbol,
  });

  final Size size;
  final bool locked;
  final bool lifted;
  final bool isSelected;
  final bool isSpecial;
  final int specialSeed;
  final String? symbol;

  /// Multiply по кремовому лицу: выбор — зелёный, перекрытая — серее.
  static Color? chromeTint({
    required bool locked,
    required bool isSelected,
  }) {
    if (isSelected) return const Color(0xFF6EE24A);
    if (locked) return const Color(0xFFC5CCC4);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tint = chromeTint(locked: locked, isSelected: isSelected);
    return TileMappedSprite(
      asset: TileBaseLayout.baseAsset,
      tileSize: size,
      color: tint,
      colorBlendMode: tint == null ? null : BlendMode.modulate,
      errorBuilder: (context, error, stack) => TileFallbackFace(
        size: size,
        locked: locked,
        lifted: lifted,
        isSelected: isSelected,
        isSpecial: false,
        symbol: null,
      ),
    );
  }
}

/// Классический глиф или сезонный мотив поверх PNG-тела.
class TileOverlayArtPainter extends CustomPainter {
  const TileOverlayArtPainter({
    this.locked = false,
    this.isSelected = false,
    this.isSpecial = false,
    this.specialSeed = 0,
    this.symbol,
  });

  final bool locked;
  final bool isSelected;
  final bool isSpecial;
  final int specialSeed;
  final String? symbol;

  @override
  void paint(Canvas canvas, Size size) {
    TileCanvas.drawOverlayArt(
      canvas,
      size,
      isSpecial: isSpecial,
      isSelected: isSelected,
      locked: locked,
      specialSeed: specialSeed,
      symbol: symbol,
    );
  }

  @override
  bool shouldRepaint(covariant TileOverlayArtPainter oldDelegate) {
    return oldDelegate.locked != locked ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isSpecial != isSpecial ||
        oldDelegate.specialSeed != specialSeed ||
        oldDelegate.symbol != symbol;
  }
}

/// Запасная отрисовка, если PNG спрайт не загрузился.
class TileFallbackFace extends StatelessWidget {
  const TileFallbackFace({
    super.key,
    required this.size,
    this.locked = false,
    this.lifted = false,
    this.isSelected = false,
    this.isSpecial = false,
    this.specialSeed = 0,
    this.symbol,
  });

  final Size size;
  final bool locked;
  final bool lifted;
  final bool isSelected;
  final bool isSpecial;
  final int specialSeed;
  final String? symbol;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: TileFacePainter(
        locked: locked,
        lifted: lifted,
        isSelected: isSelected,
        isSpecial: isSpecial,
        specialSeed: specialSeed,
        symbol: symbol,
      ),
    );
  }
}

/// Фарфоровая кость: [TileCanvas.drawTile].
class TileFacePainter extends CustomPainter {
  const TileFacePainter({
    this.locked = false,
    this.lifted = false,
    this.isSelected = false,
    this.isSpecial = false,
    this.specialSeed = 0,
    this.symbol,
  });

  final bool locked;
  final bool lifted;
  final bool isSelected;
  final bool isSpecial;
  final int specialSeed;
  final String? symbol;

  @override
  void paint(Canvas canvas, Size size) {
    TileCanvas.drawTile(
      canvas,
      size,
      locked: locked,
      lifted: lifted,
      isSelected: isSelected,
      isSpecial: isSpecial,
      specialSeed: specialSeed,
      symbol: symbol,
    );
  }

  @override
  bool shouldRepaint(covariant TileFacePainter oldDelegate) {
    return oldDelegate.locked != locked ||
        oldDelegate.lifted != lifted ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isSpecial != isSpecial ||
        oldDelegate.specialSeed != specialSeed ||
        oldDelegate.symbol != symbol;
  }
}

/// Свет на белой грани поверх PNG-кости: блик сверху-слева, диагональный
/// отлив и светлый кант. Рисуется под символом, чтобы не гасить иконку.
class TileFaceLightPainter extends CustomPainter {
  const TileFaceLightPainter({this.locked = false});

  final bool locked;

  @override
  void paint(Canvas canvas, Size size) {
    final face = TileBaseLayout.faceRectOf(size);
    if (face.isEmpty) return;

    final radius = TileBaseLayout.cornerRadius(size);
    final faceRRect = RRect.fromRectAndRadius(face, Radius.circular(radius));

    canvas.save();
    canvas.clipRRect(faceRRect);

    canvas.drawRect(
      face,
      Paint()
        ..shader = ui.Gradient.radial(
          face.topLeft + Offset(face.width * 0.22, face.height * 0.18),
          face.shortestSide * 0.86,
          [
            Colors.white.withValues(alpha: locked ? 0.10 : 0.30),
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
            Colors.white.withValues(alpha: locked ? 0.05 : 0.14),
            Colors.transparent,
            Colors.black.withValues(alpha: locked ? 0.12 : 0.05),
          ],
          const [0.0, 0.48, 1.0],
        ),
    );

    canvas.restore();

    canvas.drawRRect(
      faceRRect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = Colors.white.withValues(alpha: locked ? 0.18 : 0.42),
    );
  }

  @override
  bool shouldRepaint(covariant TileFaceLightPainter oldDelegate) {
    return oldDelegate.locked != locked;
  }
}

/// Золотое гало выбора / подсказки по контуру кости.
class TileHighlightPainter extends CustomPainter {
  const TileHighlightPainter({required this.intensity});

  final double intensity;

  static const _gold = Color(0xFFE8C96A);
  static const _goldDeep = Color(0xFFD4AF37);

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;

    final radius = TileBaseLayout.cornerRadius(size);
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final face = TileBaseLayout.faceRectOf(size);
    final faceRRect = RRect.fromRectAndRadius(face, Radius.circular(radius));
    final glow = intensity.clamp(0.0, 1.0);
    final pad = size.shortestSide * 0.22;

    canvas.saveLayer((Offset.zero & size).inflate(pad), Paint());

    canvas.drawRRect(
      body.inflate(size.shortestSide * 0.04),
      Paint()
        ..color = _gold.withValues(alpha: 0.42 * glow)
        ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, 8.5),
    );

    canvas.drawRRect(
      body.inflate(1.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = _gold.withValues(alpha: 0.95 * glow),
    );

    canvas.drawRRect(
      body.inflate(0.4),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = Colors.white.withValues(alpha: 0.55 * glow),
    );

    canvas.drawRRect(
      faceRRect,
      Paint()
        ..shader = ui.Gradient.radial(face.center, face.shortestSide * 0.72, [
          _gold.withValues(alpha: 0.10 * glow),
          Colors.transparent,
        ]),
    );

    canvas.drawRRect(
      body.inflate(size.shortestSide * 0.08),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.shortestSide * 0.12
        ..color = _goldDeep.withValues(alpha: 0.28 * glow)
        ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 9),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TileHighlightPainter oldDelegate) {
    return oldDelegate.intensity != intensity;
  }
}

/// Оборот плитки (нижний перекрытый слой).
class TileVolumePainter extends CustomPainter {
  const TileVolumePainter({
    required this.zIndex,
    this.drawBody = false,
    this.showBack = false,
  });

  final int zIndex;
  final bool drawBody;
  final bool showBack;

  static const backLight = Color(0xFFD4B896);
  static const backMid = Color(0xFF9A7048);
  static const backShade = Color(0xFF6B4428);

  static Rect faceRectOf(Size size) => TileBaseLayout.faceRectOf(size);

  static Rect symbolRectOf(Size size) => TileBaseLayout.symbolRectOf(size);

  static double edgeX(double width) => TileBaseLayout.edgeX(width);

  static double edgeY(double width) => TileBaseLayout.edgeY(width);

  @override
  void paint(Canvas canvas, Size size) {
    if (!drawBody || !showBack) return;

    final faceRect = TileBaseLayout.faceRectOf(size);
    final radius = TileBaseLayout.cornerRadius(size);
    final face = RRect.fromRectAndRadius(faceRect, Radius.circular(radius));
    _paintBack(canvas, face, faceRect);
  }

  void _paintBack(Canvas canvas, RRect face, Rect faceRect) {
    canvas.drawRRect(
      face,
      Paint()
        ..shader = ui.Gradient.linear(
          faceRect.topLeft,
          faceRect.bottomRight,
          const [backLight, backMid, backShade],
          const [0.0, 0.52, 1.0],
        ),
    );

    final inset = faceRect.deflate(faceRect.shortestSide * 0.14);
    final inner = RRect.fromRectAndRadius(
      inset,
      Radius.circular(math.min(8.0, inset.shortestSide * 0.14)),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.35),
    );

    canvas.drawRRect(
      face,
      Paint()
        ..shader = ui.Gradient.linear(
          faceRect.topLeft,
          faceRect.bottomRight,
          [
            Colors.white.withValues(alpha: 0.14),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.12),
          ],
          const [0.0, 0.42, 1.0],
        ),
    );

    canvas.drawRRect(
      face.deflate(0.7),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..color = const Color(0xFF5C3418).withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant TileVolumePainter oldDelegate) {
    return oldDelegate.zIndex != zIndex ||
        oldDelegate.drawBody != drawBody ||
        oldDelegate.showBack != showBack;
  }
}
