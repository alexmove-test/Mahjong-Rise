import 'package:shared_preferences/shared_preferences.dart';

/// Players hidden locally after a UGC hide action.
class UgcBlockStore {
  UgcBlockStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _kBlocked = 'ugc.blockedIds';

  static Future<UgcBlockStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return UgcBlockStore._(prefs);
  }

  Set<String> get blockedIds =>
      _prefs.getStringList(_kBlocked)?.toSet() ?? const {};

  bool isBlocked(String id) {
    if (id.isEmpty) return false;
    return blockedIds.contains(id);
  }

  Future<void> block(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return;
    final next = {...blockedIds, trimmed};
    await _prefs.setStringList(_kBlocked, next.toList()..sort());
  }
}
