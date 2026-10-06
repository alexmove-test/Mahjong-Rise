import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/board.dart';
import '../models/tile.dart';
import '../services/table_look_controller.dart';
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
    this.targetTileIds = const {},
  });

  final List<Tile> tiles;
  final Set<int> targetTileIds;
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
          final liveTiles = widget.tiles.where((tile) => !tile.isCleared);
          final almostFull =
              !matching &&
              liveTiles.length == Board.trayCapacity - 1 &&
              liveTiles.map((tile) => tile.symbol).toSet().length ==
                  Board.trayCapacity - 1;
          final t = matching ? _matchPulse.value : 0.0;
          final look = TableLookScope.lookOf(context);
          final casual = look.isCasual;
          final premium = look.isPremium;
          final slotH = GameBoard.traySlotHeightOf(casual);
          final glow = casual
              ? (matching
                    ? Color.lerp(TableUi.goldSoft, TableUi.gold, t)!
                    : const Color(0xFF1A4A34))
              : premium
              ? (matching
                    ? Color.lerp(TableUi.goldSoft, TableUi.gold, t)!
                    : const Color(0xFF9A7238))
              : (matching
                    ? Color.lerp(
                        const Color(0xFF5CB0FF),
                        const Color(0xFF9AD4FF),
                        t,
                      )!
                    : const Color(0xFF3D9CFF));

          return Semantics(
            container: true,
            label: AppLocalizations.of(context).traySemantic(
              widget.tiles.where((t) => !t.removing).length,
              Board.trayCapacity,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: SizedBox(
                    width: _trayW,
                    height: GameBoard.trayBarHeightOf(casual),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          casual || premium ? 18 : 14,
                        ),
                        color: casual
                            ? TableUi.trayWell
                            : premium
                            ? TableUi.premiumTrayWell
                            : const Color(0xFF0A1630),
                        border: Border.all(
                          color: glow.withValues(
                            alpha: casual
                                ? (matching ? 0.85 : 0.55)
                                : (matching ? 0.95 : 0.85),
                          ),
                          width: casual ? 1.4 : 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: casual
                                ? Colors.black.withValues(alpha: 0.45)
                                : glow.withValues(
                                    alpha: matching ? 0.55 : 0.28,
                                  ),
                            blurRadius: matching ? 16 : 8,
                            offset: casual ? const Offset(0, 3) : Offset.zero,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _TrayNichesPainter(
                          slotH: slotH,
                          casual: casual || premium,
                          almostFull: almostFull,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (var i = 0; i < Board.trayCapacity; i++)
                              SizedBox(
                                key: widget.slotKeys[i],
                                width: _slotW,
                                height: slotH,
                                child: _buildTrayTile(i, slotH),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: almostFull,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        AppLocalizations.of(context).trayAlmostFull,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFD180),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrayTile(int index, double slotH) {
    final tile = _slotTile(index);
    if (tile == null) {
      return Semantics(
        label: AppLocalizations.of(context).trayEmptySlot,
        child: const SizedBox.expand(),
      );
    }
    if (widget.smashingIds.contains(tile.id)) return const SizedBox.shrink();

    final isHinted = widget.hintedIds.contains(tile.id);

    return TileWidget(
      key: ValueKey('tray-${tile.id}-${tile.removing}'),
      tile: tile,
      isTarget: widget.targetTileIds.contains(tile.id),
      width: _slotW,
      height: slotH,
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
  const _TrayNichesPainter({
    required this.slotH,
    required this.casual,
    required this.almostFull,
  });

  final double slotH;
  final bool casual;
  final bool almostFull;

  @override
  void paint(Canvas canvas, Size size) {
    const slotW = GameBoard.traySlotW;
    const count = Board.trayCapacity;
    const gap = 3.0;
    final startX = (size.width - count * slotW) / 2;
    final startY = (size.height - slotH) / 2;
    final radius = casual ? 12.0 : 8.0;

    for (var i = 0; i < count; i++) {
      final rect = Rect.fromLTWH(
        startX + i * slotW + gap,
        startY + 1,
        slotW - gap * 2,
        slotH - 2,
      );
      final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

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
      if (almostFull && i == count - 1) {
        canvas.drawRRect(rrect, Paint()..color = const Color(0x33FFAB40));
        canvas.drawRRect(
          rrect.deflate(1),
          Paint()
            ..color = const Color(0xFFFFD180)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TrayNichesPainter oldDelegate) {
    return oldDelegate.slotH != slotH ||
        oldDelegate.casual != casual ||
        oldDelegate.almostFull != almostFull;
  }
}
