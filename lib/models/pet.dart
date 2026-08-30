/// Питомец двора и независимые циклы потребностей.
enum PetKind { cat, dog, raccoon, hamster, fox }

enum PetNeed { hunger, play, rest }

enum PetMood { content, asking, starving }

class PetDef {
  const PetDef({required this.kind, required this.symbol});

  final PetKind kind;
  final String symbol;

  static const all = [
    PetDef(kind: PetKind.cat, symbol: 'animal-01'),
    PetDef(kind: PetKind.dog, symbol: 'animal-02'),
    PetDef(kind: PetKind.raccoon, symbol: 'animal-12'),
    PetDef(kind: PetKind.hamster, symbol: 'animal-07'),
    PetDef(kind: PetKind.fox, symbol: 'animal-16'),
  ];

  static PetDef of(PetKind kind) => all.firstWhere((d) => d.kind == kind);
}

/// Результат победы: какая потребность какого питомца закрылась.
class PetFill {
  const PetFill({required this.kind, required this.need});

  final PetKind kind;
  final PetNeed need;
}

/// Чистые формулы полноты и порогов. Время подставляется снаружи.
abstract final class PetNeeds {
  PetNeeds._();

  static const hungerCycle = Duration(hours: 10);
  static const playCycle = Duration(hours: 18);
  static const restCycle = Duration(hours: 28);
  static const askThreshold = 0.45;

  static Duration cycleOf(PetNeed need) => switch (need) {
    PetNeed.hunger => hungerCycle,
    PetNeed.play => playCycle,
    PetNeed.rest => restCycle,
  };

  static double fullness({
    required DateTime lastSatisfied,
    required PetNeed need,
    required DateTime now,
  }) {
    final elapsed = now.difference(lastSatisfied);
    if (elapsed.isNegative) return 1;
    final cycleMs = cycleOf(need).inMilliseconds;
    if (cycleMs <= 0) return 0;
    return (1.0 - elapsed.inMilliseconds / cycleMs).clamp(0.0, 1.0);
  }

  static PetNeed mostUrgent(Map<PetNeed, double> fullness) {
    var chosen = PetNeed.hunger;
    var lowest = 2.0;
    for (final need in PetNeed.values) {
      final value = fullness[need] ?? 0;
      if (value < lowest) {
        lowest = value;
        chosen = need;
      }
    }
    return chosen;
  }

  /// Когда полнота дойдёт до [threshold], или null если уже ниже.
  static DateTime? nextThreshold({
    required DateTime lastSatisfied,
    required PetNeed need,
    required double threshold,
    required DateTime now,
  }) {
    final cycleMs = cycleOf(need).inMilliseconds;
    final waitMs = (cycleMs * (1.0 - threshold)).round();
    final at = lastSatisfied.add(Duration(milliseconds: waitMs));
    if (!at.isAfter(now)) return null;
    return at;
  }

  static PetMood mood({
    required double hunger,
    required double play,
    required double rest,
  }) {
    if (hunger <= 0) return PetMood.starving;
    final lowest = [hunger, play, rest].reduce((a, b) => a < b ? a : b);
    if (lowest < askThreshold) return PetMood.asking;
    return PetMood.content;
  }
}

class PetCare {
  const PetCare({
    required this.kind,
    required this.fullness,
  });

  final PetKind kind;
  final Map<PetNeed, double> fullness;

  double of(PetNeed need) => fullness[need] ?? 0;

  double get lowest =>
      PetNeed.values.map(of).reduce((a, b) => a < b ? a : b);

  bool get starving => of(PetNeed.hunger) <= 0;
  bool get asking => lowest < PetNeeds.askThreshold;
  PetMood get mood => PetNeeds.mood(
    hunger: of(PetNeed.hunger),
    play: of(PetNeed.play),
    rest: of(PetNeed.rest),
  );
  PetNeed get mostUrgent => PetNeeds.mostUrgent(fullness);
}
