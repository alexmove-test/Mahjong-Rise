/// Четыре участка двора; каждые 24 уровня сменяется следующий по кругу.
enum PlotKind {
  house,
  pond,
  road,
  internet;

  static const order = [house, pond, road, internet];

  static PlotKind ofCycle(int cycle) => order[cycle % order.length];

  String get id => name;

  String get titleEn => switch (this) {
    house => 'House',
    pond => 'Pond',
    road => 'Road',
    internet => 'Internet',
  };

  String get titleRu => switch (this) {
    house => 'Дом',
    pond => 'Ставок',
    road => 'Дорога',
    internet => 'Интернет',
  };
}
