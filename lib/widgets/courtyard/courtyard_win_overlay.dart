import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/plot_kind.dart';
import '../../services/game_sfx.dart';
import '../win_burst.dart';
import 'courtyard_estate.dart';

/// Данные праздника после победы: двор уже открыт, это только HUD сверху.
class CourtyardWinReveal {
  const CourtyardWinReveal({
    required this.estateFrom,
    required this.estateTo,
    this.cycle = 0,
    this.focusKind,
  });

  final CourtyardEstate estateFrom;
  final CourtyardEstate estateTo;
  final int cycle;
  final PlotKind? focusKind;
}

/// Конфетти и «Победа!» поверх двора. Двор остаётся экраном.
class CourtyardWinOverlay extends StatefulWidget {
  const CourtyardWinOverlay({super.key, this.onFinished});

  /// Сколько держать праздник, пока участок растёт под ним.
  static const displayDuration = Duration(milliseconds: 2800);

  final VoidCallback? onFinished;

  @override
  State<CourtyardWinOverlay> createState() => _CourtyardWinOverlayState();
}

class _CourtyardWinOverlayState extends State<CourtyardWinOverlay>
    with TickerProviderStateMixin {
  static const _goldSoft = Color(0xFFE8C96A);

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
          final titleIn = Curves.easeOutBack.transform(_segment(0.00, 0.22));
          final fadeOut = _celebrate.value > 0.78
              ? ((1 - _celebrate.value) / 0.22).clamp(0.0, 1.0)
              : 1.0;
          final title = (titleIn * fadeOut).clamp(0.0, 1.0);
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
                alignment: const Alignment(0, -0.22),
                child: Opacity(
                  opacity: title,
                  child: Transform.scale(
                    scale: 0.86 + 0.14 * titleIn,
                    child: Text(
                      L10n.of(context).youWin,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _goldSoft,
                        fontWeight: FontWeight.w900,
                        fontSize: 42,
                        height: 1.05,
                        shadows: [
                          Shadow(color: Color(0xCC000000), blurRadius: 16),
                          Shadow(color: Color(0x99000000), blurRadius: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
