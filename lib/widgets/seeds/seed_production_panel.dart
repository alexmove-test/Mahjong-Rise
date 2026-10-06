import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/seed_batch.dart';
import '../../models/seed_catalog.dart';
import 'seed_glyph.dart';

const _ivory = Color(0xFFF8F1DE);
const _goldSoft = Color(0xFFE8C96A);
const _goldLine = Color(0xFFD4AF37);

/// Блок производства в карточке дома. Цифры берёт из [SeedCatalog] и партии.
class SeedProductionPanel extends StatefulWidget {
  const SeedProductionPanel({
    super.key,
    required this.houseLevel,
    required this.balance,
    required this.batch,
    required this.onStart,
    required this.onClaim,
    this.onPlayMahjong,
    this.onOpenStorage,
    this.busy = false,
    this.now,
    this.tick = true,
  });

  final int houseLevel;
  final int balance;
  final SeedBatch? batch;
  final Future<SeedStartResult> Function() onStart;
  final Future<SeedClaimResult> Function() onClaim;
  final VoidCallback? onPlayMahjong;
  final VoidCallback? onOpenStorage;
  final bool busy;
  final DateTime Function()? now;
  final bool tick;

  @override
  State<SeedProductionPanel> createState() => _SeedProductionPanelState();
}

class _SeedProductionPanelState extends State<SeedProductionPanel>
    with WidgetsBindingObserver {
  Timer? _timer;
  var _busy = false;
  SeedInstance? _claimed;

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  bool get _locked => widget.busy || _busy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant SeedProductionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
    if (oldWidget.batch?.id != widget.batch?.id) {
      if (widget.batch != null) _claimed = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(_syncTicker);
    }
  }

  void _syncTicker() {
    final producing =
        widget.tick && phaseOf(widget.batch, _now) == SeedPhase.producing;
    if (!producing) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(_syncTicker);
    });
  }

  Future<void> _start() async {
    if (_locked) return;
    setState(() => _busy = true);
    try {
      await widget.onStart();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _claim() async {
    if (_locked) return;
    setState(() => _busy = true);
    try {
      final result = await widget.onClaim();
      if (!mounted) return;
      if (result.claimed && result.seed != null) {
        setState(() => _claimed = result.seed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offer = SeedCatalog.offerFor(widget.houseLevel);
    final phase = phaseOf(widget.batch, _now);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xEB3A2012),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x88D4AF37)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.seedProductionTitle,
              style: const TextStyle(
                color: _goldSoft,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (_claimed != null) ...[
              _AddedBanner(
                seed: _claimed!,
                reduced: reduced,
                onOpenStorage: widget.onOpenStorage,
              ),
              const SizedBox(height: 8),
            ],
            switch (phase) {
              SeedPhase.idle => _IdleBody(
                offer: offer,
                balance: widget.balance,
                locked: _locked,
                onStart: _start,
                onPlayMahjong: widget.onPlayMahjong,
              ),
              SeedPhase.producing => _ProducingBody(
                batch: widget.batch!,
                now: _now,
              ),
              SeedPhase.ready => _ReadyBody(
                batch: widget.batch!,
                locked: _locked,
                onClaim: _claim,
              ),
            },
          ],
        ),
      ),
    );
  }
}

class _IdleBody extends StatelessWidget {
  const _IdleBody({
    required this.offer,
    required this.balance,
    required this.locked,
    required this.onStart,
    required this.onPlayMahjong,
  });

  final SeedOffer offer;
  final int balance;
  final bool locked;
  final VoidCallback onStart;
  final VoidCallback? onPlayMahjong;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shortfall = (offer.cost - balance).clamp(0, offer.cost);
    final canStart = shortfall == 0 && !locked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.houseStateTitle(offer.houseLevel, 24),
          key: const ValueKey('seed-house-level'),
          style: const TextStyle(color: _ivory, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.catalogDuration(offer.duration),
          key: const ValueKey('seed-duration'),
          style: const TextStyle(color: _ivory),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.seedSpeciesHeading,
          style: const TextStyle(color: _ivory, fontWeight: FontWeight.w700),
        ),
        Text(
          l10n.seedEqualChance,
          style: const TextStyle(color: _goldSoft, fontSize: 12),
        ),
        const SizedBox(height: 4),
        for (final chance in offer.chances) ...[
          Text(
            l10n.seedClassLine(
              l10n.seedClassName(chance.seedClass),
              chance.percent,
            ),
            key: ValueKey('seed-class-${chance.seedClass.name}'),
            style: const TextStyle(
              color: _goldSoft,
              fontWeight: FontWeight.w800,
            ),
          ),
          for (final species in chance.species)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SeedGlyph(size: 28, species: species),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.seedName(species),
                      key: ValueKey('seed-option-${species.name}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _ivory),
                    ),
                  ),
                  Text(
                    l10n.seedShare(chance.species.length),
                    style: const TextStyle(
                      color: _goldSoft,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (shortfall > 0) ...[
          const SizedBox(height: 4),
          Text(
            l10n.pointsShortfall(shortfall),
            key: const ValueKey('seed-shortfall'),
            style: const TextStyle(
              color: _goldSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onPlayMahjong != null) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const ValueKey('seed-play-mahjong'),
                onPressed: onPlayMahjong,
                child: Text(l10n.seedPlayMahjong),
              ),
            ),
          ],
        ],
        const SizedBox(height: 8),
        FilledButton(
          key: const ValueKey('seed-produce-button'),
          style: _goldButtonStyle(),
          onPressed: canStart ? onStart : null,
          child: Text(
            l10n.produceSeedFor(offer.cost),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ProducingBody extends StatelessWidget {
  const _ProducingBody({required this.batch, required this.now});

  final SeedBatch batch;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final left = batch.remaining(now);
    final clock = formatSeedCountdown(left);
    final minutes = left.inMinutes;
    final seconds = left.inSeconds.remainder(60);
    return Semantics(
      label: l10n.seedProducing,
      value: l10n.seedTimeLeft(
        minutes,
        seconds == 0 && left > Duration.zero ? 1 : seconds,
      ),
      child: Column(
        children: [
          const SeedGlyph(size: 72, unknown: true),
          const SizedBox(height: 8),
          Text(
            l10n.seedUnknown,
            key: const ValueKey('seed-unknown'),
            style: const TextStyle(color: _ivory, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            key: const ValueKey('seed-progress'),
            value: batch.progress(now),
            minHeight: 8,
            backgroundColor: const Color(0x33F8F1DE),
            color: _goldSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 6),
          Text(
            clock,
            key: const ValueKey('seed-remaining'),
            style: const TextStyle(
              color: _ivory,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({
    required this.batch,
    required this.locked,
    required this.onClaim,
  });

  final SeedBatch batch;
  final bool locked;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        SeedGlyph(size: 72, species: batch.species),
        const SizedBox(height: 8),
        Text(
          l10n.seedName(batch.species),
          key: const ValueKey('seed-ready-name'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _ivory,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.seedClassName(batch.species.seedClass),
          key: const ValueKey('seed-ready-class'),
          style: const TextStyle(color: _ivory, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.seedPowerLabel(SeedCatalog.foodFor(batch.species)),
          key: const ValueKey('seed-ready-power'),
          style: const TextStyle(color: _goldSoft, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        FilledButton(
          key: const ValueKey('seed-claim-button'),
          style: _goldButtonStyle(),
          onPressed: locked ? null : onClaim,
          child: Text(
            l10n.claimSeed,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _AddedBanner extends StatelessWidget {
  const _AddedBanner({
    required this.seed,
    required this.reduced,
    required this.onOpenStorage,
  });

  final SeedInstance seed;
  final bool reduced;
  final VoidCallback? onOpenStorage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final banner = DecoratedBox(
      key: const ValueKey('seed-added'),
      decoration: BoxDecoration(
        color: const Color(0xFF2A4A32),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _goldLine.withValues(alpha: 0.8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SeedGlyph(size: 36, species: seed.species),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.seedAdded,
                style: const TextStyle(
                  color: _ivory,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (onOpenStorage != null)
              TextButton(
                key: const ValueKey('seed-open-storage'),
                onPressed: onOpenStorage,
                child: Text(l10n.openSeedStorage),
              ),
          ],
        ),
      ),
    );
    if (reduced) return banner;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: banner,
    );
  }
}

ButtonStyle _goldButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: const Color(0xFF6B3E24),
    foregroundColor: _goldSoft,
    disabledBackgroundColor: const Color(0xFF3A2012),
    disabledForegroundColor: const Color(0x88E8C96A),
    minimumSize: const Size.fromHeight(44),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: _goldLine.withValues(alpha: 0.75)),
    ),
  );
}
