import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/seed_batch.dart';
import 'seed_glyph.dart';

/// Маленький знак у дома. Время читается из сохранённой готовности, не из счётчика.
class SeedPlotBadge extends StatefulWidget {
  const SeedPlotBadge({super.key, required this.batch, required this.onTap});

  final SeedBatch? batch;
  final VoidCallback onTap;

  @override
  State<SeedPlotBadge> createState() => _SeedPlotBadgeState();
}

class _SeedPlotBadgeState extends State<SeedPlotBadge>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant SeedPlotBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTicker();
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
        phaseOf(widget.batch, DateTime.now()) == SeedPhase.producing;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final phase = phaseOf(widget.batch, now);
    final batch = widget.batch;
    final countdown = batch == null
        ? ''
        : formatSeedCountdown(batch.remaining(now));
    final label = switch (phase) {
      SeedPhase.idle => l10n.seedBadgeIdle,
      SeedPhase.producing => l10n.seedBadgeProducing(countdown),
      SeedPhase.ready => l10n.seedBadgeReady,
    };
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        key: const ValueKey('seed-plot-badge'),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xF03A2012),
            border: Border.all(
              color: phase == SeedPhase.ready
                  ? const Color(0xFFFFE7A3)
                  : const Color(0xFFD4AF37),
              width: phase == SeedPhase.idle ? 1.2 : 2.2,
            ),
            boxShadow: phase == SeedPhase.idle || reduced
                ? null
                : const [BoxShadow(color: Color(0x66E8C96A), blurRadius: 8)],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (phase == SeedPhase.producing && batch != null)
                        _ProgressRing(progress: batch.progress(now)),
                      SeedGlyph(
                        size: phase == SeedPhase.producing ? 22 : 28,
                        unknown: phase != SeedPhase.ready,
                        species: phase == SeedPhase.ready
                            ? batch?.species
                            : null,
                      ),
                    ],
                  ),
                ),
                if (phase == SeedPhase.producing)
                  Text(
                    countdown,
                    key: const ValueKey('seed-plot-time'),
                    maxLines: 1,
                    style: const TextStyle(
                      color: Color(0xFFF8F1DE),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  )
                else if (phase == SeedPhase.ready)
                  Text(
                    l10n.seedReadyMark,
                    key: const ValueKey('seed-plot-ready'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFE7A3),
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      height: 1,
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

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CircularProgressIndicator(
        value: progress.clamp(0, 1),
        strokeWidth: 3,
        backgroundColor: const Color(0x33F8F1DE),
        color: const Color(0xFFE8C96A),
      ),
    );
  }
}
