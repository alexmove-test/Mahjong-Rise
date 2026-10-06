import 'package:flutter/material.dart';

import '../../models/courtyard_reward.dart';

class CourtyardRewardView extends StatelessWidget {
  const CourtyardRewardView({super.key, required this.reward});
  final CourtyardReward reward;

  @override
  Widget build(BuildContext context) => Image(
    key: ValueKey('courtyard-reward-${reward.name}'),
    image: AssetImage(reward.asset),
    fit: BoxFit.contain,
    alignment: Alignment.bottomCenter,
    filterQuality: FilterQuality.high,
    gaplessPlayback: true,
  );
}
