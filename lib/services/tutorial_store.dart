import 'package:shared_preferences/shared_preferences.dart';

import '../models/tutorial_step.dart';

/// Сохранённый прогресс обучения на первых уровнях.
class TutorialStore {
  TutorialStore._(this._prefs);

  final SharedPreferences _prefs;

  static const _kSkipped = 'tutorial.skipped';
  static const _kForceReplay = 'tutorial.forceReplay';

  static String _keyFor(TutorialStep step) => 'tutorial.${step.name}';

  static Future<TutorialStore> open() async {
    final prefs = await SharedPreferences.getInstance();
    return TutorialStore._(prefs);
  }

  bool get skipped => _prefs.getBool(_kSkipped) ?? false;

  bool get forceReplay => _prefs.getBool(_kForceReplay) ?? false;

  bool isDone(TutorialStep step) => _prefs.getBool(_keyFor(step)) ?? false;

  bool get anyStepDone => TutorialStep.values.any(isDone);

  TutorialSnapshot get snapshot => TutorialSnapshot(
    collectDone: isDone(TutorialStep.collect),
    matchDone: isDone(TutorialStep.match),
    layersDone: isDone(TutorialStep.layers),
    boostsDone: isDone(TutorialStep.boosts),
    skipped: skipped,
    forceReplay: forceReplay,
  );

  Future<void> complete(TutorialStep step) async {
    await _prefs.setBool(_keyFor(step), true);
    if (TutorialStep.values.every(isDone)) {
      await _prefs.setBool(_kForceReplay, false);
    }
  }

  Future<void> skipAll() async {
    for (final step in TutorialStep.values) {
      await _prefs.setBool(_keyFor(step), true);
    }
    await _prefs.setBool(_kSkipped, true);
    await _prefs.setBool(_kForceReplay, false);
  }

  Future<void> reset() async {
    for (final step in TutorialStep.values) {
      await _prefs.remove(_keyFor(step));
    }
    await _prefs.remove(_kSkipped);
    await _prefs.setBool(_kForceReplay, true);
  }
}
