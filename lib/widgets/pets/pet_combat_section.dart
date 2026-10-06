import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/pet.dart';
import '../../models/pet_combat.dart';
import '../../models/pet_roster.dart';
import '../../services/points_controller.dart';
import 'gear_art.dart';
import 'pet_feed_sheet.dart';
import 'pet_gear_sheet.dart';

const _ivory = Color(0xFFF8F1DE);
const _gold = Color(0xFFE8C96A);

/// Роль, опыт, сила, кормление и назначение. Без кошелька раздел не рисуется.
class PetCombatSection extends StatefulWidget {
  const PetCombatSection({
    super.key,
    required this.kind,
    required this.hunger,
    this.onChanged,
  });

  final PetKind kind;
  final double hunger;
  final VoidCallback? onChanged;

  @override
  State<PetCombatSection> createState() => _PetCombatSectionState();
}

class _PetCombatSectionState extends State<PetCombatSection> {
  String? _reaction;

  @override
  Widget build(BuildContext context) {
    final points = PointsScope.maybeOf(context);
    if (points == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final role = PetCombatRules.roleOf(widget.kind);
    final record =
        points.roster.recordOf(widget.kind) ?? PetCombatRecord.fresh(widget.kind);
    final progress = PetLevelProgress.of(record.level, record.xp);
    final main = points.roster.defOf(record.mainItemId);
    final accessory = points.roster.defOf(record.accessoryItemId);
    final strength = PetStrength.of(
      level: progress.level,
      main: main,
      accessory: accessory,
    );
    final stat = l10n.petStat(role);
    final assigned = role == PetRole.defender
        ? points.roster.defender == widget.kind
        : points.roster.raider == widget.kind;
    final pointless = progress.maxed && widget.hunger >= 1;
    final canFeed =
        points.garden.warehouse.isNotEmpty && !pointless && !points.gearBusy;
    return Semantics(
      label: l10n.petBadgeLabel(role, progress.level),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.petRole(role),
            key: ValueKey('pet-role-${widget.kind.name}'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _gold,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.petLevelLabel(progress.level),
            key: ValueKey('pet-level-${widget.kind.name}'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ivory,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            progress.maxed
                ? l10n.petMaxLevel
                : l10n.petXpLabel(progress.xp, progress.xpForNext),
            key: ValueKey('pet-xp-${widget.kind.name}'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: _ivory, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            key: ValueKey('pet-xp-bar-${widget.kind.name}'),
            value: progress.fraction,
            minHeight: 8,
            backgroundColor: const Color(0xFF2A160E),
            color: _gold,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.petStrengthLine(
              stat: stat,
              total: strength.total,
              base: strength.base,
              main: strength.main,
              accessory: strength.accessory,
            ),
            key: ValueKey('pet-strength-${widget.kind.name}'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _ivory,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          if (assigned && role == PetRole.defender) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.petGuarding}. $stat ${strength.total}',
              key: ValueKey('pet-guard-status-${widget.kind.name}'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _gold, fontWeight: FontWeight.w800),
            ),
          ],
          if (assigned && role == PetRole.attacker) ...[
            const SizedBox(height: 4),
            Text(
              '${l10n.petRaiding}. $stat ${strength.total}',
              key: ValueKey('pet-raid-status-${widget.kind.name}'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: _gold, fontWeight: FontWeight.w800),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _SlotButton(
                  slot: GearSlot.main,
                  kind: widget.kind,
                  def: main,
                  onPressed: points.gearBusy
                      ? null
                      : () => showPetGearSheet(
                          context,
                          kind: widget.kind,
                          slot: GearSlot.main,
                        ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SlotButton(
                  slot: GearSlot.accessory,
                  kind: widget.kind,
                  def: accessory,
                  onPressed: points.gearBusy
                      ? null
                      : () => showPetGearSheet(
                          context,
                          kind: widget.kind,
                          slot: GearSlot.accessory,
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: ValueKey('pet-feed-${widget.kind.name}'),
            onPressed: canFeed
                ? () => _feed(points)
                : null,
            child: Text(
              pointless
                  ? l10n.petFeedPointless
                  : points.garden.warehouse.isEmpty
                  ? l10n.petFeedEmpty
                  : l10n.petFeed,
            ),
          ),
          const SizedBox(height: 4),
          OutlinedButton(
            key: ValueKey('pet-assign-${widget.kind.name}'),
            onPressed: points.gearBusy ? null : () => _assign(points, assigned),
            child: Text(
              role == PetRole.defender
                  ? (assigned ? l10n.petStopGuard : l10n.petGuardAction)
                  : (assigned ? l10n.petStopRaid : l10n.petRaidAction),
            ),
          ),
          if (_reaction != null) ...[
            const SizedBox(height: 8),
            Text(
              _reaction!,
              key: ValueKey('pet-feed-reaction-${widget.kind.name}'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _gold,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _feed(PointsController points) async {
    final result = await showPetFeedSheet(
      context,
      kind: widget.kind,
      hunger: widget.hunger,
    );
    if (!mounted) return;
    final preview = result?.preview;
    if (result != null && result.fed && preview != null) {
      final l10n = AppLocalizations.of(context);
      final lines = <String>[l10n.petFedReaction(l10n.petName(widget.kind))];
      if (preview.leveled) {
        lines.add(l10n.petLevelChange(preview.before.level, preview.after.level));
      }
      if (preview.strengthChanged) {
        lines.add(
          l10n.petStatChange(
            l10n.petStat(PetCombatRules.roleOf(widget.kind)),
            preview.beforeStrength.total,
            preview.afterStrength.total,
          ),
        );
      }
      if (preview.restoresHunger && preview.after.maxed && !preview.leveled) {
        lines.add(l10n.petFeedSatiety);
      }
      setState(() => _reaction = lines.join('\n'));
    }
    widget.onChanged?.call();
  }

  Future<void> _assign(PointsController points, bool assigned) async {
    await points.assignPet(kind: widget.kind, active: !assigned);
    widget.onChanged?.call();
  }
}

class _SlotButton extends StatelessWidget {
  const _SlotButton({
    required this.slot,
    required this.kind,
    required this.def,
    required this.onPressed,
  });

  final GearSlot slot;
  final PetKind kind;
  final GearDef? def;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton(
      key: ValueKey('pet-slot-${slot.name}-${kind.name}'),
      onPressed: onPressed,
      child: Column(
        children: [
          if (def != null) GearArt(def: def!, size: 28),
          Text(
            def == null ? l10n.petSlotEmpty : l10n.gearName(def!.id),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            l10n.petSlot(slot),
            style: const TextStyle(fontSize: 11, color: _gold),
          ),
        ],
      ),
    );
  }
}
