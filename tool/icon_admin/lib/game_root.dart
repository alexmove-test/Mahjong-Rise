import 'dart:io';

/// Корень игры Mahjong Rise (`assets/titles` + `lib/utils/tile_icons.dart`).
Directory? findGameRoot() {
  final starts = <Directory>{
    Directory.current,
    File(Platform.resolvedExecutable).parent,
  };

  for (final start in starts) {
    var dir = start;
    for (var i = 0; i < 10; i++) {
      if (_isGameRoot(dir)) return dir;
      final parent = dir.parent;
      if (parent.path == dir.path) break;
      dir = parent;
    }
  }
  return null;
}

bool _isGameRoot(Directory dir) {
  final pubspec = File('${dir.path}/pubspec.yaml');
  if (!pubspec.existsSync()) return false;
  final nameLine = pubspec
      .readAsStringSync()
      .split('\n')
      .firstWhere((line) => line.startsWith('name:'), orElse: () => '');
  if (nameLine.split(':').last.trim() != 'mahjong') return false;
  return Directory('${dir.path}/assets/titles').existsSync() &&
      File('${dir.path}/lib/utils/tile_icons.dart').existsSync();
}

Directory titlesDir(Directory gameRoot) =>
    Directory('${gameRoot.path}/assets/titles');

File tileIconsFile(Directory gameRoot) =>
    File('${gameRoot.path}/lib/utils/tile_icons.dart');
