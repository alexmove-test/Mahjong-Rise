import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Полноэкранная имитация rewarded-ролика (web/desktop, где AdMob нет).
class SimulatedRewardedAd extends StatefulWidget {
  const SimulatedRewardedAd({
    super.key,
    this.watchDuration = const Duration(seconds: 5),
  });

  final Duration watchDuration;

  static Future<bool> show(
    BuildContext context, {
    Duration watchDuration = const Duration(seconds: 5),
  }) async {
    final earned = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: L10n.of(context).ad,
      barrierColor: const Color(0xE60A120F),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, _) {
        return SimulatedRewardedAd(watchDuration: watchDuration);
      },
      transitionBuilder: (context, animation, _, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
    return earned ?? false;
  }

  @override
  State<SimulatedRewardedAd> createState() => _SimulatedRewardedAdState();
}

class _SimulatedRewardedAdState extends State<SimulatedRewardedAd> {
  static const _ivory = Color(0xFFF8F1DE);
  static const _gold = Color(0xFFE8C96A);
  static const _jade = Color(0xFF1B9A6A);

  Timer? _timer;
  late Duration _remaining;
  bool _finished = false;
  bool _popped = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.watchDuration;
    if (_remaining <= Duration.zero) {
      _finished = true;
      _timer = Timer(const Duration(milliseconds: 700), () {
        _close(earned: true);
      });
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted) return;
      final next = _remaining - const Duration(milliseconds: 200);
      if (next <= Duration.zero) {
        _timer?.cancel();
        _finishWatch();
        return;
      }
      setState(() => _remaining = next);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _progress {
    final total = widget.watchDuration.inMilliseconds;
    if (total <= 0) return 1;
    return 1 - (_remaining.inMilliseconds / total);
  }

  void _finishWatch() {
    _remaining = Duration.zero;
    _finished = true;
    if (mounted) setState(() {});
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 700), () {
      _close(earned: true);
    });
  }

  void _close({required bool earned}) {
    if (!mounted || _popped) return;
    _popped = true;
    _timer?.cancel();
    Navigator.of(context).pop(earned || _finished);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final secondsLeft = (_remaining.inMilliseconds / 1000).ceil();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A2012),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _gold.withValues(alpha: 0.45)),
                    ),
                    child: Text(
                      l10n.ad,
                      style: TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _finished
                        ? l10n.done
                        : '0:${secondsLeft.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: _ivory.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: _finished
                        ? l10n.claimReward
                        : l10n.closeWithoutReward,
                    onPressed: () => _close(earned: _finished),
                    icon: Icon(
                      Icons.close_rounded,
                      color: _ivory.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0B5C40), Color(0xFF083528)],
                    ),
                    border: Border.all(color: _gold.withValues(alpha: 0.28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_circle_fill_rounded,
                                size: 72,
                                color: _gold,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.simulatedAd,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _ivory,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                l10n.watchClipForBoost,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Color(0xCCF8F1DE),
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        bottom: 18,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _progress.clamp(0.0, 1.0),
                            minHeight: 8,
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.28,
                            ),
                            color: _gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _finished ? () => _close(earned: true) : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _jade,
                    disabledBackgroundColor: const Color(0xFF1A3D2E),
                    foregroundColor: _ivory,
                    disabledForegroundColor: _ivory.withValues(alpha: 0.38),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _finished ? l10n.claimReward : l10n.watchingAd,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
