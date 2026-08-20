import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../debug_agent_log.dart';
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

  /// Смещение слоя тени: z × 4 px по X и Y.
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

  /// Подъём одного слоя по Y (~8% высоты плитки при опорной ширине 80).
  static const liftStepYPx = 7.5;

  /// Лёгкий сдвиг по X: стопка растёт почти строго вверх.
  static const liftStepXPx = 1.5;

  static const _baseShadowOpacity = 0.42;
  static const _shadowOpacityPerZ = 0.09;
  static const _baseShadowBlur = 0.8;
  static const _shadowBlurPerZ = 2.6;

  static const _refTileWidth = 80.0;

  /// Масштаб px-констант под фактический размер плитки на экране.
  static double scaleFor(double tileWidth) =>
      (tileWidth / _refTileWidth).clamp(0.55, 2.4);

  /// Визуальные параметры для плитки с высотой [z].
  static TilePyramidVisuals visuals({
    required int z,
    required double tileWidth,
    required double tileHeight,
  }) {
    final scale = scaleFor(tileWidth);
    final lift = baseOffset(z: z, tileWidth: tileWidth, tileHeight: tileHeight);

    return TilePyramidVisuals(
      baseOffset: lift,
      shadowOffset: shadowOffset(z: z, scale: scale),
      shadowOpacity: shadowOpacity(z: z),
      shadowBlur: shadowBlur(z: z, scale: scale),
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

  /// shadow.x = shadow.y = z × 4 px.
  static Offset shadowOffset({required int z, double scale = 1.0}) {
    final px = z * shadowStepPx * scale;
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
      tileHeight: tileWidth * 1.15,
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
    required this.asset,
  });

  final TilePyramidVisuals visuals;
  final Size tileSize;
  final String asset;

  @override
  Widget build(BuildContext context) {
    Widget shadow = Opacity(
      opacity: visuals.shadowOpacity,
      child: TileMappedSprite(
        asset: asset,
        tileSize: tileSize,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stack) {
          // #region agent log
          agentDbg(
            location: 'tile_pyramid_position.dart:shadow',
            message: 'tile_shadow failed to decode',
            hypothesisId: 'B',
            runId: 'post-fix',
            data: {'error': error.toString(), 'asset': asset},
          );
          // #endregion
          return const SizedBox.shrink();
        },
      ),
    );

    if (visuals.shadowBlur > 0.35 && !kIsWeb) {
      shadow = ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: visuals.shadowBlur,
          sigmaY: visuals.shadowBlur,
        ),
        child: shadow,
      );
    }

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
    required String shadowAsset,
    required String baseAsset,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        TilePyramidShadowLayer(
          visuals: visuals,
          tileSize: tileSize,
          asset: shadowAsset,
        ),
        Positioned.fill(
          child: TileMappedSprite(asset: baseAsset, tileSize: tileSize),
        ),
        this,
      ],
    );
  }
}
