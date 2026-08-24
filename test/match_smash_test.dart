import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/widgets/match_smash.dart';
import 'package:mahjong/widgets/tile_widget.dart';

void _expectUnit(double value, {required String name}) {
  expect(value, inInclusiveRange(0.0, 1.0), reason: name);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('smash chance is uncommon but not rare', () {
    final rng = Random(1);
    var hits = 0;
    const n = 4000;
    for (var i = 0; i < n; i++) {
      if (MatchSmash.roll(rng)) hits++;
    }
    expect(hits / n, inInclusiveRange(0.22, 0.34));
  });

  test('layout is deterministic for a seed', () {
    final a = MatchSmashLayout.generate(seed: 9);
    final b = MatchSmashLayout.generate(seed: 9);
    final c = MatchSmashLayout.generate(seed: 10);

    expect(a.shards.length, MatchSmashLayout.defaultCount);
    expect(a.shards.first.angle, b.shards.first.angle);
    expect(a.shards.last.size, b.shards.last.size);
    expect(
      a.shards.map((s) => s.angle).toList(),
      isNot(c.shards.map((s) => s.angle).toList()),
    );
  });

  test('normalized shard fields stay in 0..1', () {
    final layout = MatchSmashLayout.generate();
    expect(layout.shards, hasLength(MatchSmashLayout.defaultCount));
    for (final shard in layout.shards) {
      _expectUnit(shard.angle, name: 'angle');
      _expectUnit(shard.speed, name: 'speed');
      _expectUnit(shard.spin, name: 'spin');
      _expectUnit(shard.size, name: 'size');
      _expectUnit(shard.delay, name: 'delay');
      _expectUnit(shard.lift, name: 'lift');
      _expectUnit(shard.gravity, name: 'gravity');
      _expectUnit(shard.alpha, name: 'alpha');
    }
  });

  test('tiles pull apart then slam into the midpoint', () {
    const left = Rect.fromLTWH(80, 400, 46, 54);
    const right = Rect.fromLTWH(140, 400, 46, 54);
    final startGap =
        (matchSmashCenter(start: left, other: right, t: 0) -
                matchSmashCenter(start: right, other: left, t: 0))
            .distance;
    final pulledGap =
        (matchSmashCenter(start: left, other: right, t: 0.3) -
                matchSmashCenter(start: right, other: left, t: 0.3))
            .distance;
    final impactGap =
        (matchSmashCenter(start: left, other: right, t: MatchSmash.impactAt) -
                matchSmashCenter(
                  start: right,
                  other: left,
                  t: MatchSmash.impactAt,
                ))
            .distance;

    expect(pulledGap, greaterThan(startGap + MatchSmash.pullPx));
    expect(impactGap, lessThan(1));
  });

  testWidgets('overlay hides tiles after impact and completes', (tester) async {
    var impacts = 0;
    var done = 0;
    final left = Tile(id: 1, symbol: 'soft-01', layer: 0, x: 0, y: 0);
    final right = Tile(id: 2, symbol: 'soft-01', layer: 0, x: 2, y: 0);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 720,
          child: Stack(
            children: [
              MatchSmashOverlay(
                left: left,
                right: right,
                leftRect: const Rect.fromLTWH(100, 500, 46, 54),
                rightRect: const Rect.fromLTWH(160, 500, 46, 54),
                onImpact: () => impacts++,
                onComplete: () => done++,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(TileWidget), findsNWidgets(2));

    await tester.pump(
      Duration(
        milliseconds: (MatchSmash.duration.inMilliseconds * MatchSmash.impactAt)
            .round(),
      ),
    );
    await tester.pump();
    expect(impacts, 1);
    expect(find.byType(TileWidget), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);

    await tester.pump(MatchSmash.duration);
    expect(done, 1);
  });
}
