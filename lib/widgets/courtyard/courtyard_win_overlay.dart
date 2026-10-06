import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/plot_kind.dart';
import '../../models/points_award.dart';
import '../../models/rank_climb.dart';
import '../../services/game_sfx.dart';
import '../points/points_award_badge.dart';
import '../win_burst.dart';
import 'courtyard_estate.dart';

const _goldSoft = Color(0xFFE8C96A);

/// Данные праздника после победы: двор уже открыт, это только HUD сверху.
class CourtyardWinReveal {
  const CourtyardWinReveal({
    required this.estateFrom,
    required this.estateTo,
    this.cycle = 0,
    this.focusKind,
    this.score = 0,
    this.stars = 0,
    this.isNewBest = false,
    this.pointsAward = const PointsAward.none(),
    this.houseUpgradeNote,
    this.climb,
  });

  final CourtyardEstate estateFrom;
  final CourtyardEstate estateTo;
  final int cycle;
  final PlotKind? focusKind;
  final int score;
  final int stars;
  final bool isNewBest;

  /// Сколько баллов принесла победа — уже зачислено в кошелёк.
  final PointsAward pointsAward;

  /// Цена следующего облика или нехватка поинтов. Дом сам не меняется.
  final String? houseUpgradeNote;

  /// Подъём в рейтинге считается параллельно с праздником двора.
  final Future<RankClimb?>? climb;
}

/// Конфетти, счёт и «Победа!» поверх двора. Двор остаётся экраном.
class CourtyardWinOverlay extends StatefulWidget {
  const CourtyardWinOverlay({
    super.key,
    this.onFinished,
    this.score = 0,
    this.stars = 0,
    this.isNewBest = false,
    this.points = 0,
    this.houseUpgradeNote,
  });

  /// Сколько держать праздник поверх двора. Дом за это время не меняется.
  static const displayDuration = Duration(milliseconds: 2800);

  final VoidCallback? onFinished;
  final int score;
  final int stars;
  final bool isNewBest;

  /// Начисленные за победу баллы; 0 — плашку не показываем.
  final int points;

  /// Доступность покупки следующего облика. Пусто — строку не показываем.
  final String? houseUpgradeNote;

  @override
  State<CourtyardWinOverlay> createState() => _CourtyardWinOverlayState();
}

class _CourtyardWinOverlayState extends State<CourtyardWinOverlay>
    with TickerProviderStateMixin {
  late final WinBurstLayout _burstLayout;
  late final AnimationController _celebrate;
  late final AnimationController _rain;
  final GameSfx _sfx = GameSfx();
  Timer? _done;

  @override
  void initState() {
    super.initState();
    _burstLayout = WinBurstLayout.generate();
    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();
    _rain = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    unawaited(_playFanfare());
    _done = Timer(CourtyardWinOverlay.displayDuration, () {
      widget.onFinished?.call();
    });
  }

  Future<void> _playFanfare() async {
    await _sfx.init();
    if (!mounted) return;
    await _sfx.win();
  }

  @override
  void dispose() {
    _done?.cancel();
    _celebrate.dispose();
    _rain.dispose();
    _sfx.dispose();
    super.dispose();
  }

  double _segment(double start, double end) {
    final t = _celebrate.value;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: Listenable.merge([_celebrate, _rain]),
        builder: (context, _) {
          final titleIn = Curves.easeOutBack.transform(_segment(0.00, 0.26));
          final fadeOut = _celebrate.value > 0.78
              ? ((1 - _celebrate.value) / 0.22).clamp(0.0, 1.0)
              : 1.0;
          final title = (titleIn * fadeOut).clamp(0.0, 1.0);
          final recapIn = Curves.easeOutCubic.transform(_segment(0.14, 0.36));
          final recap = (recapIn * fadeOut).clamp(0.0, 1.0);
          final shimmer = Curves.easeInOutCubic.transform(_segment(0.18, 0.58));
          final pointsIn = Curves.easeOutBack.transform(_segment(0.28, 0.52));
          final coinShine = _segment(0.34, 0.78);
          final glow =
              0.72 + 0.28 * (0.5 + 0.5 * math.sin(_rain.value * math.pi * 2));
          final l10n = AppLocalizations.of(context);
          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(
                painter: WinBurstPainter(
                  layout: _burstLayout,
                  burstT: (_celebrate.value * 2).clamp(0.0, 1.0),
                  rainT: _rain.value,
                ),
              ),
              Align(
                alignment: const Alignment(0, -0.18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: title,
                      child: Transform.scale(
                        scale: 0.72 + 0.28 * titleIn,
                        child: _WinTitle(
                          text: l10n.youWin,
                          shimmer: shimmer,
                          spin: _rain.value,
                          glow: glow,
                        ),
                      ),
                    ),
                    if (widget.score > 0 || widget.stars > 0) ...[
                      const SizedBox(height: 10),
                      Opacity(
                        opacity: recap,
                        child: _WinScoreRecap(
                          score: widget.score,
                          stars: widget.stars,
                          isNewBest: widget.isNewBest,
                        ),
                      ),
                    ],
                    if (widget.points > 0) ...[
                      const SizedBox(height: 12),
                      Opacity(
                        opacity: (pointsIn * fadeOut).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.76 + 0.24 * pointsIn,
                          child: PointsAwardBadge(
                            points: widget.points,
                            shine: coinShine,
                            glow: glow,
                          ),
                        ),
                      ),
                    ],
                    if (widget.houseUpgradeNote != null) ...[
                      const SizedBox(height: 8),
                      Opacity(
                        opacity: (pointsIn * fadeOut).clamp(0.0, 1.0),
                        child: Text(
                          widget.houseUpgradeNote!,
                          key: const ValueKey('win-house-upgrade'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _goldSoft,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

const winTitleKey = ValueKey('win-title');

class _WinTitle extends StatelessWidget {
  const _WinTitle({
    required this.text,
    required this.shimmer,
    required this.spin,
    required this.glow,
  });

  final String text;
  final double shimmer;
  final double spin;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: WinTitleHaloPainter(spin: spin, glow: glow),
      foregroundPainter: WinTitleGlyphPainter(
        text: text,
        textDirection: Directionality.of(context),
        shimmer: shimmer,
        glow: glow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 32),
        child: Text(
          text,
          key: winTitleKey,
          textAlign: TextAlign.center,
          style: WinTitleGlyphPainter.style.copyWith(color: Colors.transparent),
        ),
      ),
    );
  }
}

const winScoreRecapKey = ValueKey('win-score-recap');

class _WinScoreRecap extends StatelessWidget {
  const _WinScoreRecap({
    required this.score,
    required this.stars,
    required this.isNewBest,
  });

  final int score;
  final int stars;
  final bool isNewBest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final earned = stars.clamp(0, 3);
    return Column(
      key: winScoreRecapKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (earned > 0)
          Semantics(
            label: l10n.starsCount(earned),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(
                    Icons.star_rounded,
                    size: 26,
                    color: i < earned ? _goldSoft : const Color(0x66E8C96A),
                  ),
              ],
            ),
          ),
        if (score > 0) ...[
          if (earned > 0) const SizedBox(height: 4),
          Text(
            l10n.score(score),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFF8F1DE),
              fontWeight: FontWeight.w800,
              fontSize: 18,
              shadows: [
                Shadow(color: Color(0xE6000000), blurRadius: 10),
                Shadow(color: Color(0x99000000), blurRadius: 4),
              ],
            ),
          ),
        ],
        if (isNewBest) ...[
          const SizedBox(height: 4),
          Text(
            l10n.newBest,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _goldSoft,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              shadows: [Shadow(color: Color(0x99000000), blurRadius: 8)],
            ),
          ),
        ],
      ],
    );
  }
}
