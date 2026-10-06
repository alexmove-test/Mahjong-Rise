/// Выделение пакета на витрине.
enum PointsPackBadge { popular, best }

/// Пакет баллов. [priceTag] — витринная цена, пока биллинг не подключён:
/// живой магазин отдаёт локализованную цену сам.
class PointsPack {
  const PointsPack({
    required this.id,
    required this.points,
    required this.priceTag,
    this.bonus = 0,
    this.badge,
  });

  final String id;
  final int points;
  final int bonus;
  final String priceTag;
  final PointsPackBadge? badge;

  int get total => points + bonus;

  int get bonusPercent => points <= 0 ? 0 : (bonus * 100 / points).round();

  static const catalog = <PointsPack>[
    PointsPack(id: 'points.handful', points: 50, priceTag: r'$0.01'),
    PointsPack(
      id: 'points.pouch',
      points: 150,
      bonus: 15,
      priceTag: r'$0.03',
      badge: PointsPackBadge.popular,
    ),
    PointsPack(
      id: 'points.chest',
      points: 400,
      bonus: 80,
      priceTag: r'$0.08',
    ),
    PointsPack(
      id: 'points.vault',
      points: 1000,
      bonus: 300,
      priceTag: r'$0.17',
      badge: PointsPackBadge.best,
    ),
  ];
}
