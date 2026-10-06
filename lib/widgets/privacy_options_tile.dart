import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/ad_bootstrap.dart';

/// IAB entry point: reopen the GDPR privacy options form when required.
class PrivacyOptionsTile extends StatefulWidget {
  const PrivacyOptionsTile({
    super.key,
    required this.iconColor,
    required this.textColor,
    this.onMessage,
  });

  final Color iconColor;
  final Color textColor;
  final ValueChanged<String>? onMessage;

  @override
  State<PrivacyOptionsTile> createState() => _PrivacyOptionsTileState();
}

class _PrivacyOptionsTileState extends State<PrivacyOptionsTile> {
  bool _required = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final required = await AdBootstrap.privacyOptionsRequired();
    if (!mounted) return;
    setState(() => _required = required);
  }

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    final error = await AdBootstrap.showPrivacyOptions();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null && error.isNotEmpty) {
      widget.onMessage?.call(error);
    }
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (!_required) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: Icon(Icons.tune_rounded, color: widget.iconColor),
      title: Text(
        l10n.privacySettings,
        style: TextStyle(color: widget.textColor),
      ),
      enabled: !_busy,
      onTap: _open,
    );
  }
}
