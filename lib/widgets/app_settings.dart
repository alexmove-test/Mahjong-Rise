import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../l10n/locale_controller.dart';
import '../services/haptic_controller.dart';
import '../services/locale_store.dart';
import '../services/local_reminder_service.dart';
import '../services/reminder_store.dart';
import '../services/sfx_controller.dart';

const _ivory = Color(0xFFF8F1DE);
const _gold = Color(0xFFE8C96A);
const _wood = Color(0xFF3A2012);

Future<void> showAppSettings(BuildContext context) {
  final locale = LocaleScope.maybeOf(context);
  final haptic = HapticScope.maybeOf(context);
  final sfx = SfxScope.maybeOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: _wood,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([
            if (locale != null) locale,
            if (haptic != null) haptic,
            if (sfx != null) sfx,
          ]),
          builder: (_, _) {
            final l10n = L10n.of(ctx);
            final current = locale?.preference ?? LanguagePref.system;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    l10n.settings,
                    style: const TextStyle(
                      color: _gold,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                SfxSwitchTile(controller: sfx, l10n: l10n),
                HapticSwitchTile(controller: haptic, l10n: l10n),
                const ReminderSwitchTile(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Divider(color: Color(0x44F8F1DE)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.language,
                      style: const TextStyle(
                        color: _gold,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                _languageTile(
                  ctx,
                  locale,
                  LanguagePref.system,
                  current,
                  l10n.languageSystem,
                ),
                _languageTile(
                  ctx,
                  locale,
                  LanguagePref.en,
                  current,
                  l10n.languageEnglish,
                ),
                _languageTile(
                  ctx,
                  locale,
                  LanguagePref.ru,
                  current,
                  l10n.languageRussian,
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      );
    },
  );
}

Future<void> showLanguagePicker(BuildContext context) {
  final controller = LocaleScope.maybeOf(context);
  final l10n = L10n.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: _wood,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      final current = controller?.preference ?? LanguagePref.system;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                l10n.language,
                style: const TextStyle(
                  color: _gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            _languageTile(
              ctx,
              controller,
              LanguagePref.system,
              current,
              l10n.languageSystem,
              popOnSelect: true,
            ),
            _languageTile(
              ctx,
              controller,
              LanguagePref.en,
              current,
              l10n.languageEnglish,
              popOnSelect: true,
            ),
            _languageTile(
              ctx,
              controller,
              LanguagePref.ru,
              current,
              l10n.languageRussian,
              popOnSelect: true,
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

class SfxSwitchTile extends StatelessWidget {
  const SfxSwitchTile({
    super.key,
    required this.controller,
    required this.l10n,
  });

  final SfxController? controller;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final enabled = controller?.enabled ?? true;
    return SwitchListTile(
      secondary: Icon(
        enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        color: enabled ? _gold : _ivory,
      ),
      title: Text(
        l10n.sound,
        style: TextStyle(
          color: enabled ? _gold : _ivory,
          fontWeight: FontWeight.w700,
        ),
      ),
      value: enabled,
      onChanged: controller?.setEnabled,
      activeThumbColor: _gold,
      activeTrackColor: _gold.withValues(alpha: 0.38),
    );
  }
}

class ReminderSwitchTile extends StatefulWidget {
  const ReminderSwitchTile({super.key});

  @override
  State<ReminderSwitchTile> createState() => _ReminderSwitchTileState();
}

class _ReminderSwitchTileState extends State<ReminderSwitchTile> {
  ReminderStore? _store;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = await ReminderStore.open();
    if (!mounted) return;
    setState(() => _store = store);
  }

  Future<void> _setEnabled(bool value) async {
    final store = _store;
    if (store == null) return;
    if (value) {
      final allowed = await LocalReminderService.requestPermission();
      if (!allowed) return;
    }
    await store.setEnabled(value);
    if (!mounted) return;
    await LocalReminderService.resync(l10n: L10n.of(context));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final enabled = _store?.enabled ?? false;
    return SwitchListTile(
      secondary: Icon(
        Icons.notifications_rounded,
        color: enabled ? _gold : _ivory,
      ),
      title: Text(
        l10n.reminders,
        style: TextStyle(
          color: enabled ? _gold : _ivory,
          fontWeight: FontWeight.w700,
        ),
      ),
      value: enabled,
      onChanged: _store == null ? null : _setEnabled,
      activeThumbColor: _gold,
      activeTrackColor: _gold.withValues(alpha: 0.38),
    );
  }
}

class HapticSwitchTile extends StatelessWidget {
  const HapticSwitchTile({
    super.key,
    required this.controller,
    required this.l10n,
  });

  final HapticController? controller;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final enabled = controller?.enabled ?? true;
    return SwitchListTile(
      secondary: Icon(Icons.vibration_rounded, color: enabled ? _gold : _ivory),
      title: Text(
        l10n.hapticFeedback,
        style: TextStyle(
          color: enabled ? _gold : _ivory,
          fontWeight: FontWeight.w700,
        ),
      ),
      value: enabled,
      onChanged: controller?.setEnabled,
      activeThumbColor: _gold,
      activeTrackColor: _gold.withValues(alpha: 0.38),
    );
  }
}

Widget _languageTile(
  BuildContext ctx,
  LocaleController? controller,
  LanguagePref value,
  LanguagePref current,
  String label, {
  bool popOnSelect = false,
}) {
  final selected = value == current;
  return ListTile(
    leading: Icon(
      selected ? Icons.check_circle_rounded : Icons.circle_outlined,
      color: selected ? _gold : _ivory,
    ),
    title: Text(
      label,
      style: TextStyle(
        color: selected ? _gold : _ivory,
        fontWeight: FontWeight.w700,
      ),
    ),
    onTap: () async {
      if (popOnSelect) Navigator.pop(ctx);
      await controller?.setPreference(value);
    },
  );
}
