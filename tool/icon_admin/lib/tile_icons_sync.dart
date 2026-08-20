import 'dart:io';

import 'game_root.dart';
import 'icon_catalog.dart';

class DeleteReport {
  const DeleteReport({
    required this.deletedFiles,
    required this.removedIds,
    required this.skipped,
  });

  final int deletedFiles;
  final int removedIds;
  final List<String> skipped;
}

/// Удаляет выбранные файлы и вычищает их ID из `tile_icons.dart`.
Future<DeleteReport> deleteIcons({
  required Directory gameRoot,
  required List<IconItem> allItems,
  required List<IconItem> selected,
}) async {
  final skipped = <String>[];
  final deleting = <IconItem>[];

  var shapesLeft = allItems
      .where((item) => item.usedInGame && _isShape(item))
      .length;
  var numbersLeft = allItems
      .where((item) => item.usedInGame && _isNumber(item))
      .length;

  for (final item in selected) {
    if (!item.relativePath.startsWith('assets/titles/')) {
      skipped.add('${item.fileName}: вне assets/titles');
      continue;
    }
    if (item.symbolId == 'flower-01' ||
        item.relativePath == 'assets/titles/flower/01.svg') {
      skipped.add('flower/01.svg: запасной файл игры');
      continue;
    }
    if (item.usedInGame && _isShape(item)) {
      if (shapesLeft <= 1) {
        skipped.add('${item.fileName}: последняя фигура');
        continue;
      }
      shapesLeft--;
    }
    if (item.usedInGame && _isNumber(item)) {
      if (numbersLeft <= 1) {
        skipped.add('${item.fileName}: последняя цифра');
        continue;
      }
      numbersLeft--;
    }
    deleting.add(item);
  }

  final removedIds = <String>{
    for (final item in deleting)
      if (item.usedInGame && item.symbolId != null) item.symbolId!,
  };

  if (removedIds.isNotEmpty) {
    final dartFile = tileIconsFile(gameRoot);
    dartFile.writeAsStringSync(
      removeIconIdsFromSource(dartFile.readAsStringSync(), removedIds),
    );
    await _formatDart(dartFile.path);
  }

  var deletedFiles = 0;
  for (final item in deleting) {
    if (item.file.existsSync()) {
      item.file.deleteSync();
      deletedFiles++;
    }
  }

  return DeleteReport(
    deletedFiles: deletedFiles,
    removedIds: removedIds.length,
    skipped: skipped,
  );
}

String removeIconIdsFromSource(String source, Set<String> ids) {
  var result = source;
  final ordered = ids.toList()..sort((a, b) => b.length.compareTo(a.length));

  for (final id in ordered) {
    final escaped = RegExp.escape(id);
    result = result.replaceAll(
      RegExp("\n[ \t]*'$escaped':\\s*'\\\$assetRoot/[^']+',"),
      '',
    );
    result = result.replaceAll(RegExp("'$escaped',[ \t]*"), '');
  }

  return result
      .split('\n')
      .where((line) => line.isEmpty || line.trim().isNotEmpty)
      .join('\n');
}

bool _isShape(IconItem item) => item.symbolId?.startsWith('shape-') ?? false;

bool _isNumber(IconItem item) {
  final id = item.symbolId;
  return id != null && id.startsWith('number-');
}

class IconAddTarget {
  const IconAddTarget({
    required this.folder,
    required this.listName,
    required this.label,
  });

  final String folder;
  final String listName;
  final String label;
}

const iconAddTargets = <IconAddTarget>[
  IconAddTarget(folder: 'fruit', listName: '_fruit', label: 'Фрукты'),
  IconAddTarget(folder: 'flower', listName: '_nature', label: 'Цветы'),
  IconAddTarget(folder: 'season', listName: '_nature', label: 'Сезоны'),
  IconAddTarget(folder: 'bamboo', listName: '_nature', label: 'Бамбук'),
  IconAddTarget(folder: 'animal', listName: '_nature', label: 'Животные'),
  IconAddTarget(folder: 'emperor', listName: '_court', label: 'Императоры'),
  IconAddTarget(folder: 'queen', listName: '_court', label: 'Королевы'),
  IconAddTarget(folder: 'profession', listName: '_court', label: 'Профессии'),
  IconAddTarget(folder: 'art', listName: '_court', label: 'Искусство'),
  IconAddTarget(folder: 'dragon', listName: '_myth', label: 'Драконы'),
  IconAddTarget(folder: 'clown', listName: '_myth', label: 'Клоуны'),
  IconAddTarget(folder: 'joker', listName: '_myth', label: 'Джокеры'),
  IconAddTarget(folder: 'character', listName: '_classic', label: 'Иероглифы'),
  IconAddTarget(folder: 'dot', listName: '_classic', label: 'Точки'),
  IconAddTarget(folder: 'wind', listName: '_classic', label: 'Ветра'),
  IconAddTarget(folder: 'shape', listName: '_shape', label: 'Фигуры'),
  IconAddTarget(folder: 'number', listName: '_number', label: 'Цифры'),
];

class AddReport {
  const AddReport({required this.addedIds, required this.skipped});

  final List<String> addedIds;
  final List<String> skipped;
}

/// Копирует SVG в `assets/titles` и дописывает ID в `tile_icons.dart`.
Future<AddReport> addSvgIcons({
  required Directory gameRoot,
  required String folder,
  required String listName,
  required List<String> sourcePaths,
}) async {
  final skipped = <String>[];
  final svgPaths = <String>[];
  for (final path in sourcePaths) {
    if (!path.toLowerCase().endsWith('.svg')) {
      skipped.add('${_fileName(path)}: нужен SVG');
      continue;
    }
    if (!File(path).existsSync()) {
      skipped.add('${_fileName(path)}: файл не найден');
      continue;
    }
    svgPaths.add(path);
  }

  if (svgPaths.isEmpty) {
    return AddReport(addedIds: const [], skipped: skipped);
  }

  final destDir = Directory('${gameRoot.path}/assets/titles/$folder');
  destDir.createSync(recursive: true);

  var next = nextIconIndex(
    folder: folder,
    dartSource: tileIconsFile(gameRoot).readAsStringSync(),
    folderDir: destDir,
  );

  final addedIds = <String>[];
  for (final path in svgPaths) {
    while (true) {
      final name = next.toString().padLeft(2, '0');
      final dest = File('${destDir.path}/$name.svg');
      next++;
      if (dest.existsSync()) continue;
      File(path).copySync(dest.path);
      addedIds.add('$folder-$name');
      break;
    }
  }

  if (addedIds.isNotEmpty) {
    final dartFile = tileIconsFile(gameRoot);
    dartFile.writeAsStringSync(
      addIconIdsToSource(dartFile.readAsStringSync(), listName, addedIds),
    );
    await _formatDart(dartFile.path);
    ensurePubspecAssetFolder(File('${gameRoot.path}/pubspec.yaml'), folder);
  }

  return AddReport(addedIds: addedIds, skipped: skipped);
}

/// Все SVG в папке, включая вложенные. [skipUnder] не импортируется (свои assets).
List<String> collectSvgPaths(String root, {String? skipUnder}) {
  final dir = Directory(root);
  if (!dir.existsSync()) return const [];

  final skip = skipUnder == null ? null : _normDir(skipUnder);
  final files = <String>[];
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    if (!entity.path.toLowerCase().endsWith('.svg')) continue;
    if (skip != null && _normPath(entity.path).startsWith(skip)) continue;
    files.add(entity.path);
  }
  files.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return files;
}

int nextIconIndex({
  required String folder,
  required String dartSource,
  required Directory folderDir,
}) {
  var max = 0;
  final idRe = RegExp("'$folder-(\\d+)'");
  for (final match in idRe.allMatches(dartSource)) {
    max = _max(max, int.parse(match.group(1)!));
  }
  if (folderDir.existsSync()) {
    final fileRe = RegExp(r'^(\d+)\.svg$', caseSensitive: false);
    for (final entity in folderDir.listSync()) {
      final match = fileRe.firstMatch(_fileName(entity.path));
      if (match != null) {
        max = _max(max, int.parse(match.group(1)!));
      }
    }
  }
  return max + 1;
}

String addIconIdsToSource(String source, String listName, List<String> ids) {
  if (ids.isEmpty) return source;
  final header = RegExp('static const $listName = <String>\\[');
  final match = header.firstMatch(source);
  if (match == null) {
    throw StateError('Не найден список $listName в tile_icons.dart');
  }

  final open = match.end - 1;
  var depth = 0;
  var close = -1;
  for (var i = open; i < source.length; i++) {
    if (source[i] == '[') depth++;
    if (source[i] == ']') {
      depth--;
      if (depth == 0) {
        close = i;
        break;
      }
    }
  }
  if (close < 0) {
    throw StateError('Не закрыт список $listName');
  }

  final inner = source.substring(open + 1, close);
  final entries = ids.map((id) => "    '$id',").join('\n');
  final newInner = inner.trim().isEmpty
      ? '\n$entries\n  '
      : '${inner.endsWith('\n') ? inner : '$inner\n'}$entries\n  ';
  return '${source.substring(0, open + 1)}$newInner${source.substring(close)}';
}

void ensurePubspecAssetFolder(File pubspec, String folder) {
  if (!pubspec.existsSync()) return;
  var text = pubspec.readAsStringSync();
  final needle = 'assets/titles/$folder/';
  if (text.contains(needle)) return;

  final matches = RegExp(r'    - assets/titles/[^\n]+\n').allMatches(text);
  if (matches.isEmpty) return;
  final last = matches.last;
  text = text.replaceRange(last.end, last.end, '    - $needle\n');
  pubspec.writeAsStringSync(text);
}

String _fileName(String path) => path.replaceAll('\\', '/').split('/').last;

String _normPath(String path) => path.replaceAll('\\', '/').toLowerCase();

String _normDir(String path) {
  final norm = _normPath(path);
  return norm.endsWith('/') ? norm : '$norm/';
}

int _max(int a, int b) => a > b ? a : b;

Future<void> _formatDart(String path) async {
  try {
    await Process.run('dart', ['format', path], runInShell: true);
  } catch (_) {}
}
