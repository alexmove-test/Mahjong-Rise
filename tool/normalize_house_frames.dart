// Приводит кадры построек к одной опоре и превращает запечённую серую тень
// в настоящую — тёмную и полупрозрачную, чтобы она не белела на траве.
//
//   dart run tool/normalize_house_frames.dart --dry-run
//   dart run tool/normalize_house_frames.dart
//
// Кадр состоит из непрозрачного силуэта, тонкой каймы сглаживания вокруг него
// и мягкой тени в стороне. Тень отличается тем, что она серая и лежит дальше
// [haloRadius] от силуэта, — по этому её и находим.

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const frameCount = 24;
const solidAlpha = 250;
const shadowMinAlpha = 8;
const maxSaturation = 40;

/// Порог «серости» и светлоты, по которым тень отличается от постройки.
const neutralSaturation = 16;
const shadowMinLuminance = 105;

/// Тень: холодный тёмный тон вместо серого, с заметно меньшей плотностью.
const shadowRed = 26;
const shadowGreen = 34;
const shadowBlue = 20;
const shadowPeakAlpha = 132;

/// Доля высоты кадра под линией земли — считается по самой глубокой тени.
const minBaselineGap = 0.02;

class FrameStats {
  FrameStats({
    required this.frame,
    required this.solid,
    required this.content,
    required this.shadowPixels,
    required this.shadowPeak,
  });

  final int frame;
  final _Box solid;
  final _Box content;
  final int shadowPixels;
  final int shadowPeak;
}

class _Box {
  _Box(this.left, this.top, this.right, this.bottom);

  final int left;
  final int top;
  final int right;
  final int bottom;

  bool get isEmpty => right < left || bottom < top;
  int get width => right - left + 1;
  int get height => bottom - top + 1;
  int get centerX => (left + right) ~/ 2;
}

_Box _boundsOf(img.Image image, bool Function(img.Pixel) test) {
  var left = image.width;
  var top = image.height;
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (!test(image.getPixel(x, y))) continue;
      if (x < left) left = x;
      if (x > right) right = x;
      if (y < top) top = y;
      if (y > bottom) bottom = y;
    }
  }
  return _Box(left, top, right, bottom);
}

bool _isSolid(img.Pixel p) => p.a >= solidAlpha;

bool _hasInk(img.Pixel p) => p.a > 0;

int _saturation(img.Pixel p) {
  final high = math.max(p.r, math.max(p.g, p.b));
  final low = math.min(p.r, math.min(p.g, p.b));
  return (high - low).round();
}

int _luminance(img.Pixel p) =>
    (p.r * 0.299 + p.g * 0.587 + p.b * 0.114).round();

/// Тень запечена непрозрачным серым и примыкает к прозрачному фону, а серые
/// части самой постройки со всех сторон закрыты цветными пикселями. Поэтому
/// ищем её заливкой от рамки кадра: проходимы фон и светлый нейтральный серый.
List<bool> _shadowMask(img.Image image) {
  final w = image.width;
  final h = image.height;
  final seen = List<bool>.filled(w * h, false);
  final shadow = List<bool>.filled(w * h, false);

  // Тень лежит у основания, поэтому верхняя половина кадра неприкосновенна:
  // иначе под правило попадает белый дым над костром.
  final content = _boundsOf(image, _hasInk);
  final cutoff = content.top + content.height ~/ 2;

  bool passable(int x, int y) {
    final p = image.getPixel(x, y);
    if (p.a < shadowMinAlpha) return true;
    return _saturation(p) <= neutralSaturation &&
        _luminance(p) >= shadowMinLuminance;
  }

  final queue = <int>[];
  void push(int x, int y) {
    final at = y * w + x;
    if (seen[at] || !passable(x, y)) return;
    seen[at] = true;
    queue.add(at);
  }

  for (var x = 0; x < w; x++) {
    push(x, 0);
    push(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    push(0, y);
    push(w - 1, y);
  }
  while (queue.isNotEmpty) {
    final at = queue.removeLast();
    final x = at % w;
    final y = at ~/ w;
    if (y >= cutoff && image.getPixel(x, y).a >= shadowMinAlpha) {
      shadow[at] = true;
    }
    if (x > 0) push(x - 1, y);
    if (x < w - 1) push(x + 1, y);
    if (y > 0) push(x, y - 1);
    if (y < h - 1) push(x, y + 1);
  }
  return shadow;
}

/// Перекрашивает найденную тень: серый градиент становится градиентом
/// прозрачности, поэтому край овала растворяется вместо белой кромки.
({int pixels, int peak}) _repaintShadow(img.Image image) {
  final shadow = _shadowMask(image);
  var pixels = 0;
  var darkest = 255;
  var lightest = 0;
  for (var at = 0; at < shadow.length; at++) {
    if (!shadow[at]) continue;
    final lum = _luminance(image.getPixel(at % image.width, at ~/ image.width));
    pixels++;
    darkest = math.min(darkest, lum);
    lightest = math.max(lightest, lum);
  }
  if (pixels == 0 || lightest <= darkest) return (pixels: 0, peak: 0);

  for (var at = 0; at < shadow.length; at++) {
    if (!shadow[at]) continue;
    final x = at % image.width;
    final y = at ~/ image.width;
    final lum = _luminance(image.getPixel(x, y));
    final density = (lightest - lum) / (lightest - darkest);
    final alpha = (density * shadowPeakAlpha).round().clamp(0, 255);
    image.setPixelRgba(x, y, shadowRed, shadowGreen, shadowBlue, alpha);
  }
  return (pixels: pixels, peak: lightest - darkest);
}

/// Красит найденную тень в маджентовый, чтобы её было видно глазами.
void _writeMask(String kind, int frame) {
  final image = img.decodePng(File(_pathOf(kind, frame)).readAsBytesSync())!;
  final shadow = _shadowMask(image);
  for (var at = 0; at < shadow.length; at++) {
    if (!shadow[at]) continue;
    image.setPixelRgba(
      at % image.width,
      at ~/ image.width,
      255,
      0,
      255,
      255,
    );
  }
  final out = 'build/shadow-mask-${frame.toString().padLeft(2, '0')}.png';
  File(out).writeAsBytesSync(img.encodePng(image));
  stdout.writeln('$out  shadow=${shadow.where((v) => v).length}');
}

String _pathOf(String kind, int frame) {
  final n = frame.toString().padLeft(2, '0');
  return 'assets/courtyard/builds/$kind/$n.png';
}

/// Карта кадра в символах: видно, где силуэт, а где серый овал под ним.
void _probe(String kind, int frame) {
  final image = img.decodePng(File(_pathOf(kind, frame)).readAsBytesSync())!;
  const rows = 46;
  final step = image.height ~/ rows;
  for (var y = 0; y < image.height; y += step) {
    final line = StringBuffer();
    for (var x = 0; x < image.width; x += step) {
      final p = image.getPixel(x, y);
      final alpha = p.a.round();
      final lum = (p.r * 0.299 + p.g * 0.587 + p.b * 0.114).round();
      line.write(switch (null) {
        _ when alpha < 8 => '.',
        _ when alpha < solidAlpha => 'o',
        _ when _saturation(p) >= maxSaturation => '#',
        _ when lum > 165 => 'S',
        _ => '+',
      });
    }
    stdout.writeln(line);
  }
  for (final at in [
    (x: image.width ~/ 6, y: image.height * 5 ~/ 6),
    (x: image.width ~/ 2, y: image.height * 5 ~/ 6),
    (x: image.width ~/ 2, y: image.height ~/ 2),
  ]) {
    final p = image.getPixel(at.x, at.y);
    stdout.writeln(
      'at ${at.x},${at.y} rgba=${p.r.round()},${p.g.round()},'
      '${p.b.round()},${p.a.round()} sat=${_saturation(p)}',
    );
  }
}

void main(List<String> args) {
  final dryRun = args.contains('--dry-run');
  final kind = args
      .firstWhere((a) => a.startsWith('--kind='), orElse: () => '--kind=house')
      .split('=')
      .last;

  final probe = args.firstWhere(
    (a) => a.startsWith('--probe='),
    orElse: () => '',
  );
  if (probe.isNotEmpty) {
    _probe(kind, int.parse(probe.split('=').last));
    return;
  }

  final mask = args.firstWhere(
    (a) => a.startsWith('--mask='),
    orElse: () => '',
  );
  if (mask.isNotEmpty) {
    for (final frame in mask.split('=').last.split(',')) {
      _writeMask(kind, int.parse(frame));
    }
    return;
  }

  final images = <int, img.Image>{};
  final stats = <FrameStats>[];

  for (var frame = 1; frame <= frameCount; frame++) {
    final path = _pathOf(kind, frame);
    final bytes = File(path).readAsBytesSync();
    final decoded = img.decodePng(bytes);
    if (decoded == null) throw StateError('cannot decode $path');
    final shadow = _repaintShadow(decoded);
    final solid = _boundsOf(decoded, _isSolid);
    final content = _boundsOf(decoded, _hasInk);
    if (solid.isEmpty) throw StateError('no silhouette in $path');
    images[frame] = decoded;
    stats.add(
      FrameStats(
        frame: frame,
        solid: solid,
        content: content,
        shadowPixels: shadow.pixels,
        shadowPeak: shadow.peak,
      ),
    );
  }

  final height = images[1]!.height;
  final width = images[1]!.width;
  for (final frame in images.values) {
    if (frame.width != width || frame.height != height) {
      throw StateError('frames must share one canvas size');
    }
  }

  // Линия земли одна на все кадры: столько места под ней, чтобы самая
  // глубокая тень уместилась целиком.
  var deepest = 0;
  for (final s in stats) {
    deepest = math.max(deepest, s.content.bottom - s.solid.bottom);
  }
  final gap = math.max(deepest, (height * minBaselineGap).round());
  final baselineY = height - 1 - gap;

  stdout.writeln('kind=$kind canvas=${width}x$height');
  stdout.writeln('baseline=$baselineY gap=$gap (deepest shadow $deepest px)');
  stdout.writeln('frame  solid w x h   dx    dy   shadowPx  peakA');

  for (final s in stats) {
    final image = images[s.frame]!;
    var dx = width ~/ 2 - s.solid.centerX;
    var dy = baselineY - s.solid.bottom;
    // Ничего не обрезаем: сдвиг ограничен рамкой всех непрозрачных пикселей.
    dx = dx.clamp(-s.content.left, width - 1 - s.content.right);
    dy = dy.clamp(-s.content.top, height - 1 - s.content.bottom);

    stdout.writeln(
      '${s.frame.toString().padLeft(5)}  '
      '${s.solid.width.toString().padLeft(4)} x '
      '${s.solid.height.toString().padLeft(4)}  '
      '${dx.toString().padLeft(5)} '
      '${dy.toString().padLeft(5)}  '
      '${s.shadowPixels.toString().padLeft(8)}  '
      '${s.shadowPeak.toString().padLeft(5)}',
    );

    if (dryRun || (dx == 0 && dy == 0)) continue;
    final moved = img.Image(width: width, height: height, numChannels: 4);
    img.compositeImage(moved, image, dstX: dx, dstY: dy);
    images[s.frame] = moved;
  }

  if (dryRun) {
    stdout.writeln('dry run: nothing written');
    return;
  }
  for (final entry in images.entries) {
    File(
      _pathOf(kind, entry.key),
    ).writeAsBytesSync(img.encodePng(entry.value));
  }
  stdout.writeln('written ${images.length} frames');
}
