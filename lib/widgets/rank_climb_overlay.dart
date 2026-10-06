import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/leaderboard_entry.dart';
import '../models/rank_climb.dart';

const rankClimbOverlayKey = ValueKey('rank-climb-overlay');

const _gold = Color(0xFFD4AF37);
const _goldSoft = Color(0xFFE8C96A);
const _ivory = Color(0xFFF8F1DE);
const _woodTop = Color(0xFF6B3E24);
const _woodDeep = Color(0xFF3A2012);

/// Мини-таблица после победы: строка игрока поднимается и обгоняет верхних.
class RankClimbOverlay extends StatefulWidget {
  const RankClimbOverlay({super.key, required this.climb, this.onFinished});

  final RankClimb climb;
  final VoidCallback? onFinished;

  static const introDuration = Duration(milliseconds: 360);
  static const stepDuration = Duration(milliseconds: 420);
  static const outroDuration = Duration(milliseconds: 900);
  static const rowExtent = 64.0;

  static Duration displayDurationFor(RankClimb climb) =>
      introDuration + stepDuration * climb.passed.length + outroDuration;

  @override
  State<RankClimbOverlay> createState() => _RankClimbOverlayState();
}

class _RankClimbOverlayState extends State<RankClimbOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  Timer? _done;
  var _notified = false;

  RankClimb get _climb => widget.climb;

  Duration get _total => RankClimbOverlay.displayDurationFor(_climb);

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: _total)..forward();
    _done = Timer(_total, _notifyDone);
  }

  @override
  void dispose() {
    _done?.cancel();
    _anim.dispose();
    super.dispose();
  }

  void _notifyDone() {
    if (_notified) return;
    _notified = true;
    _done?.cancel();
    widget.onFinished?.call();
  }

  void _skip() {
    if (_notified) return;
    _anim.value = 1;
    _notifyDone();
  }

  double _passedT(double value) {
    final n = _climb.passed.length;
    if (n <= 0) return 0;
    final intro = RankClimbOverlay.introDuration.inMilliseconds / _ms;
    final climb = RankClimbOverlay.stepDuration.inMilliseconds * n / _ms;
    if (value <= intro) return 0;
    if (value >= intro + climb) return n.toDouble();
    return (value - intro) / climb * n;
  }

  double _smoothPassed(double raw) {
    final n = _climb.passed.length;
    if (raw <= 0) return 0;
    if (raw >= n) return n.toDouble();
    final k = raw.floor();
    final f = raw - k;
    return k + Curves.easeInOutCubic.transform(f);
  }

  int get _ms => _total.inMilliseconds.clamp(1, 1 << 20);

  double _fade(double value) {
    final intro = RankClimbOverlay.introDuration.inMilliseconds / _ms;
    final outro = RankClimbOverlay.outroDuration.inMilliseconds / _ms;
    if (value < intro) {
      return Curves.easeOutCubic.transform((value / intro).clamp(0.0, 1.0));
    }
    if (value > 1 - outro) {
      final t = ((value - (1 - outro)) / outro).clamp(0.0, 1.0);
      return t < 0.55 ? 1 : ((1 - t) / 0.45).clamp(0.0, 1.0);
    }
    return 1;
  }

  double _slotOfPassed(int i, double t) {
    final a = _climb.stillAbove.length;
    final p = _climb.passed.length;
    final start = a + i.toDouble();
    final passAt = p - i;
    final passStart = passAt - 1;
    if (t <= passStart) return start;
    if (t >= passAt) return start + 1;
    return start + (t - passStart);
  }

  double _slotOfPlayer(double t) {
    return _climb.stillAbove.length + _climb.passed.length - t;
  }

  int _rankForSlot(double slot) {
    final top = _climb.rankTo - _climb.stillAbove.length;
    return (top + slot).round().clamp(1, 999999);
  }

  String _formatRating(int rating) {
    final text = rating.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final posFromEnd = text.length - i;
      buffer.write(text[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write(' ');
    }
    return buffer.toString();
  }

  int _lerpedRating(double t) {
    final n = _climb.passed.length;
    final u = n <= 0 ? 1.0 : (t / n).clamp(0.0, 1.0);
    return (_climb.ratingFrom + (_climb.ratingTo - _climb.ratingFrom) * u)
        .round();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rowCount =
        _climb.stillAbove.length +
        _climb.passed.length +
        1 +
        _climb.below.length;
    final listH = rowCount * RankClimbOverlay.rowExtent;

    return GestureDetector(
      key: rankClimbOverlayKey,
      behavior: HitTestBehavior.opaque,
      onTap: _skip,
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final fade = _fade(_anim.value);
          final t = _smoothPassed(_passedT(_anim.value));
          final playerSlot = _slotOfPlayer(t);
          final playerRank = _rankForSlot(playerSlot);
          final rating = _lerpedRating(t);
          return Opacity(
            opacity: fade,
            child: Align(
              alignment: const Alignment(0, -0.08),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [_woodTop, _woodDeep],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _gold.withValues(alpha: 0.82),
                        width: 1.6,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x99000000),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.youClimbed,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _goldSoft,
                              fontWeight: FontWeight.w900,
                              fontSize: 22,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.rankClimbPlaces(
                              _climb.rankFrom,
                              _climb.rankTo,
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _ivory.withValues(alpha: 0.86),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: listH,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                for (
                                  var i = 0;
                                  i < _climb.stillAbove.length;
                                  i++
                                )
                                  _rowAt(
                                    slot: i.toDouble(),
                                    entry: _climb.stillAbove[i],
                                    rank: _rankForSlot(i.toDouble()),
                                  ),
                                for (var i = 0; i < _climb.passed.length; i++)
                                  _rowAt(
                                    slot: _slotOfPassed(i, t),
                                    entry: _climb.passed[i],
                                    rank: _rankForSlot(_slotOfPassed(i, t)),
                                  ),
                                for (var i = 0; i < _climb.below.length; i++)
                                  _rowAt(
                                    slot:
                                        (_climb.stillAbove.length +
                                                _climb.passed.length +
                                                1 +
                                                i)
                                            .toDouble(),
                                    entry: _climb.below[i],
                                    rank: _rankForSlot(
                                      (_climb.stillAbove.length +
                                              _climb.passed.length +
                                              1 +
                                              i)
                                          .toDouble(),
                                    ),
                                  ),
                                _rowAt(
                                  slot: playerSlot,
                                  entry: _climb.player,
                                  rank: playerRank,
                                  ratingLabel: _formatRating(rating),
                                  player: true,
                                  lift: (t - t.floor()).clamp(0.0, 1.0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _rowAt({
    required double slot,
    required LeaderboardEntry entry,
    required int rank,
    String? ratingLabel,
    bool player = false,
    double lift = 0,
  }) {
    final pulse = player ? 1 + 0.035 * Curves.easeOut.transform(lift) : 1.0;
    return Positioned(
      left: 0,
      right: 0,
      top: slot * RankClimbOverlay.rowExtent,
      height: RankClimbOverlay.rowExtent,
      child: Transform.scale(
        scale: pulse,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _ClimbRow(
            rank: rank,
            name: entry.name,
            ratingLabel: ratingLabel ?? _formatRating(entry.rating),
            player: player,
          ),
        ),
      ),
    );
  }
}

class _ClimbRow extends StatelessWidget {
  const _ClimbRow({
    required this.rank,
    required this.name,
    required this.ratingLabel,
    required this.player,
  });

  final int rank;
  final String name;
  final String ratingLabel;
  final bool player;

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context).displayName(name);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: player
            ? const Color(0xFF6B3E24).withValues(alpha: 0.96)
            : Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: player
              ? _gold.withValues(alpha: 0.9)
              : const Color(0xFF7CB392).withValues(alpha: 0.4),
          width: player ? 1.6 : 1.0,
        ),
        boxShadow: player
            ? const [
                BoxShadow(
                  color: Color(0x66D4AF37),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            _ClimbRankBadge(rank: rank, player: player),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: player ? _goldSoft : const Color(0xFF1E5A3A),
                ),
              ),
            ),
            Text(
              ratingLabel,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: player ? _ivory : const Color(0xFF1E5A3A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClimbRankBadge extends StatelessWidget {
  const _ClimbRankBadge({required this.rank, required this.player});

  final int rank;
  final bool player;

  @override
  Widget build(BuildContext context) {
    Color? medal;
    if (rank == 1) medal = const Color(0xFFFFD54F);
    if (rank == 2) medal = const Color(0xFFB0BEC5);
    if (rank == 3) medal = const Color(0xFFCD7F32);
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            medal ??
            (player
                ? const Color(0xFFE8C96A).withValues(alpha: 0.22)
                : const Color(0xFF1B5E3A).withValues(alpha: 0.12)),
        border: Border.all(
          color:
              medal ??
              (player
                  ? _gold
                  : const Color(0xFF1E5A3A).withValues(alpha: 0.25)),
          width: 1.2,
        ),
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: medal != null
              ? const Color(0xFF3A2012)
              : player
              ? _goldSoft
              : const Color(0xFF1E5A3A),
        ),
      ),
    );
  }
}
