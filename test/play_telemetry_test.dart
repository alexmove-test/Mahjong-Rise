import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/services/play_telemetry.dart';

void startAttempt(
  PlayTelemetry play, {
  int levelId = 7,
  bool isDaily = false,
  String layout = 'turtle',
  PlayStartSource source = PlayStartSource.newGame,
  bool firstTry = true,
}) {
  play.start(
    levelId: levelId,
    isDaily: isDaily,
    layout: layout,
    source: source,
    firstTry: firstTry,
    hints: 2,
    shuffles: 1,
    magnets: 2,
    undos: 1,
    tilesLeft: 36,
  );
}

void main() {
  late List<({String name, Map<String, Object> params})> events;
  late int sessionSeq;
  late PlayTelemetry play;

  setUp(() {
    events = [];
    sessionSeq = 0;
    play = PlayTelemetry(
      log: (name, params) => events.add((name: name, params: Map.of(params))),
      newSessionId: () => 's${++sessionSeq}',
    );
  });

  test('start then booster then end does not send leave', () {
    startAttempt(play);
    play.booster(boost: 'hint', tilesLeft: 24, chargesLeft: 1);
    play.end(success: true, tilesLeft: 0, score: 900, stars: 2);
    play.leave(reason: 'back', tilesLeft: 0, score: 900);

    expect(events.map((e) => e.name), [
      PlayTelemetry.eventStart,
      PlayTelemetry.eventBooster,
      PlayTelemetry.eventEnd,
    ]);
    expect(events[1].params['boost'], 'hint');
    expect(events[2].params['success'], 1);
  });

  test('repeat end and leave are ignored after a terminal event', () {
    startAttempt(play);
    play.end(success: false, tilesLeft: 12, score: 200, canContinue: true);
    play.end(success: true, tilesLeft: 0, score: 800, stars: 1);
    play.leave(reason: 'exit', tilesLeft: 12, score: 200);

    expect(events.map((e) => e.name), [
      PlayTelemetry.eventStart,
      PlayTelemetry.eventEnd,
    ]);
    expect(events.last.params['success'], 0);
    expect(events.last.params['can_continue'], 1);
  });

  test('daily attempt uses level_id 0', () {
    startAttempt(play, levelId: 4, isDaily: true, layout: 'daily');

    expect(events.single.name, PlayTelemetry.eventStart);
    expect(events.single.params['level_id'], 0);
    expect(events.single.params['mode'], 'daily');
    expect(events.single.params['layout'], 'daily');
    expect(events.single.params['session_id'], 's1');
  });

  test('revive can log a later win on the same session', () {
    startAttempt(play);
    play.end(success: false, tilesLeft: 10, score: 100);
    play.continueAttempt();
    play.end(success: true, tilesLeft: 0, score: 700, stars: 1);

    expect(events.map((e) => e.name), [
      PlayTelemetry.eventStart,
      PlayTelemetry.eventEnd,
      PlayTelemetry.eventEnd,
    ]);
    expect(events[1].params['session_id'], 's1');
    expect(events[2].params['session_id'], 's1');
    expect(events[1].params['success'], 0);
    expect(events[2].params['success'], 1);
  });
}
