import 'house_upgrade.dart';

/// Класс семени. Срок роста, цена посадки и корм зависят только от него.
enum SeedClass { common, nutrient, rare }

/// Шесть вымышленных видов, по два в каждом классе.
enum SeedSpecies {
  amberbell(SeedClass.common),
  mistfern(SeedClass.common),
  glassreed(SeedClass.nutrient),
  crimsonplum(SeedClass.nutrient),
  nightlotus(SeedClass.rare),
  starbamboo(SeedClass.rare);

  const SeedSpecies(this.seedClass);

  final SeedClass seedClass;
}

/// Доля класса на текущем уровне дома.
class SeedClassChance {
  const SeedClassChance({required this.seedClass, required this.percent});

  final SeedClass seedClass;
  final int percent;

  List<SeedSpecies> get species => [
    for (final species in SeedSpecies.values)
      if (species.seedClass == seedClass) species,
  ];
}

/// Источник экземпляра. Посадка и скрещивание появятся отдельными источниками.
abstract final class SeedSource {
  static const houseProduction = 'house_production';
}

/// Правила производства версии [rulesVersion].
///
/// Срок дома, цена минуты, классы и корм живут только здесь.
/// Платное ускорение, очередь и автозапуск в эту версию не входят.
abstract final class SeedCatalog {
  static const rulesVersion = 2;

  static Duration durationForLevel(int houseLevel) {
    final level = HouseUpgrade.clampState(houseLevel);
    final seconds = 600 - 20 * (level - 1);
    return Duration(seconds: seconds < 180 ? 180 : seconds);
  }

  /// Одна минута таймера стоит 1 поинт. Короче нуля не бывает.
  static int pointsFor(Duration duration) {
    final rounded = (duration.inSeconds / 60).round();
    return rounded < 1 ? 1 : rounded;
  }

  static int costForLevel(int houseLevel) =>
      pointsFor(durationForLevel(houseLevel));

  static int foodFor(SeedSpecies species) => switch (species.seedClass) {
    SeedClass.common => 10,
    SeedClass.nutrient => 25,
    SeedClass.rare => 60,
  };

  static List<SeedClassChance> chancesAt(int houseLevel) {
    final level = HouseUpgrade.clampState(houseLevel);
    if (level <= 4) {
      return const [SeedClassChance(seedClass: SeedClass.common, percent: 100)];
    }
    if (level <= 12) {
      return const [
        SeedClassChance(seedClass: SeedClass.common, percent: 75),
        SeedClassChance(seedClass: SeedClass.nutrient, percent: 25),
      ];
    }
    if (level <= 20) {
      return const [
        SeedClassChance(seedClass: SeedClass.common, percent: 55),
        SeedClassChance(seedClass: SeedClass.nutrient, percent: 35),
        SeedClassChance(seedClass: SeedClass.rare, percent: 10),
      ];
    }
    return const [
      SeedClassChance(seedClass: SeedClass.common, percent: 40),
      SeedClassChance(seedClass: SeedClass.nutrient, percent: 40),
      SeedClassChance(seedClass: SeedClass.rare, percent: 20),
    ];
  }

  static bool bandChanges(int from, int to) {
    final current = chancesAt(from);
    final next = chancesAt(to);
    if (current.length != next.length) return true;
    for (var i = 0; i < current.length; i++) {
      if (current[i].seedClass != next[i].seedClass ||
          current[i].percent != next[i].percent) {
        return true;
      }
    }
    return false;
  }

  static List<SeedSpecies> speciesAt(int houseLevel) => [
    for (final chance in chancesAt(houseLevel)) ...chance.species,
  ];

  /// Сначала класс по весу из 100, затем один из двух видов поровну.
  ///
  /// [roll] — это `Random.nextInt`: первый вызов получает 100, второй — число видов.
  static SeedSpecies rollSpecies(int houseLevel, int Function(int count) roll) {
    final chances = chancesAt(houseLevel);
    var ticket = roll(100);
    if (ticket < 0) ticket = 0;
    SeedClassChance chosen = chances.last;
    for (final chance in chances) {
      if (ticket < chance.percent) {
        chosen = chance;
        break;
      }
      ticket -= chance.percent;
    }
    final species = chosen.species;
    var index = roll(species.length);
    if (index < 0 || index >= species.length) index = 0;
    return species[index];
  }

  static SeedOffer offerFor(int houseLevel) {
    final level = HouseUpgrade.clampState(houseLevel);
    final duration = durationForLevel(level);
    return SeedOffer(
      houseLevel: level,
      cost: pointsFor(duration),
      duration: duration,
      chances: chancesAt(level),
    );
  }
}

/// Параметры партии, которые дом может запустить прямо сейчас.
class SeedOffer {
  const SeedOffer({
    required this.houseLevel,
    required this.cost,
    required this.duration,
    required this.chances,
  });

  final int houseLevel;
  final int cost;
  final Duration duration;
  final List<SeedClassChance> chances;

  List<SeedSpecies> get species => [
    for (final chance in chances) ...chance.species,
  ];
}
