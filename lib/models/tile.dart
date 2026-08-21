/// Одна плитка маджонга на поле.
class Tile {
  Tile({
    required this.id,
    required this.symbol,
    required this.layer,
    required this.x,
    required this.y,
    this.removed = false,
    this.removing = false,
    this.inTray = false,
    this.flying = false,
  });

  final int id;

  /// Символ/лицо плитки (может меняться при shuffle).
  String symbol;

  /// Высота стопки: 0 — нижний слой.
  final int layer;

  /// Координаты в сетке раскладки (в половинах ширины/высоты плитки).
  final int x;
  final int y;

  /// Полностью убрана (после матча из лотка).
  bool removed;

  /// Идёт анимация исчезновения (матч в лотке).
  bool removing;

  /// Лежит в верхнем лотке (снята с поля, но ещё не сматчена).
  bool inTray;

  /// Летит с поля в лоток — ещё не участвует в матче.
  bool flying;

  /// Полностью вышла из игры.
  bool get isCleared => removed || removing;

  /// Ещё лежит на раскладке.
  bool get isOnBoard => !removed && !removing && !inTray;

  Tile copy() => Tile(
    id: id,
    symbol: symbol,
    layer: layer,
    x: x,
    y: y,
    removed: removed,
    removing: removing,
    inTray: inTray,
    flying: flying,
  );

  @override
  String toString() =>
      'Tile($id, $symbol, L$layer @($x,$y)${isCleared
          ? " ✕"
          : inTray
          ? " tray"
          : ""})';
}
