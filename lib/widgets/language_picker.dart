import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../l10n/locale_controller.dart';
import '../services/locale_store.dart';

Future<void> showLanguagePicker(BuildContext context) {
  final controller = LocaleScope.of(context);
  final l10n = L10n.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF3A2012),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      final current = controller.preference;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                l10n.language,
                style: const TextStyle(
                  color: Color(0xFFE8C96A),
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
            _tile(ctx, controller, LanguagePref.system, current, l10n.languageSystem),
            _tile(ctx, controller, LanguagePref.en, current, l10n.languageEnglish),
            _tile(ctx, controller, LanguagePref.ru, current, l10n.languageRussian),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Widget _tile(
  BuildContext ctx,
  LocaleController controller,
  LanguagePref value,
  LanguagePref current,
  String label,
) {
  const ivory = Color(0xFFF8F1DE);
  const gold = Color(0xFFE8C96A);
  final selected = value == current;
  return ListTile(
    leading: Icon(
      selected ? Icons.check_circle_rounded : Icons.circle_outlined,
      color: selected ? gold : ivory,
    ),
    title: Text(
      label,
      style: TextStyle(
        color: selected ? gold : ivory,
        fontWeight: FontWeight.w700,
      ),
    ),
    onTap: () async {
      Navigator.pop(ctx);
      await controller.setPreference(value);
    },
  );
}
