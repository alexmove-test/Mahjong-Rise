import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/analytics_service.dart';
import '../../services/points_controller.dart';
import '../courtyard/home_upgrade_preview.dart';
import 'seed_production_panel.dart';
import 'seed_storage_sheet.dart';

const _wood = Color(0xFF24160E);

/// Карточка своего дома: покупка облика и производство семян.
Future<void> showHouseSheet(
  BuildContext context, {
  required Future<void> Function() onBuy,
  required VoidCallback onPlayMahjong,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    builder: (ctx) {
      return HouseSheet(
        height: MediaQuery.sizeOf(ctx).height * 0.9,
        onBuy: onBuy,
        onPlayMahjong: onPlayMahjong,
      );
    },
  );
}

class HouseSheet extends StatelessWidget {
  const HouseSheet({
    super.key,
    required this.height,
    required this.onBuy,
    required this.onPlayMahjong,
  });

  final double height;
  final Future<void> Function() onBuy;
  final VoidCallback onPlayMahjong;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final points = PointsScope.of(context);
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: _wood,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: SizedBox(
          height: height,
          child: ListenableBuilder(
            listenable: points,
            builder: (context, _) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.houseCardTitle,
                    style: const TextStyle(
                      color: Color(0xFFE8C96A),
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  HomeUpgradePreview(
                    state: points.houseState,
                    balance: points.balance,
                    onBuy: onBuy,
                  ),
                  const SizedBox(height: 12),
                  SeedProductionPanel(
                    houseLevel: points.houseState,
                    balance: points.balance,
                    batch: points.seedBatch,
                    busy: points.seedStartBusy || points.seedClaimBusy,
                    onStart: () async {
                      final result = await points.startSeedBatch();
                      if (result.started) {
                        AnalyticsService.log('seed_produce', <String, Object>{
                          'house': result.seeds.batch?.houseLevel ?? 0,
                          'cost': result.cost,
                        });
                      }
                      return result;
                    },
                    onClaim: () async {
                      final result = await points.claimSeed();
                      if (result.claimed) {
                        AnalyticsService.log('seed_claim', <String, Object>{
                          'power': result.seed?.power ?? 0,
                        });
                      }
                      return result;
                    },
                    onPlayMahjong: onPlayMahjong,
                    onOpenStorage: () => showSeedStorage(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
