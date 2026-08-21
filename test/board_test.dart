import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/board.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/utils/tile_icons.dart';

void main() {
  group('pick', () {
    test('moves free tile to tray', () {
      final tile = Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0);
      final board = Board(tiles: [tile]);

      expect(board.pick(tile), MatchResult.collected);
      expect(board.tray, [tile]);
      expect(tile.inTray, isTrue);
      expect(tile.isOnBoard, isFalse);
    });

    test('blocked when covered by a higher tile', () {
      final board = Board(
        tiles: [
          Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
          Tile(id: 1, symbol: 'B', layer: 1, x: 0, y: 0),
        ],
      );
      final bottom = board.tiles[0];
      final top = board.tiles[1];

      expect(board.isFree(bottom), isFalse);
      expect(board.isFree(top), isTrue);
      expect(board.pick(bottom), MatchResult.blocked);
      expect(board.tray, isEmpty);
    });

    test('same-layer neighbors do not block on a flat layout', () {
      final board = Board(
        tiles: [
          Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
          Tile(id: 1, symbol: 'B', layer: 0, x: 2, y: 0),
          Tile(id: 2, symbol: 'C', layer: 0, x: 4, y: 0),
        ],
      );
      final mid = board.tiles[1];

      expect(board.isFree(mid), isTrue);
      expect(board.pick(mid), MatchResult.collected);
      expect(board.tray, [mid]);
    });

    test('trayFull when capacity reached', () {
      final board = Board(
        tiles: [
          for (var i = 0; i < 5; i++)
            Tile(id: i, symbol: 'S$i', layer: 0, x: i * 4, y: 0),
        ],
      );

      for (var i = 0; i < 4; i++) {
        expect(board.pick(board.tiles[i]), MatchResult.collected);
      }

      expect(board.trayLiveCount, Board.trayCapacity);
      expect(board.pick(board.tiles[4]), MatchResult.trayFull);
    });
  });

  group('resolveTray', () {
    test('matched when tray holds a pair and tiles remain on board', () {
      final a = Tile(id: 0, symbol: 'pair', layer: 0, x: 0, y: 0);
      final b = Tile(id: 1, symbol: 'pair', layer: 0, x: 4, y: 0);
      final extra = Tile(id: 2, symbol: 'solo', layer: 0, x: 8, y: 0);
      final board = Board(tiles: [a, b, extra]);
      a.inTray = true;
      b.inTray = true;
      board.tray.addAll([a, b]);

      expect(board.resolveTray(), MatchResult.matched);
      expect(a.removing, isTrue);
      expect(b.removing, isTrue);
      expect(board.lastMatched, [a, b]);
      expect(board.isWon, isFalse);
      expect(board.isLost, isFalse);
    });

    test('clears multiple pairs in one resolve when board not empty', () {
      final tiles = [
        Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
        Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0),
        Tile(id: 2, symbol: 'B', layer: 0, x: 8, y: 0),
        Tile(id: 3, symbol: 'B', layer: 0, x: 12, y: 0),
        Tile(id: 4, symbol: 'C', layer: 0, x: 16, y: 0),
      ];
      final board = Board(tiles: tiles);
      for (final tile in tiles.take(4)) {
        tile.inTray = true;
        board.tray.add(tile);
      }

      expect(board.resolveTray(), MatchResult.matched);
      expect(tiles.take(4).every((t) => t.removing), isTrue);
      expect(board.lastMatched.length, 4);
      expect(tiles[4].isOnBoard, isTrue);
    });

    test('win when last pair enters tray', () {
      final a = Tile(id: 0, symbol: 'Z', layer: 0, x: 0, y: 0);
      final b = Tile(id: 1, symbol: 'Z', layer: 0, x: 4, y: 0);
      final board = Board(tiles: [a, b]);

      expect(board.pick(a), MatchResult.collected);
      expect(board.resolveTray(), MatchResult.collected);

      expect(board.pick(b), MatchResult.collected);
      expect(board.resolveTray(), MatchResult.win);

      expect(a.removing, isTrue);
      expect(b.removing, isTrue);
      expect(board.isWon, isTrue);
    });

    test('lose when tray is full without a pair', () {
      final board = Board(
        tiles: [
          Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
          Tile(id: 1, symbol: 'B', layer: 0, x: 4, y: 0),
          Tile(id: 2, symbol: 'C', layer: 0, x: 8, y: 0),
          Tile(id: 3, symbol: 'D', layer: 0, x: 12, y: 0),
        ],
      );
      for (final tile in board.tiles) {
        tile.inTray = true;
        board.tray.add(tile);
      }

      expect(board.resolveTray(), MatchResult.lose);
      expect(board.isLost, isTrue);
      expect(board.trayHasPair(), isFalse);
    });

    test('collected when tray has space and no pair', () {
      final board = Board(
        tiles: [
          Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
          Tile(id: 1, symbol: 'B', layer: 0, x: 4, y: 0),
        ],
      );
      board.tiles[0].inTray = true;
      board.tray.add(board.tiles[0]);

      expect(board.resolveTray(), MatchResult.collected);
      expect(board.isLost, isFalse);
    });
  });

  group('undo tray', () {
    test('returnFromTray restores collect undo', () {
      final tile = Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0);
      final board = Board(tiles: [tile]);

      board.pick(tile);
      expect(board.returnFromTray(tile), isTrue);

      expect(board.tray, isEmpty);
      expect(tile.inTray, isFalse);
      expect(tile.removed, isFalse);
      expect(tile.isOnBoard, isTrue);
    });

    test('restoreMatchedToTray restores match undo', () {
      final a = Tile(id: 0, symbol: 'M', layer: 0, x: 0, y: 0);
      final b = Tile(id: 1, symbol: 'M', layer: 0, x: 4, y: 0);
      final board = Board(tiles: [a, b]);

      a.inTray = true;
      b.inTray = true;
      board.tray.addAll([a, b]);
      board.resolveTray();
      board.finishRemoval(a);
      board.finishRemoval(b);

      board.restoreMatchedToTray(a, b);

      expect(a.removed, isFalse);
      expect(b.removed, isFalse);
      expect(a.inTray, isTrue);
      expect(b.inTray, isTrue);
      expect(board.tray, containsAll([a, b]));
      expect(board.remaining, 2);
    });
  });

  group('level layouts smoke', () {
    for (final level in Levels.all) {
      test('level ${level.id} (${level.layout}) has even tile count', () {
        final board = Board.fromLayout(
          level.layout,
          random: Random(level.id),
          style: level.style,
          pairSize: level.pairSize,
          uniqueCap: level.uniqueCap,
          levelId: level.id,
          guestTypes: level.guestTileTypes,
        );

        expect(
          board.tiles.length.isEven,
          isTrue,
          reason:
              'level ${level.id} "${level.title}" layout ${level.layout}: '
              '${board.tiles.length} tiles',
        );
      });
    }
  });

  group('vita layouts', () {
    const expected = {
      'petal': 16,
      'bloom': 24,
      'meadow': 28,
      'wave': 30,
      'garden': 40,
      'fan': 44,
      'lotus': 64,
      'koi': 62,
      'vine': 72,
      'festival': 72,
      'pavilion': 88,
      'dragon': 122,
    };

    for (final entry in expected.entries) {
      test('${entry.key} has ${entry.value} tiles with stacked layers', () {
        final board = Board.fromLayout(entry.key, random: Random(1));
        expect(board.tiles.length, entry.value);
        final maxLayer = board.tiles.map((t) => t.layer).reduce(max);
        expect(maxLayer, greaterThanOrEqualTo(2));
      });
    }
  });

  test('styled levels keep one shape and one number on the board', () {
    final level = Levels.byId(1);
    final board = Board.fromLayout(
      level.layout,
      random: Random(level.id),
      style: level.style,
      pairSize: level.pairSize,
      uniqueCap: level.uniqueCap,
      levelId: level.id,
      guestTypes: level.guestTileTypes,
    );

    final symbols = board.tiles.map((t) => t.symbol).toSet();
    final shapes = symbols.where(TileIcons.shapeIds.contains).toList();
    final numbers = symbols.where(TileIcons.numberIds.contains).toList();
    final soft = symbols.where((id) => id.startsWith('soft-')).toSet();

    expect(soft, isNotEmpty);
    expect(shapes, hasLength(1));
    expect(numbers, hasLength(1));
    expect(symbols.length, soft.length + 2);
  });

  test('mix levels use mixed style and full icon pool', () {
    final level = Levels.byId(21);
    expect(level.style, 'mixed');
    expect(level.guestTileTypes, 0);
    expect(TileIcons.idsForStyle('mixed'), equals(TileIcons.softIds));
  });

  test('fruit icons map to titles/fruit assets', () {
    expect(TileIcons.idsForStyle('fruit').length, greaterThan(20));
    expect(TileIcons.assetFor('soft-01'), 'assets/titles/soft/01.png');
    expect(TileIcons.assetFor('soft-32'), 'assets/titles/soft/32.png');
    expect(TileIcons.assetFor('fruit-01'), 'assets/titles/fruit/01.svg');
    expect(TileIcons.assetFor('fruit-12'), 'assets/titles/fruit/12.svg');
    expect(TileIcons.assetFor('shape-01'), 'assets/titles/shape/01.svg');
    expect(TileIcons.assetFor('number-05'), 'assets/titles/number/05.svg');
    expect(
      TileIcons.assetFor('set1-bamboo-03'),
      'assets/titles/1/Bamboo 3.png',
    );
    expect(TileIcons.assetFor('tile-02-05'), 'assets/titles/tile/02/05.svg');
  });

  group('hints magnets and deals', () {
    test('findHint highlights a free-free pair instead of a random tile', () {
      final a = Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0);
      final b = Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0);
      final c = Tile(id: 2, symbol: 'B', layer: 0, x: 8, y: 0);
      final board = Board(tiles: [a, b, c]);
      final hint = board.findHint();
      expect(hint, isNotNull);
      expect({hint!.boardTile.id, hint.pairTile!.id}, {0, 1});
    });

    test('findHint returns null when no pair exists', () {
      final board = Board(
        tiles: [
          Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
          Tile(id: 1, symbol: 'B', layer: 0, x: 4, y: 0),
        ],
      );
      expect(board.findHint(), isNull);
      expect(board.findMagnetTarget(), isNull);
    });

    test('magnet prefers a tray match', () {
      final tray = Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0, inTray: true);
      final match = Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0);
      final other = Tile(id: 2, symbol: 'B', layer: 0, x: 8, y: 0);
      final board = Board(tiles: [tray, match, other]);
      board.tray.add(tray);
      expect(board.findMagnetTarget()?.id, 1);
    });

    test('fromLayout starts with a useful match', () {
      for (final level in Levels.all) {
        final board = Board.fromLayout(
          level.layout,
          random: Random(level.id * 17),
          style: level.style,
          pairSize: level.pairSize,
          uniqueCap: level.uniqueCap,
          levelId: level.id,
          guestTypes: level.guestTileTypes,
        );
        expect(
          board.hasUsefulMove(),
          isTrue,
          reason: 'level ${level.id} ${level.layout}',
        );
        expect(
          board.findHint(),
          isNotNull,
          reason: 'level ${level.id} should have a hintable pair',
        );
      }
    });

    test('shuffleRemaining only succeeds with a real pair', () {
      final board = Board(
        tiles: [
          Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
          Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0),
          Tile(id: 2, symbol: 'B', layer: 0, x: 8, y: 0),
          Tile(id: 3, symbol: 'B', layer: 0, x: 12, y: 0),
        ],
      );
      expect(board.shuffleRemaining(random: Random(4)), isTrue);
      expect(board.findHint(), isNotNull);
    });
  });
}
