import 'dart:math' as math;
import 'dart:ui';

import '../../models/courtyard_reward.dart';
import 'courtyard_lot_build.dart';

/// Нормированная раскладка `country_base.png` (9:16): двор по центру экрана.
abstract final class CourtyardWorldLayout {
  static const mapWidth = 720.0;
  static const mapHeight = 1280.0;
  static const mapAspect = mapWidth / mapHeight;

  static const countryBase = 'assets/courtyard/world/country_base.png';

  /// Лужайка внутри ограды, в долях карты. Небо над ней закрывает верхняя панель.
  static const lawn = Rect.fromLTRB(0.06, 0.38, 0.94, 0.70);

  /// Дом на каменном круге: низ рамки — линия земли, примерно середина экрана.
  static const homeYard = Rect.fromLTWH(0.111, 0.359, 0.278, 0.156);

  /// Голая земля справа от развилки. Пруд встаёт сюда, когда дом достроен.
  static const pondYard = Rect.fromLTWH(0.64, 0.345, 0.26, 0.15);

  /// Знак производства семян: в зазоре между домом и качелями, не на доме и не на питомцах.
  static const seedBadge = Rect.fromLTWH(0.393, 0.414, 0.083, 0.047);

  /// Три грядки на траве сразу перед домом: ниже дома и выше клумбы.
  static const gardenBeds = <Rect>[
    Rect.fromLTWH(0.06, 0.522, 0.105, 0.038),
    Rect.fromLTWH(0.175, 0.522, 0.105, 0.038),
    Rect.fromLTWH(0.290, 0.522, 0.105, 0.038),
  ];

  static Rect gardenBed(int index) => gardenBeds[index];

  /// Склад на передней траве справа, ниже питомцев и в стороне от пруда.
  static const warehouse = Rect.fromLTWH(0.64, 0.648, 0.22, 0.050);

  /// Питомцы на поляне впереди-справа, у развилки дорожки.
  /// Шире одной фигурки: на лужайке может стоять вся компания.
  static const petYard = Rect.fromLTWH(0.52, 0.50, 0.32, 0.14);

  /// Соседние дворы вырезаны из кадра, тапать на карте нечего.
  static const neighbors = <Rect>[];

  static int get neighborCount => neighbors.length;

  /// Кадр камеры: вся лужайка с запасом на ограду.
  static Rect get yardCover => lawn.inflate(0.02);

  /// Награды стоят на свободной траве, в стороне от дома и питомца.
  /// Спрайты квадратные, поэтому рамка тоже квадратная в пикселях карты:
  /// доля высоты больше доли ширины во столько же раз, во сколько карта шире.
  static Rect rewardOf(CourtyardReward reward) => switch (reward) {
    CourtyardReward.pond => _standing(0.78, 0.47, 0.16),
    CourtyardReward.swing => _standing(0.55, 0.46, 0.14),
    CourtyardReward.flowerBed => _standing(0.22, 0.64, 0.14),
  };

  /// Квадратная рамка ширины [width], стоящая низом на точке ([x], [ground]).
  static Rect _standing(double x, double ground, double width) {
    final height = width * mapAspect;
    return Rect.fromLTWH(x - width / 2, ground - height, width, height);
  }

  static Rect neighborOf(int slot) => neighbors[slot];

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
