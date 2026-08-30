import 'package:flutter/material.dart';

import '../widgets/tile_canvas.dart';
import '../widgets/tile_painter.dart';

/// Визуальные параметры одной плитки в пирамиде по координатам (x, y, z).
class TilePyramidVisuals {
  const TilePyramidVisuals({
    required this.baseOffset,
    required this.shadowOffset,
    required this.shadowOpacity,
    required this.shadowBlur,
  });

  /// Смещение базового спрайта относительно ячейки сетки.
  final Offset baseOffset;

  /// Смещение слоя тени: 4 px + z × 4 px по X и Y.
  final Offset shadowOffset;

  /// Прозрачность тени (растёт с z).
  final double shadowOpacity;

  /// Размытие тени в sigma (растёт с z).
  final double shadowBlur;
}

/// Позиционирование плиток в пирамиде: подъём базы, тень, blur и opacity от z.
class TilePyramidPosition {
  TilePyramidPosition._();

  static const shadowStepPx = 4.0;

  /// Базовый сдвиг тени вниз-вправо, даже у нижнего слоя.
  static const baseShadowOffsetPx = 4.0;

  /// Подъём одного слоя по Y (~11% высоты плитки при опорной ширине 80).
  static const liftStepYPx = 9.0;

  /// Сдвиг по X: стопка уходит вглубь влево-вверх.
  static const liftStepXPx = 2.5;

  static const _baseShadowOpacity = 0.34;
  static const _shadowOpacityPerZ = 0.09;
  static const _baseShadowBlur = 4.0;
  static const _shadowBlurPerZ = 1.8;

  /// Перекрытая кость лежит в тени соседей: тень короче, мягче и бледнее.
  /// Свободная отрывается от стопки — тень плотнее.
  static const lockedShadowExtent = 0.72;
  static const lockedShadowOpacityFactor = 0.82;
  static const lockedShadowBlurFactor = 0.85;
  static const liftedShadowOpacityFactor = 1.12;

  static const _refTileWidth = 80.0;

  /// Масштаб px-констант под фактический размер плитки на экране.
  static double scaleFor(double tileWidth) =>
      (tileWidth / _refTileWidth).clamp(0.55, 2.4);

  /// Визуальные параметры для плитки с высотой [z].
  ///
  /// [lifted] — кость свободна и читается как «можно взять». Значение по
  /// умолчанию даёт максимальную тень: расчёт границ поля опирается на него.
  static TilePyramidVisuals visuals({
    required int z,
    required double tileWidth,
    required double tileHeight,
    bool lifted = true,
  }) {
    final scale = scaleFor(tileWidth);
    final lift = baseOffset(z: z, tileWidth: tileWidth, tileHeight: tileHeight);
    final extent = lifted ? 1.0 : lockedShadowExtent;
    final opacityFactor = lifted
        ? liftedShadowOpacityFactor
        : lockedShadowOpacityFactor;
    final blurFactor = lifted ? 1.0 : lockedShadowBlurFactor;

    return TilePyramidVisuals(
      baseOffset: lift,
      shadowOffset: shadowOffset(z: z, scale: scale * extent),
      shadowOpacity: (shadowOpacity(z: z) * opacityFactor).clamp(0.0, 0.97),
      shadowBlur: shadowBlur(z: z, scale: scale) * blurFactor,
    );
  }

  /// Чем выше z, тем сильнее смещение базы вверх (отрицательный Y).
  static Offset baseOffset({
    required int z,
    required double tileWidth,
    required double tileHeight,
  }) {
    if (z <= 0) return Offset.zero;

    final scale = scaleFor(tileWidth);
    return Offset(-z * liftStepXPx * scale, -z * liftStepYPx * scale);
  }

  /// shadow.x = shadow.y = 4 px + z × 4 px.
  static Offset shadowOffset({required int z, double scale = 1.0}) {
    final px = (baseShadowOffsetPx + z * shadowStepPx) * scale;
    return Offset(px, px);
  }

  static double shadowOpacity({required int z}) {
    return (_baseShadowOpacity + z * _shadowOpacityPerZ).clamp(0.0, 0.97);
  }

  static double shadowBlur({required int z, double scale = 1.0}) {
    return (_baseShadowBlur + z * _shadowBlurPerZ) * scale;
  }

  /// Абсолютная позиция левого верхнего угла плитки на поле.
  static Offset boardOrigin({
    required int x,
    required int y,
    required int z,
    required int minX,
    required int minY,
    required double originX,
    required double originY,
    required double cellW,
    required double cellH,
    required double tileW,
    required double tileH,
  }) {
    final lift = baseOffset(z: z, tileWidth: tileW, tileHeight: tileH);
    return Offset(
      originX + ((x - minX) / 2) * cellW + lift.dx,
      originY + ((y - minY) / 2) * cellH + lift.dy,
    );
  }

  /// Дополнительный запас под тень для расчёта bounds поля.
  static Offset shadowBleed({required int maxZ, required double tileWidth}) {
    final v = visuals(
      z: maxZ,
      tileWidth: tileWidth,
      tileHeight: tileWidth * TileBaseLayout.spriteAspect,
    );
    return Offset(
      v.shadowOffset.dx + v.shadowBlur * 2.5,
      v.shadowOffset.dy + v.shadowBlur * 2.5,
    );
  }
}

/// Слой тени с offset, blur и opacity от z.
class TilePyramidShadowLayer extends StatelessWidget {
  const TilePyramidShadowLayer({
    super.key,
    required this.visuals,
    required this.tileSize,
  });

  final TilePyramidVisuals visuals;
  final Size tileSize;

  @override
  Widget build(BuildContext context) {
    Widget shadow = CustomPaint(
      size: tileSize,
      painter: TileDropShadowPainter(
        opacity: visuals.shadowOpacity,
        blur: visuals.shadowBlur,
      ),
    );

    return Positioned(
      left: visuals.shadowOffset.dx,
      top: visuals.shadowOffset.dy,
      width: tileSize.width,
      height: tileSize.height,
      child: shadow,
    );
  }
}

/// Модификатор: накладывает слои тени и базы с учётом z-пирамиды.
extension TilePyramidLayerModifier on Widget {
  Widget withTilePyramidLayers({
    required TilePyramidVisuals visuals,
    required Size tileSize,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TilePyramidShadowLayer(
          visuals: visuals,
          tileSize: tileSize,
        ),
        Positioned.fill(
          child: CustomPaint(painter: const TileFacePainter(lifted: true)),
        ),
        this,
      ],
    );
  }
}
