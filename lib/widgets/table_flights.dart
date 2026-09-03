import 'package:flutter/material.dart';

import '../models/tile.dart';

/// Полёт плитки с поля в лоток или обратно при undo.
class TileFlight {
  TileFlight({
    required this.token,
    required this.tile,
    required this.from,
    required this.to,
    required this.scoreBefore,
    required this.comboBefore,
    this.returning = false,
    this.forcePick = false,
  });

  final int token;
  final Tile tile;
  final Rect from;
  final Rect to;
  final int scoreBefore;
  final int comboBefore;
  final bool returning;
  final bool forcePick;
}

/// Пара из лотка, которая разлетается при матче.
class SmashFlight {
  SmashFlight({
    required this.token,
    required this.left,
    required this.right,
    required this.leftRect,
    required this.rightRect,
  });

  final int token;
  final Tile left;
  final Tile right;
  final Rect leftRect;
  final Rect rightRect;
}
