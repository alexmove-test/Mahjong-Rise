import 'package:mahjong/config/ad_config.dart';

Future<void> testExecutable(Future<void> Function() testMain) async {
  AdConfig.debugSimulateAds = true;
  await testMain();
}
