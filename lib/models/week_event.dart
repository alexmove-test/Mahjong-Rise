import 'week_id.dart';

/// Weekly daily-table modifier. Catalog is fixed; rotation is from [WeekId].
class WeekEvent {
  const WeekEvent({
    required this.id,
    required this.style,
    required this.extraBoosts,
  });

  final String id;
  final String style;
  final int extraBoosts;

  static const catalog = <WeekEvent>[
    WeekEvent(id: 'garden', style: 'nature', extraBoosts: 1),
    WeekEvent(id: 'court', style: 'court', extraBoosts: 1),
    WeekEvent(id: 'lanterns', style: 'classic', extraBoosts: 1),
    WeekEvent(id: 'myth', style: 'myth', extraBoosts: 1),
    WeekEvent(id: 'harvest', style: 'fruit', extraBoosts: 1),
  ];

  static WeekEvent forWeek(WeekId week) =>
      catalog[week.seed.abs() % catalog.length];

  static WeekEvent current([DateTime? now]) =>
      forWeek(WeekId.fromDate(now ?? DateTime.now()));
}
