import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Full-screen stand-in for a rewarded ad until real AdMob is enabled.
abstract final class SimulatedRewardedAd {
  static Future<bool> show(BuildContext context) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, _, _) => const _SimulatedAdPage(),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(anim),
            child: child,
          ),
        );
      },
    ).then((value) => value ?? false);
  }
}

class _SimulatedAdPage extends StatefulWidget {
  const _SimulatedAdPage();

  @override
  State<_SimulatedAdPage> createState() => _SimulatedAdPageState();
}

class _SimulatedAdPageState extends State<_SimulatedAdPage> {
  static const _seconds = 5;
  late int _left;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _left = _seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_left <= 1) {
        timer.cancel();
        setState(() => _left = 0);
        return;
      }
      setState(() => _left -= 1);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    const gold = Color(0xFFE8C96A);
    const ivory = Color(0xFFF8F1DE);
    final ready = _left <= 0;

    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Material(
            color: const Color(0xFF3A2012),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      tooltip: l10n.skip,
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded, color: ivory),
                    ),
                  ),
                  Text(
                    l10n.simulatedAdTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.simulatedAdBody,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: ivory.withValues(alpha: 0.88),
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    ready ? l10n.claimReward : l10n.secondsLeft(_left),
                    style: const TextStyle(
                      color: ivory,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: const Color(0xFF3A2012),
                        disabledBackgroundColor: gold.withValues(alpha: 0.35),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: ready
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      child: Text(
                        l10n.claimReward,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
