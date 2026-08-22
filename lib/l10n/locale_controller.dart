import 'dart:async';

import 'package:flutter/material.dart';

import 'l10n.dart';
import '../services/locale_store.dart';

class LocaleController extends ChangeNotifier {
  LocaleController(this._store, {required Locale deviceLocale})
    : _deviceLocale = deviceLocale,
      _preference = _store.preference;

  LocaleStore _store;
  Locale _deviceLocale;
  LanguagePref _preference;
  bool _userOverride = false;

  LanguagePref get preference => _preference;

  String get code =>
      LocaleStore.resolve(_preference, _deviceLocale.languageCode);

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

  void updateDeviceLocale(Locale locale) {
    if (_deviceLocale == locale) return;
    _deviceLocale = locale;
    if (_preference == LanguagePref.system) notifyListeners();
  }

  Future<void> setPreference(LanguagePref pref) async {
    if (pref == _preference) return;
    _preference = pref;
    _userOverride = true;
    await _store.setPreference(pref);
    notifyListeners();
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
