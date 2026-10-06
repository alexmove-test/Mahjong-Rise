// Ключует чёрный фон у сгенерированных фруктов и кладёт силуэт
// в квадрат 512 с теми же полями, что у 01.png / 02.png.
//
//   dart run tool/fit_fruit_icons.dart

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const sourceDir = r'C:\Users\Main\.cursor\projects\c-Code-Mahjong\assets';
const destDir = 'assets/titles/fruit';
const outSize = 512;
const keyTolerance = 28.0;
const rimAlpha = 140;

/// Поля как у 01/02: ~14% по бокам, чуть меньше сверху, чуть больше снизу.
const padX = 0.138;
const padTop = 0.074;
const padBottom = 0.106;

void main() {
  final dest = Directory(destDir);
  if (!dest.existsSync()) {
    stderr.writeln('Missing $destDir');
    exit(1);
  }

  for (var n = 3; n <= 20; n++) {
    final id = n.toString().padLeft(2, '0');
    final source = File('$sourceDir${Platform.pathSeparator}fruit-$id.png');
    if (!source.existsSync()) {
      stderr.writeln('Missing ${source.path}');
      exit(1);
    }
    final raw = img.decodeImage(source.readAsBytesSync());
    if (raw == null) {
      stderr.writeln('Cannot decode ${source.path}');
      exit(1);
    }
    final keyed = _keyBackground(raw);
    final fitted = _fitSquare(keyed);
    final out = File('$destDir/$id.png');
    out.writeAsBytesSync(img.encodePng(fitted));
    stdout.writeln('wrote ${out.path} from ${source.path}');
  }
}

img.Image _keyBackground(img.Image source) {
  final image = source.convert(numChannels: 4);
  final key = _cornerKey(image);
  final background = _floodBackground(image, key);

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (background[y * image.width + x]) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }
  _trimFringe(image, background);
  return image;
}

({double r, double g, double b, int a}) _cornerKey(img.Image image) {
  final corners = [
    image.getPixel(0, 0),
    image.getPixel(image.width - 1, 0),
    image.getPixel(0, image.height - 1),
    image.getPixel(image.width - 1, image.height - 1),
  ];
  var r = 0.0, g = 0.0, b = 0.0, a = 0;
  for (final p in corners) {
    r += p.r;
    g += p.g;
    b += p.b;
    a += p.a.toInt();
  }
  return (r: r / 4, g: g / 4, b: b / 4, a: a ~/ 4);
}

bool _isKey(img.Pixel p, ({double r, double g, double b, int a}) key) {
  if (key.a < 16) return p.a < 16;
  if (p.a < 16) return true;
  final dr = p.r - key.r;
  final dg = p.g - key.g;
  final db = p.b - key.b;
  return math.sqrt(dr * dr + dg * dg + db * db) <= keyTolerance;
}

List<bool> _floodBackground(
  img.Image image,
  ({double r, double g, double b, int a}) key,
) {
  final w = image.width;
  final h = image.height;
  final out = List<bool>.filled(w * h, false);
  final stack = <int>[];

  void offer(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    final i = y * w + x;
    if (out[i]) return;
    if (!_isKey(image.getPixel(x, y), key)) return;
    out[i] = true;
    stack.add(i);
  }

  for (var x = 0; x < w; x++) {
    offer(x, 0);
    offer(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    offer(0, y);
    offer(w - 1, y);
  }

  while (stack.isNotEmpty) {
    final i = stack.removeLast();
    final x = i % w;
    final y = i ~/ w;
    offer(x - 1, y);
    offer(x + 1, y);
    offer(x, y - 1);
    offer(x, y + 1);
  }
  return out;
}

void _trimFringe(img.Image image, List<bool> background) {
  final w = image.width;
  final h = image.height;

  bool touches(int x, int y) {
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        if (background[ny * w + nx]) return true;
      }
    }
    return false;
  }

  final cut = List<bool>.filled(w * h, false);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (background[y * w + x]) continue;
      if (image.getPixel(x, y).a == 0) continue;
      if (touches(x, y)) cut[y * w + x] = true;
    }
  }
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (!cut[i]) continue;
      image.setPixelRgba(x, y, 0, 0, 0, 0);
      background[i] = true;
    }
  }
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (background[y * w + x]) continue;
      if (image.getPixel(x, y).a == 0) continue;
      if (!touches(x, y)) continue;
      final p = image.getPixel(x, y);
      image.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), rimAlpha);
    }
  }
}

img.Image _fitSquare(img.Image source) {
  var left = source.width;
  var top = source.height;
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      if (source.getPixel(x, y).a < 8) continue;
      if (x < left) left = x;
      if (y < top) top = y;
      if (x > right) right = x;
      if (y > bottom) bottom = y;
    }
  }
  if (right < left) {
    return img.Image(width: outSize, height: outSize, numChannels: 4);
  }

  final boxW = right - left + 1;
  final boxH = bottom - top + 1;
  final innerW = outSize * (1 - padX * 2);
  final innerH = outSize * (1 - padTop - padBottom);
  final scale = math.min(innerW / boxW, innerH / boxH);
  final drawW = math.max(1, (boxW * scale).round());
  final drawH = math.max(1, (boxH * scale).round());
  final dx = ((outSize - drawW) / 2).round();
  final dy = (outSize * padTop + (innerH - drawH) / 2).round();

  final cropped = img.copyCrop(
    source,
    x: left,
    y: top,
    width: boxW,
    height: boxH,
  );
  final scaled = img.copyResize(
    cropped,
    width: drawW,
    height: drawH,
    interpolation: img.Interpolation.cubic,
  );
  final out = img.Image(width: outSize, height: outSize, numChannels: 4);
  img.compositeImage(out, scaled, dstX: dx, dstY: dy);
  return out;
}
