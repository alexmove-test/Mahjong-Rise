import 'pet.dart';

enum PetStoryItem {
  cushion,
  yarn,
  curtain,
  lantern,
  bell,
  telescope,
  seedling,
  butterflies,
  fountain,
  books,
  blanket,
  lamp,
  teacup,
  flowers,
  banner,
  signpost,
  bowl,
  ball,
  rope,
  badge,
  basket,
  treats,
  kite,
  compass,
  ribbon,
  flags,
  drum,
  medal,
  toolbox,
  gears,
  clock,
  coins,
  map,
  boat,
  shell,
  crate,
  wateringCan,
  windmill,
  mug,
  cookies,
  tracks,
  cart,
  station,
  seedBag,
  shelf,
  jar,
  ladder,
  star,
  pot,
  bridge,
  mushroom,
  hat,
  cake,
  confetti,
  clearing,
  bed,
  toy,
  fireflies,
  mailbox,
  letters,
  satchel,
  easel,
  paints,
  frame,
  tent,
  campfire,
}

class PetStoryDef {
  const PetStoryDef({
    required this.id,
    required this.pet,
    required this.items,
  });

  final String id;
  final PetKind pet;
  final List<PetStoryItem> items;
}

abstract final class PetStories {
  static const perPet = 5;
  static const chapters = 3;

  static const all = <PetStoryDef>[
    PetStoryDef(
      id: 'cat_window',
      pet: PetKind.cat,
      items: [PetStoryItem.cushion, PetStoryItem.yarn, PetStoryItem.curtain],
    ),
    PetStoryDef(
      id: 'cat_watch',
      pet: PetKind.cat,
      items: [PetStoryItem.lantern, PetStoryItem.bell, PetStoryItem.telescope],
    ),
    PetStoryDef(
      id: 'cat_garden',
      pet: PetKind.cat,
      items: [
        PetStoryItem.seedling,
        PetStoryItem.butterflies,
        PetStoryItem.fountain,
      ],
    ),
    PetStoryDef(
      id: 'cat_library',
      pet: PetKind.cat,
      items: [PetStoryItem.books, PetStoryItem.blanket, PetStoryItem.lamp],
    ),
    PetStoryDef(
      id: 'cat_tea',
      pet: PetKind.cat,
      items: [PetStoryItem.teacup, PetStoryItem.flowers, PetStoryItem.banner],
    ),

    PetStoryDef(
      id: 'dog_trail',
      pet: PetKind.dog,
      items: [PetStoryItem.signpost, PetStoryItem.bowl, PetStoryItem.ball],
    ),
    PetStoryDef(
      id: 'dog_bridge',
      pet: PetKind.dog,
      items: [PetStoryItem.rope, PetStoryItem.lantern, PetStoryItem.badge],
    ),
    PetStoryDef(
      id: 'dog_picnic',
      pet: PetKind.dog,
      items: [PetStoryItem.basket, PetStoryItem.blanket, PetStoryItem.treats],
    ),
    PetStoryDef(
      id: 'dog_kite',
      pet: PetKind.dog,
      items: [PetStoryItem.kite, PetStoryItem.compass, PetStoryItem.ribbon],
    ),
    PetStoryDef(
      id: 'dog_festival',
      pet: PetKind.dog,
      items: [PetStoryItem.flags, PetStoryItem.drum, PetStoryItem.medal],
    ),

    PetStoryDef(
      id: 'raccoon_workshop',
      pet: PetKind.raccoon,
      items: [PetStoryItem.toolbox, PetStoryItem.gears, PetStoryItem.clock],
    ),
    PetStoryDef(
      id: 'raccoon_market',
      pet: PetKind.raccoon,
      items: [PetStoryItem.basket, PetStoryItem.lantern, PetStoryItem.coins],
    ),
    PetStoryDef(
      id: 'raccoon_river',
      pet: PetKind.raccoon,
      items: [PetStoryItem.map, PetStoryItem.boat, PetStoryItem.shell],
    ),
    PetStoryDef(
      id: 'raccoon_recycle',
      pet: PetKind.raccoon,
      items: [
        PetStoryItem.crate,
        PetStoryItem.wateringCan,
        PetStoryItem.windmill,
      ],
    ),
    PetStoryDef(
      id: 'raccoon_cafe',
      pet: PetKind.raccoon,
      items: [PetStoryItem.mug, PetStoryItem.cookies, PetStoryItem.signpost],
    ),

    PetStoryDef(
      id: 'hamster_railway',
      pet: PetKind.hamster,
      items: [PetStoryItem.tracks, PetStoryItem.cart, PetStoryItem.station],
    ),
    PetStoryDef(
      id: 'hamster_pantry',
      pet: PetKind.hamster,
      items: [PetStoryItem.seedBag, PetStoryItem.shelf, PetStoryItem.jar],
    ),
    PetStoryDef(
      id: 'hamster_clouds',
      pet: PetKind.hamster,
      items: [PetStoryItem.ladder, PetStoryItem.telescope, PetStoryItem.star],
    ),
    PetStoryDef(
      id: 'hamster_garden',
      pet: PetKind.hamster,
      items: [PetStoryItem.pot, PetStoryItem.bridge, PetStoryItem.mushroom],
    ),
    PetStoryDef(
      id: 'hamster_birthday',
      pet: PetKind.hamster,
      items: [PetStoryItem.hat, PetStoryItem.cake, PetStoryItem.confetti],
    ),

    PetStoryDef(
      id: 'fox_cozy',
      pet: PetKind.fox,
      items: [PetStoryItem.clearing, PetStoryItem.bed, PetStoryItem.toy],
    ),
    PetStoryDef(
      id: 'fox_fireflies',
      pet: PetKind.fox,
      items: [
        PetStoryItem.lantern,
        PetStoryItem.flowers,
        PetStoryItem.fireflies,
      ],
    ),
    PetStoryDef(
      id: 'fox_post',
      pet: PetKind.fox,
      items: [PetStoryItem.mailbox, PetStoryItem.letters, PetStoryItem.satchel],
    ),
    PetStoryDef(
      id: 'fox_studio',
      pet: PetKind.fox,
      items: [PetStoryItem.easel, PetStoryItem.paints, PetStoryItem.frame],
    ),
    PetStoryDef(
      id: 'fox_camp',
      pet: PetKind.fox,
      items: [PetStoryItem.tent, PetStoryItem.campfire, PetStoryItem.telescope],
    ),
  ];

  static List<PetStoryDef> forPet(PetKind pet) =>
      all.where((story) => story.pet == pet).toList(growable: false);

  static PetStoryDef? byId(String? id) {
    if (id == null) return null;
    for (final story in all) {
      if (story.id == id) return story;
    }
    return null;
  }
}


