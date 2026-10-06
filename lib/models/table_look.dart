/// Visual skin of the game table. New (premium) is the default.
enum TableLook {
  classic,
  casual,
  premium;

  static const storedClassic = 'classic';
  static const storedCasual = 'casual';
  static const storedPremium = 'premium';
  static const defaultLook = TableLook.premium;

  static TableLook? tryParse(String? raw) {
    return switch (raw) {
      storedClassic => TableLook.classic,
      storedCasual => TableLook.casual,
      storedPremium => TableLook.premium,
      _ => null,
    };
  }

  static TableLook parse(String? raw) => tryParse(raw) ?? defaultLook;

  String get id => switch (this) {
    TableLook.classic => storedClassic,
    TableLook.casual => storedCasual,
    TableLook.premium => storedPremium,
  };

  bool get isCasual => this == TableLook.casual;

  /// Новая тема: белая фарфоровая кость с тёплым торцом, как на референсе.
  bool get isPremium => this == TableLook.premium;

  /// Classic and casual can still be recorded as courtyard gifts.
  /// The menu offers every look from the first launch.
  bool get isGift => this == classic || this == casual;

  static const giftLooks = [classic, casual];

  static Set<TableLook> giftsFrom(Iterable<dynamic> raw) {
    final names = raw.whereType<String>().toSet();
    return {
      for (final look in giftLooks)
        if (names.contains(look.id)) look,
    };
  }
}
