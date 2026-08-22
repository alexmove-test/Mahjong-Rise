import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/widgets/win_burst.dart';

void _expectUnit(double value, {required String name}) {
  expect(value, inInclusiveRange(0.0, 1.0), reason: name);
}

void main() {
  test('generate is deterministic for a seed', () {
    final a = WinBurstLayout.generate(seed: 7);
    final b = WinBurstLayout.generate(seed: 7);
    final c = WinBurstLayout.generate(seed: 8);

    expect(a.pieces.length, WinBurstLayout.defaultCount);
    expect(a.shards.length, WinBurstLayout.defaultShardCount);
    expect(a.rays.length, WinBurstLayout.defaultRayCount);

    expect(a.pieces.length, b.pieces.length);
    expect(a.pieces.first.x, b.pieces.first.x);
    expect(a.pieces.first.delay, b.pieces.first.delay);
    expect(a.pieces.last.color, b.pieces.last.color);
    expect(a.shards.first.angle, b.shards.first.angle);
    expect(a.rays.first.length, b.rays.first.length);

    expect(
      a.pieces.map((p) => p.x).toList(),
      isNot(c.pieces.map((p) => p.x).toList()),
    );
  });

  test('normalized fields stay in 0..1', () {
    final layout = WinBurstLayout.generate();

    expect(layout.pieces, hasLength(WinBurstLayout.defaultCount));
    for (final piece in layout.pieces) {
      _expectUnit(piece.x, name: 'x');
      _expectUnit(piece.delay, name: 'delay');
      _expectUnit(piece.speed, name: 'speed');
      _expectUnit(piece.spin, name: 'spin');
      _expectUnit(piece.wobble, name: 'wobble');
      _expectUnit(piece.size, name: 'size');
      _expectUnit(piece.alpha, name: 'alpha');
    }

    for (final shard in layout.shards) {
      _expectUnit(shard.angle, name: 'shard.angle');
      _expectUnit(shard.speed, name: 'shard.speed');
      _expectUnit(shard.spin, name: 'shard.spin');
      _expectUnit(shard.size, name: 'shard.size');
      _expectUnit(shard.alpha, name: 'shard.alpha');
    }

    for (final ray in layout.rays) {
      _expectUnit(ray.angle, name: 'ray.angle');
      _expectUnit(ray.length, name: 'ray.length');
      _expectUnit(ray.width, name: 'ray.width');
    }
  });

  test('custom count is honored', () {
    final layout = WinBurstLayout.generate(
      seed: 1,
      count: 12,
      shardCount: 4,
      rayCount: 5,
    );
    expect(layout.pieces, hasLength(12));
    expect(layout.shards, hasLength(4));
    expect(layout.rays, hasLength(5));
  });
}
