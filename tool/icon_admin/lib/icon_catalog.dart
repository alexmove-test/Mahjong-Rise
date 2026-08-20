import 'dart:io';

import 'game_root.dart';

class IconItem {
  const IconItem({
    required this.file,
    required this.relativePath,
    required this.folder,
    required this.fileName,
    required this.usedInGame,
    required this.symbolId,
    required this.isRaster,
  });

  final File file;
  final String relativePath;
  final String folder;
  final String fileName;
  final bool usedInGame;
  final String? symbolId;
  final bool isRaster;
}

class IconCatalog {
  const IconCatalog({required this.gameRoot, required this.items});

  final Directory gameRoot;
  final List<IconItem> items;

  Iterable<String> get folders sync* {
    final seen = <String>{};
    for (final item in items) {
      if (seen.add(item.folder)) yield item.folder;
    }
  }

  int get usedCount => items.where((item) => item.usedInGame).length;

  int get draftCount => items.length - usedCount;
}

IconCatalog loadCatalog(Directory gameRoot) {
  final dartSource = tileIconsFile(gameRoot).readAsStringSync();
  final usedByPath = <String, String>{};
  for (final used in parseUsedIcons(dartSource)) {
    usedByPath.putIfAbsent(used.assetPath, () => used.id);
  }

  const extensions = {'.svg', '.png', '.jpg', '.jpeg', '.webp'};
  final items = <IconItem>[];

  for (final entity in titlesDir(gameRoot).listSync(recursive: true)) {
    if (entity is! File) continue;
    final lower = entity.path.toLowerCase();
    if (!extensions.any(lower.endsWith)) continue;

    final relative = _relativeToRoot(gameRoot, entity);
    final under = relative.replaceFirst('assets/titles/', '');
    items.add(
      IconItem(
        file: entity,
        relativePath: relative,
        folder: _folderOf(under),
        fileName: under.split('/').last,
        usedInGame: usedByPath.containsKey(relative),
        symbolId: usedByPath[relative],
        isRaster: !lower.endsWith('.svg'),
      ),
    );
  }

  items.sort((a, b) {
    final folder = a.folder.compareTo(b.folder);
    if (folder != 0) return folder;
    return a.fileName.compareTo(b.fileName);
  });

  return IconCatalog(gameRoot: gameRoot, items: items);
}

class UsedIcon {
  const UsedIcon({required this.id, required this.assetPath});

  final String id;
  final String assetPath;
}

/// ID из `tile_icons.dart` и путь ассета, который рисует игра.
List<UsedIcon> parseUsedIcons(String dartSource) {
  final mapped = <String, String>{};
  final mapRe = RegExp(r"'([a-z0-9-]+)':\s*'\$assetRoot/([^']+)'");
  for (final match in mapRe.allMatches(dartSource)) {
    mapped[match.group(1)!] = 'assets/titles/${match.group(2)!}';
  }

  final ids = <String>{};
  final idRe = RegExp(r"'([a-z][a-z0-9]*(?:-[a-z0-9]+)+)'");
  for (final match in idRe.allMatches(dartSource)) {
    ids.add(match.group(1)!);
  }

  return [
    for (final id in ids)
      UsedIcon(id: id, assetPath: mapped[id] ?? assetPathFor(id)),
  ];
}

String assetPathFor(String symbol) {
  final dash = symbol.indexOf('-');
  if (dash <= 0 || dash == symbol.length - 1) {
    return 'assets/titles/flower/01.svg';
  }
  final folder = symbol.substring(0, dash);
  final rest = symbol.substring(dash + 1);
  if (folder == 'tile') {
    final parts = rest.split('-');
    if (parts.length == 2) {
      return 'assets/titles/tile/${parts[0]}/${parts[1]}.svg';
    }
  }
  return 'assets/titles/$folder/$rest.svg';
}

String _relativeToRoot(Directory gameRoot, File file) {
  final root = gameRoot.path.replaceAll('\\', '/');
  final path = file.path.replaceAll('\\', '/');
  final prefix = root.endsWith('/') ? root : '$root/';
  if (path.startsWith(prefix)) return path.substring(prefix.length);
  return path;
}

String _folderOf(String underTitles) {
  final parts = underTitles.split('/');
  if (parts.length >= 2 && parts.first == 'tile') {
    return 'tile/${parts[1]}';
  }
  if (parts.first == '1') return 'set1';
  return parts.first;
}
