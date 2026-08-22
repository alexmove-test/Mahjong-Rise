import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import 'courtyard_progress.dart';
import 'courtyard_scene.dart';

/// Полноэкранный двор сразу после победы: рост участка + праздник.
Future<void> showCourtyardWinOverlay({
  required BuildContext context,
  required int levelId,
  required String levelTitle,
  required int score,
  required int stars,
  required bool isNewBest,
  required bool unlockedNext,
  required bool hasNext,
  required bool nextUnlocked,
  required CourtyardSnapshot courtyardFrom,
  required CourtyardSnapshot courtyardTo,
  required String pathPhrase,
  required bool firstHome,
  required VoidCallback onMap,
  required VoidCallback onNext,
  required VoidCallback onRetry,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black,
    barrierLabel: MaterialLocalizations.of(context).dialogLabel,
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return CourtyardWinOverlay(
        levelId: levelId,
        levelTitle: levelTitle,
        score: score,
        stars: stars,
        isNewBest: isNewBest,
        unlockedNext: unlockedNext,
        hasNext: hasNext,
        nextUnlocked: nextUnlocked,
        courtyardFrom: courtyardFrom,
        courtyardTo: courtyardTo,
        pathPhrase: pathPhrase,
        firstHome: firstHome,
        onMap: onMap,
        onNext: onNext,
        onRetry: onRetry,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class CourtyardWinOverlay extends StatefulWidget {
  const CourtyardWinOverlay({
    super.key,
    required this.levelId,
    required this.levelTitle,
    required this.score,
    required this.stars,
    required this.isNewBest,
    required this.unlockedNext,
    required this.hasNext,
    required this.nextUnlocked,
    required this.courtyardFrom,
    required this.courtyardTo,
    required this.pathPhrase,
    required this.firstHome,
    required this.onMap,
    required this.onNext,
    required this.onRetry,
  });

  final int levelId;
  final String levelTitle;
  final int score;
  final int stars;
  final bool isNewBest;
  final bool unlockedNext;
  final bool hasNext;
  final bool nextUnlocked;
  final CourtyardSnapshot courtyardFrom;
  final CourtyardSnapshot courtyardTo;
  final String pathPhrase;
  final bool firstHome;
  final VoidCallback onMap;
  final VoidCallback onNext;
  final VoidCallback onRetry;

  @override
  State<CourtyardWinOverlay> createState() => _CourtyardWinOverlayState();
}

class _CourtyardWinOverlayState extends State<CourtyardWinOverlay>
    with SingleTickerProviderStateMixin {
  static const _gold = Color(0xFFD4AF37);
  static const _goldSoft = Color(0xFFE8C96A);
  static const _ivory = Color(0xFFF8F1DE);
  static const _woodTop = Color(0xFF6B3E24);

  late final AnimationController _celebrate;

  @override
  void initState() {
    super.initState();
    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();
  }

  @override
  void dispose() {
    _celebrate.dispose();
    super.dispose();
  }

  double _segment(double start, double end) {
    final t = _celebrate.value;
    if (t <= start) return 0;
    if (t >= end) return 1;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  double _starProgress(int index) =>
      _segment(0.14 + index * 0.16, 0.30 + index * 0.16);

  Widget _starIcon(int index) {
    final earned = index < widget.stars;
    if (!earned) {
      return const Icon(
        Icons.star_outline_rounded,
        color: Colors.white24,
        size: 40,
      );
    }

    final t = Curves.elasticOut.transform(_starProgress(index));
    return Transform.scale(
      scale: t,
      child: Icon(
        Icons.star_rounded,
        color: _gold,
        size: 40,
        shadows: [
          Shadow(color: _goldSoft.withValues(alpha: 0.55 * t), blurRadius: 10),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _celebrate,
      builder: (context, _) {
        final l10n = L10n.of(context);
        final titleIn = Curves.easeOutBack.transform(_segment(0.00, 0.18));
        final scoreIn = Curves.easeOutBack.transform(_segment(0.08, 0.24));
        final phraseIn = Curves.easeOut.transform(_segment(0.28, 0.55));
        final recordIn = Curves.easeOut.transform(_segment(0.62, 0.82));
        final unlockIn = Curves.easeOut.transform(_segment(0.72, 0.92));

        return Material(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CourtyardScene(
                from: widget.courtyardFrom,
                to: widget.courtyardTo,
                animate: true,
                idle: false,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0x00000000),
                      Color(0x00000000),
                      Color(0xCC1A0E08),
                    ],
                    stops: [0, 0.22, 0.48, 1],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: WinConfettiPainter(progress: _celebrate.value),
                  ),
                ),
              ),
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: titleIn.clamp(0.0, 1.0),
                          child: Transform.scale(
                            scale: 0.86 + 0.14 * titleIn,
                            child: Text(
                              l10n.youWin,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _goldSoft,
                                fontWeight: FontWeight.w900,
                                fontSize: 36,
                                height: 1.05,
                                shadows: [
                                  Shadow(
                                    color: Color(0x99000000),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.levelCleared(widget.levelId),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _ivory,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            shadows: [
                              Shadow(color: Color(0x88000000), blurRadius: 8),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Opacity(
                          opacity: phraseIn,
                          child: Text(
                            widget.pathPhrase,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _ivory.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.levelTitle,
                          style: TextStyle(
                            color: _ivory.withValues(alpha: 0.72),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < 3; i++) ...[
                              if (i > 0) const SizedBox(width: 10),
                              _starIcon(i),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Transform.scale(
                          scale: 0.92 + 0.08 * scoreIn,
                          child: Opacity(
                            opacity: scoreIn.clamp(0.0, 1.0),
                            child: Text(
                              l10n.score(widget.score),
                              style: const TextStyle(
                                color: _ivory,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                        if (widget.isNewBest)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Opacity(
                              opacity: recordIn,
                              child: Transform.scale(
                                scale: 0.85 + 0.15 * recordIn,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _gold.withValues(alpha: 0.35),
                                        _goldSoft.withValues(alpha: 0.2),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _goldSoft.withValues(alpha: 0.75),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Text(
                                    l10n.newBest,
                                    style: const TextStyle(
                                      color: _goldSoft,
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
                                l10n.levelUnlocked(widget.levelId + 1),
                                style: TextStyle(
                                  color: _goldSoft.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (widget.firstHome) ...[
                              if (widget.hasNext && widget.nextUnlocked)
                                Expanded(
                                  child: TextButton(
                                    onPressed: widget.onNext,
                                    child: Text(
                                      l10n.next,
                                      style: const TextStyle(color: _ivory),
                                    ),
                                  ),
                                )
                              else
                                const Spacer(),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _woodTop,
                                    foregroundColor: _goldSoft,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed: widget.onMap,
                                  child: Text(l10n.courtyard),
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: TextButton(
                                  onPressed: widget.onMap,
                                  child: Text(
                                    l10n.courtyard,
                                    style: const TextStyle(color: _ivory),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _woodTop,
                                    foregroundColor: _goldSoft,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed:
                                      widget.hasNext && widget.nextUnlocked
                                      ? widget.onNext
                                      : widget.onRetry,
                                  child: Text(
                                    widget.hasNext && widget.nextUnlocked
                                        ? l10n.next
                                        : l10n.playAgain,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class WinConfettiPainter extends CustomPainter {
  const WinConfettiPainter({required this.progress});

  final double progress;

  static const _pieceCount = 88;
  static const _sparkCount = 22;

  static const _confettiColors = [
    Color(0xFFD4AF37),
    Color(0xFFE8C96A),
    Color(0xFFF8F1DE),
    Color(0xFFE84855),
    Color(0xFF4DA3FF),
    Colors.white,
    Color(0xFFF2A65A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final fade = progress < 0.88
        ? 1.0
        : (1 - (progress - 0.88) / 0.12).clamp(0.0, 1.0);

    for (var i = 0; i < _pieceCount; i++) {
      final rng = math.Random(i * 29 + 11);
      final delay = rng.nextDouble() * 0.28;
      final local = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      final x =
          rng.nextDouble() * size.width +
          math.sin(local * math.pi * 3 + i) * 18;
      final y = -12 + local * (size.height + 48);
      final rotation = local * math.pi * 3 + rng.nextDouble();
      final w = 4 + rng.nextDouble() * 5;
      final h = 7 + rng.nextDouble() * 8;
      final color = _confettiColors[i % _confettiColors.length].withValues(
        alpha: (0.55 + rng.nextDouble() * 0.4) * fade,
      );

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rotation);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(1.4),
        ),
        Paint()..color = color,
      );
      canvas.restore();
    }

    final sparkCenter = Offset(size.width / 2, size.height * 0.28);
    final sparkT = ((progress - 0.08) / 0.5).clamp(0.0, 1.0);
    if (sparkT <= 0) return;

    for (var i = 0; i < _sparkCount; i++) {
      final angle = i / _sparkCount * math.pi * 2 - math.pi / 2;
      final dist = 36 + 90 * Curves.easeOut.transform(sparkT);
      final opacity = (1 - sparkT) * fade;
      final tip =
          sparkCenter +
          Offset(math.cos(angle) * dist, math.sin(angle) * dist * 0.72);
      canvas.drawLine(
        sparkCenter,
        tip,
        Paint()
          ..color = const Color(0xFFE8C96A).withValues(alpha: 0.5 * opacity)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant WinConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
