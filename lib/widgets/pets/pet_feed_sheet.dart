import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/garden.dart';
import '../../models/pet.dart';
import '../../models/pet_combat.dart';
import '../../models/pet_roster.dart';
import '../../services/points_controller.dart';
import '../garden/plant_art.dart';

const _ivory = Color(0xFFF8F1DE);
const _gold = Color(0xFFE8C96A);
const _wood = Color(0xFF3A2012);

/// Выбор одного растения со склада. Семена и грядки сюда не попадают.
Future<FeedResult?> showPetFeedSheet(
  BuildContext context, {
  required PetKind kind,
  required double hunger,
}) {
  final points = PointsScope.of(context);
  return showModalBottomSheet<FeedResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _wood,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return PointsScope(
        controller: points,
        child: _PetFeedSheet(kind: kind, hunger: hunger),
      );
    },
  );
}

class _PetFeedSheet extends StatefulWidget {
  const _PetFeedSheet({required this.kind, required this.hunger});

  final PetKind kind;
  final double hunger;

  @override
  State<_PetFeedSheet> createState() => _PetFeedSheetState();
}

class _PetFeedSheetState extends State<_PetFeedSheet> {
  String? _plantId;
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final points = PointsScope.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final stacks = stackPlants(points.garden.warehouse);
    final record =
        points.roster.recordOf(widget.kind) ??
        PetCombatRecord.fresh(widget.kind);
    final main = points.roster.defOf(record.mainItemId);
    final accessory = points.roster.defOf(record.accessoryItemId);
    HarvestedPlant? selected;
    if (_plantId != null) {
      for (final plant in points.garden.warehouse) {
        if (plant.id == _plantId) {
          selected = plant;
          break;
        }
      }
    }
    final preview = selected == null
        ? null
        : previewFeed(
            level: record.level,
            xp: record.xp,
            plantPower: GardenCatalog.foodFor(selected.species),
            hunger: widget.hunger,
            main: main,
            accessory: accessory,
          );
    final role = PetCombatRules.roleOf(widget.kind);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            l10n.petFeedTitle,
            key: const ValueKey('pet-feed-title'),
            style: const TextStyle(
              color: _ivory,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          if (stacks.isEmpty)
            Text(
              l10n.petFeedEmpty,
              key: const ValueKey('pet-feed-empty'),
              style: const TextStyle(color: _gold, fontWeight: FontWeight.w700),
            )
          else
            for (final stack in stacks)
              _FeedOption(
                stack: stack,
                selected: stack.instances.first.id == _plantId,
                xp: previewFeed(
                  level: record.level,
                  xp: record.xp,
                  plantPower: GardenCatalog.foodFor(stack.species),
                  hunger: widget.hunger,
                  main: main,
                  accessory: accessory,
                ).xpGain,
                onTap: _busy
                    ? null
                    : () => setState(() {
                        _plantId = stack.instances.first.id;
                      }),
              ),
          if (preview != null && selected != null) ...[
            const SizedBox(height: 12),
            _FeedPreviewBlock(
              preview: preview,
              stat: l10n.petStat(role),
              reduced: reduced,
            ),
            const SizedBox(height: 12),
            FilledButton(
              key: const ValueKey('pet-feed-confirm'),
              onPressed: _busy || preview.pointless || points.feedBusy
                  ? null
                  : () => _confirm(selected!.id),
              child: Text(
                preview.pointless ? l10n.petFeedPointless : l10n.petFeedConfirm,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirm(String plantId) async {
    if (_busy) return;
    setState(() => _busy = true);
    final points = PointsScope.of(context);
    final result = await points.feedPet(kind: widget.kind, plantId: plantId);
    if (!mounted) return;
    if (result.fed) {
      Navigator.of(context).pop(result);
      return;
    }
    final l10n = AppLocalizations.of(context);
    final message = result.status == FeedStatus.missingPlant
        ? l10n.petFeedMissing
        : result.status == FeedStatus.pointless
        ? l10n.petFeedPointless
        : l10n.petFeedFailed;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    setState(() {
      _busy = false;
      if (result.status == FeedStatus.missingPlant) _plantId = null;
    });
  }
}

class _FeedOption extends StatelessWidget {
  const _FeedOption({
    required this.stack,
    required this.selected,
    required this.xp,
    required this.onTap,
  });

  final PlantStack stack;
  final bool selected;
  final int xp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plant = stack.instances.first;
    final name = l10n.seedName(stack.species);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? const Color(0xFF5A3A22) : const Color(0xFF4A2C18),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          key: ValueKey('pet-feed-option-${plant.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                PlantArt(
                  species: stack.species,
                  stage: GrowthStage.ripe,
                  size: 42,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: _ivory,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        l10n.plantPower(GardenCatalog.foodFor(stack.species)),
                        style: const TextStyle(color: _gold, fontSize: 12),
                      ),
                      Text(
                        l10n.petFeedXp(xp),
                        style: const TextStyle(color: _ivory, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  l10n.seedGroupCount(stack.count),
                  style: const TextStyle(
                    color: _ivory,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedPreviewBlock extends StatelessWidget {
  const _FeedPreviewBlock({
    required this.preview,
    required this.stat,
    required this.reduced,
  });

  final FeedPreview preview;
  final String stat;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final after = preview.after;
    return AnimatedContainer(
      duration: reduced ? Duration.zero : const Duration(milliseconds: 160),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _gold.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (after.maxed)
            Text(
              l10n.petMaxLevel,
              key: const ValueKey('pet-feed-max'),
              style: const TextStyle(color: _gold, fontWeight: FontWeight.w800),
            )
          else
            Text(
              l10n.petXpLabel(after.xp, after.xpForNext),
              key: const ValueKey('pet-feed-xp-after'),
              style: const TextStyle(
                color: _ivory,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (preview.leveled)
            Text(
              l10n.petLevelChange(preview.before.level, after.level),
              key: const ValueKey('pet-feed-level-change'),
              style: const TextStyle(
                color: _ivory,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (preview.strengthChanged)
            Text(
              l10n.petStatChange(
                stat,
                preview.beforeStrength.total,
                preview.afterStrength.total,
              ),
              key: const ValueKey('pet-feed-strength-change'),
              style: const TextStyle(
                color: _ivory,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (preview.restoresHunger && after.maxed && !preview.leveled)
            Text(
              l10n.petFeedSatiety,
              key: const ValueKey('pet-feed-satiety'),
              style: const TextStyle(color: _gold, fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: after.fraction,
            minHeight: 8,
            backgroundColor: const Color(0xFF2A160E),
            color: _gold,
          ),
        ],
      ),
    );
  }
}
