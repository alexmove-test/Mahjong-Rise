import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/pet.dart';
import '../../services/analytics_service.dart';
import '../../services/local_reminder_service.dart';
import '../../services/pet_store.dart';
import '../../services/reminder_store.dart';
import '../tile_symbol_image.dart';

const _gold = Color(0xFFD4AF37);
const _goldSoft = Color(0xFFE8C96A);
const _ivory = Color(0xFFF8F1DE);
const _woodTop = Color(0xFF6B3E24);
const _woodDeep = Color(0xFF3A2012);

Future<void> showPetSheet(BuildContext context, {required PetStore pets}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    builder: (ctx) {
      return PetSheet(
        height: MediaQuery.sizeOf(ctx).height * 0.62,
        pets: pets,
      );
    },
  );
}

class PetSheet extends StatefulWidget {
  const PetSheet({super.key, required this.height, required this.pets});

  final double height;
  final PetStore pets;

  @override
  State<PetSheet> createState() => _PetSheetState();
}

class _PetSheetState extends State<PetSheet> {
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _picking = !widget.pets.hasPet;
  }

  Future<void> _adopt(PetKind kind) async {
    final first = !widget.pets.hasPet;
    await widget.pets.adopt(kind);
    AnalyticsService.log('pet_adopt', {'kind': kind.name});
    if (!mounted) return;
    setState(() => _picking = false);
    await LocalReminderService.resync(l10n: L10n.of(context));
    if (!mounted) return;
    if (first) await _offerReminders();
  }

  Future<void> _offerReminders() async {
    final reminder = await ReminderStore.open();
    if (widget.pets.remindersPrompted || reminder.enabled) return;
    await widget.pets.markRemindersPrompted();
    if (!mounted) return;
    final l10n = L10n.of(context);
    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _woodDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: _gold.withValues(alpha: 0.7), width: 1.6),
          ),
          title: Text(
            l10n.petRemindersPromptTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _goldSoft,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            l10n.petRemindersPromptBody,
            textAlign: TextAlign.center,
            style: TextStyle(color: _ivory.withValues(alpha: 0.9)),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                l10n.petRemindersLater,
                style: TextStyle(color: _ivory.withValues(alpha: 0.75)),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: const Color(0xFF2A160C),
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.petRemindersYes),
            ),
          ],
        );
      },
    );
    if (enable != true) return;
    final allowed = await LocalReminderService.requestPermission();
    if (!allowed) return;
    await reminder.setEnabled(true);
    if (!mounted) return;
    await LocalReminderService.resync(l10n: L10n.of(context));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final title = _picking
        ? (widget.pets.hasPet ? l10n.addPet : l10n.chooseAPet)
        : l10n.petsTitle(widget.pets.owned.length);
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4A2C18), _woodDeep],
              ),
              border: Border(
                top: BorderSide(
                  color: _gold.withValues(alpha: 0.55),
                  width: 1.4,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _ivory.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: _ivory,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Expanded(
                  child: _picking ? _picker(l10n) : _care(l10n),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _picker(L10n l10n) {
    final available = [
      for (final def in PetDef.all)
        if (!widget.pets.owns(def.kind)) def,
    ];
    if (available.isEmpty) {
      return _care(l10n);
    }
    return GridView.count(
      padding: EdgeInsets.fromLTRB(
        16,
        4,
        16,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.78,
      children: [
        for (final def in available)
          _PetCard(
            def: def,
            onTap: () => _adopt(def.kind),
          ),
      ],
    );
  }

  Widget _care(L10n l10n) {
    final snapshots = widget.pets.allCare();
    if (snapshots.isEmpty) {
      return _picker(l10n);
    }
    final compact = snapshots.length > 1;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        if (!compact) ..._soloCare(l10n, snapshots.first),
        if (compact)
          for (final snapshot in snapshots) ...[
            _OwnedPetRow(snapshot: snapshot),
            const SizedBox(height: 12),
          ],
        Text(
          l10n.petCareHint,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _ivory.withValues(alpha: 0.78),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        if (widget.pets.canAdoptMore) ...[
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => setState(() => _picking = true),
            child: Text(
              l10n.addPet,
              style: const TextStyle(
                color: _goldSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _soloCare(L10n l10n, PetCare snapshot) {
    final def = PetDef.of(snapshot.kind);
    return [
      SizedBox(
        height: 140,
        child: TileSymbolImage(symbol: def.symbol),
      ),
      const SizedBox(height: 10),
      Text(
        l10n.petMoodLine(snapshot.kind, snapshot.mood),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _goldSoft,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
      const SizedBox(height: 16),
      for (final need in PetNeed.values) ...[
        _NeedBar(
          label: l10n.petNeedLabel(need),
          value: snapshot.of(need),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 6),
    ];
  }
}

class _OwnedPetRow extends StatelessWidget {
  const _OwnedPetRow({required this.snapshot});

  final PetCare snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final def = PetDef.of(snapshot.kind);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [_woodTop, _woodDeep]),
        border: Border.all(color: _gold.withValues(alpha: 0.55), width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              height: 88,
              child: TileSymbolImage(symbol: def.symbol),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.petName(snapshot.kind),
                    style: const TextStyle(
                      color: _ivory,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.petMoodLine(snapshot.kind, snapshot.mood),
                    style: const TextStyle(
                      color: _goldSoft,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final need in PetNeed.values) ...[
                    _NeedBar(
                      label: l10n.petNeedLabel(need),
                      value: snapshot.of(need),
                    ),
                    if (need != PetNeed.rest) const SizedBox(height: 6),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  const _PetCard({
    required this.def,
    required this.onTap,
  });

  final PetDef def;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(colors: [_woodTop, _woodDeep]),
            border: Border.all(
              color: _gold.withValues(alpha: 0.55),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
                  child: TileSymbolImage(symbol: def.symbol),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Text(
                  l10n.petName(def.kind),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ivory,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NeedBar extends StatelessWidget {
  const _NeedBar({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    final fill = value.clamp(0.0, 1.0);
    final color = fill <= 0
        ? const Color(0xFFC45C4A)
        : fill < PetNeeds.askThreshold
        ? const Color(0xFFE0A24B)
        : const Color(0xFF7CB87A);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _ivory,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 8,
            backgroundColor: _ivory.withValues(alpha: 0.16),
            color: color,
          ),
        ),
      ],
    );
  }
}
