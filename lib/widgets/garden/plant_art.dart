import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/garden.dart';
import '../../models/seed_batch.dart';
import '../../models/seed_catalog.dart';
import '../seeds/seed_glyph.dart';

const gardenIvory = Color(0xFFF8F1DE);
const gardenGold = Color(0xFFD4AF37);
const gardenGoldSoft = Color(0xFFE8C96A);
const gardenWood = Color(0xFF3A2012);
const gardenSoil = Color(0xFF6A4428);

Color plantColor(SeedSpecies species) => switch (species) {
  SeedSpecies.amberbell => const Color(0xFFE2A53A),
  SeedSpecies.mistfern => const Color(0xFF3E8F62),
  SeedSpecies.glassreed => const Color(0xFF7EC8D4),
  SeedSpecies.crimsonplum => const Color(0xFFB44A55),
  SeedSpecies.nightlotus => const Color(0xFF8E74C9),
  SeedSpecies.starbamboo => const Color(0xFF2F8F6B),
};

/// Растение на грядке. Стадия читается из сохранённого времени, не из таймера.
class PlantArt extends StatelessWidget {
  const PlantArt({
    super.key,
    required this.species,
    required this.stage,
    this.size = 36,
  });

  final SeedSpecies species;
  final GrowthStage stage;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (stage == GrowthStage.sown) {
      return SeedGlyph(size: size, species: species);
    }
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PlantPainter(species: species, stage: stage),
      ),
    );
  }
}

class _PlantPainter extends CustomPainter {
  const _PlantPainter({required this.species, required this.stage});

  final SeedSpecies species;
  final GrowthStage stage;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final color = plantColor(species);
    final stem = Paint()
      ..color = const Color(0xFF2F5C45)
      ..strokeWidth = side * 0.06
      ..strokeCap = StrokeCap.round;
    final leaf = Paint()..color = color;
    final height = switch (stage) {
      GrowthStage.sown => 0.05,
      GrowthStage.sprout => 0.22,
      GrowthStage.growing => 0.38,
      GrowthStage.ripe => 0.48,
    };
    canvas.drawLine(
      center.translate(0, side * 0.28),
      center.translate(0, side * (0.28 - height)),
      stem,
    );
    final spread = stage == GrowthStage.sprout ? 0.12 : 0.22;
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(-side * spread * 0.7, side * 0.02),
        width: side * spread,
        height: side * spread * 0.55,
      ),
      leaf,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center.translate(side * spread * 0.7, side * 0.02),
        width: side * spread,
        height: side * spread * 0.55,
      ),
      leaf,
    );
    if (stage == GrowthStage.ripe) {
      canvas.drawCircle(
        center.translate(0, -side * 0.16),
        side * 0.12,
        Paint()..color = color,
      );
      canvas.drawCircle(
        center.translate(-side * 0.04, -side * 0.2),
        side * 0.035,
        Paint()..color = gardenIvory.withValues(alpha: 0.8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PlantPainter oldDelegate) =>
      oldDelegate.species != species || oldDelegate.stage != stage;
}

class GardenBedView extends StatefulWidget {
  const GardenBedView({
    super.key,
    required this.index,
    required this.planting,
    required this.onTap,
    this.now,
  });

  final int index;
  final Planting? planting;
  final VoidCallback? onTap;
  final DateTime Function()? now;

  @override
  State<GardenBedView> createState() => _GardenBedViewState();
}

class _GardenBedViewState extends State<GardenBedView>
    with WidgetsBindingObserver {
  Timer? _timer;

  DateTime _now() => (widget.now ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant GardenBedView oldWidget) {
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
    final planting = widget.planting;
    final ticking =
        widget.now == null && planting != null && !planting.isReady(_now());
    if (!ticking) {
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
    final planting = widget.planting;
    final now = _now();
    final stage = planting == null ? null : stageOf(planting, now);
    final ready = stage == GrowthStage.ripe;
    final reduced = MediaQuery.disableAnimationsOf(context);
    final number = widget.index + 1;
    final label = planting == null || stage == null
        ? l10n.gardenBedEmpty(number)
        : l10n.gardenBedLabel(
            number: number,
            name: l10n.seedName(planting.species),
            stage: l10n.growthStage(stage),
            time: formatSeedCountdown(planting.remaining(now)),
            ready: ready,
          );
    return Semantics(
      button: widget.onTap != null,
      label: label,
      child: GestureDetector(
        key: ValueKey('garden-bed-${widget.index}'),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: ExcludeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: gardenSoil,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ready ? gardenGoldSoft : gardenGold,
                width: ready ? 2.4 : 1.4,
              ),
              boxShadow: ready && !reduced
                  ? const [BoxShadow(color: Color(0x88E8C96A), blurRadius: 8)]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Column(
                children: [
                  Expanded(
                    child: planting == null || stage == null
                        ? const FittedBox(
                            child: Icon(
                              Icons.add_rounded,
                              color: gardenGoldSoft,
                            ),
                          )
                        : PlantArt(species: planting.species, stage: stage),
                  ),
                  if (ready)
                    Text(
                      l10n.harvestMark,
                      key: ValueKey('garden-ready-${widget.index}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: gardenIvory,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  else if (planting != null && stage != null)
                    Text(
                      formatSeedCountdown(planting.remaining(now)),
                      maxLines: 1,
                      style: const TextStyle(
                        color: gardenIvory,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class WarehouseBuilding extends StatelessWidget {
  const WarehouseBuilding({
    super.key,
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: onTap != null,
      label: l10n.warehouseSemantic(count),
      child: GestureDetector(
        key: const ValueKey('courtyard-warehouse'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          children: [
            Expanded(
              child: CustomPaint(
                painter: const _WarehousePainter(),
                child: const SizedBox.expand(),
              ),
            ),
            Text(
              l10n.warehouseTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: gardenIvory,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: Color(0xCC000000), blurRadius: 3)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarehousePainter extends CustomPainter {
  const _WarehousePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.12, h * 0.38, w * 0.76, h * 0.58),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF8A5A32));
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, w * 0.02)
        ..color = gardenGold,
    );
    final roof = Path()
      ..moveTo(w * 0.06, h * 0.42)
      ..lineTo(w * 0.5, h * 0.08)
      ..lineTo(w * 0.94, h * 0.42)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF6B3E24));
    canvas.drawPath(
      roof,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, w * 0.018)
        ..color = gardenGoldSoft,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.42, h * 0.58, w * 0.16, h * 0.34),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = gardenWood,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.18, h * 0.52, w * 0.16, h * 0.16),
        Radius.circular(w * 0.02),
      ),
      Paint()..color = const Color(0xFFC4A574),
    );
  }

  @override
  bool shouldRepaint(covariant _WarehousePainter oldDelegate) => false;
}
