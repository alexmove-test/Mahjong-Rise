import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'match_particles.dart';
import 'win_burst.dart';

/// Полноэкранный праздник победы: лучи, конфетти, карточка со звёздами.
class WinOverlay extends StatefulWidget {
  const WinOverlay({
    super.key,
    required this.levelId,
    required this.levelTitle,
    required this.score,
    required this.stars,
    required this.isNewBest,
    required this.unlockedNext,
    required this.hasNext,
    required this.nextUnlocked,
    required this.onMap,
    required this.onNext,
    required this.onRetry,
    this.layout,
  });

  final int levelId;
  final String levelTitle;
  final int score;
  final int stars;
  final bool isNewBest;
  final bool unlockedNext;
  final bool hasNext;
  final bool nextUnlocked;
  final VoidCallback onMap;
  final VoidCallback onNext;
  final VoidCallback onRetry;
  final WinBurstLayout? layout;

  static const gold = Color(0xFFD4AF37);
  static const goldSoft = Color(0xFFE8C96A);
  static const ivory = Color(0xFFF8F1DE);
  static const woodDeep = Color(0xFF3A2012);
  static const woodWarm = Color(0xFF5C3218);

  @override
  State<WinOverlay> createState() => _WinOverlayState();
}

class _WinOverlayState extends State<WinOverlay> with TickerProviderStateMixin {
  late final WinBurstLayout _layout;
  late final AnimationController _appear;
  late final AnimationController _burst;
  late final AnimationController _rain;
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _layout = widget.layout ?? WinBurstLayout.generate();
    _appear = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..forward();
    _burst = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _rain = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 10000),
    )..repeat();
  }

  @override
  void dispose() {
    _appear.dispose();
    _burst.dispose();
    _rain.dispose();
    _glow.dispose();
    super.dispose();
  }

  double _segment(double t, double start, double end) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  double _starProgress(int index) =>
      _segment(_appear.value, 0.14 + index * 0.16, 0.30 + index * 0.16);

  double _titleScale(double t) {
    final local = _segment(t, 0.0, 0.28);
    if (local <= 0) return 0;
    if (local < 0.72) {
      return Curves.easeOutBack.transform(local / 0.72) * 1.12;
    }
    final rest = (local - 0.72) / 0.28;
    return 1.12 - 0.12 * Curves.easeOut.transform(rest);
  }

  Widget _starIcon(int index) {
    final earned = index < widget.stars;
    final t = _starProgress(index);

    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (earned) MatchSparkBurst(progress: t, width: 64, height: 64),
          Transform.scale(
            scale: earned ? Curves.elasticOut.transform(t) : 1,
            child: Icon(
              earned ? Icons.star_rounded : Icons.star_outline_rounded,
              color: earned ? WinOverlay.gold : Colors.white24,
              size: 48,
              shadows: earned
                  ? [
                      Shadow(
                        color: WinOverlay.goldSoft.withValues(alpha: 0.7 * t),
                        blurRadius: 16,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: SizedBox.expand(
        child: Material(
          color: Colors.transparent,
          child: AnimatedBuilder(
            animation: Listenable.merge([_appear, _burst, _rain, _glow]),
            builder: (context, _) {
              final appear = _appear.value;
              final scoreIn = Curves.easeOutBack.transform(
                _segment(appear, 0.04, 0.18),
              );
              final recordIn = Curves.easeOut.transform(
                _segment(appear, 0.62, 0.82),
              );
              final unlockIn = Curves.easeOut.transform(
                _segment(appear, 0.72, 0.92),
              );
              final titleScale = _titleScale(appear);
              final glowPulse =
                  0.82 +
                  0.18 * (0.5 - 0.5 * math.cos(_glow.value * 2 * math.pi));

              return Stack(
                fit: StackFit.expand,
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(0, -0.12),
                          radius: 1.18,
                          colors: [
                            Color(0xCC5C3218),
                            Color(0xD10B3D32),
                            Color(0xF0051510),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.18),
                          radius: 0.62,
                          colors: [
                            WinOverlay.goldSoft.withValues(
                              alpha: 0.38 * glowPulse,
                            ),
                            WinOverlay.gold.withValues(alpha: 0.10 * glowPulse),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: WinSunburstPainter(
                          rotation: _glow.value,
                          intensity: 0.55 + 0.45 * glowPulse,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: WinBurstPainter(
                            layout: _layout,
                            burstT: _burst.value,
                            rainT: _rain.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 18,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  WinOverlay.woodWarm,
                                  WinOverlay.woodDeep,
                                  Color(0xFF2A160C),
                                ],
                              ),
                              border: Border.all(
                                color: WinOverlay.gold.withValues(alpha: 0.92),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: WinOverlay.goldSoft.withValues(
                                    alpha: 0.42 * glowPulse,
                                  ),
                                  blurRadius: 28,
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.42),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                20,
                                22,
                                20,
                                16,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Transform.scale(
                                    scale: titleScale,
                                    child: Opacity(
                                      opacity: titleScale.clamp(0.0, 1.0),
                                      child: Text(
                                        'Победа!',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: WinOverlay.goldSoft,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 42,
                                          height: 1.05,
                                          letterSpacing: 1.1,
                                          shadows: [
                                            Shadow(
                                              color: WinOverlay.gold.withValues(
                                                alpha: 0.85 * glowPulse,
                                              ),
                                              blurRadius: 22,
                                            ),
                                            Shadow(
                                              color: const Color(0xFFFFF3C4)
                                                  .withValues(alpha: 0.7),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Уровень ${widget.levelId} · ${widget.levelTitle}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: WinOverlay.ivory.withValues(
                                        alpha: 0.82,
                                      ),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (var i = 0; i < 3; i++) _starIcon(i),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Transform.scale(
                                    scale: 0.92 + 0.08 * scoreIn,
                                    child: Opacity(
                                      opacity: scoreIn.clamp(0.0, 1.0),
                                      child: Text(
                                        'Счёт: ${widget.score}',
                                        style: const TextStyle(
                                          color: WinOverlay.ivory,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (widget.isNewBest)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 10),
                                      child: Opacity(
                                        opacity: recordIn,
                                        child: Transform.scale(
                                          scale: 0.85 + 0.15 * recordIn,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  WinOverlay.gold.withValues(
                                                    alpha: 0.45,
                                                  ),
                                                  WinOverlay.goldSoft
                                                      .withValues(alpha: 0.22),
                                                ],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: WinOverlay.goldSoft
                                                    .withValues(alpha: 0.85),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: const Text(
                                              'Новый рекорд!',
                                              style: TextStyle(
                                                color: WinOverlay.ivory,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (widget.unlockedNext)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Opacity(
                                        opacity: unlockIn,
                                        child: Text(
                                          'Открыт уровень ${widget.levelId + 1}',
                                          style: TextStyle(
                                            color: WinOverlay.goldSoft
                                                .withValues(alpha: 0.95),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 18),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: widget.onMap,
                                        child: const Text(
                                          'Карта',
                                          style: TextStyle(
                                            color: WinOverlay.ivory,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (widget.hasNext && widget.nextUnlocked)
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: WinOverlay.gold,
                                            foregroundColor:
                                                WinOverlay.woodDeep,
                                            elevation: 4,
                                            shadowColor: WinOverlay.goldSoft,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 22,
                                              vertical: 12,
                                            ),
                                          ),
                                          onPressed: widget.onNext,
                                          child: const Text(
                                            'Дальше',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        )
                                      else
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: WinOverlay.gold,
                                            foregroundColor:
                                                WinOverlay.woodDeep,
                                            elevation: 4,
                                            shadowColor: WinOverlay.goldSoft,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 22,
                                              vertical: 12,
                                            ),
                                          ),
                                          onPressed: widget.onRetry,
                                          child: const Text(
                                            'Ещё раз',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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
