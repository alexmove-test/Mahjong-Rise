import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/board.dart';
import '../models/tile.dart';
import 'game_board.dart';
import 'table_theme.dart';
import 'tile_widget.dart';

/// Лоток с четырьмя вдавленными нишами под плитки.
class TileTray extends StatefulWidget {
  const TileTray({
    super.key,
    required this.tiles,
    required this.slotKeys,
    required this.hintedIds,
    required this.smashingIds,
    required this.onRemoveComplete,
  });

  final List<Tile> tiles;
  final List<GlobalKey> slotKeys;
  final Set<int> hintedIds;
  final Set<int> smashingIds;
  final void Function(Tile tile) onRemoveComplete;

  @override
  State<TileTray> createState() => _TileTrayState();
}

class _TileTrayState extends State<TileTray>
    with SingleTickerProviderStateMixin {
  static const _slotW = GameBoard.traySlotW;
  static const _slotH = GameBoard.traySlotH;
  static const _padX = 8.0;
  static const _trayW = _padX * 2 + Board.trayCapacity * _slotW;

  late final AnimationController _matchPulse;

  bool get _isMatching => widget.tiles.any((t) => t.removing);

  @override
  void initState() {
    super.initState();
    _matchPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _syncMatchPulse();
  }

  @override
  void didUpdateWidget(TileTray oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMatchPulse();
  }

  void _syncMatchPulse() {
    if (_isMatching) {
      if (!_matchPulse.isAnimating) {
        _matchPulse.repeat(reverse: true);
      }
    } else if (_matchPulse.isAnimating) {
      _matchPulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _matchPulse.dispose();
    super.dispose();
  }

  Tile? _slotTile(int i) {
    if (i >= widget.tiles.length) return null;
    return widget.tiles[i];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 4),
      child: AnimatedBuilder(
        animation: _matchPulse,
        builder: (context, _) {
          final matching = _isMatching;
          final t = matching ? _matchPulse.value : 0.0;
          final glow = matching
              ? Color.lerp(const Color(0xFF5CB0FF), const Color(0xFF9AD4FF), t)!
              : const Color(0xFF3D9CFF);

          return Semantics(
            container: true,
            label: L10n.of(context).traySemantic(
              widget.tiles.where((t) => !t.removing).length,
              Board.trayCapacity,
            ),
            child: Center(
              child: SizedBox(
                width: _trayW,
                height: GameBoard.trayBarH,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: const Color(0xFF0A1630),
                    border: Border.all(
                      color: glow.withValues(alpha: matching ? 0.95 : 0.85),
                      width: 1.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: glow.withValues(alpha: matching ? 0.55 : 0.28),
                        blurRadius: matching ? 16 : 8,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: const _TrayNichesPainter(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < Board.trayCapacity; i++)
                          SizedBox(
                            key: widget.slotKeys[i],
                            width: _slotW,
                            height: _slotH,
                            child: _buildTrayTile(i),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrayTile(int index) {
    final tile = _slotTile(index);
    if (tile == null) {
      return Semantics(
        label: L10n.of(context).trayEmptySlot,
        child: const SizedBox.expand(),
      );
    }
    if (widget.smashingIds.contains(tile.id)) return const SizedBox.shrink();

    final isHinted = widget.hintedIds.contains(tile.id);

    return TileWidget(
      key: ValueKey('tray-${tile.id}-${tile.removing}'),
      tile: tile,
      width: _slotW,
      height: _slotH,
      isSelected: isHinted,
      isFree: true,
      isHinted: isHinted,
      isRemoving: tile.removing,
      compact: true,
      onTap: null,
      onRemoveComplete: () => widget.onRemoveComplete(tile),
    );
  }
}

class _TrayNichesPainter extends CustomPainter {
  const _TrayNichesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const slotW = GameBoard.traySlotW;
    const slotH = GameBoard.traySlotH;
    const count = Board.trayCapacity;
    const gap = 3.0;
    final startX = (size.width - count * slotW) / 2;
    final startY = (size.height - slotH) / 2;

    for (var i = 0; i < count; i++) {
      final rect = Rect.fromLTWH(
        startX + i * slotW + gap,
        startY + 1,
        slotW - gap * 2,
        slotH - 2,
      );
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));

      canvas.drawRRect(rrect, Paint()..color = TableUi.buttonDeep);

      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawRRect(
        rrect.shift(const Offset(0, 1.8)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.38)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.8),
      );
      canvas.drawRect(
        Rect.fromLTWH(rect.left, rect.bottom - 6, rect.width, 8),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.white.withValues(alpha: 0.08), Colors.transparent],
          ).createShader(rect),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
