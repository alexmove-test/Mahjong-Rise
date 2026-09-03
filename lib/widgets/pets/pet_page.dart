import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/pet.dart';
import '../../services/analytics_service.dart';
import '../../services/local_reminder_service.dart';
import '../../services/pet_store.dart';
import '../../services/reminder_store.dart';
import '../mahjong_backdrop.dart';
import 'pet_portrait.dart';
import 'pet_sheet.dart';

const _gold = Color(0xFFD4AF37);
const _goldSoft = Color(0xFFE8C96A);
const _ivory = Color(0xFFF8F1DE);
const _woodTop = Color(0xFF6B3E24);
const _woodDeep = Color(0xFF3A2012);

Future<void> openPetPage(BuildContext context, {required PetStore pets}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (ctx, animation, secondaryAnimation) {
        return PetPage(pets: pets);
      },
      transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
        final incoming = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(incoming),
          child: child,
        );
      },
    ),
  );
}

/// Полноэкранный раздел питомца: крупный портрет и потребности.
class PetPage extends StatefulWidget {
  const PetPage({super.key, required this.pets});

  final PetStore pets;

  @override
  State<PetPage> createState() => _PetPageState();
}

class _PetPageState extends State<PetPage> {
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
    setState(() {
      _picking = false;
    });
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

    return Scaffold(
      backgroundColor: const Color(0xFF0B5C40),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const MahjongScreenBackdrop(dark: true),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: l10n.back,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: _ivory,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _ivory,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: _picking ? _picker(l10n) : _portrait(l10n),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _picker(L10n l10n) {
    final available = [
      for (final def in PetDef.all)
        if (!widget.pets.owns(def.kind)) def,
    ];
    if (available.isEmpty) {
      return _portrait(l10n);
    }
    return GridView.count(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.82,
      children: [
        for (final def in available)
          _AdoptCard(def: def, onTap: () => unawaited(_adopt(def.kind))),
      ],
    );
  }

  Widget _portrait(L10n l10n) {
    final ownedCare = widget.pets.allCare();
    if (ownedCare.isEmpty) {
      return _picker(l10n);
    }
    if (ownedCare.length == 1) {
      return _soloPortrait(l10n, ownedCare.first);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        for (final snapshot in ownedCare) ...[
          OwnedPetCard(snapshot: snapshot),
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
          const SizedBox(height: 8),
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

  Widget _soloPortrait(L10n l10n, PetCare snapshot) {
    final def = PetDef.of(snapshot.kind);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      children: [
        _HeroPortrait(kind: def.kind, mood: snapshot.mood),
        const SizedBox(height: 18),
        Text(
          l10n.petName(snapshot.kind),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ivory,
            fontWeight: FontWeight.w800,
            fontSize: 28,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.petMoodLine(snapshot.kind, snapshot.mood),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _goldSoft,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 22),
        for (final need in PetNeed.values) ...[
          PetNeedBar(
            label: l10n.petNeedLabel(need),
            value: snapshot.of(need),
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 8),
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
}

class _HeroPortrait extends StatelessWidget {
  const _HeroPortrait({required this.kind, required this.mood});

  final PetKind kind;
  final PetMood mood;

  @override
  Widget build(BuildContext context) {
    final glow = switch (mood) {
      PetMood.starving => const Color(0xFFC45C4A),
      PetMood.asking => const Color(0xFFE0A24B),
      PetMood.content => _goldSoft,
    };
    return Center(
      child: SizedBox(
        width: 260,
        height: 280,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                glow.withValues(alpha: 0.42),
                glow.withValues(alpha: 0.08),
                Colors.transparent,
              ],
              stops: const [0.35, 0.72, 1],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: PetPortrait(kind: kind),
          ),
        ),
      ),
    );
  }
}

class _AdoptCard extends StatelessWidget {
  const _AdoptCard({required this.def, required this.onTap});

  final PetDef def;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_woodTop, _woodDeep],
            ),
            border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1.3),
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                  child: PetPortrait(kind: def.kind),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 16),
                child: Text(
                  l10n.petName(def.kind),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _ivory,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
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
