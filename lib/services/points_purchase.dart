import '../models/points_pack.dart';

enum PointsPurchaseStatus { purchased, cancelled, unavailable }

class PointsPurchaseResult {
  const PointsPurchaseResult(this.status, {this.points = 0});

  const PointsPurchaseResult.cancelled() : this(PointsPurchaseStatus.cancelled);

  const PointsPurchaseResult.unavailable()
    : this(PointsPurchaseStatus.unavailable);

  final PointsPurchaseStatus status;
  final int points;

  bool get isPurchased => status == PointsPurchaseStatus.purchased;
}

/// Платёжный бэкенд витрины — единственная точка, куда встанет реальный
/// биллинг магазина приложений.
abstract interface class PointsPurchaseBackend {
  /// Деньги списывает магазин, а не заглушка.
  bool get isLive;

  /// Цена пакета в том виде, в котором её показывает витрина.
  String priceLabel(PointsPack pack);

  Future<PointsPurchaseResult> buy(PointsPack pack);
}

/// Заглушка до подключения биллинга: подтверждение сразу зачисляет баллы.
class DemoPointsPurchase implements PointsPurchaseBackend {
  const DemoPointsPurchase({this.delay = const Duration(milliseconds: 400)});

  final Duration delay;

  @override
  bool get isLive => false;

  @override
  String priceLabel(PointsPack pack) => pack.priceTag;

  @override
  Future<PointsPurchaseResult> buy(PointsPack pack) async {
    await Future<void>.delayed(delay);
    return PointsPurchaseResult(
      PointsPurchaseStatus.purchased,
      points: pack.total,
    );
  }
}

abstract final class PointsPurchase {
  static PointsPurchaseBackend backend = const DemoPointsPurchase();

  static bool get isLive => backend.isLive;

  static String priceLabel(PointsPack pack) => backend.priceLabel(pack);

  static Future<PointsPurchaseResult> buy(PointsPack pack) => backend.buy(pack);
}
