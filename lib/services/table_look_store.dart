import 'package:shared_preferences/shared_preferences.dart';

import '../models/table_look.dart';

/// Saved table skin. New (premium) until the player picks another look.
class TableLookStore {
  TableLookStore._(this._prefs);

  final SharedPreferences? _prefs;
  bool? _chosenOverride;

  static const _kPref = 'app.tableLook';
  static const _kChosen = 'app.tableLookChosen';
  static const _kPreviewPrefix = 'app.tableLookPreview.';

  static TableLookStore memory() => TableLookStore._(null);

  static Future<TableLookStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return TableLookStore._(prefs);
  }

  bool get canPersist => _prefs != null;

  TableLook get look => TableLook.parse(_prefs?.getString(_kPref));

  /// True after the player picks a look in the menu.
  ///
  /// A saved look from before this flag existed counts as a pick, so a new
  /// game does not replace a theme the player already chose.
  bool get playerChoseLook {
    final override = _chosenOverride;
    if (override != null) return override;
    final prefs = _prefs;
    if (prefs == null) return false;
    if (prefs.containsKey(_kChosen)) return prefs.getBool(_kChosen) ?? false;
    return prefs.containsKey(_kPref);
  }

  TableLook? previewFor(int levelId) {
    return TableLook.tryParse(_prefs?.getString('$_kPreviewPrefix$levelId'));
  }

  Future<void> setPreview(int levelId, TableLook value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString('$_kPreviewPrefix$levelId', value.id);
  }

  Future<void> setLook(TableLook value) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(_kPref, value.id);
  }

  Future<void> markChosen() async {
    _chosenOverride = true;
    await _prefs?.setBool(_kChosen, true);
  }

  /// Remembers a showcase look without treating it as the player's choice.
  Future<void> saveShowcaseLook(TableLook value) async {
    if (playerChoseLook) return;
    final prefs = _prefs;
    if (prefs == null) return;
    _chosenOverride = false;
    await prefs.setBool(_kChosen, false);
    if (_chosenOverride != false) {
      await prefs.setBool(_kChosen, true);
      return;
    }
    await prefs.setString(_kPref, value.id);
  }
}
