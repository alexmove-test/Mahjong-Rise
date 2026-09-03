import '../../models/levels.dart';
import '../../models/plot_kind.dart';
import '../../services/progress_store.dart';

/// Монотонный рост участка: 12 эпох × 8 шагов = 96 стадий на каждый PlotKind.
///
/// По умолчанию уровни качают участки по очереди. Стадия — число пройденных
/// уровней этого вида, с потолком [maxStage].
abstract final class CourtyardLotBuild {
  static const maxStage = 96;
  static const eraLength = 8;
  static const eraCount = 12;

  static double stageOf({required int maxUnlocked, required PlotKind kind}) {
    if (!Levels.plotReached(kind, maxUnlocked)) return 0;
    return Levels.completedStages(
      kind,
      maxUnlocked,
    ).clamp(0, maxStage).toDouble();
  }

  static double stageFromProgress(ProgressStore store, PlotKind kind) {
    if (!store.plotReached(kind)) return 0;
    return store.plotStage(kind).clamp(0, maxStage).toDouble();
  }

  /// 0–11. Стадия 0 (пустое поле) читается как начало первой эпохи.
  static int eraIndex(num stage) {
    if (stage <= 0) return 0;
    return ((stage - 1).floor() ~/ eraLength).clamp(0, eraCount - 1);
  }

  /// 0 на пустом поле, иначе 1–8 внутри эпохи.
  static int detailInEra(num stage) {
    if (stage <= 0) return 0;
    return ((stage - 1).floor() % eraLength) + 1;
  }

  /// Прозрачность слоя с номером [layer] (1…[maxStage]) при дробной стадии.
  /// Целая стадия N показывает слои 1…N полностью; дробная часть
  /// проявляет следующий слой — так работает победный lerp.
  static double layerOpacity(num stage, int layer) {
    if (layer <= 0) return 0;
    if (stage >= layer) return 1;
    if (stage <= layer - 1) return 0;
    return (stage.toDouble() - (layer - 1)).clamp(0.0, 1.0).toDouble();
  }

  /// 0 = пустой участок, 1 = домик с карты полностью виден.
  /// Первый круг из 24 уровней проявляет участок; дальше он остаётся собранным.
  static double revealOf({required double stage, required bool unlocked}) {
    if (!unlocked) return 0;
    return (stage / Levels.storyLength).clamp(0.0, 1.0);
  }

  static String eraNameEn(PlotKind kind, int era) {
    final e = era.clamp(0, eraCount - 1);
    return switch (kind) {
      PlotKind.house => houseEraNamesEn[e],
      PlotKind.pond => pondEraNamesEn[e],
      PlotKind.pets => petsEraNamesEn[e],
      PlotKind.guest => guestEraNamesEn[e],
    };
  }

  static String eraNameRu(PlotKind kind, int era) {
    final e = era.clamp(0, eraCount - 1);
    return switch (kind) {
      PlotKind.house => houseEraNamesRu[e],
      PlotKind.pond => pondEraNamesRu[e],
      PlotKind.pets => petsEraNamesRu[e],
      PlotKind.guest => guestEraNamesRu[e],
    };
  }
}

/// 24 кадра эволюции участка: 12 эпох × 2 шага, растянутые на [CourtyardLotBuild.maxStage].
abstract final class PlotStages {
  static const frameCount = 24;
  static const stagesPerFrame = 4;
  static const assetDir = 'assets/courtyard/builds';

  static String assetOf(PlotKind kind, int frame) {
    final n = frame.toString().padLeft(2, '0');
    return '$assetDir/${kind.buildFolder}/$n.png';
  }

  static List<String> assetsFor(PlotKind kind) {
    return [for (var i = 1; i <= frameCount; i++) assetOf(kind, i)];
  }

  static List<String> get allAssets => [
    for (final kind in PlotKind.order) ...assetsFor(kind),
  ];

  /// 0 = пустой участок, 1…24 = номер кадра.
  static int currentFrame(double stage) {
    if (stage < 1) return 0;
    return (((stage - 1) / stagesPerFrame).floor() + 1).clamp(1, frameCount);
  }

  static int nextFrame(double stage) {
    if (stage <= 0) return 0;
    return currentFrame(stage.ceil().toDouble());
  }

  static double nextOpacity(double stage) {
    if (stage <= 0) return 0;
    if (stage >= CourtyardLotBuild.maxStage) return 0;
    final current = currentFrame(stage);
    final next = nextFrame(stage);
    if (next <= current) return 0;
    return (stage - stage.floor()).clamp(0.0, 1.0);
  }

  static bool isMaxFrame(double stage) => currentFrame(stage) >= frameCount;

  /// Стадия, на которой сменится картинка. `null`, если кадр уже последний.
  static int? nextFrameStage(double stage) {
    if (isMaxFrame(stage)) return null;
    if (stage < 1) return 1;
    return currentFrame(stage) * stagesPerFrame + 1;
  }

  /// Сколько побед на этом участке до следующей картинки.
  static int remainingToNextFrame(double stage) {
    return remainingExact(stage).ceil().clamp(0, stagesPerFrame);
  }

  /// Дробный остаток до следующей картинки — для lerp после победы.
  static double remainingExact(double stage) {
    final nextAt = nextFrameStage(stage);
    if (nextAt == null) return 0;
    return (nextAt - stage).clamp(0.0, stagesPerFrame.toDouble());
  }

  /// 0…1: сколько уже сделано из шагов до следующей картинки.
  static double frameProgress(double stage) {
    if (isMaxFrame(stage)) return 1;
    if (stage < 1) return stage.clamp(0.0, 1.0);
    return (1 - remainingExact(stage) / stagesPerFrame).clamp(0.0, 1.0);
  }
}

const houseEraNamesEn = <String>[
  'Clearing',
  'Shack',
  'Hut',
  'Cabin',
  'House',
  'Cottage',
  'Estate',
  'Mansion',
  'Keep',
  'Castle',
  'Grand castle',
  'Residence',
];

const houseEraNamesRu = <String>[
  'Пустырь',
  'Лачуга',
  'Хижина',
  'Изба',
  'Дом',
  'Коттедж',
  'Усадьба',
  'Особняк',
  'Крепость',
  'Замок',
  'Большой замок',
  'Резиденция',
];

const pondEraNamesEn = <String>[
  'Hollow',
  'Puddle',
  'Pond',
  'Walkway',
  'Koi pond',
  'Pavilion',
  'Water garden',
  'Stone banks',
  'Bridge',
  'Water court',
  'Palace pond',
  'Water garden complete',
];

const pondEraNamesRu = <String>[
  'Низина',
  'Лужа',
  'Ставок',
  'Мостки',
  'Пруд с карпами',
  'Беседка',
  'Водный сад',
  'Каменные берега',
  'Мост',
  'Водный двор',
  'Дворцовый пруд',
  'Сад готов',
];

const petsEraNamesEn = <String>[
  'Yard',
  'Bowls',
  'Kennel',
  'Hutch',
  'Pet house',
  'Play yard',
  'Garden',
  'Den',
  'Lodge',
  'Menagerie',
  'Sanctuary',
  'Pet home complete',
];

const petsEraNamesRu = <String>[
  'Двор',
  'Миски',
  'Будка',
  'Клетка',
  'Домик питомца',
  'Площадка',
  'Сад',
  'Нора',
  'Флигель',
  'Зверинец',
  'Приют',
  'Домик готов',
];

const guestEraNamesEn = <String>[
  'Quiet yard',
  'Pole',
  'Cable',
  'Dish',
  'Screens',
  'Line lamp',
  'Far talk',
  'Signal tower',
  'Observatory',
  'Crystal line',
  'Beacon',
  'Yard online',
];

const guestEraNamesRu = <String>[
  'Тихий двор',
  'Столб',
  'Кабель',
  'Тарелка',
  'Экраны',
  'Фонарь линии',
  'Дальняя связь',
  'Башня сигнала',
  'Обсерватория',
  'Хрустальная линия',
  'Маяк',
  'Двор в сети',
];

const houseEraPhrasesEn = <String>[
  'A house will stand here.',
  'A shack leans on the plot.',
  'The hut has a door.',
  'The cabin is timber now.',
  'A real house stands here.',
  'The cottage has two floors.',
  'The estate spreads its wings.',
  'The mansion is stone.',
  'The walls become a keep.',
  'A castle rises.',
  'The castle fills the hill.',
  'The residence is complete.',
];

const houseEraPhrasesRu = <String>[
  'Здесь будет дом.',
  'На участке встала лачуга.',
  'У хижины появилась дверь.',
  'Изба уже из бревен.',
  'Стоит настоящий дом.',
  'У коттеджа два этажа.',
  'Усадьба расправила крылья.',
  'Особняк стал каменным.',
  'Стены стали крепостью.',
  'Растёт замок.',
  'Замок занял холм.',
  'Резиденция собрана.',
];

const pondEraPhrasesEn = <String>[
  'A pond will fill this hollow.',
  'The puddle holds.',
  'Reeds take the shore.',
  'The walkway is down.',
  'Koi have a home.',
  'A pavilion watches the water.',
  'The pond is a garden.',
  'Stone banks and lanterns.',
  'A bridge crosses the water.',
  'The water court is walled.',
  'Palace gardens reach the pond.',
  'The water garden is complete.',
];

const pondEraPhrasesRu = <String>[
  'Здесь нальётся ставок.',
  'Лужа держит воду.',
  'Камыш взял кромку.',
  'Мостки легли.',
  'Карпам есть дом.',
  'Беседка смотрит на воду.',
  'Ставок стал садом.',
  'Каменные берега и фонари.',
  'Мост перешёл воду.',
  'Водный двор обнесён стеной.',
  'Дворцовый сад дошёл до ставка.',
  'Водный сад собран.',
];

const petsEraPhrasesEn = <String>[
  'A pet house will stand here.',
  'Bowls wait in the grass.',
  'A kennel leans on the plot.',
  'The hutch has a door.',
  'The pets have a house.',
  'A play yard opens.',
  'The garden is theirs.',
  'A den is lined.',
  'The lodge is warm.',
  'A menagerie gathers.',
  'The sanctuary is fenced.',
  'The pet house is complete.',
];

const petsEraPhrasesRu = <String>[
  'Здесь будет домик питомца.',
  'Миски ждут в траве.',
  'На участке встала будка.',
  'У клетки появилась дверь.',
  'У питомцев есть дом.',
  'Открылась площадка.',
  'Сад стал их.',
  'Нора выстлана.',
  'Флигель тёплый.',
  'Зверинец собирается.',
  'Приют обнесён.',
  'Домик питомца собран.',
];

const guestEraPhrasesEn = <String>[
  'A signal will reach this yard.',
  'The pole holds the line.',
  'Cable finds the house.',
  'The dish is up.',
  'Screens glow in the yard.',
  'A lamp of the line.',
  'The yard talks farther.',
  'A tower of the signal.',
  'The observatory rises.',
  'Crystal and wire.',
  'A beacon on the hill.',
  'The yard is fully online.',
];

const guestEraPhrasesRu = <String>[
  'Сюда дойдёт сигнал.',
  'Столб держит линию.',
  'Кабель нашёл дом.',
  'Тарелка стоит.',
  'Экраны светятся во дворе.',
  'Фонарь линии.',
  'Двор говорит дальше.',
  'Башня сигнала.',
  'Растёт обсерватория.',
  'Хрусталь и провод.',
  'Маяк на холме.',
  'Двор полностью в сети.',
];

List<String> eraPhrasesFor(PlotKind kind, {required bool ru}) => switch (kind) {
  PlotKind.house => ru ? houseEraPhrasesRu : houseEraPhrasesEn,
  PlotKind.pond => ru ? pondEraPhrasesRu : pondEraPhrasesEn,
  PlotKind.pets => ru ? petsEraPhrasesRu : petsEraPhrasesEn,
  PlotKind.guest => ru ? guestEraPhrasesRu : guestEraPhrasesEn,
};
