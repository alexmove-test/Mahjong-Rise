import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icon_admin/game_root.dart';
import 'package:icon_admin/icon_catalog.dart';
import 'package:icon_admin/tile_icons_sync.dart';

void main() {
  test('assetPathFor matches game mapping', () {
    expect(assetPathFor('fruit-01'), 'assets/titles/fruit/01.svg');
    expect(assetPathFor('tile-02-05'), 'assets/titles/tile/02/05.svg');
    expect(assetPathFor('dragon-03'), 'assets/titles/dragon/03.svg');
  });

  test('parseUsedIcons reads list and png map', () {
    const source = r'''
    static const _fruit = <String>['fruit-01', 'fruit-02'];
    static const _set1Assets = <String, String>{
      'set1-bamboo-01': '$assetRoot/1/Bamboo 1.png',
    };
''';
    final used = parseUsedIcons(source);
    final byId = {for (final item in used) item.id: item.assetPath};
    expect(byId['fruit-01'], 'assets/titles/fruit/01.svg');
    expect(byId['set1-bamboo-01'], 'assets/titles/1/Bamboo 1.png');
  });

  test('removeIconIdsFromSource drops list and map entries', () {
    const source = r'''
    static const _fruit = <String>[
      'fruit-01',
      'fruit-02',
    ];
    static const _tile = <String>[
      'tile-00-01', 'tile-00-02', 'tile-00-03',
    ];
    static const _set1Assets = <String, String>{
      'set1-bamboo-01': '$assetRoot/1/Bamboo 1.png',
      'set1-bamboo-02': '$assetRoot/1/Bamboo 2.png',
    };
''';
    final out = removeIconIdsFromSource(source, {
      'fruit-01',
      'tile-00-02',
      'set1-bamboo-01',
    });
    expect(out.contains("'fruit-01'"), isFalse);
    expect(out.contains("'fruit-02'"), isTrue);
    expect(out.contains("'tile-00-02'"), isFalse);
    expect(out.contains("'tile-00-01'"), isTrue);
    expect(out.contains("'set1-bamboo-01'"), isFalse);
    expect(out.contains("'set1-bamboo-02'"), isTrue);
  });

  test('catalog scans the Mahjong titles folder', () {
    final root = findGameRoot();
    expect(root, isNotNull);
    final catalog = loadCatalog(root!);
    expect(catalog.items, isNotEmpty);
    expect(catalog.usedCount, greaterThan(40));
    expect(catalog.draftCount, greaterThan(0));
    expect(
      catalog.items.any(
        (item) => item.relativePath == 'assets/titles/fruit/01.svg',
      ),
      isTrue,
    );
  });

  test('addIconIdsToSource appends to the named list', () {
    const source = '''
    static const _fruit = <String>[
      'fruit-01',
    ];
    static const _nature = <String>[
      'flower-01',
    ];
''';
    final out = addIconIdsToSource(source, '_fruit', ['fruit-13', 'fruit-14']);
    expect(out.contains("'fruit-13'"), isTrue);
    expect(out.contains("'fruit-14'"), isTrue);
    expect(
      out.indexOf("'fruit-13'"),
      lessThan(out.indexOf('static const _nature')),
    );
  });

  test('addIconIdsToSource fills an empty list', () {
    const source = 'static const _fruit = <String>[];';
    final out = addIconIdsToSource(source, '_fruit', ['fruit-01']);
    expect(out.contains("'fruit-01'"), isTrue);
  });

  test('nextIconIndex uses max of ids and files', () {
    final dir = Directory.systemTemp.createTempSync('icon-next');
    addTearDown(() => dir.deleteSync(recursive: true));
    File('${dir.path}/12.svg').writeAsStringSync('<svg/>');
    File('${dir.path}/12-01.svg').writeAsStringSync('<svg/>');
    expect(
      nextIconIndex(
        folder: 'fruit',
        dartSource: "static const _fruit = <String>['fruit-08'];",
        folderDir: dir,
      ),
      13,
    );
  });

  test('addSvgIcons copies files and registers ids', () async {
    final tmp = Directory.systemTemp.createTempSync('icon-add');
    addTearDown(() => tmp.deleteSync(recursive: true));
    File('${tmp.path}/pubspec.yaml').writeAsStringSync('''
name: mahjong
flutter:
  assets:
    - assets/titles/fruit/
''');
    File('${tmp.path}/lib/utils/tile_icons.dart')
      ..createSync(recursive: true)
      ..writeAsStringSync('''
class TileIcons {
  static const _fruit = <String>[
    'fruit-01',
  ];
}
''');
    Directory('${tmp.path}/assets/titles/fruit').createSync(recursive: true);
    File(
      '${tmp.path}/assets/titles/fruit/01.svg',
    ).writeAsStringSync('<svg xmlns="http://www.w3.org/2000/svg"/>');
    final source = File('${tmp.path}/new.svg')
      ..writeAsStringSync('<svg xmlns="http://www.w3.org/2000/svg"/>');

    final report = await addSvgIcons(
      gameRoot: tmp,
      folder: 'fruit',
      listName: '_fruit',
      sourcePaths: [source.path],
    );

    expect(report.addedIds, ['fruit-02']);
    expect(File('${tmp.path}/assets/titles/fruit/02.svg').existsSync(), isTrue);
    expect(
      File('${tmp.path}/lib/utils/tile_icons.dart').readAsStringSync(),
      contains("'fruit-02'"),
    );
  });

  test('collectSvgPaths walks nested folders and skips game titles', () {
    final tmp = Directory.systemTemp.createTempSync('icon-collect');
    addTearDown(() => tmp.deleteSync(recursive: true));
    File('${tmp.path}/a.svg').writeAsStringSync('<svg/>');
    File('${tmp.path}/skip.png').writeAsStringSync('x');
    Directory('${tmp.path}/nested').createSync();
    File('${tmp.path}/nested/b.svg').writeAsStringSync('<svg/>');
    Directory('${tmp.path}/titles').createSync();
    File('${tmp.path}/titles/c.svg').writeAsStringSync('<svg/>');

    final found = collectSvgPaths(tmp.path, skipUnder: '${tmp.path}/titles');
    expect(found.length, 2);
    expect(found.any((path) => path.endsWith('a.svg')), isTrue);
    expect(
      found.any((path) => path.replaceAll('\\', '/').endsWith('nested/b.svg')),
      isTrue,
    );
    expect(found.any((path) => path.contains('titles')), isFalse);
  });
}
