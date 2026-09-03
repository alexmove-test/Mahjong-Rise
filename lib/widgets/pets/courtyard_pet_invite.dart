import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../models/pet.dart';
import '../../services/pet_store.dart';
import 'pet_portrait.dart';

const _gold = Color(0xFFD4AF37);
const _goldSoft = Color(0xFFE8C96A);
const _ivory = Color(0xFFF8F1DE);
const _woodDeep = Color(0xFF3A2012);

/// Питомец в углу двора: показывает состояние и открывает свой раздел.
class CourtyardPetInvite extends StatefulWidget {
  const CourtyardPetInvite({
    super.key,
    required this.pets,
    required this.onTap,
  });

  final PetStore? pets;
  final VoidCallback onTap;

  @override
  State<CourtyardPetInvite> createState() => _CourtyardPetInviteState();
}

class _CourtyardPetInviteState extends State<CourtyardPetInvite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _idle;
  double _dragDx = 0;
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    _hidden = widget.pets?.yardHidden ?? false;
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (!_hidden) _idle.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant CourtyardPetInvite oldWidget) {
    super.didUpdateWidget(oldWidget);
    final stored = widget.pets?.yardHidden;
    if (stored != null && stored != _hidden && _dragDx == 0) {
      _hidden = stored;
      _syncIdle();
    }
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  void _syncIdle() {
    if (_hidden) {
      _idle.stop();
      _idle.reset();
    } else if (!_idle.isAnimating) {
      _idle.repeat(reverse: true);
    }
  }

  Future<void> _setHidden(bool value) async {
    setState(() {
      _hidden = value;
      _dragDx = 0;
    });
    _syncIdle();
    await widget.pets?.setYardHidden(value);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_hidden) return;
    final next = (_dragDx + details.delta.dx).clamp(0.0, 280.0);
    if (next == _dragDx) return;
    setState(() => _dragDx = next);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_hidden) return;
    final fling = details.primaryVelocity ?? 0;
    if (_dragDx > 72 || fling > 420) {
      unawaited(_setHidden(true));
      return;
    }
    setState(() => _dragDx = 0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final pets = widget.pets;
    final cares = pets?.allCare() ?? const <PetCare>[];
    final urgent = pets?.mostUrgentCare();
    final asking = urgent?.asking ?? false;

    if (_hidden) {
      return _YardPetsTab(
        asking: asking,
        tooltip: l10n.petInviteShow,
        onTap: () => unawaited(_setHidden(false)),
      );
    }

    final statusLines = cares.isEmpty
        ? [(text: l10n.petInviteAdopt, urgent: false)]
        : [
            for (final care in cares)
              (
                text: l10n.petMoodLine(care.kind, care.mood),
                urgent: care.asking,
              ),
          ];
    final status = statusLines.map((line) => line.text).join(' ');

    return Semantics(
      button: true,
      label: '${l10n.pets}. $status',
      child: GestureDetector(
        key: const ValueKey('courtyard-pets'),
        onTap: widget.onTap,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _idle,
          builder: (context, child) {
            final t = Curves.easeInOut.transform(_idle.value);
            final lift = asking ? -6.0 * t : -4.0 * t;
            final tilt = math.sin(t * math.pi) * 0.04;
            return Transform.translate(
              offset: Offset(_dragDx, lift),
              child: Transform.rotate(angle: tilt, child: child),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _InviteBubble(lines: statusLines),
              const SizedBox(height: 6),
              if (cares.isEmpty)
                const _YardPetFigure(kind: null, asking: false)
              else
                _YardPetPack(cares: cares),
            ],
          ),
        ),
      ),
    );
  }
}

class _YardPetsTab extends StatelessWidget {
  const _YardPetsTab({
    required this.asking,
    required this.tooltip,
    required this.onTap,
  });

  final bool asking;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: GestureDetector(
        key: const ValueKey('courtyard-pets-tab'),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _woodDeep.withValues(alpha: 0.92),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              border: Border.all(
                color: _gold.withValues(alpha: asking ? 0.95 : 0.7),
                width: asking ? 1.6 : 1.2,
              ),
            ),
            child: SizedBox(
              width: 40,
              height: 52,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.pets_rounded,
                    color: asking ? _goldSoft : _ivory,
                    size: 22,
                  ),
                  if (asking)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFC45C4A),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(width: 8, height: 8),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteBubble extends StatelessWidget {
  const _InviteBubble({required this.lines});

  final List<({String text, bool urgent})> lines;

  @override
  Widget build(BuildContext context) {
    final urgent = lines.any((line) => line.urgent);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 168),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _woodDeep.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _gold.withValues(alpha: urgent ? 0.95 : 0.7),
            width: urgent ? 1.6 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < lines.length; i++) ...[
                if (i > 0) const SizedBox(height: 4),
                Text(
                  lines[i].text,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: lines[i].urgent ? _goldSoft : _ivory,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _YardPetPack extends StatelessWidget {
  const _YardPetPack({required this.cares});

  final List<PetCare> cares;

  @override
  Widget build(BuildContext context) {
    final n = cares.length;
    final size = n >= 4
        ? 58.0
        : n >= 2
        ? 70.0
        : 96.0;
    final step = n >= 4
        ? 34.0
        : n >= 2
        ? 44.0
        : size;
    final width = size + (n - 1) * step;
    final height = size * (108 / 96);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < n; i++)
            Positioned(
              left: i * step,
              bottom: 0,
              child: _YardPetFigure(
                kind: cares[i].kind,
                asking: cares[i].asking,
                size: size,
              ),
            ),
        ],
      ),
    );
  }
}

class _YardPetFigure extends StatelessWidget {
  const _YardPetFigure({
    required this.kind,
    required this.asking,
    this.size = 96,
  });

  final PetKind? kind;
  final bool asking;
  final double size;

  @override
  Widget build(BuildContext context) {
    final height = size * (108 / 96);
    return SizedBox(
      width: size,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 4,
            child: CustomPaint(
              size: Size(size * 0.67, height * 0.13),
              painter: _GroundBlobPainter(
                color: Colors.black.withValues(alpha: 0.28),
              ),
            ),
          ),
          if (kind != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PetPortrait(kind: kind!),
            )
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Icon(
                Icons.pets_rounded,
                size: size * 0.58,
                color: _goldSoft.withValues(alpha: 0.92),
                shadows: const [Shadow(color: Colors.black54, blurRadius: 8)],
              ),
            ),
          if (asking)
            Positioned(
              right: size * 0.08,
              top: size * 0.08,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFFC45C4A),
                  shape: BoxShape.circle,
                ),
                child: SizedBox(width: 10, height: 10),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroundBlobPainter extends CustomPainter {
  const _GroundBlobPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(rect, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _GroundBlobPainter oldDelegate) =>
      oldDelegate.color != color;
}
