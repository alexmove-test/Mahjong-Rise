import 'package:flutter/material.dart';

import '../../models/garden.dart';
import '../../models/seed_catalog.dart';
import 'plant_art.dart';

/// Короткий перелёт уже собранного растения. Пропуск не влияет на склад.
class PlantFlight extends StatefulWidget {
  const PlantFlight({
    super.key,
    required this.species,
    required this.from,
    required this.to,
    required this.onDone,
  });

  final SeedSpecies species;
  final Offset from;
  final Offset to;
  final VoidCallback onDone;

  static const duration = Duration(milliseconds: 520);

  @override
  State<PlantFlight> createState() => _PlantFlightState();
}

class _PlantFlightState extends State<PlantFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  var _done = false;
  var _started = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: PlantFlight.duration);
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) _finish();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduced = MediaQuery.disableAnimationsOf(context);
    _ctrl.duration = reduced ? Duration.zero : PlantFlight.duration;
    _ctrl.forward();
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    if (!_done) {
      _done = true;
      final onDone = widget.onDone;
      WidgetsBinding.instance.addPostFrameCallback((_) => onDone());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = Curves.easeInOutCubic.transform(_ctrl.value);
          final pos = Offset.lerp(widget.from, widget.to, t)!;
          return Stack(
            children: [
              Positioned(
                left: pos.dx - 18,
                top: pos.dy - 18,
                child: PlantArt(
                  species: widget.species,
                  stage: GrowthStage.ripe,
                  size: 36,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
