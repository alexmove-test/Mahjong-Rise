import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/ad_config.dart';
import '../../services/ad_bootstrap.dart';
import '../../services/banner_hide_controller.dart';

/// Обычный закреплённый adaptive-баннер, не высокий large.
/// До загрузки места не занимает, чтобы верстка не прыгала
/// и widget-тесты видели прежний экран.
class BannerAdSlot extends StatefulWidget {
  const BannerAdSlot({super.key});

  /// Перезапрашиваем объявление только на заметной смене ширины —
  /// ориентация в приложении не зафиксирована.
  static const widthTolerance = 16.0;

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _ad;
  AdSize? _size;
  double? _requestedWidth;
  bool _loading = false;
  bool _suppressed = false;

  @override
  void initState() {
    super.initState();
    // Двор рисуется раньше, чем AdMob заканчивает init. Без этого
    // слот навсегда остаётся пустым.
    if (AdBootstrap.simulation || AdBootstrap.enabled) return;
    unawaited(_armWhenReady());
  }

  Future<void> _armWhenReady() async {
    await AdBootstrap.ensureInitialized();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  bool _needsReload(double width) {
    final requested = _requestedWidth;
    if (requested == null) return true;
    return (requested - width).abs() > BannerAdSlot.widthTolerance;
  }

  Future<void> _load(double width) async {
    if (_loading || _suppressed) return;
    _loading = true;
    _requestedWidth = width;
    final previous = _ad;
    _ad = null;
    _size = null;
    previous?.dispose();

    try {
      // Large (до 20% экрана, 50–150 dp) режет двор. Короткий размер
      // ещё отдаёт SDK, хотя метод помечен устаревшим.
      final size =
          await AdSize
          // ignore: deprecated_member_use
          .getCurrentOrientationAnchoredAdaptiveBannerAdSize(width.truncate());
      if (!mounted || size == null) return;
      final ad = BannerAd(
        size: size,
        adUnitId: AdConfig.bannerUnitId,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            if (!mounted || _suppressed) {
              if (_suppressed) _requestedWidth = null;
              ad.dispose();
              return;
            }
            setState(() {
              _ad = ad as BannerAd;
              _size = size;
            });
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('BannerAd failed: ${error.code} ${error.message}');
            ad.dispose();
          },
        ),
      );
      await ad.load();
    } catch (error) {
      debugPrint('BannerAd load threw: $error');
    } finally {
      _loading = false;
    }
  }

  void _dropAd() {
    final previous = _ad;
    _ad = null;
    _size = null;
    _requestedWidth = null;
    previous?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hidden = BannerHideScope.maybeOf(context)?.isHidden ?? false;
    _suppressed = hidden || AdBootstrap.simulation || !AdBootstrap.enabled;
    if (_suppressed && _ad != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _suppressed) _dropAd();
      });
    }
    if (_suppressed) {
      return const SizedBox.shrink();
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width.isFinite && width > 0 && _needsReload(width)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_suppressed) _load(width);
          });
        }
        final ad = _ad;
        final size = _size;
        if (ad == null || size == null) return const SizedBox.shrink();
        return SizedBox(
          width: size.width.toDouble(),
          height: size.height.toDouble(),
          child: AdWidget(ad: ad),
        );
      },
    );
  }
}
