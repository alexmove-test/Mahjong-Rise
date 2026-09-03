import 'package:flutter/material.dart';

import '../../models/pet.dart';

/// Крупный или мелкий портрет питомца из `assets/pets`.
class PetPortrait extends StatelessWidget {
  const PetPortrait({super.key, required this.kind, this.fit = BoxFit.contain});

  final PetKind kind;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      PetDef.of(kind).portrait,
      fit: fit,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
  }
}
