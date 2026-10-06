import 'package:mahjong/l10n/app_localizations.dart';
import 'package:mahjong/utils/points_format.dart';
import 'package:mahjong/models/points_award.dart';

extension FormatText on AppLocalizations {
  String upgradeHouseFor(int price) =>
      upgradeHouseForText(formatPoints(price));
  String pointsShortfall(int amount) =>
      pointsShortfallText(formatPoints(amount));
  String houseUpgradeOffer(int cost) =>
      houseUpgradeOfferText(formatPoints(cost));
  String pointsBalance(int value) =>
      pointsBalanceText(formatPoints(value));
  String get pointsEarnRule =>
      pointsEarnRuleText(PointsAward.perClear, PointsAward.perStar);
  String pointsCredited(int value) =>
      pointsCreditedText(formatPoints(value));
  String pointsWatchAdReward(int value) =>
      pointsWatchAdRewardText(formatPoints(value));
  String boostEarned(String name, {int count = 1}) =>
      boostEarnedText(count, name);
  String petStrengthLine({required String stat, required int total, required int base, required int main, required int accessory}) =>
      petStrengthLineText(stat, total, base, main, accessory);
  String gearPrice(int price) =>
      gearPriceText(formatPoints(price));
  String gearShortfall(int shortfall) =>
      gearShortfallText(formatPoints(shortfall));
  String produceSeedFor(int price) =>
      produceSeedForText(formatPoints(price));
  String plantAction(int seeds, int points) =>
      plantActionText(seeds, formatPoints(points));
  String plantCostLabel(int points) =>
      plantCostLabelText(formatPoints(points));
}
