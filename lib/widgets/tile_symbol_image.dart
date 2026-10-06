import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../debug_agent_log.dart';
import '../services/table_look_controller.dart';
import '../utils/tile_icons.dart';

/// Иконка символа: SVG или PNG из [assets/titles].
class TileSymbolImage extends StatelessWidget {
  const TileSymbolImage({
    super.key,
    required this.symbol,
    this.fit = BoxFit.contain,
    this.placeholder = const SizedBox.shrink(),
  });

  final String symbol;
  final BoxFit fit;
  final Widget placeholder;

  static int _logged = 0;

  @override
  Widget build(BuildContext context) {
    final look = TableLookScope.lookOf(context);
    // «Новая» использует масштабируемые SVG там, где они доступны.
    final preferRaster = look.isCasual;
    final asset = TileIcons.assetFor(symbol, casual: preferRaster);
    final raster = TileIcons.isRasterAsset(asset);
    final vectorFallback = TileIcons.vectorFallbackFor(
      symbol,
      casual: preferRaster,
    );
    // #region agent log
    if (_logged < 4) {
      _logged++;
      agentDbg(
        location: 'tile_symbol_image.dart:build',
        message: 'symbol asset resolved',
        hypothesisId: 'D',
        data: {
          'symbol': symbol,
          'asset': asset,
          'raster': raster,
          'fallback': vectorFallback,
        },
      );
    }
    // #endregion
    if (raster) {
      return Image.asset(
        asset,
        fit: fit,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stack) {
          // #region agent log
          agentDbg(
            location: 'tile_symbol_image.dart:raster',
            message: 'symbol raster failed',
            hypothesisId: 'D',
            data: {'symbol': symbol, 'asset': asset, 'error': error.toString()},
          );
          // #endregion
          if (vectorFallback != null) {
            return SvgPicture.asset(
              vectorFallback,
              fit: fit,
              clipBehavior: Clip.hardEdge,
              placeholderBuilder: (_) => placeholder,
            );
          }
          return placeholder;
        },
      );
    }

    return SvgPicture.asset(
      asset,
      fit: fit,
      clipBehavior: Clip.hardEdge,
      placeholderBuilder: (_) => placeholder,
    );
  }
}
