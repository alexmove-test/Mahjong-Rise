import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/house_upgrade.dart';
import '../../models/plot_kind.dart';
import '../../models/seed_catalog.dart';
import 'courtyard_lot_build.dart';

const _ivory = Color(0xFFF8F1DE);
const _goldSoft = Color(0xFFE8C96A);
const _goldLine = Color(0xFFD4AF37);

/// Покупка следующего облика: снаружи миниатюра и кнопка, подробности в шторке.
class HomeUpgradePreview extends StatefulWidget {
  const HomeUpgradePreview({
    super.key,
    required this.state,
    required this.balance,
    this.busy = false,
    this.onBuy,
  });

  /// Текущее состояние, 1…24.
  final int state;
  final int balance;
  final bool busy;
  final Future<void> Function()? onBuy;

  @override
  State<HomeUpgradePreview> createState() => _HomeUpgradePreviewState();
}

class _HomeUpgradePreviewState extends State<HomeUpgradePreview>
    with SingleTickerProviderStateMixin {
  var _busy = false;
  var _detailsOpen = false;
  late final AnimationController _curtain;

  bool get _locked => widget.busy || _busy;

  @override
  void initState() {
    super.initState();
    _curtain = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _curtain.duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220);
  }

  @override
  void dispose() {
    _curtain.dispose();
    super.dispose();
  }

  void _toggleDetails() {
    setState(() => _detailsOpen = !_detailsOpen);
    if (_detailsOpen) {
      _curtain.forward();
    } else {
      _curtain.reverse();
    }
  }

  Future<void> _buy() async {
    final action = widget.onBuy;
    if (action == null || _locked) return;
    if (!HouseUpgrade.canAdvance(widget.state)) return;
    final price = HouseUpgrade.priceAfter(widget.state);
    if (widget.balance < price) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = HouseUpgrade.clampState(widget.state);
    final maxed = !HouseUpgrade.canAdvance(state);
    final price = maxed ? 0 : HouseUpgrade.priceAfter(state);
    final shortfall = maxed ? 0 : (price - widget.balance).clamp(0, price);
    final canBuy = !maxed && shortfall == 0 && widget.onBuy != null && !_locked;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xEB3A2012),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x88D4AF37)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (maxed)
              Text(
                l10n.houseFullyUpgraded,
                key: const ValueKey('house-upgrade-max'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _goldSoft,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _NextHouseArt(frame: state + 1),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UpgradeButton(
                      label: l10n.upgradeHouseFor(price),
                      onPressed: canBuy ? _buy : null,
                    ),
                  ),
                ],
              ),
            _CurtainHandle(open: _detailsOpen, onTap: _toggleDetails),
            AnimatedBuilder(
              animation: _curtain,
              builder: (context, _) {
                final t = Curves.easeOut.transform(_curtain.value);
                return ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: t == 0 ? 0 : t,
                    child: t == 0
                        ? const SizedBox(width: double.infinity, height: 0)
                        : _UpgradeDetails(
                            state: state,
                            price: price,
                            shortfall: shortfall,
                            maxed: maxed,
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      key: const ValueKey('house-upgrade-button'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF6B3E24),
        foregroundColor: _goldSoft,
        disabledBackgroundColor: const Color(0xFF3A2012),
        disabledForegroundColor: const Color(0x88E8C96A),
        minimumSize: const Size.fromHeight(44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _goldLine.withValues(alpha: 0.75)),
        ),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      ),
    );
  }
}

class _CurtainHandle extends StatelessWidget {
  const _CurtainHandle({required this.open, required this.onTap});

  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = open ? l10n.houseDetailsHide : l10n.houseDetailsShow;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        key: const ValueKey('house-upgrade-curtain'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Icon(
            open ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            color: _goldSoft,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _UpgradeDetails extends StatelessWidget {
  const _UpgradeDetails({
    required this.state,
    required this.price,
    required this.shortfall,
    required this.maxed,
  });

  final int state;
  final int price;
  final int shortfall;
  final bool maxed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        if (!maxed) ...[
          Text(
            l10n.houseStateTitle(state, HouseUpgrade.stateCount),
            key: const ValueKey('house-state-title'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _goldSoft,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
        ],
        _HouseLookLine(
          key: const ValueKey('house-look-line'),
          stage: state.toDouble(),
        ),
        if (!maxed) ...[
          const SizedBox(height: 8),
          Text(
            l10n.houseUpgradeOffer(price),
            key: const ValueKey('house-upgrade-price'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _ivory,
              fontSize: 13,
              height: 1.25,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          _SeedUpgradeBenefit(state: state),
          if (shortfall > 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.pointsShortfall(shortfall),
              key: const ValueKey('house-upgrade-shortfall'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _goldSoft,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _SeedUpgradeBenefit extends StatelessWidget {
  const _SeedUpgradeBenefit({required this.state});

  final int state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = SeedCatalog.offerFor(state);
    final next = SeedCatalog.offerFor(state + 1);
    final band = SeedCatalog.bandChanges(state, state + 1);
    return Column(
      key: const ValueKey('seed-upgrade-benefits'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.seedDurationStep(
            l10n.catalogDuration(current.duration),
            l10n.catalogDuration(next.duration),
          ),
          key: const ValueKey('seed-duration-step'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _goldSoft, fontSize: 12, height: 1.2),
        ),
        Text(
          l10n.seedCostStep(current.cost, next.cost),
          key: const ValueKey('seed-cost-step'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: _goldSoft, fontSize: 12, height: 1.2),
        ),
        if (band)
          Text(
            l10n.seedChanceStep(l10n.seedChanceSummary(next.chances)),
            key: const ValueKey('seed-chance-step'),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _ivory, fontSize: 12, height: 1.2),
          ),
      ],
    );
  }
}

class _NextHouseArt extends StatefulWidget {
  const _NextHouseArt({required this.frame});

  final int frame;

  @override
  State<_NextHouseArt> createState() => _NextHouseArtState();
}

class _NextHouseArtState extends State<_NextHouseArt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant _NextHouseArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.frame != oldWidget.frame + 1) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    _pulse.forward(from: 0);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(_pulse.value);
        final scale = _pulse.isAnimating ? 0.86 + 0.14 * t : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Image.asset(
        PlotStages.assetOf(PlotKind.house, widget.frame),
        key: const ValueKey('next-house-image'),
        width: 72,
        height: 72,
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
    );
  }
}

/// Opaque height fraction of each 1024² house frame. Early looks sit
/// at the bottom of the canvas, so thumbnails zoom into that region.
const _houseContentSpan = <double>[
  0.322,
  0.568,
  0.593,
  0.727,
  0.572,
  0.786,
  0.791,
  0.701,
  0.795,
  0.765,
  0.852,
  0.850,
  0.766,
  0.707,
  0.872,
  0.858,
  0.828,
  0.804,
  0.857,
  0.860,
  0.881,
  0.887,
  0.908,
  0.912,
];

const _houseMistMatrix = <double>[
  0.52,
  0.34,
  0.14,
  0,
  16,
  0.46,
  0.40,
  0.14,
  0,
  20,
  0.40,
  0.36,
  0.24,
  0,
  28,
  0,
  0,
  0,
  0.92,
  0,
];

const _lookGold = Color(0xFFE8C96A);
const _lookLineHeight = 58.0;
const _lookCellWidth = 62.0;

/// All 24 house frames. Built ones are marked on a gold track; the rest are fog.
class _HouseLookLine extends StatefulWidget {
  const _HouseLookLine({super.key, required this.stage});

  final double stage;

  @override
  State<_HouseLookLine> createState() => _HouseLookLineState();
}

class _HouseLookLineState extends State<_HouseLookLine> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerCurrent());
  }

  @override
  void didUpdateWidget(covariant _HouseLookLine oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (PlotStages.currentFrame(oldWidget.stage) !=
        PlotStages.currentFrame(widget.stage)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _centerCurrent());
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _centerCurrent() {
    if (!mounted || !_scroll.hasClients) return;
    final current = PlotStages.currentFrame(widget.stage);
    final index = current <= 0 ? 0 : current - 1;
    final viewport = _scroll.position.viewportDimension;
    final itemCenter = index * _lookCellWidth + _lookCellWidth / 2;
    final target = itemCenter - viewport / 2;
    _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    final current = PlotStages.currentFrame(widget.stage);
    return Semantics(
      container: true,
      label: AppLocalizations.of(
        context,
      ).houseLookLine(current, PlotStages.frameCount),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x40140A06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x33D4AF37)),
        ),
        child: SizedBox(
          height: _lookLineHeight,
          child: ListView.builder(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            primary: false,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemExtent: _lookCellWidth,
            itemCount: PlotStages.frameCount,
            itemBuilder: (context, index) {
              final frame = index + 1;
              final built = current > 0 && frame <= current;
              return _HouseLookCell(
                frame: frame,
                built: built,
                here: frame == current,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HouseLookCell extends StatelessWidget {
  const _HouseLookCell({
    required this.frame,
    required this.built,
    required this.here,
  });

  final int frame;
  final bool built;
  final bool here;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: here
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _lookGold, width: 1.5),
                    )
                  : const BoxDecoration(),
              child: Padding(
                padding: EdgeInsets.all(here ? 2 : 1),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _ZoomedHouse(frame: frame, mist: !built),
                      if (!built)
                        CustomPaint(
                          key: ValueKey('house-look-fog-$frame'),
                          painter: const _FogVeilPainter(),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _LookTrack(
            built: built,
            here: here,
            markKey: built ? ValueKey('house-look-built-$frame') : null,
          ),
        ],
      ),
    );
  }
}

class _ZoomedHouse extends StatelessWidget {
  const _ZoomedHouse({required this.frame, required this.mist});

  final int frame;
  final bool mist;

  @override
  Widget build(BuildContext context) {
    assert(_houseContentSpan.length == PlotStages.frameCount);
    final span = _houseContentSpan[frame - 1];
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxHeight / span;
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final cache = (side * dpr).round().clamp(96, 512);
        Widget image = Image.asset(
          PlotStages.assetOf(PlotKind.house, frame),
          width: side,
          height: side,
          fit: BoxFit.fill,
          cacheWidth: cache,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          excludeFromSemantics: true,
        );
        if (mist) {
          image = ColorFiltered(
            colorFilter: const ColorFilter.matrix(_houseMistMatrix),
            child: image,
          );
        }
        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.bottomCenter,
            minWidth: side,
            maxWidth: side,
            minHeight: side,
            maxHeight: side,
            child: image,
          ),
        );
      },
    );
  }
}

class _LookTrack extends StatelessWidget {
  const _LookTrack({required this.built, required this.here, this.markKey});

  final bool built;
  final bool here;
  final Key? markKey;

  @override
  Widget build(BuildContext context) {
    final line = built ? _lookGold : const Color(0x668EACBA);
    return SizedBox(
      height: 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            right: 0,
            child: SizedBox(height: 2, child: ColoredBox(color: line)),
          ),
          Container(
            key: markKey,
            width: here ? 9 : 6,
            height: here ? 9 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: built ? _lookGold : const Color(0xFF9BB0BC),
              border: Border.all(color: const Color(0xFF3A2012), width: 1),
              boxShadow: here
                  ? const [BoxShadow(color: Color(0xAAE8C96A), blurRadius: 5)]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _FogVeilPainter extends CustomPainter {
  const _FogVeilPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cloud = Paint()
      ..color = const Color(0xA8F7FBFD)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.66),
        width: size.width * 1.15,
        height: size.height * 0.72,
      ),
      cloud,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.32, size.height * 0.4),
        width: size.width * 0.72,
        height: size.height * 0.42,
      ),
      cloud..color = const Color(0x8CFFFFFF),
    );
  }

  @override
  bool shouldRepaint(covariant _FogVeilPainter oldDelegate) => false;
}
