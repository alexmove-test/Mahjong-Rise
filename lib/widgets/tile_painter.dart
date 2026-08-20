import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Разметка спрайтов плитки: [tile_shadow.png] и [tile_base.png].
class TileBaseLayout {
  TileBaseLayout._();

  static const baseAsset = 'assets/tile_base.png';
  static const shadowAsset = 'assets/tile_shadow.png';

  /// Кадр уже обрезан по видимой кости.
  static const spriteLeft = 0.0;
  static const spriteTop = 0.0;
  static const spriteWidth = 1.0;
  static const spriteHeight = 1.0;
  static const spriteAspect = 709 / 514;

  /// Отступ символа от краёв белой грани.
  static const _insetHorizontal = 0.10;
  static const _insetTop = 0.09;
  static const _insetBottom = 0.11;

  /// Доля, которую занимают правая и нижняя боковины на [tile_base.png].
  static const faceInsetRight = 0.105;
  static const faceInsetBottom = 0.11;

  /// Смещённое вверх-влево лицо: справа и снизу видна толщина тела.
  static Rect faceRectOf(Size size) {
    return Rect.fromLTWH(
      0,
      0,
      size.width * (1 - faceInsetRight),
      size.height * (1 - faceInsetBottom),
    );
  }

  /// Прямоугольник грани внутри спрайта, если спрайт растянут в [size].
  static Rect spriteRectOf(Size size) {
    return Rect.fromLTWH(
      size.width * spriteLeft,
      size.height * spriteTop,
      size.width * spriteWidth,
      size.height * spriteHeight,
    );
  }

  static Rect symbolRectOf(Size size) {
    final face = faceRectOf(size);
    return Rect.fromLTRB(
      face.left + face.width * _insetHorizontal,
      face.top + face.height * _insetTop,
      face.right - face.width * _insetHorizontal,
      face.bottom - face.height * _insetBottom,
    );
  }

  static double cornerRadius(Size size) {
    final face = faceRectOf(size);
    return math.min(14.0, face.shortestSide * 0.16);
  }

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
    this.errorBuilder,
  });

  final String asset;
  final Size tileSize;
  final FilterQuality filterQuality;
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
        errorBuilder: errorBuilder,
      ),
    );
  }
}

/// Запасная отрисовка, если PNG спрайт не загрузился.
class TileFallbackFace extends StatelessWidget {
  const TileFallbackFace({
    super.key,
    required this.size,
    this.locked = false,
    this.lifted = false,
  });

  final Size size;
  final bool locked;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: TileFacePainter(locked: locked, lifted: lifted),
    );
  }
}

/// Ледяная кость: aqua-боковины, ivory-лицо, контактная тень.
class TileFacePainter extends CustomPainter {
  const TileFacePainter({this.locked = false, this.lifted = false});

  final bool locked;
  final bool lifted;

  static const _iceHi = Color(0xFFB8EAF6);
  static const _iceMid = Color(0xFF5BA8C4);
  static const _iceDeep = Color(0xFF2F6F88);
  static const _iceLockedHi = Color(0xFF7AA8B6);
  static const _iceLockedMid = Color(0xFF3E6E82);
  static const _iceLockedDeep = Color(0xFF244A5A);

  static const _ivoryHi = Color(0xFFFFFDF8);
  static const _ivoryLo = Color(0xFFF3EEE4);
  static const _ivoryLockedHi = Color(0xFFE6E3DC);
  static const _ivoryLockedLo = Color(0xFFD2CEC6);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final face = TileBaseLayout.faceRectOf(size);
    final radius = TileBaseLayout.cornerRadius(size);
    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final faceRRect = RRect.fromRectAndRadius(face, Radius.circular(radius));

    final iceHi = locked ? _iceLockedHi : _iceHi;
    final iceMid = locked ? _iceLockedMid : _iceMid;
    final iceDeep = locked ? _iceLockedDeep : _iceDeep;
    final ivoryHi = locked
        ? _ivoryLockedHi
        : (lifted ? const Color(0xFFFFFFF8) : _ivoryHi);
    final ivoryLo = locked ? _ivoryLockedLo : _ivoryLo;

    canvas.drawRRect(
      body.shift(Offset(w * 0.045, h * 0.08)),
      Paint()
        ..color = Colors.black.withValues(alpha: locked ? 0.28 : 0.46)
        ..maskFilter = ui.MaskFilter.blur(BlurStyle.normal, w * 0.10),
    );

    canvas.drawRRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          Offset(w, h),
          [iceHi, iceMid, iceDeep],
          const [0.0, 0.42, 1.0],
        ),
    );

    canvas.save();
    canvas.clipRRect(body);
    canvas.drawRect(
      Rect.fromLTRB(face.right - 0.5, 0, w, h),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(face.right, face.top),
          Offset(w, face.top),
          [iceMid.withValues(alpha: 0.15), iceDeep.withValues(alpha: 0.72)],
        ),
    );
    canvas.drawRect(
      Rect.fromLTRB(0, face.bottom - 0.5, w, h),
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, face.bottom), Offset(0, h), [
          iceMid.withValues(alpha: 0.08),
          const Color(0xFF1E4A5C).withValues(alpha: locked ? 0.55 : 0.62),
        ]),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.12, 0),
          Offset(w * 0.12, h * 0.22),
          [
            Colors.white.withValues(alpha: locked ? 0.18 : 0.38),
            Colors.transparent,
          ],
        ),
    );
    canvas.restore();

    canvas.drawRRect(
      faceRRect,
      Paint()
        ..shader = ui.Gradient.linear(face.topCenter, face.bottomCenter, [
          ivoryHi,
          ivoryLo,
        ]),
    );

    canvas.drawRRect(
      faceRRect,
      Paint()
        ..shader = ui.Gradient.radial(
          face.topLeft + Offset(face.width * 0.18, face.height * 0.16),
          face.shortestSide * 0.78,
          [
            Colors.white.withValues(alpha: locked ? 0.42 : 0.90),
            Colors.transparent,
          ],
        ),
    );

    canvas.drawRRect(
      faceRRect,
      Paint()
        ..shader = ui.Gradient.linear(
          face.topLeft,
          face.bottomRight,
          [
            Colors.white.withValues(alpha: locked ? 0.18 : 0.35),
            Colors.transparent,
            Colors.black.withValues(alpha: locked ? 0.10 : 0.07),
          ],
          const [0.0, 0.45, 1.0],
        ),
    );

    canvas.drawRRect(
      faceRRect.deflate(0.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.05
        ..shader = ui.Gradient.linear(face.topLeft, face.bottomRight, [
          Colors.white.withValues(alpha: locked ? 0.35 : 0.72),
          const Color(0xFFC9BFAE).withValues(alpha: 0.55),
        ]),
    );
  }

  @override
  bool shouldRepaint(covariant TileFacePainter oldDelegate) {
    return oldDelegate.locked != locked || oldDelegate.lifted != lifted;
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
