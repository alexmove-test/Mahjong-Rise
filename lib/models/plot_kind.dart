/// Четыре участка двора; каждые 24 уровня сменяется следующий по кругу.
enum PlotKind {
  house,
  pond,
  pets,
  guest;

  static const order = [house, pond, guest, pets];

  static PlotKind ofCycle(int cycle) => order[cycle % order.length];

  static PlotKind? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final kind in values) {
      if (kind.name == raw) return kind;
    }
    return null;
  }

  String get id => name;

  /// Папка 24 кадров постройки. Гостевой участок идёт по старому треку интернет.
  String get buildFolder => switch (this) {
    guest => 'internet',
    _ => name,
  };

  String get titleEn => switch (this) {
    house => 'House',
    pond => 'Pond',
    pets => 'Pets',
    guest => 'Guest house',
  };

  String get titleRu => switch (this) {
    house => 'Дом',
    pond => 'Ставок',
    pets => 'Питомцы',
    guest => 'Дом для гостей',
  };
}
