import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/points_pack.dart';
import '../../services/ad_bootstrap.dart';
import '../../services/analytics_service.dart';
import '../../services/points_controller.dart';
import '../../services/points_purchase.dart';
import '../../services/rewarded_ad_service.dart';
import '../../utils/points_format.dart';
import 'points_chip.dart';

const _ivory = Color(0xFFF8F1DE);
const _gold = Color(0xFFE8C96A);
const _goldLine = Color(0xFFD4AF37);
const _wood = Color(0xFF3A2012);

Future<void> showPointsShop(BuildContext context) {
  final points = PointsScope.read(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _wood,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      const sheet = PointsShopSheet();
      if (points == null) return sheet;
      return PointsScope(controller: points, child: sheet);
    },
  );
}

/// Витрина баллов: пакеты на покупку и бесплатная горсть за ролик.
class PointsShopSheet extends StatefulWidget {
  const PointsShopSheet({super.key, this.backend, this.showAd});

  /// Платёжный бэкенд; по умолчанию — общий [PointsPurchase.backend].
  final PointsPurchaseBackend? backend;

  final Future<RewardedAdShowResult> Function(BuildContext context)? showAd;

  /// Сколько баллов даёт один рекламный ролик.
  static const adReward = 50;

  @override
  State<PointsShopSheet> createState() => _PointsShopSheetState();
}

class _PointsShopSheetState extends State<PointsShopSheet> {
  String? _busyId;
  String? _note;

  PointsPurchaseBackend get _backend =>
      widget.backend ?? PointsPurchase.backend;

  bool get _busy => _busyId != null;

  static Future<RewardedAdShowResult> _showRewarded(BuildContext context) {
    return RewardedAdService.instance.show(context: context);
  }

  Future<void> _buy(PointsPack pack) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final controller = PointsScope.read(context);
    if (controller == null) return;
    setState(() {
      _busyId = pack.id;
      _note = null;
    });
    try {
      final result = await _backend.buy(pack);
      if (!mounted) return;
      if (!result.isPurchased) {
        setState(
          () => _note = result.status == PointsPurchaseStatus.cancelled
              ? l10n.pointsPurchaseCancelled
              : l10n.pointsPurchaseUnavailable,
        );
        return;
      }
      await controller.creditPurchase(result.points);
      unawaited(
        AnalyticsService.log('points_purchase', <String, Object>{
          'pack': pack.id,
          'points': result.points,
        }),
      );
      if (!mounted) return;
      setState(() => _note = l10n.pointsCredited(result.points));
    } catch (_) {
      if (!mounted) return;
      setState(() => _note = l10n.pointsPurchaseUnavailable);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _watchAd() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final controller = PointsScope.read(context);
    if (controller == null) return;
    setState(() {
      _busyId = 'ad';
      _note = null;
    });
    try {
      if (widget.showAd == null && !AdBootstrap.simulation) {
        if (!AdBootstrap.initFinished || !AdBootstrap.enabled) {
          await AdBootstrap.prepareForAdRequest();
        }
        if (!mounted) return;
        if (!AdBootstrap.available) {
          setState(() => _note = l10n.adUnavailable);
          return;
        }
      }
      final result = await (widget.showAd ?? _showRewarded)(context);
      if (!mounted) return;
      if (result != RewardedAdShowResult.earned) {
        setState(
          () => _note = result == RewardedAdShowResult.skipped
              ? l10n.rewardNotEarned
              : l10n.adUnavailable,
        );
        return;
      }
      await controller.earn(PointsShopSheet.adReward);
      unawaited(
        AnalyticsService.log('points_ad', <String, Object>{
          'points': PointsShopSheet.adReward,
        }),
      );
      if (!mounted) return;
      setState(() => _note = l10n.pointsCredited(PointsShopSheet.adReward));
    } catch (_) {
      if (!mounted) return;
      setState(() => _note = l10n.adUnavailable);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final note = _note;
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.pointsShopTitle,
                      style: const TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const PointsChipLive(),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                l10n.pointsShopSubtitle,
                style: const TextStyle(
                  color: _ivory,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.pointsEarnRule,
                style: TextStyle(
                  color: _ivory.withValues(alpha: 0.65),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              for (final pack in PointsPack.catalog) ...[
                _PackCard(
                  pack: pack,
                  price: _backend.priceLabel(pack),
                  tier: PointsPack.catalog.indexOf(pack),
                  busy: _busyId == pack.id,
                  onBuy: _busy ? null : () => _buy(pack),
                ),
                const SizedBox(height: 10),
              ],
              _AdRow(
                reward: PointsShopSheet.adReward,
                busy: _busyId == 'ad',
                onWatch: _busy ? null : _watchAd,
              ),
              if (note != null) ...[
                const SizedBox(height: 12),
                Text(
                  note,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
              if (!_backend.isLive) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.pointsDemoNote,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _ivory.withValues(alpha: 0.5),
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard({
    required this.pack,
    required this.price,
    required this.tier,
    required this.busy,
    required this.onBuy,
  });

  final PointsPack pack;
  final String price;
  final int tier;
  final bool busy;
  final VoidCallback? onBuy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final badge = switch (pack.badge) {
      PointsPackBadge.popular => l10n.pointsPackPopular,
      PointsPackBadge.best => l10n.pointsPackBest,
      null => null,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B3E24), Color(0xFF2A1708)],
        ),
        border: Border.all(
          color: _goldLine.withValues(alpha: pack.badge == null ? 0.5 : 0.9),
          width: pack.badge == null ? 1.2 : 1.6,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          children: [
            _StarPile(tier: tier),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatPoints(pack.total),
                    style: const TextStyle(
                      color: _ivory,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      height: 1.1,
                    ),
                  ),
                  if (pack.bonus > 0)
                    Text(
                      l10n.pointsPackBonus(pack.bonusPercent),
                      style: const TextStyle(
                        color: Color(0xFF7BE0AE),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  if (badge != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: _gold,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _PriceButton(label: price, busy: busy, onTap: onBuy),
          ],
        ),
      ),
    );
  }
}

class _PriceButton extends StatelessWidget {
  const _PriceButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${AppLocalizations.of(context).pointsBuy} $label',
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF1B9A6A),
          disabledBackgroundColor: const Color(0xFF14543D),
          foregroundColor: _ivory,
          minimumSize: const Size(94, 42),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: _goldLine.withValues(alpha: 0.7),
              width: 1.2,
            ),
          ),
        ),
        onPressed: onTap,
        child: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: _gold),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}

class _AdRow extends StatelessWidget {
  const _AdRow({
    required this.reward,
    required this.busy,
    required this.onWatch,
  });

  final int reward;
  final bool busy;
  final VoidCallback? onWatch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onWatch,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: _goldLine.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                if (busy)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _gold,
                    ),
                  )
                else
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    color: _gold,
                    size: 22,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.pointsWatchAdReward(reward),
                    style: const TextStyle(
                      color: _ivory,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  l10n.pointsWatchAd,
                  style: const TextStyle(
                    color: _gold,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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

/// Горка звёздочек на пакете: чем крупнее пакет, тем больше звёзд.
class _StarPile extends StatelessWidget {
  const _StarPile({required this.tier});

  final int tier;

  static const _box = 54.0;

  @override
  Widget build(BuildContext context) {
    final stars = _spots[tier.clamp(0, _spots.length - 1)];
    return SizedBox(
      width: _box,
      height: _box,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final star in stars)
            Positioned(
              left: star.left,
              top: star.top,
              child: Transform.rotate(
                angle: star.turn,
                child: Icon(
                  Icons.star_rounded,
                  size: star.size,
                  color: _gold.withValues(alpha: star.alpha),
                  shadows: star.glow
                      ? const [
                          Shadow(color: Color(0xB3FFD86B), blurRadius: 8),
                        ]
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StarSpot {
  const _StarSpot({
    required this.left,
    required this.top,
    required this.size,
    this.turn = 0,
    this.alpha = 1,
    this.glow = false,
  });

  final double left;
  final double top;
  final double size;
  final double turn;
  final double alpha;
  final bool glow;
}

const _spots = <List<_StarSpot>>[
  [
    _StarSpot(left: 11, top: 10, size: 32, glow: true),
  ],
  [
    _StarSpot(left: 1, top: 18, size: 22, turn: -0.22, alpha: 0.82),
    _StarSpot(left: 20, top: 6, size: 32, turn: 0.08, glow: true),
  ],
  [
    _StarSpot(left: 0, top: 24, size: 18, turn: -0.3, alpha: 0.7),
    _StarSpot(left: 30, top: 20, size: 20, turn: 0.28, alpha: 0.82),
    _StarSpot(left: 11, top: 2, size: 34, turn: -0.04, glow: true),
  ],
  [
    _StarSpot(left: 0, top: 28, size: 16, turn: -0.35, alpha: 0.62),
    _StarSpot(left: 34, top: 26, size: 17, turn: 0.32, alpha: 0.72),
    _StarSpot(left: 16, top: 16, size: 22, turn: 0.12, alpha: 0.88),
    _StarSpot(left: 8, top: 0, size: 34, turn: -0.06, glow: true),
  ],
];
