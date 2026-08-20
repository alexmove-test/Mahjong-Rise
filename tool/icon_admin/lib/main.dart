import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'game_root.dart';
import 'icon_catalog.dart';
import 'tile_icons_sync.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IconAdminApp());
}

class IconAdminApp extends StatelessWidget {
  const IconAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Админ иконок',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2F6B4F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const IconAdminPage(),
    );
  }
}

enum _Filter { all, used, drafts }

class IconAdminPage extends StatefulWidget {
  const IconAdminPage({super.key});

  @override
  State<IconAdminPage> createState() => _IconAdminPageState();
}

class _IconAdminPageState extends State<IconAdminPage> {
  IconCatalog? _catalog;
  String? _error;
  _Filter _filter = _Filter.all;
  String? _folder;
  String _query = '';
  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _selected.clear();
    try {
      final root = findGameRoot();
      if (root == null) {
        _catalog = null;
        _error =
            'Не найден проект Mahjong. Запустите из C:\\Code\\Mahjong или tool\\icon_admin.';
        return;
      }
      _catalog = loadCatalog(root);
      _error = null;
    } catch (error) {
      _catalog = null;
      _error = error.toString();
    }
  }

  void _reload() {
    setState(_load);
  }

  List<IconItem> get _visible {
    final catalog = _catalog;
    if (catalog == null) return const [];
    final q = _query.trim().toLowerCase();
    return catalog.items.where((item) {
      if (_folder != null && item.folder != _folder) return false;
      switch (_filter) {
        case _Filter.used:
          if (!item.usedInGame) return false;
        case _Filter.drafts:
          if (item.usedInGame) return false;
        case _Filter.all:
          break;
      }
      if (q.isEmpty) return true;
      return item.fileName.toLowerCase().contains(q) ||
          item.folder.toLowerCase().contains(q) ||
          (item.symbolId?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _toggle(IconItem item) {
    setState(() {
      if (!_selected.remove(item.relativePath)) {
        _selected.add(item.relativePath);
      }
    });
  }

  void _selectVisibleDrafts() {
    setState(() {
      for (final item in _visible) {
        if (!item.usedInGame) _selected.add(item.relativePath);
      }
    });
  }

  void _selectVisible() {
    setState(() {
      _selected
        ..clear()
        ..addAll(_visible.map((item) => item.relativePath));
    });
  }

  Future<void> _confirmDelete() async {
    final catalog = _catalog;
    if (catalog == null || _selected.isEmpty) return;

    final chosen = catalog.items
        .where((item) => _selected.contains(item.relativePath))
        .toList();
    final used = chosen.where((item) => item.usedInGame).length;
    final drafts = chosen.length - used;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить иконки?'),
          content: Text(
            'Файлов: ${chosen.length}\n'
            'В колоде игры: $used\n'
            'Черновиков: $drafts\n\n'
            'Файлы удалятся из assets/titles. ID из колоды тоже уберутся.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;

    final report = await deleteIcons(
      gameRoot: catalog.gameRoot,
      allItems: catalog.items,
      selected: chosen,
    );
    if (!mounted) return;

    _reload();

    final skipped = report.skipped.isEmpty
        ? ''
        : '\nПропущено: ${report.skipped.join('; ')}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Удалено файлов: ${report.deletedFiles}, ID: ${report.removedIds}$skipped',
        ),
        duration: Duration(seconds: report.skipped.isEmpty ? 3 : 8),
      ),
    );
  }

  Future<void> _addFiles() async {
    final picked = await FilePicker.pickFiles(
      dialogTitle: 'Выберите один или несколько SVG (Ctrl / Shift)',
      type: FileType.custom,
      allowedExtensions: const ['svg'],
    );
    if (picked.isEmpty || !mounted) return;

    final paths = <String>[
      for (final file in picked)
        if (file.path != null)
          file.path!
        else if (file.uri.scheme == 'file')
          file.uri.toFilePath(),
    ];
    await _importPaths(paths);
  }

  Future<void> _addFolder() async {
    final catalog = _catalog;
    if (catalog == null) return;

    final dir = await FilePicker.getDirectoryPath(
      dialogTitle: 'Выберите папку с SVG',
    );
    if (dir == null || !mounted) return;

    final paths = collectSvgPaths(
      dir,
      skipUnder: titlesDir(catalog.gameRoot).path,
    );
    if (paths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('В папке нет SVG (или это папка игры).')),
      );
      return;
    }
    await _importPaths(paths);
  }

  Future<void> _importPaths(List<String> paths) async {
    final catalog = _catalog;
    if (catalog == null || paths.isEmpty) return;

    final initial = iconAddTargets.firstWhere(
      (target) => target.folder == _folder,
      orElse: () => iconAddTargets.first,
    );
    final chosen = await showDialog<IconAddTarget>(
      context: context,
      builder: (context) =>
          _AddIconsDialog(fileCount: paths.length, initial: initial),
    );
    if (chosen == null || !mounted) return;

    final report = await addSvgIcons(
      gameRoot: catalog.gameRoot,
      folder: chosen.folder,
      listName: chosen.listName,
      sourcePaths: paths,
    );
    if (!mounted) return;

    _reload();
    setState(() => _folder = chosen.folder);

    final skipped = report.skipped.isEmpty
        ? ''
        : '\nПропущено: ${report.skipped.join('; ')}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          report.addedIds.isEmpty
              ? 'Ничего не добавлено$skipped'
              : '${_addedSummary(report.addedIds)}$skipped',
        ),
        duration: Duration(seconds: report.skipped.isEmpty ? 4 : 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.delete): _confirmDelete,
        const SingleActivator(LogicalKeyboardKey.keyA, control: true):
            _selectVisible,
        const SingleActivator(LogicalKeyboardKey.keyN, control: true):
            _addFiles,
        const SingleActivator(
          LogicalKeyboardKey.keyN,
          control: true,
          shift: true,
        ): _addFolder,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFF101C18),
          body: _error != null
              ? _ErrorPane(message: _error!, onRetry: _reload)
              : _catalog == null
              ? const Center(child: CircularProgressIndicator())
              : _buildWorkspace(),
        ),
      ),
    );
  }

  Widget _buildWorkspace() {
    final catalog = _catalog!;
    final visible = _visible;
    final selectedVisible = visible
        .where((item) => _selected.contains(item.relativePath))
        .length;

    return Column(
      children: [
        _TopBar(
          used: catalog.usedCount,
          drafts: catalog.draftCount,
          total: catalog.items.length,
          query: _query,
          filter: _filter,
          onQuery: (value) => setState(() => _query = value),
          onFilter: (value) => setState(() => _filter = value),
          onReload: _reload,
          onAddFiles: _addFiles,
          onAddFolder: _addFolder,
        ),
        Expanded(
          child: Row(
            children: [
              _FolderList(
                folders: catalog.folders.toList(),
                items: catalog.items,
                selected: _folder,
                onSelect: (folder) => setState(() => _folder = folder),
              ),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: visible.isEmpty
                          ? const Center(child: Text('Нет иконок по фильтру'))
                          : _IconGrid(
                              items: visible,
                              selected: _selected,
                              onToggle: _toggle,
                            ),
                    ),
                    _BottomBar(
                      visibleCount: visible.length,
                      selectedCount: selectedVisible,
                      onSelectDrafts: _selectVisibleDrafts,
                      onClear: () => setState(_selected.clear),
                      onAddFiles: _addFiles,
                      onAddFolder: _addFolder,
                      onDelete: _selected.isEmpty ? null : _confirmDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _addedSummary(List<String> ids) {
  if (ids.length <= 8) return 'В колоду: ${ids.join(', ')}';
  return 'В колоду: ${ids.length} шт. (${ids.first} … ${ids.last})';
}

class _AddMenuButton extends StatelessWidget {
  const _AddMenuButton({
    required this.onAddFiles,
    required this.onAddFolder,
    this.tonal = false,
  });

  final VoidCallback onAddFiles;
  final VoidCallback onAddFolder;
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) {
        void onPressed() {
          if (controller.isOpen) {
            controller.close();
          } else {
            controller.open();
          }
        }
        final icon = const Icon(Icons.add);
        const label = Text('Добавить');
        if (tonal) {
          return FilledButton.tonalIcon(
            onPressed: onPressed,
            icon: icon,
            label: label,
          );
        }
        return FilledButton.icon(
          onPressed: onPressed,
          icon: icon,
          label: label,
        );
      },
      menuChildren: [
        MenuItemButton(
          onPressed: onAddFiles,
          leadingIcon: const Icon(Icons.insert_drive_file_outlined),
          child: const Text('Несколько SVG'),
        ),
        MenuItemButton(
          onPressed: onAddFolder,
          leadingIcon: const Icon(Icons.folder_outlined),
          child: const Text('Папку целиком'),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.used,
    required this.drafts,
    required this.total,
    required this.query,
    required this.filter,
    required this.onQuery,
    required this.onFilter,
    required this.onReload,
    required this.onAddFiles,
    required this.onAddFolder,
  });

  final int used;
  final int drafts;
  final int total;
  final String query;
  final _Filter filter;
  final ValueChanged<String> onQuery;
  final ValueChanged<_Filter> onFilter;
  final VoidCallback onReload;
  final VoidCallback onAddFiles;
  final VoidCallback onAddFolder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF173028),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.grid_view_rounded, color: Color(0xFFD4B56A)),
            const Text(
              'Админ иконок',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Text(
              '$total файлов · $used в игре · $drafts черновиков',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.65)),
            ),
            SizedBox(
              width: 220,
              child: TextField(
                onChanged: onQuery,
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Поиск',
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            SegmentedButton<_Filter>(
              segments: const [
                ButtonSegment(value: _Filter.all, label: Text('Все')),
                ButtonSegment(value: _Filter.used, label: Text('В игре')),
                ButtonSegment(value: _Filter.drafts, label: Text('Черновики')),
              ],
              selected: {filter},
              onSelectionChanged: (value) => onFilter(value.first),
            ),
            IconButton(
              onPressed: onReload,
              tooltip: 'Обновить',
              icon: const Icon(Icons.refresh),
            ),
            _AddMenuButton(onAddFiles: onAddFiles, onAddFolder: onAddFolder),
          ],
        ),
      ),
    );
  }
}

class _FolderList extends StatelessWidget {
  const _FolderList({
    required this.folders,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  final List<String> folders;
  final List<IconItem> items;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Material(
        color: const Color(0xFF15241F),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _folderTile('Все папки', null, items.length),
            const Divider(height: 16),
            for (final folder in folders)
              _folderTile(
                folder,
                folder,
                items.where((item) => item.folder == folder).length,
              ),
          ],
        ),
      ),
    );
  }

  Widget _folderTile(String label, String? folder, int count) {
    final active = selected == folder;
    return ListTile(
      dense: true,
      selected: active,
      selectedTileColor: const Color(0xFF2F6B4F).withValues(alpha: 0.35),
      title: Text(label),
      trailing: Text('$count'),
      onTap: () => onSelect(folder),
    );
  }
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  final List<IconItem> items;
  final Set<String> selected;
  final ValueChanged<IconItem> onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / 200).floor().clamp(2, 8);
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _IconCard(
              item: item,
              selected: selected.contains(item.relativePath),
              onTap: () => onToggle(item),
            );
          },
        );
      },
    );
  }
}

class _IconCard extends StatelessWidget {
  const _IconCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final IconItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E332B),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? const Color(0xFFD4B56A) : const Color(0xFF2C4A3E),
          width: selected ? 3 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F1E6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _IconPreview(item: item),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.fileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _Badge(
                    label: item.usedInGame ? 'В игре' : 'Черновик',
                    color: item.usedInGame
                        ? const Color(0xFFD4B56A)
                        : const Color(0xFF7EA18F),
                  ),
                  const Spacer(),
                  if (selected) const Icon(Icons.check_circle, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
    );
  }
}

class _IconPreview extends StatelessWidget {
  const _IconPreview({required this.item});

  final IconItem item;

  @override
  Widget build(BuildContext context) {
    if (item.isRaster) {
      return Image.file(
        item.file,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stack) =>
            const Icon(Icons.broken_image_outlined, color: Colors.brown),
      );
    }
    return SvgPicture.file(
      item.file,
      fit: BoxFit.contain,
      placeholderBuilder: (context) => const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.visibleCount,
    required this.selectedCount,
    required this.onSelectDrafts,
    required this.onClear,
    required this.onAddFiles,
    required this.onAddFolder,
    required this.onDelete,
  });

  final int visibleCount;
  final int selectedCount;
  final VoidCallback onSelectDrafts;
  final VoidCallback onClear;
  final VoidCallback onAddFiles;
  final VoidCallback onAddFolder;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF173028),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('На экране: $visibleCount · выбрано: $selectedCount'),
            TextButton(
              onPressed: onSelectDrafts,
              child: const Text('Выбрать черновики'),
            ),
            TextButton(
              onPressed: selectedCount == 0 ? null : onClear,
              child: const Text('Снять выбор'),
            ),
            _AddMenuButton(
              onAddFiles: onAddFiles,
              onAddFolder: onAddFolder,
              tonal: true,
            ),
            FilledButton.icon(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Удалить выбранные'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.folder_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}

class _AddIconsDialog extends StatefulWidget {
  const _AddIconsDialog({required this.fileCount, required this.initial});

  final int fileCount;
  final IconAddTarget initial;

  @override
  State<_AddIconsDialog> createState() => _AddIconsDialogState();
}

class _AddIconsDialogState extends State<_AddIconsDialog> {
  late IconAddTarget _target = widget.initial;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Добавить в колоду'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Файлов: ${widget.fileCount}'),
            const SizedBox(height: 12),
            DropdownMenu<IconAddTarget>(
              width: 380,
              initialSelection: _target,
              label: const Text('Папка / тема'),
              dropdownMenuEntries: [
                for (final target in iconAddTargets)
                  DropdownMenuEntry(
                    value: target,
                    label: '${target.label} (${target.folder})',
                  ),
              ],
              onSelected: (value) {
                if (value != null) setState(() => _target = value);
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Найдено SVG: ${widget.fileCount}. '
              'Они скопируются как ${_target.folder}/NN.svg и сразу попадут в игру.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _target),
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}
