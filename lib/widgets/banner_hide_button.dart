import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/ad_bootstrap.dart';
import '../services/analytics_service.dart';
import '../services/banner_hide_controller.dart';
import '../services/rewarded_ad_service.dart';

/// Плавающая кнопка над баннером. Полный текст награды — в окне до ролика.
class BannerHideButton extends StatefulWidget {
  const BannerHideButton({
    super.key,
    this.adsLive,
    this.showAd,
    this.navigatorKey,
  });

  /// В тестах можно показать кнопку, пока реклама имитируется.
  final bool? adsLive;

  final Future<RewardedAdShowResult> Function(BuildContext context)? showAd;

  /// Контекст под [Navigator]: сама кнопка живёт над ним, в builder приложения.
  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  State<BannerHideButton> createState() => _BannerHideButtonState();
}

class _BannerHideButtonState extends State<BannerHideButton> {
  static const _ivory = Color(0xFFF8F1DE);
  static const _gold = Color(0xFFE8C96A);
  static const _goldLine = Color(0xFFD4AF37);

  bool _busy = false;
  String? _note;

  bool get _adsLive => widget.adsLive ?? !AdBootstrap.simulation;

  static Future<RewardedAdShowResult> _showRewarded(BuildContext context) {
    return RewardedAdService.instance.show(context: context);
  }

  BuildContext get _dialogContext =>
      widget.navigatorKey?.currentContext ?? context;

  Future<void> _watch(BannerHideController controller) async {
    if (_busy || controller.isHidden) return;
    final dialogContext = _dialogContext;
    if (!dialogContext.mounted) return;
    final watch = await _confirm(dialogContext);
    if (!watch || !mounted || controller.isHidden) return;

    setState(() {
      _busy = true;
      _note = null;
    });
    try {
      if (widget.showAd == null) {
        if (!AdBootstrap.initFinished || !AdBootstrap.enabled) {
          await AdBootstrap.prepareForAdRequest();
        }
        if (!mounted) return;
        if (!AdBootstrap.available) {
          setState(() => _note = AppLocalizations.of(context).adUnavailable);
          return;
        }
      }
      final result = await (widget.showAd ?? _showRewarded)(dialogContext);
      if (!mounted) return;
      if (result != RewardedAdShowResult.earned) {
        setState(() {
          _note = result == RewardedAdShowResult.skipped
              ? AppLocalizations.of(context).rewardNotEarned
              : AppLocalizations.of(context).adUnavailable;
        });
        return;
      }
      await controller.grant();
      unawaited(
        AnalyticsService.log('banner_hide', <String, Object>{'hours': 24}),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _note = AppLocalizations.of(context).adUnavailable);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(BuildContext dialogContext) {
    final l10n = AppLocalizations.of(dialogContext);
    return showDialog<bool>(
      context: dialogContext,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF3A2012),
          title: Text(
            l10n.hideBannerTitle,
            style: const TextStyle(color: _gold, fontWeight: FontWeight.w800),
          ),
          content: Text(
            l10n.hideBannerSubtitle,
            style: const TextStyle(color: _ivory, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.hideBannerNotNow),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B9A6A),
                foregroundColor: _ivory,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.hideBannerWatch),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_adsLive) return const SizedBox.shrink();
    final controller = BannerHideScope.maybeOf(context);
    if (controller == null || controller.isHidden) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final note = _note;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (note != null) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xE6141A12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                note,
                style: const TextStyle(
                  color: _ivory,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Semantics(
          button: true,
          label: l10n.hideBannerTitle,
          child: Material(
            color: Colors.transparent,
            elevation: 2,
            shadowColor: const Color(0x33000000),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              onTap: _busy ? null : () => _watch(controller),
              borderRadius: BorderRadius.circular(999),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF6B3E24).withValues(alpha: 0.55),
                      const Color(0xFF3A2012).withValues(alpha: 0.55),
                    ],
                  ),
                  border: Border.all(
                    color: _goldLine.withValues(alpha: 0.55),
                    width: 1.4,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_busy)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _gold,
                          ),
                        )
                      else
                        const Icon(
                          Icons.visibility_off_rounded,
                          color: _gold,
                          size: 18,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.hideBannerButton,
                        style: const TextStyle(
                          color: _ivory,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
