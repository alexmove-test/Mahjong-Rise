import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/board.dart';
import 'package:mahjong/models/levels.dart';
import 'package:mahjong/models/tile.dart';
import 'package:mahjong/utils/layouts.dart';
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
      expect(board.pick(bottom, force: true), MatchResult.collected);
      expect(board.tray, [bottom]);
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

    test('reviveFromTray undoes a full tray and clears lose', () {
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

      expect(board.reviveFromTray(board.tiles[3]), isTrue);
      expect(board.isLost, isFalse);
      expect(board.tray, hasLength(3));
      expect(board.tiles[3].isOnBoard, isTrue);
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

  group('findHint', () {
    test('returns both free tiles of a matching pair', () {
      final board = Board(
        tiles: [
          Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
          Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0),
          Tile(id: 2, symbol: 'B', layer: 0, x: 8, y: 0),
        ],
      );

      final hint = board.findHint();
      expect(hint, isNotNull);
      expect({hint!.boardTile.id, hint.match.id}, {0, 1});
      expect(hint.boardTile.symbol, 'A');
      expect(hint.match.symbol, 'A');
    });

    test('returns a free tile that matches the tray', () {
      final tray = Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0, inTray: true);
      final board = Board(
        tiles: [
          tray,
          Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0),
          Tile(id: 2, symbol: 'B', layer: 0, x: 8, y: 0),
        ],
      );
      board.tray.add(tray);

      final hint = board.findHint();
      expect(hint, isNotNull);
      expect(hint!.boardTile.id, 1);
      expect(hint.match.id, 0);
    });

    test('is null when free tiles do not form a pair', () {
      final board = Board(
        tiles: [
          Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
          Tile(id: 1, symbol: 'B', layer: 0, x: 4, y: 0),
        ],
      );
      expect(board.findHint(), isNull);
    });
  });

  group('findMagnetPair', () {
    test('pulls both free tiles of a matching pair', () {
      final board = Board(
        tiles: [
          Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
          Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0),
          Tile(id: 2, symbol: 'B', layer: 0, x: 8, y: 0),
        ],
      );

      final pair = board.findMagnetPair();
      expect(pair, isNotNull);
      expect({pair!.boardTile.id, pair.match.id}, {0, 1});
    });

    test('pulls a free tile that matches the tray', () {
      final tray = Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0, inTray: true);
      final board = Board(
        tiles: [
          tray,
          Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0),
          Tile(id: 2, symbol: 'B', layer: 0, x: 8, y: 0),
        ],
      );
      board.tray.add(tray);

      final pair = board.findMagnetPair();
      expect(pair, isNotNull);
      expect(pair!.boardTile.id, 1);
      expect(pair.match.id, 0);
    });

    test('pulls a covered tile that matches the tray', () {
      final tray = Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0, inTray: true);
      final buried = Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0);
      final cover = Tile(id: 2, symbol: 'B', layer: 1, x: 4, y: 0);
      final board = Board(tiles: [tray, buried, cover]);
      board.tray.add(tray);

      expect(board.isFree(buried), isFalse);
      final pair = board.findMagnetPair();
      expect(pair, isNotNull);
      expect(pair!.boardTile.id, 1);
      expect(pair.match.id, 0);
    });

    test('prefers a tray match over a free pair of another symbol', () {
      final tray = Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0, inTray: true);
      final buried = Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0);
      final cover = Tile(id: 2, symbol: 'B', layer: 1, x: 4, y: 0);
      final freeC1 = Tile(id: 3, symbol: 'C', layer: 0, x: 8, y: 0);
      final freeC2 = Tile(id: 4, symbol: 'C', layer: 0, x: 12, y: 0);
      final board = Board(tiles: [tray, buried, cover, freeC1, freeC2]);
      board.tray.add(tray);

      final pair = board.findMagnetPair();
      expect(pair, isNotNull);
      expect(pair!.boardTile.id, 1);
      expect(pair.match.id, 0);
    });

    test('does not fill the last tray slot with a board pair', () {
      final board = Board(
        tiles: [
          Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0, inTray: true),
          Tile(id: 1, symbol: 'B', layer: 0, x: 4, y: 0, inTray: true),
          Tile(id: 2, symbol: 'C', layer: 0, x: 8, y: 0, inTray: true),
          Tile(id: 3, symbol: 'D', layer: 0, x: 12, y: 0),
          Tile(id: 4, symbol: 'D', layer: 0, x: 16, y: 0),
        ],
      );
      board.tray.addAll(board.tiles.take(3));

      expect(board.trayLiveCount, 3);
      expect(board.findMagnetPair(), isNull);
    });
  });

  group('useful moves and shuffle', () {
    test('hasUsefulMove when two free tiles are a pair', () {
      final board = Board(
        tiles: [
          Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
          Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0),
        ],
      );
      expect(board.hasUsefulMove(), isTrue);
    });

    test('hasUsefulMove when a free tile matches the tray', () {
      final tray = Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0, inTray: true);
      final board = Board(
        tiles: [
          tray,
          Tile(id: 1, symbol: 'A', layer: 0, x: 4, y: 0),
          Tile(id: 2, symbol: 'B', layer: 0, x: 8, y: 0),
        ],
      );
      board.tray.add(tray);
      expect(board.hasUsefulMove(), isTrue);
    });

    test('hasUsefulMove is false when free tiles do not form a pair', () {
      final board = Board(
        tiles: [
          Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
          Tile(id: 1, symbol: 'B', layer: 0, x: 4, y: 0),
        ],
      );
      expect(board.hasUsefulMove(), isFalse);
    });

    test('hasUsefulMove is false when nothing on the board is free', () {
      final board = Board(
        tiles: [
          Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0, inTray: true),
          Tile(id: 1, symbol: 'B', layer: 0, x: 4, y: 0, inTray: true),
        ],
      );
      board.tray.addAll(board.tiles);
      expect(board.freeTiles(), isEmpty);
      expect(board.hasUsefulMove(), isFalse);
    });

    test('shuffleRemaining does not touch a board with no free tiles', () {
      final board = Board(
        tiles: [
          Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0, inTray: true),
          Tile(id: 1, symbol: 'B', layer: 0, x: 4, y: 0, inTray: true),
        ],
      );
      board.tray.addAll(board.tiles);
      expect(board.shuffleRemaining(random: Random(1)), isFalse);
      expect(board.tiles.map((t) => t.symbol), ['A', 'B']);
    });

    test('retry shuffle finds a top pair when one shuffle may not', () {
      Board stacked() => Board(
        tiles: [
          Tile(id: 0, symbol: 'A', layer: 0, x: 0, y: 0),
          Tile(id: 1, symbol: 'B', layer: 0, x: 4, y: 0),
          Tile(id: 2, symbol: 'A', layer: 1, x: 0, y: 0),
          Tile(id: 3, symbol: 'B', layer: 1, x: 4, y: 0),
        ],
      );

      bool topPair(Board board) {
        final free = board.freeTiles();
        for (var i = 0; i < free.length; i++) {
          for (var j = i + 1; j < free.length; j++) {
            if (free[i].symbol == free[j].symbol) return true;
          }
        }
        return false;
      }

      var foundMismatch = false;
      for (var seed = 0; seed < 80; seed++) {
        final once = stacked();
        once.shuffleRemaining(random: Random(seed), attempts: 0);
        if (topPair(once)) continue;
        foundMismatch = true;
        final retried = stacked();
        expect(retried.shuffleRemaining(random: Random(seed)), isTrue);
        expect(topPair(retried), isTrue);
        break;
      }
      expect(
        foundMismatch,
        isTrue,
        reason: 'need a seed where one shuffle misses',
      );
    });
  });

  group('level layouts smoke', () {
    for (final level in Levels.all.take(Levels.storyLength)) {
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

    test('plots cycle house pond road internet with harder loops', () {
      expect(Levels.maxLevelId, 10000);
      expect(Levels.cycleCount, greaterThan(10));
      final first = Levels.byId(1);
      final pond = Levels.byId(25);
      final road = Levels.byId(49);
      final net = Levels.byId(73);
      final house2 = Levels.byId(97);
      expect(first.title, 'House');
      expect(pond.title, 'Pond');
      expect(road.title, 'Road');
      expect(net.title, 'Internet');
      expect(house2.title, 'House');
      expect(first.storyId, house2.storyId);
      expect(house2.layout, isNot(first.layout));
      expect(house2.shuffles, lessThan(first.shuffles));
      expect(house2.uniqueCap, greaterThan(first.uniqueCap!));
    });

    test('first story level has no guest tile types', () {
      expect(Levels.byId(1).guestTileTypes, 0);
      expect(Levels.byId(25).guestTileTypes, 0);
      expect(Levels.byId(2).guestTileTypes, 2);
    });

    test('campaign is split into named plots of 24', () {
      expect(Levels.cycleOf(1), 0);
      expect(Levels.cycleOf(24), 0);
      expect(Levels.cycleOf(25), 1);
      expect(Levels.localId(25), 1);
      expect(Levels.cycleStartId(1), 25);
      expect(Levels.cycleEndId(0), 24);
      expect(Levels.cycleLevels(0), hasLength(24));
      expect(Levels.cycleLevels(0).first.title, 'House');
      expect(Levels.plotLabel(0), 'House');
      expect(Levels.plotLabel(1), 'Pond');
    });

    test('daily table picks a story layout for the local calendar day', () {
      final first = Levels.dailyFor(DateTime(2024, 1, 1));
      final next = Levels.dailyFor(DateTime(2024, 1, 2));
      expect(first.title, 'Today');
      expect(first.id, 1);
      expect(next.id, 2);
      expect(Levels.dailyFor(DateTime(2024, 1, 25)).id, first.id);
    });
  });

  group('vita layouts', () {
    const expected = {
      'petal': 16,
      'buds': 20,
      'bloom': 24,
      'glade': 28,
      'meadow': 32,
      'grove': 36,
      'wave': 36,
      'stream': 40,
      'garden': 44,
      'gazebo': 48,
      'fan': 48,
      'peacock': 52,
      'lotus': 56,
      'pond': 60,
      'koi': 64,
      'lake': 68,
      'vine': 72,
      'ivy': 76,
      'festival': 80,
      'lanterns': 84,
      'pavilion': 96,
      'temple': 104,
      'dragon': 112,
      'sky': 128,
    };

    for (final entry in expected.entries) {
      test('${entry.key} has ${entry.value} tiles with stacked layers', () {
        final board = Board.fromLayout(entry.key, random: Random(1));
        expect(board.tiles.length, entry.value);
        final maxLayer = board.tiles.map((t) => t.layer).reduce(max);
        expect(maxLayer, greaterThanOrEqualTo(2));
      });
    }

    test('late layouts grow in depth instead of spreading the grid', () {
      final dragon = Board.fromLayout('dragon', random: Random(1));
      final sky = Board.fromLayout('sky', random: Random(1));
      expect(
        dragon.tiles.map((t) => t.layer).reduce(max),
        greaterThanOrEqualTo(12),
      );
      expect(
        sky.tiles.map((t) => t.layer).reduce(max),
        greaterThanOrEqualTo(12),
      );
    });

    test(
      'mirrored and deeper variants stay even and change the silhouette',
      () {
        expect(Layouts.campaignLayoutCount, 96);
        for (final base in Layouts.campaignBases) {
          for (final variant in [0, 1, 2, 3]) {
            final name = Layouts.variantName(base, variant);
            expect(Layouts.tileCount(name).isEven, isTrue, reason: name);
          }
          final origin = Layouts.byName(base);
          final mirrored = Layouts.byName('$base-m');
          expect(mirrored, isNot(origin), reason: base);
        }
      },
    );
  });

  test('all campaign levels are fruit-majority', () {
    for (var id = 1; id <= Levels.storyLength; id++) {
      final level = Levels.byId(id);
      final expected = level.style == 'fruit'
          ? TileSymbols.fruitWorldShare
          : TileSymbols.fruitShare;
      expect(level.cuteSimpleShare, expected, reason: 'level $id share');
      expect(
        TileSymbols.cuteSimpleShareFor(id, style: level.style),
        expected,
        reason: 'level $id deck share',
      );

      final board = Board.fromLayout(
        level.layout,
        random: Random(level.id),
        style: level.style,
        pairSize: level.pairSize,
        uniqueCap: level.uniqueCap,
        levelId: level.id,
        guestTypes: level.guestTileTypes,
      );

      final fruit = board.tiles.where((t) => t.symbol.startsWith('fruit-'));
      final share = fruit.length / board.tiles.length;
      expect(
        share,
        greaterThan(0.5),
        reason: 'level $id fruit share $share of ${board.tiles.length}',
      );
      expect(
        share,
        inInclusiveRange(expected - 0.08, expected + 0.08),
        reason: 'level $id fruit share $share expected ~$expected',
      );
    }
  });

  test('easy levels still mix a number and a shape into the fruit deck', () {
    for (final id in [1, 2, 3, 4, 5]) {
      final level = Levels.byId(id);
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
      expect(
        symbols.any((s) => s.startsWith('number-')),
        isTrue,
        reason: 'level $id missing number',
      );
      expect(
        symbols.any((s) => s.startsWith('shape-')),
        isTrue,
        reason: 'level $id missing shape',
      );
    }
  });

  test('mix levels use mixed style without Chinese mahjong faces', () {
    final level = Levels.byId(21);
    expect(level.style, 'mixed');
    expect(level.guestTileTypes, 0);
    final mixed = TileIcons.idsForStyle('mixed');
    expect(mixed, isNot(equals(TileIcons.mahjongIds)));
    expect(mixed, containsAll(TileIcons.fruitIds));
    expect(
      mixed.where(TileIcons.mahjongIds.contains),
      isEmpty,
      reason: 'mixed deck should not include Chinese mahjong faces',
    );
  });

  test('campaign has more fruit worlds than classic Chinese ones', () {
    final styles = [
      for (var id = 1; id <= Levels.storyLength; id++) Levels.byId(id).style,
    ];
    final fruit = styles.where((s) => s == 'fruit').length;
    final classic = styles.where((s) => s == 'classic').length;
    expect(fruit, greaterThan(classic));
    expect(fruit, 12);
    expect(classic, 0);
  });

  test('fruit icons map to titles/fruit assets', () {
    expect(TileIcons.idsForStyle('fruit'), equals(TileIcons.fruitIds));
    expect(TileIcons.idsForStyle('fruit'), hasLength(20));
    expect(TileIcons.idsForStyle('classic'), equals(TileIcons.mahjongIds));
    expect(TileIcons.assetFor('soft-01'), 'assets/titles/soft/01.png');
    expect(TileIcons.assetFor('soft-32'), 'assets/titles/soft/32.png');
    expect(TileIcons.assetFor('fruit-01'), 'assets/titles/fruit/01.svg');
    expect(TileIcons.assetFor('fruit-12'), 'assets/titles/fruit/12.svg');
    expect(TileIcons.assetFor('fruit-20'), 'assets/titles/fruit/20.svg');
    expect(TileIcons.assetFor('shape-01'), 'assets/titles/shape/01.svg');
    expect(TileIcons.assetFor('number-05'), 'assets/titles/number/05.svg');
    expect(
      TileIcons.assetFor('set1-bamboo-03'),
      'assets/titles/1/Bamboo 3.png',
    );
    expect(TileIcons.assetFor('tile-02-05'), 'assets/titles/tile/02/05.svg');
  });

  test('hard levels start with a visible pair and stay playable', () {
    for (var id = 13; id <= Levels.storyLength; id++) {
      final level = Levels.byId(id);
      for (final seed in [1, 7, 13, 42]) {
        final board = Board.fromLayout(
          level.layout,
          random: Random(seed * 100 + id),
          style: level.style,
          pairSize: level.pairSize,
          uniqueCap: level.uniqueCap,
          levelId: level.id,
          guestTypes: level.guestTileTypes,
        );
        expect(
          board.freeTiles(),
          isNotEmpty,
          reason: 'level $id seed $seed has no free tiles',
        );
        expect(
          board.hasUsefulMove(),
          isTrue,
          reason: 'level $id seed $seed has no visible pair',
        );
      }
    }
  });

  test('lotus deal can be cleared by matching visible pairs', () {
    final level = Levels.byId(13);
    final board = Board.fromLayout(
      level.layout,
      random: Random(13),
      style: level.style,
      pairSize: level.pairSize,
      uniqueCap: level.uniqueCap,
      levelId: level.id,
      guestTypes: level.guestTileTypes,
    );

    expect(_clearByVisiblePairs(board), isTrue);
    expect(board.isWon, isTrue);
  });
}

bool _clearByVisiblePairs(Board board) {
  for (var step = 0; step < 400; step++) {
    if (board.isWon) return true;
    if (!board.hasUsefulMove()) return false;

    final free = board.freeTiles();
    Tile? pick;
    for (final trayTile in board.tray.where((t) => !t.removing)) {
      for (final tile in free) {
        if (tile.symbol == trayTile.symbol) {
          pick = tile;
          break;
        }
      }
      if (pick != null) break;
    }
    if (pick == null) {
      for (var i = 0; i < free.length; i++) {
        for (var j = i + 1; j < free.length; j++) {
          if (free[i].symbol == free[j].symbol) {
            pick = free[i];
            break;
          }
        }
        if (pick != null) break;
      }
    }
    if (pick == null) return false;

    board.pick(pick);
    board.resolveTray();
    for (final tile in board.tiles.where((t) => t.removing).toList()) {
      board.finishRemoval(tile);
    }
  }
  return board.isWon;
}
