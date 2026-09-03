import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_version.dart';
import '../config/app_links.dart';
import '../l10n/l10n.dart';
import '../services/haptic_controller.dart';
import '../services/locked_tile_dim_controller.dart';
import '../services/music_controller.dart';
import '../services/q_mode_controller.dart';
import '../services/sfx_controller.dart';
import 'app_settings.dart';
import 'table_theme.dart';

Future<void> showGameTableMenu(
  BuildContext context, {
  required VoidCallback onRetry,
  required VoidCallback onCourtyard,
  required VoidCallback onHowToPlay,
  required ValueChanged<String> onLinkFailed,
}) {
  final l10n = L10n.of(context);
  final haptic = HapticScope.maybeOf(context);
  final sfx = SfxScope.maybeOf(context);
  final music = MusicScope.maybeOf(context);
  final qMode = QModeScope.maybeOf(context);
  final lockedDim = LockedTileDimScope.maybeOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TableUi.woodDeep,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) => SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([
          ?haptic,
          ?sfx,
          ?music,
          ?qMode,
          ?lockedDim,
        ]),
        builder: (_, _) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.refresh_rounded,
                  color: TableUi.ivory,
                ),
                title: Text(
                  l10n.retry,
                  style: const TextStyle(color: TableUi.ivory),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onRetry();
                },
              ),
              ListTile(
                leading: const Icon(Icons.home_rounded, color: TableUi.ivory),
                title: Text(
                  l10n.courtyard,
                  style: const TextStyle(color: TableUi.ivory),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onCourtyard();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.help_outline_rounded,
                  color: TableUi.ivory,
                ),
                title: Text(
                  l10n.howToPlay,
                  style: const TextStyle(color: TableUi.ivory),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  onHowToPlay();
                },
              ),
              SfxSwitchTile(controller: sfx, l10n: l10n),
              MusicSwitchTile(controller: music, l10n: l10n),
              HapticSwitchTile(controller: haptic, l10n: l10n),
              LockedTileDimSwitchTile(controller: lockedDim, l10n: l10n),
              QModeSwitchTile(controller: qMode, l10n: l10n),
              ListTile(
                leading: const Icon(
                  Icons.language_rounded,
                  color: TableUi.ivory,
                ),
                title: Text(
                  l10n.language,
                  style: const TextStyle(color: TableUi.ivory),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(showLanguagePicker(context));
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.privacy_tip_rounded,
                  color: TableUi.ivory,
                ),
                title: Text(
                  l10n.privacyPolicy,
                  style: const TextStyle(color: TableUi.ivory),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  unawaited(_openPrivacy(context, onLinkFailed));
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_rounded, color: TableUi.ivory),
                title: Text(
                  l10n.aboutGame,
                  style: const TextStyle(color: TableUi.ivory),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  showAboutGameDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _openPrivacy(
  BuildContext context,
  ValueChanged<String> onLinkFailed,
) async {
  final uri = Uri.parse(AppLinks.privacyPolicy);
  final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    onLinkFailed(L10n.of(context).couldNotOpenLink);
  }
}

Future<void> showAboutGameDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: const Color(0xFF3A2012),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: TableUi.gold.withValues(alpha: 0.7),
            width: 1.6,
          ),
        ),
        title: Text(
          L10n.of(dialogContext).aboutGame,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TableUi.goldSoft,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Mahjong Rise',
              style: TextStyle(
                color: TableUi.ivory,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              appVersionLabel,
              style: TextStyle(
                color: TableUi.ivory.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              L10n.of(dialogContext).builtAt(appBuildTime),
              style: TextStyle(
                color: TableUi.ivory.withValues(alpha: 0.55),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              L10n.of(dialogContext).close,
              style: const TextStyle(
                color: TableUi.goldSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      );
    },
  );
}
