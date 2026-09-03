import 'dart:math' as math;
import 'dart:ui';

import '../../models/plot_kind.dart';
import 'courtyard_lot_build.dart';

/// Нормированная раскладка `country_base.png` (3:2): свой двор в центре, соседи на холмах.
abstract final class CourtyardWorldLayout {
  static const mapWidth = 1536.0;
  static const mapHeight = 1024.0;
  static const mapAspect = mapWidth / mapHeight;

  static const countryBase = 'assets/courtyard/world/country_base.png';

  static const lotWidth = 0.136;
  static const lotHeight = 0.155;

  /// Центры в пикселях `country_base.png` (1536×1024).
  /// Дом: 594,470 (47 на карте — верх плато, не 47 px).
  static final lots = <PlotKind, Rect>{
    PlotKind.house: lotAtPx(594, 470),
    PlotKind.pond: lotAtPx(971, 474),
    PlotKind.pets: lotAtPx(979, 766),
    PlotKind.guest: lotAtPx(574, 715),
  };

  static Rect lotAtPx(double x, double y) {
    return Rect.fromCenter(
      center: Offset(x / mapWidth, y / mapHeight),
      width: lotWidth,
      height: lotHeight,
    );
  }

  static const neighbors = <Rect>[
    Rect.fromLTWH(0.13, 0.26, 0.14, 0.14),
    Rect.fromLTWH(0.40, 0.12, 0.14, 0.14),
    Rect.fromLTWH(0.64, 0.18, 0.16, 0.16),
    Rect.fromLTWH(0.78, 0.38, 0.14, 0.14),
  ];

  static int get neighborCount => neighbors.length;

  static Rect get plateau {
    var left = lots[PlotKind.house]!.left;
    var top = lots[PlotKind.house]!.top;
    var right = lots[PlotKind.house]!.right;
    var bottom = lots[PlotKind.house]!.bottom;
    for (final lot in lots.values) {
      left = math.min(left, lot.left);
      top = math.min(top, lot.top);
      right = math.max(right, lot.right);
      bottom = math.max(bottom, lot.bottom);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  static Rect lotOf(PlotKind kind) => lots[kind]!;

  static Rect neighborOf(int slot) => neighbors[slot];

  /// Экранный 2×2 двора: дом|пруд / гости|питомцы.
  static (int col, int row) lotCell(PlotKind kind) => switch (kind) {
    PlotKind.house => (0, 0),
    PlotKind.pond => (1, 0),
    PlotKind.guest => (0, 1),
    PlotKind.pets => (1, 1),
  };

  static Rect neighborLotOf(int slot, PlotKind kind) {
    final hill = neighborOf(slot);
    final (col, row) = lotCell(kind);
    final w = hill.width / 2;
    final h = hill.height / 2;
    return Rect.fromLTWH(hill.left + col * w, hill.top + row * h, w, h);
  }

  static Rect mapRect(Rect norm) {
    return Rect.fromLTWH(
      norm.left * mapWidth,
      norm.top * mapHeight,
      norm.width * mapWidth,
      norm.height * mapHeight,
    );
  }

  /// Масштаб, при котором карта закрывает весь [viewport] — без полей по бокам.
  static double coverScale(Size viewport) {
    if (viewport.width < 1 || viewport.height < 1) return 1;
    return math.max(viewport.width / mapWidth, viewport.height / mapHeight);
  }

  /// Камера: участок в кадре, карта всегда до краёв экрана.
  static ({double scale, double tx, double ty}) camera({
    required Size viewport,
    required Rect focusNorm,
    double coverage = 0.78,
  }) {
    final focus = mapRect(focusNorm);
    final cover = coverScale(viewport);
    var scale = math.min(
      viewport.width * coverage / focus.width,
      viewport.height * coverage / focus.height,
    );
    if (scale < cover) scale = cover;

    var tx = viewport.width / 2 - focus.center.dx * scale;
    var ty = viewport.height / 2 - focus.center.dy * scale;
    final minTx = viewport.width - mapWidth * scale;
    final minTy = viewport.height - mapHeight * scale;
    if (minTx <= 0) tx = tx.clamp(minTx, 0);
    if (minTy <= 0) ty = ty.clamp(minTy, 0);
    return (scale: scale, tx: tx, ty: ty);
  }

  static List<String> get allAssets => [countryBase, ...PlotStages.allAssets];
}
