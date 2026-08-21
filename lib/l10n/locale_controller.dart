import 'dart:async';

import 'package:flutter/material.dart';

import 'l10n.dart';
import '../services/locale_store.dart';

class LocaleController extends ChangeNotifier {
  LocaleController(this._store, {required List<Locale> deviceLocales})
    : _deviceLocales = List<Locale>.from(deviceLocales),
      _preference = _store.preference;

  LocaleStore _store;
  List<Locale> _deviceLocales;
  LanguagePref _preference;
  bool _userOverride = false;

  LanguagePref get preference => _preference;

  List<String> get deviceLanguageCodes => [
    for (final locale in _deviceLocales) locale.languageCode,
  ];

  String get code => LocaleStore.resolve(_preference, deviceLanguageCodes);

  Locale get locale => Locale(code);

  L10n get l10n => L10n(code);

  void attachStore(LocaleStore store) {
    _store = store;
    if (_userOverride) {
      unawaited(_store.setPreference(_preference));
      return;
    }
    final next = store.preference;
    if (next == _preference) return;
    _preference = next;
    notifyListeners();
  }

  void updateDeviceLocales(List<Locale> locales) {
    if (_listEquals(locales, _deviceLocales)) return;
    _deviceLocales = List<Locale>.from(locales);
    if (_preference == LanguagePref.system) notifyListeners();
  }

  Future<void> setPreference(LanguagePref pref) async {
    if (pref == _preference) return;
    _preference = pref;
    _userOverride = true;
    await _store.setPreference(pref);
    notifyListeners();
  }

  static bool _listEquals(List<Locale> a, List<Locale> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class LocaleScope extends InheritedNotifier<LocaleController> {
  const LocaleScope({
    super.key,
    required LocaleController controller,
    required super.child,
  }) : super(notifier: controller);

  LocaleController get controller => notifier!;

  static LocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LocaleScope>();
    assert(scope != null, 'LocaleScope not found');
    return scope!.controller;
  }

  static LocaleController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocaleScope>()?.controller;
  }
}
