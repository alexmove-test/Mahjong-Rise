import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/pet.dart';
import '../../models/pet_combat.dart';
import '../../models/pet_roster.dart';
import '../../services/points_controller.dart';
import '../../utils/points_format.dart';
import 'gear_art.dart';

const _ivory = Color(0xFFF8F1DE);
const _gold = Color(0xFFE8C96A);
const _wood = Color(0xFF3A2012);

Future<void> showPetGearSheet(
  BuildContext context, {
  required PetKind kind,
  required GearSlot slot,
}) {
  final points = PointsScope.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _wood,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return PointsScope(
        controller: points,
        child: _PetGearSheet(kind: kind, slot: slot),
      );
    },
  );
}

class _PetGearSheet extends StatefulWidget {
  const _PetGearSheet({required this.kind, required this.slot});

  final PetKind kind;
  final GearSlot slot;

  @override
  State<_PetGearSheet> createState() => _PetGearSheetState();
}

class _PetGearSheetState extends State<_PetGearSheet> {
  String? _busyId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final points = PointsScope.of(context);
    final role = PetCombatRules.roleOf(widget.kind);
    final record =
        points.roster.recordOf(widget.kind) ?? PetCombatRecord.fresh(widget.kind);
    final equippedId = record.itemIn(widget.slot);
    final strength = PetStrength.of(
      level: record.level,
      main: points.roster.defOf(record.mainItemId),
      accessory: points.roster.defOf(record.accessoryItemId),
    );
    final offers = GearCatalog.forSlot(role, widget.slot);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Text(
            l10n.petSlot(widget.slot),
            style: const TextStyle(
              color: _ivory,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.gearOfferLabel(role: role, slot: widget.slot),
            style: const TextStyle(color: _gold, fontWeight: FontWeight.w700),
          ),
          if (equippedId != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: ValueKey('pet-gear-unequip-${widget.slot.name}'),
                onPressed: _busyId == null
                    ? () => _unequip()
                    : null,
                child: Text(l10n.gearUnequip),
              ),
            ),
          ],
          const SizedBox(height: 8),
          for (final def in offers) ...[
            _OfferCard(
              def: def,
              level: record.level,
              balance: points.balance,
              strength: strength,
              busy: _busyId != null,
              copies: [
                for (final item in points.roster.items)
                  if (item.defId == def.id &&
                      points.roster.wearerOf(item.id) != widget.kind)
                    item,
              ],
              onBuy: _busyId == null ? () => _buy(def) : null,
              onEquip: _busyId == null ? (id) => _equip(id) : null,
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Future<void> _buy(GearDef def) async {
    setState(() => _busyId = def.id);
    final points = PointsScope.of(context);
    final result = await points.buyGear(kind: widget.kind, defId: def.id);
    if (!mounted) return;
    setState(() => _busyId = null);
    if (result.bought) return;
    final l10n = AppLocalizations.of(context);
    final message = result.status == GearBuyStatus.insufficient
        ? l10n.gearShortfall(result.shortfall)
        : l10n.gearBuyFailed;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _equip(String itemId) async {
    setState(() => _busyId = itemId);
    final points = PointsScope.of(context);
    final result = await points.equipGear(
      kind: widget.kind,
      itemId: itemId,
      slot: widget.slot,
    );
    if (!mounted) return;
    setState(() => _busyId = null);
    if (!result.equipped) {
      final l10n = AppLocalizations.of(context);
      final worn = result.wornBy;
      final message = worn == null
          ? l10n.gearBuyFailed
          : l10n.gearWornBy(l10n.petName(worn));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _unequip() async {
    setState(() => _busyId = 'off');
    final points = PointsScope.of(context);
    await points.unequipGear(kind: widget.kind, slot: widget.slot);
    if (!mounted) return;
    setState(() => _busyId = null);
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.def,
    required this.level,
    required this.balance,
    required this.strength,
    required this.busy,
    required this.copies,
    required this.onBuy,
    required this.onEquip,
  });

  final GearDef def;
  final int level;
  final int balance;
  final PetStrength strength;
  final bool busy;
  final List<GearInstance> copies;
  final VoidCallback? onBuy;
  final ValueChanged<String>? onEquip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locked = level < def.minLevel;
    final projected = strength.replacing(slot: def.slot, bonus: def.bonus);
    final stat = l10n.petStat(def.role);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gearGold.withValues(alpha: 0.55)),
        color: const Color(0xFF4A2C18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GearArt(def: def),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.gearName(def.id),
                        key: ValueKey('pet-gear-name-${def.id}'),
                        style: const TextStyle(
                          color: _ivory,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        l10n.gearOfferLabel(role: def.role, slot: def.slot),
                        style: const TextStyle(color: _gold, fontSize: 12),
                      ),
                      Text(
                        l10n.gearBonus(def.bonus),
                        style: const TextStyle(color: _ivory, fontSize: 12),
                      ),
                      Text(
                        l10n.gearPrice(def.price),
                        style: const TextStyle(color: _ivory, fontSize: 12),
                      ),
                      Text(
                        l10n.gearLevelRequired(def.minLevel),
                        style: const TextStyle(color: _ivory, fontSize: 12),
                      ),
                      Text(
                        l10n.gearIfEquipped(stat, strength.total, projected.total),
                        key: ValueKey('pet-gear-preview-${def.id}'),
                        style: const TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              key: ValueKey('pet-gear-buy-${def.id}'),
              onPressed: busy || locked || balance < def.price ? null : onBuy,
              child: Text(
                locked
                    ? l10n.gearLevelRequired(def.minLevel)
                    : balance < def.price
                    ? l10n.gearShortfall(def.price - balance)
                    : '${l10n.gearBuy} · ${formatPoints(def.price)}',
              ),
            ),
            for (final copy in copies)
              _CopyRow(
                item: copy,
                onEquip: busy ? null : onEquip,
              ),
          ],
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.item, required this.onEquip});

  final GearInstance item;
  final ValueChanged<String>? onEquip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final points = PointsScope.of(context);
    final wearer = points.roster.wearerOf(item.id);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        key: ValueKey('pet-gear-equip-${item.id}'),
        onPressed: wearer == null ? () => onEquip?.call(item.id) : null,
        child: Text(
          wearer == null
              ? l10n.gearEquip
              : l10n.gearWornBy(l10n.petName(wearer)),
        ),
      ),
    );
  }
}
