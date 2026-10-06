import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/pet.dart';
import '../../models/pet_story.dart';
import '../../services/pet_story_store.dart';
import 'pet_portrait.dart';

const petStorySectionKey = ValueKey('pet-story-section');
const petStoryMomentKey = ValueKey('pet-story-moment');

String petStoryItemTitle(AppLocalizations l, PetStoryItem item) =>
    l.petItemTitle(item);

IconData _itemIcon(PetStoryItem item) => switch (item) {
  PetStoryItem.cushion || PetStoryItem.bed => Icons.bed_rounded,
  PetStoryItem.yarn || PetStoryItem.ball => Icons.sports_baseball_rounded,
  PetStoryItem.curtain ||
  PetStoryItem.banner ||
  PetStoryItem.flags => Icons.flag_rounded,
  PetStoryItem.lantern ||
  PetStoryItem.lamp ||
  PetStoryItem.fireflies => Icons.lightbulb_rounded,
  PetStoryItem.bell => Icons.notifications_active_rounded,
  PetStoryItem.telescope || PetStoryItem.star => Icons.auto_awesome_rounded,
  PetStoryItem.seedling ||
  PetStoryItem.flowers ||
  PetStoryItem.pot => Icons.local_florist_rounded,
  PetStoryItem.butterflies => Icons.flutter_dash_rounded,
  PetStoryItem.fountain || PetStoryItem.bowl => Icons.water_drop_rounded,
  PetStoryItem.books => Icons.menu_book_rounded,
  PetStoryItem.blanket => Icons.texture_rounded,
  PetStoryItem.teacup || PetStoryItem.mug => Icons.emoji_food_beverage_rounded,
  PetStoryItem.signpost => Icons.signpost_rounded,
  PetStoryItem.rope || PetStoryItem.ribbon => Icons.gesture_rounded,
  PetStoryItem.badge || PetStoryItem.medal => Icons.workspace_premium_rounded,
  PetStoryItem.basket || PetStoryItem.crate => Icons.shopping_basket_rounded,
  PetStoryItem.treats || PetStoryItem.cookies => Icons.cookie_rounded,
  PetStoryItem.kite => Icons.air_rounded,
  PetStoryItem.compass || PetStoryItem.map => Icons.explore_rounded,
  PetStoryItem.drum => Icons.music_note_rounded,
  PetStoryItem.toolbox => Icons.handyman_rounded,
  PetStoryItem.gears || PetStoryItem.clock => Icons.settings_rounded,
  PetStoryItem.coins => Icons.paid_rounded,
  PetStoryItem.boat => Icons.sailing_rounded,
  PetStoryItem.shell => Icons.spa_rounded,
  PetStoryItem.wateringCan => Icons.shower_rounded,
  PetStoryItem.windmill => Icons.toys_rounded,
  PetStoryItem.tracks || PetStoryItem.station => Icons.train_rounded,
  PetStoryItem.cart => Icons.shopping_cart_rounded,
  PetStoryItem.seedBag || PetStoryItem.jar => Icons.inventory_2_rounded,
  PetStoryItem.shelf => Icons.shelves,
  PetStoryItem.ladder => Icons.stairs_rounded,
  PetStoryItem.bridge => Icons.architecture_rounded,
  PetStoryItem.mushroom => Icons.cottage_rounded,
  PetStoryItem.hat => Icons.celebration_rounded,
  PetStoryItem.cake => Icons.cake_rounded,
  PetStoryItem.confetti => Icons.auto_awesome_rounded,
  PetStoryItem.clearing => Icons.grass_rounded,
  PetStoryItem.toy => Icons.smart_toy_rounded,
  PetStoryItem.mailbox || PetStoryItem.letters => Icons.mail_rounded,
  PetStoryItem.satchel => Icons.work_rounded,
  PetStoryItem.easel ||
  PetStoryItem.paints ||
  PetStoryItem.frame => Icons.palette_rounded,
  PetStoryItem.tent => Icons.holiday_village_rounded,
  PetStoryItem.campfire => Icons.local_fire_department_rounded,
};

class PetStoryItemView extends StatelessWidget {
  const PetStoryItemView({super.key, required this.item, this.preview = false});
  final PetStoryItem item;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    final colors = const [
      Color(0xFFE8A34A),
      Color(0xFF79B989),
      Color(0xFF76AACE),
      Color(0xFFD98EA4),
      Color(0xFFB697D3),
      Color(0xFFD4C068),
    ];
    final color = colors[item.index % colors.length];
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: preview ? 0.18 : 0.82),
        shape: BoxShape.circle,
        border: Border.all(
          color: preview ? Colors.white54 : const Color(0xFFFFE7AF),
          width: 2,
        ),
      ),
      child: Icon(
        _itemIcon(item),
        color: preview ? Colors.white60 : Colors.white,
      ),
    );
  }
}

(Color, Color) _storySky(PetStoryDef story) {
  return switch (story.id) {
    'cat_watch' ||
    'fox_fireflies' ||
    'fox_camp' ||
    'raccoon_market' ||
    'raccoon_cafe' => (const Color(0xFF101A38), const Color(0xFF2C3F28)),
    'cat_window' ||
    'cat_tea' ||
    'dog_picnic' => (const Color(0xFF4A7FA8), const Color(0xFF5F8A52)),
    'cat_garden' ||
    'hamster_garden' ||
    'raccoon_recycle' => (const Color(0xFF1C5538), const Color(0xFF4A7A38)),
    'cat_library' ||
    'hamster_pantry' ||
    'raccoon_workshop' => (const Color(0xFF3A2418), const Color(0xFF5A3C22)),
    'dog_festival' ||
    'hamster_birthday' => (const Color(0xFF6A2A4A), const Color(0xFF8A5A32)),
    'raccoon_river' ||
    'dog_kite' => (const Color(0xFF1A4A6A), const Color(0xFF3A6A52)),
    'hamster_clouds' ||
    'hamster_railway' => (const Color(0xFF5A8AB8), const Color(0xFF62885A)),
    'fox_cozy' => (const Color(0xFF3A291D), const Color(0xFF4A5A2A)),
    'fox_studio' => (const Color(0xFF8A4A28), const Color(0xFF6A5A2A)),
    'fox_post' ||
    'dog_trail' ||
    'dog_bridge' => (const Color(0xFF24543C), const Color(0xFF4A6A38)),
    _ => (
      const Color(0xFF153F39),
      Color.lerp(
        const Color(0xFF315D3D),
        const Color(0xFF57422A),
        story.pet.index / 5,
      )!,
    ),
  };
}

Alignment _propAlignment(PetStoryItem item) {
  return switch (item) {
    PetStoryItem.cushion => const Alignment(-0.02, 0.70),
    PetStoryItem.yarn => const Alignment(0.78, 0.52),
    PetStoryItem.curtain => const Alignment(-0.82, -0.12),
    PetStoryItem.lantern => const Alignment(0.72, -0.62),
    PetStoryItem.bell => const Alignment(-0.70, -0.48),
    PetStoryItem.telescope => const Alignment(0.80, 0.08),
    PetStoryItem.seedling => const Alignment(-0.78, 0.55),
    PetStoryItem.butterflies => const Alignment(0.55, -0.45),
    PetStoryItem.fountain => const Alignment(-0.72, 0.40),
    PetStoryItem.books => const Alignment(-0.78, 0.36),
    PetStoryItem.blanket => const Alignment(0.08, 0.74),
    PetStoryItem.lamp => const Alignment(0.78, -0.08),
    PetStoryItem.teacup => const Alignment(-0.62, 0.58),
    PetStoryItem.flowers => const Alignment(0.72, 0.48),
    PetStoryItem.banner => const Alignment(-0.04, -0.72),
    PetStoryItem.signpost => const Alignment(-0.80, 0.10),
    PetStoryItem.bowl => const Alignment(-0.55, 0.70),
    PetStoryItem.ball => const Alignment(0.78, 0.58),
    PetStoryItem.rope => const Alignment(0.70, 0.18),
    PetStoryItem.badge => const Alignment(0.55, -0.32),
    PetStoryItem.basket => const Alignment(-0.76, 0.50),
    PetStoryItem.treats => const Alignment(0.62, 0.62),
    PetStoryItem.kite => const Alignment(0.70, -0.55),
    PetStoryItem.compass => const Alignment(-0.60, 0.55),
    PetStoryItem.ribbon => const Alignment(0.55, 0.34),
    PetStoryItem.flags => const Alignment(-0.08, -0.68),
    PetStoryItem.drum => const Alignment(0.72, 0.50),
    PetStoryItem.medal => const Alignment(0.48, -0.28),
    PetStoryItem.toolbox => const Alignment(-0.76, 0.55),
    PetStoryItem.gears => const Alignment(0.74, 0.16),
    PetStoryItem.clock => const Alignment(0.10, -0.62),
    PetStoryItem.coins => const Alignment(0.68, 0.62),
    PetStoryItem.map => const Alignment(-0.68, 0.26),
    PetStoryItem.boat => const Alignment(0.04, 0.78),
    PetStoryItem.shell => const Alignment(0.72, 0.58),
    PetStoryItem.crate => const Alignment(-0.74, 0.50),
    PetStoryItem.wateringCan => const Alignment(0.70, 0.48),
    PetStoryItem.windmill => const Alignment(0.78, -0.18),
    PetStoryItem.mug => const Alignment(-0.62, 0.58),
    PetStoryItem.cookies => const Alignment(0.58, 0.62),
    PetStoryItem.tracks => const Alignment(0.0, 0.82),
    PetStoryItem.cart => const Alignment(0.55, 0.70),
    PetStoryItem.station => const Alignment(-0.72, 0.18),
    PetStoryItem.seedBag => const Alignment(-0.74, 0.52),
    PetStoryItem.shelf => const Alignment(-0.80, 0.04),
    PetStoryItem.jar => const Alignment(0.70, 0.48),
    PetStoryItem.ladder => const Alignment(-0.82, 0.08),
    PetStoryItem.star => const Alignment(0.62, -0.62),
    PetStoryItem.pot => const Alignment(-0.70, 0.55),
    PetStoryItem.bridge => const Alignment(0.04, 0.78),
    PetStoryItem.mushroom => const Alignment(0.76, 0.20),
    PetStoryItem.hat => const Alignment(0.04, -0.52),
    PetStoryItem.cake => const Alignment(0.62, 0.58),
    PetStoryItem.confetti => const Alignment(-0.55, -0.38),
    PetStoryItem.clearing => const Alignment(-0.78, 0.70),
    PetStoryItem.bed => const Alignment(0.0, 0.72),
    PetStoryItem.toy => const Alignment(0.78, 0.58),
    PetStoryItem.fireflies => const Alignment(0.50, -0.40),
    PetStoryItem.mailbox => const Alignment(-0.78, 0.26),
    PetStoryItem.letters => const Alignment(0.68, 0.18),
    PetStoryItem.satchel => const Alignment(0.74, 0.55),
    PetStoryItem.easel => const Alignment(-0.74, 0.06),
    PetStoryItem.paints => const Alignment(-0.52, 0.62),
    PetStoryItem.frame => const Alignment(0.72, -0.14),
    PetStoryItem.tent => const Alignment(-0.70, 0.04),
    PetStoryItem.campfire => const Alignment(0.58, 0.55),
  };
}

bool _sitsBehindPet(PetStoryItem item) => switch (item) {
  PetStoryItem.bed ||
  PetStoryItem.cushion ||
  PetStoryItem.blanket ||
  PetStoryItem.tent ||
  PetStoryItem.easel ||
  PetStoryItem.fountain ||
  PetStoryItem.mushroom ||
  PetStoryItem.station ||
  PetStoryItem.shelf ||
  PetStoryItem.curtain ||
  PetStoryItem.mailbox ||
  PetStoryItem.windmill ||
  PetStoryItem.tracks ||
  PetStoryItem.bridge ||
  PetStoryItem.clearing => true,
  _ => false,
};

Size _propBox(PetStoryItem item, double base) {
  return switch (item) {
    PetStoryItem.bed ||
    PetStoryItem.cushion ||
    PetStoryItem.blanket => Size(base * 1.75, base * 0.72),
    PetStoryItem.tent ||
    PetStoryItem.easel ||
    PetStoryItem.mushroom => Size(base * 1.28, base * 1.28),
    PetStoryItem.tracks ||
    PetStoryItem.bridge => Size(base * 2.05, base * 0.55),
    PetStoryItem.curtain ||
    PetStoryItem.banner ||
    PetStoryItem.flags => Size(base * 0.92, base * 1.38),
    _ => Size(base, base),
  };
}

List<Widget> _storyAmbience(PetStoryDef story) {
  final night = const {
    'cat_watch',
    'fox_fireflies',
    'fox_camp',
    'raccoon_market',
    'raccoon_cafe',
    'hamster_clouds',
  }.contains(story.id);
  final sun = const {'cat_window', 'dog_picnic', 'dog_kite'}.contains(story.id);
  return [
    if (night) ...[
      const Positioned(
        top: 10,
        left: 16,
        child: Icon(Icons.star_rounded, color: Color(0x88FFE7AF), size: 16),
      ),
      const Positioned(
        top: 18,
        right: 24,
        child: Icon(Icons.star_rounded, color: Color(0x66FFE7AF), size: 12),
      ),
      const Positioned(
        top: 8,
        right: 64,
        child: Icon(Icons.star_rounded, color: Color(0x55FFE7AF), size: 10),
      ),
    ],
    if (sun)
      const Positioned(
        top: 8,
        right: 14,
        child: Icon(Icons.wb_sunny_rounded, color: Color(0x88FFD478), size: 26),
      ),
  ];
}

class _StoryProp extends StatelessWidget {
  const _StoryProp({required this.item, required this.preview});

  final PetStoryItem item;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    if (item == PetStoryItem.bed || item == PetStoryItem.cushion) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: preview ? const Color(0x667BAFC1) : const Color(0xFFE5AD6B),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: const Color(0xFFF9E4BB), width: 3),
        ),
        child: Icon(
          _itemIcon(item),
          color: preview ? Colors.white54 : Colors.white,
        ),
      );
    }
    return PetStoryItemView(item: item, preview: preview);
  }
}

class PetStoryScene extends StatelessWidget {
  const PetStoryScene({
    super.key,
    required this.story,
    required this.stage,
    this.revealLatest = false,
    this.height = 210,
    this.showPet = true,
  });
  final PetStoryDef story;
  final int stage;
  final bool revealLatest;
  final double height;
  final bool showPet;

  @override
  Widget build(BuildContext context) {
    final sky = _storySky(story);
    final ground = Color.lerp(
      const Color(0xFF5A6438),
      const Color(0xFF8FA35A),
      (stage / 3).clamp(0.0, 1.0),
    )!;
    final compact = height < 160;
    final base = (height * 0.28).clamp(28.0, 58.0);
    return Container(
      key: ValueKey('pet-story-scene-${story.id}'),
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 18 : 24),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sky.$1, sky.$2],
        ),
        border: Border.all(color: const Color(0x88E8C96A)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ..._storyAmbience(story),
          Positioned(
            left: 16,
            right: 16,
            bottom: height * 0.04,
            height: height * 0.30,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: ground,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: const Color(0xFFDAC694),
                  width: compact ? 2 : 3,
                ),
              ),
            ),
          ),
          for (var index = 0; index < story.items.length; index++)
            if (_sitsBehindPet(story.items[index]))
              _prop(context, index: index, base: base),
          if (showPet)
            Align(
              alignment: const Alignment(0, 0.10),
              child: SizedBox(
                width: height * (compact ? 0.42 : 0.54),
                height: height * (compact ? 0.60 : 0.70),
                child: PetPortrait(kind: story.pet),
              ),
            ),
          for (var index = 0; index < story.items.length; index++)
            if (!_sitsBehindPet(story.items[index]))
              _prop(context, index: index, base: base),
        ],
      ),
    );
  }

  Widget _prop(
    BuildContext context, {
    required int index,
    required double base,
  }) {
    final item = story.items[index];
    final size = _propBox(item, base);
    return Align(
      alignment: _propAlignment(item),
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('story-item-reveal-${story.id}-$index'),
          tween: Tween(
            begin: revealLatest && index == stage - 1 ? 0.0 : 1.0,
            end: 1.0,
          ),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) => Opacity(
            opacity:
                value *
                (index < stage
                    ? 1
                    : index == stage
                    ? 0.46
                    : 0.16),
            child: Transform.scale(scale: 0.55 + value * 0.45, child: child),
          ),
          child: _StoryProp(item: item, preview: index >= stage),
        ),
      ),
    );
  }
}

class PetStorySection extends StatelessWidget {
  const PetStorySection({
    super.key,
    required this.pet,
    required this.store,
    this.onPlay,
    this.showScene = true,
  });
  final PetKind pet;
  final PetStoryStore store;
  final VoidCallback? onPlay;
  final bool showScene;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final current = store.currentFor(pet);
    if (current == null) return const SizedBox.shrink();
    final stage = store.progress(current);
    return Column(
      key: petStorySectionKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l.adventures,
              style: const TextStyle(
                color: Color(0xFFE8C96A),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${store.completedFor(pet)}/${PetStories.perPet}',
              style: const TextStyle(
                color: Color(0xFFE8C96A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (showScene) ...[
          const SizedBox(height: 10),
          PetStoryScene(story: current, stage: stage),
        ],
        const SizedBox(height: 10),
        Text(
          l.petStoryTitle(current.id),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 17,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          stage >= 3
              ? l.adventureComplete
              : l.storyNextItem(petStoryItemTitle(l, current.items[stage])),
          style: const TextStyle(color: Color(0xFFE8C96A)),
        ),
        const SizedBox(height: 10),
        if (onPlay != null)
          FilledButton.icon(
            key: const ValueKey('play-active-pet-story'),
            onPressed: onPlay,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l.play),
          ),
        const SizedBox(height: 14),
        for (final story in PetStories.forPet(pet))
          _StoryRow(story: story, store: store),
      ],
    );
  }
}

class PetStorySummaryCard extends StatelessWidget {
  const PetStorySummaryCard({
    super.key,
    required this.pet,
    required this.store,
    required this.onTap,
    this.sceneHeight = 156,
  });

  final PetKind pet;
  final PetStoryStore store;
  final VoidCallback onTap;
  final double sceneHeight;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final story = store.currentFor(pet);
    if (story == null) return const SizedBox.shrink();
    final stage = store.progress(story);
    return Material(
      key: ValueKey('pet-story-summary-${pet.name}'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PetStoryScene(story: story, stage: stage, height: sceneHeight),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.petStoryTitle(story.id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${l.adventures} · '
                        '${store.completedFor(pet)}/${PetStories.perPet}',
                        style: const TextStyle(
                          color: Color(0xFFE8C96A),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.white70),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryRow extends StatelessWidget {
  const _StoryRow({required this.story, required this.store});
  final PetStoryDef story;
  final PetStoryStore store;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final unlocked = store.isUnlocked(story);
    final stage = store.progress(story);
    return Opacity(
      opacity: unlocked ? 1 : 0.42,
      child: ListTile(
        key: ValueKey('story-row-${story.id}'),
        contentPadding: EdgeInsets.zero,
        leading: SizedBox(
          width: 42,
          height: 42,
          child: PetStoryItemView(
            item: story.items[(stage.clamp(0, 2))],
            preview: stage == 0,
          ),
        ),
        title: Text(
          l.petStoryTitle(story.id),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          unlocked
              ? '$stage / 3'
              : l.storyLocked,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: store.isComplete(story)
            ? const Icon(Icons.check_circle_rounded, color: Color(0xFF83D39E))
            : unlocked
            ? const Icon(Icons.card_giftcard_rounded, color: Color(0xFFE8C96A))
            : const Icon(Icons.lock_rounded, size: 18),
      ),
    );
  }
}

Future<void> showPetStoryMoment(
  BuildContext context,
  PetStoryStore store,
) async {
  final story = store.active;
  if (story == null || !store.hasPendingMoment) return;
  final stage = store.progress(story);
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final l = AppLocalizations.of(dialogContext);
      return AlertDialog(
        key: petStoryMomentKey,
        backgroundColor: const Color(0xFF3A291D),
        title: Text(
          l.petStoryTitle(story.id),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFFFDB91),
            fontWeight: FontWeight.w800,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PetStoryScene(story: story, stage: stage, revealLatest: true),
              const SizedBox(height: 14),
              Text(
                l.newGiftItem(petStoryItemTitle(l, story.items[stage - 1])),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFDB91),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l.petStoryChapter(story.id, stage - 1),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                '$stage / 3',
                style: const TextStyle(color: Color(0xFFFFDB91)),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () async {
              await store.acknowledgeMoment();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: Text(
              stage >= 3 ? l.adventureCompleteBang : l.continueGame,
            ),
          ),
        ],
      );
    },
  );
}
