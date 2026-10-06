import 'dart:async';
import 'dart:math';

import 'analytics_service.dart';

typedef PlayTelemetrySink =
    void Function(String name, Map<String, Object> parameters);

enum PlayStartSource {
  newGame('new'),
  resume('resume'),
  retry('retry');

  const PlayStartSource(this.value);
  final String value;
}

enum PlayAdResult {
  offer('ad_offer'),
  complete('ad_complete'),
  skip('ad_skip');

  const PlayAdResult(this.event);
  final String event;
}

/// Воронка одной попытки: старт → буст/реклама → победа, поражение или уход.
class PlayTelemetry {
  PlayTelemetry({PlayTelemetrySink? log, String Function()? newSessionId})
    : _log =
          log ??
          ((name, parameters) {
            unawaited(AnalyticsService.log(name, parameters));
          }),
      _newSessionId = newSessionId ?? _defaultSessionId;

  static const eventStart = 'level_start';
  static const eventBooster = 'booster_use';
  static const eventAdOffer = 'ad_offer';
  static const eventAdComplete = 'ad_complete';
  static const eventAdSkip = 'ad_skip';
  static const eventEnd = 'level_end';
  static const eventLeave = 'level_leave';

  static const placementLoseContinue = 'lose_continue';

  static String boostPlacement(String boost) => 'boost_$boost';

  final PlayTelemetrySink _log;
  final String Function() _newSessionId;

  String? _sessionId;
  int _levelId = 0;
  String _mode = 'campaign';
  String _layout = '';
  String _source = PlayStartSource.newGame.value;
  bool _terminal = false;

  bool get hasAttempt => _sessionId != null;
  bool get isTerminal => _terminal;

  void start({
    required int levelId,
    required bool isDaily,
    required String layout,
    required PlayStartSource source,
    required bool firstTry,
    required int hints,
    required int shuffles,
    required int magnets,
    required int undos,
    required int tilesLeft,
  }) {
    _sessionId = _newSessionId();
    _levelId = isDaily ? 0 : levelId;
    _mode = isDaily ? 'daily' : 'campaign';
    _layout = layout;
    _source = source.value;
    _terminal = false;
    _emit(eventStart, {
      'first_try': firstTry ? 1 : 0,
      'hints': hints,
      'shuffles': shuffles,
      'magnets': magnets,
      'undos': undos,
      'tiles_left': tilesLeft,
    });
  }

  void booster({
    required String boost,
    required int tilesLeft,
    required int chargesLeft,
    bool? useful,
  }) {
    if (!hasAttempt) return;
    _emit(eventBooster, {
      'boost': boost,
      'tiles_left': tilesLeft,
      'charges_left': chargesLeft,
      if (useful != null) 'useful': useful ? 1 : 0,
    });
  }

  void ad({
    required String placement,
    required PlayAdResult result,
    required bool simulated,
  }) {
    if (!hasAttempt) return;
    _emit(result.event, {
      'placement': placement,
      'simulated': simulated ? 1 : 0,
    });
  }

  void end({
    required bool success,
    required int tilesLeft,
    required int score,
    int? stars,
    bool? canContinue,
  }) {
    if (!hasAttempt || _terminal) return;
    _terminal = true;
    _emit(eventEnd, {
      'success': success ? 1 : 0,
      'tiles_left': tilesLeft,
      'score': score,
      if (stars != null) 'stars': stars,
      if (canContinue != null) 'can_continue': canContinue ? 1 : 0,
    });
  }

  void leave({
    required String reason,
    required int tilesLeft,
    required int score,
  }) {
    if (!hasAttempt || _terminal) return;
    _terminal = true;
    _emit(eventLeave, {
      'reason': reason,
      'tiles_left': tilesLeft,
      'score': score,
    });
  }

  /// Поражение уже залогировано, попытка продолжается после revive.
  void continueAttempt() {
    if (!hasAttempt) return;
    _terminal = false;
  }

  void _emit(String name, Map<String, Object> extra) {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    _log(name, {
      'session_id': sessionId,
      'level_id': _levelId,
      'mode': _mode,
      'layout': _layout,
      'source': _source,
      ...extra,
    });
  }

  static String _defaultSessionId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final n = Random().nextInt(0x7fffffff);
    return '$now-$n';
  }
}
