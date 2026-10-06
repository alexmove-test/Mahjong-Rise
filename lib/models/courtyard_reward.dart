enum CourtyardReward { pond, swing, flowerBed }

extension CourtyardRewardCopy on CourtyardReward {
  /// Рисованный спрайт в стиле построек двора.
  String get asset => switch (this) {
    CourtyardReward.pond => 'assets/courtyard/props/pond.png',
    CourtyardReward.swing => 'assets/courtyard/props/swing.png',
    CourtyardReward.flowerBed => 'assets/courtyard/props/flower_bed.png',
  };
}
