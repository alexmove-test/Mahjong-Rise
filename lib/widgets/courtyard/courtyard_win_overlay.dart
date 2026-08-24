import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../win_burst.dart';
import 'courtyard_progress.dart';
import 'courtyard_scene.dart';

/// Полноэкранный двор сразу после победы: рост участка + праздник.
Future<void> showCourtyardWinOverlay({
  required BuildContext context,
  required int stars,
  required bool hasNext,
  required bool nextUnlocked,
  required CourtyardSnapshot courtyardFrom,
  required CourtyardSnapshot courtyardTo,
  required String pathPhrase,
  int cycle = 0,
  String? title,
  String? subtitle,
  bool showStars = true,
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
        stars: stars,
        hasNext: hasNext,
        nextUnlocked: nextUnlocked,
        courtyardFrom: courtyardFrom,
        courtyardTo: courtyardTo,
        pathPhrase: pathPhrase,
        cycle: cycle,
        title: title,
        subtitle: subtitle,
        showStars: showStars,
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
    required this.stars,
    required this.hasNext,
    required this.nextUnlocked,
    required this.courtyardFrom,
    required this.courtyardTo,
    required this.pathPhrase,
    this.cycle = 0,
    this.title,
    this.subtitle,
    this.showStars = true,
    required this.onMap,
    required this.onNext,
    required this.onRetry,
  });

  final int stars;
  final bool hasNext;
  final bool nextUnlocked;
  final CourtyardSnapshot courtyardFrom;
  final CourtyardSnapshot courtyardTo;
  final String pathPhrase;
  final int cycle;
  final String? title;
  final String? subtitle;
  final bool showStars;
  final VoidCallback onMap;
  final VoidCallback onNext;
  final VoidCallback onRetry;

  @override
  State<CourtyardWinOverlay> createState() => _CourtyardWinOverlayState();
}

class _CourtyardWinOverlayState extends State<CourtyardWinOverlay>
    with TickerProviderStateMixin {
  static const _gold = Color(0xFFD4AF37);
  static const _goldSoft = Color(0xFFE8C96A);
  static const _ivory = Color(0xFFF8F1DE);
  static const _ink = Color(0xFF2A160C);

  late final WinBurstLayout _burstLayout;
  late final AnimationController _celebrate;
  late final AnimationController _rain;

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
  }

  @override
  void dispose() {
    _celebrate.dispose();
    _rain.dispose();
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
      animation: Listenable.merge([_celebrate, _rain]),
      builder: (context, _) {
        final l10n = L10n.of(context);
        final titleIn = Curves.easeOutBack.transform(_segment(0.00, 0.18));
        final phraseIn = Curves.easeOut.transform(_segment(0.28, 0.55));
        final canContinue = widget.hasNext && widget.nextUnlocked;

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
                cycle: widget.cycle,
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
                    painter: WinBurstPainter(
                      layout: _burstLayout,
                      burstT: (_celebrate.value * 2).clamp(0.0, 1.0),
                      rainT: _rain.value,
                    ),
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
                              widget.title ?? l10n.youWin,
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
                          widget.subtitle ?? l10n.anotherLevelCleared,
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
                        if (widget.showStars) ...[
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
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _gold,
                              foregroundColor: _ink,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                letterSpacing: 0.4,
                              ),
                            ),
                            onPressed: canContinue
                                ? widget.onNext
                                : widget.onRetry,
                            child: Text(
                              canContinue ? l10n.next : l10n.playAgain,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onMap,
                          child: Text(
                            l10n.courtyard,
                            style: TextStyle(
                              color: _ivory.withValues(alpha: 0.88),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
