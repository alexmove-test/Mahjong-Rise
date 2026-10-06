// Вырезает однотонный ключевой фон у спрайта декора и ставит объект низом
// на дно квадратного кадра — тогда `BoxFit.contain` с `bottomCenter` кладёт
// его основание точно на линию земли.
//
//   dart run tool/cut_prop_background.dart <источник.png> <результат.png>
//
// Цвет ключа берётся из углов кадра, а не из константы: генератор отдаёт то
// чистую мадженту, то насыщенный розовый.

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Допуск по расстоянию в RGB: фон плоский, объекту до ключа далеко.
const keyTolerance = 78.0;

/// Полупрозрачность внешнего ряда, чтобы срез не выглядел вырубленным.
const rimAlpha = 150;

({double r, double g, double b}) _keyColor(img.Image image) {
  final corners = [
    image.getPixel(0, 0),
    image.getPixel(image.width - 1, 0),
    image.getPixel(0, image.height - 1),
    image.getPixel(image.width - 1, image.height - 1),
  ];
  var r = 0.0;
  var g = 0.0;
  var b = 0.0;
  for (final p in corners) {
    r += p.r;
    g += p.g;
    b += p.b;
  }
  return (r: r / corners.length, g: g / corners.length, b: b / corners.length);
}

/// Ключ ищем по всему кадру, а не заливкой от рамки: у качелей фон заперт
/// внутри A-образной рамы и снаружи до него не добраться.
List<bool> _background(img.Image image, ({double r, double g, double b}) key) {
  final out = List<bool>.filled(image.width * image.height, false);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final p = image.getPixel(x, y);
      final dr = p.r - key.r;
      final dg = p.g - key.g;
      final db = p.b - key.b;
      out[y * image.width + x] =
          math.sqrt(dr * dr + dg * dg + db * db) <= keyTolerance;
    }
  }
  return out;
}

/// Пиксели, соседние с фоном, замешаны с цветом ключа — их снимаем, а новый
/// внешний ряд делаем полупрозрачным.
void _trimFringe(img.Image image, List<bool> background) {
  final w = image.width;
  final h = image.height;

  bool touches(List<bool> mask, int x, int y) {
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        final nx = x + dx;
        final ny = y + dy;
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        if (mask[ny * w + nx]) return true;
      }
    }
    return false;
  }

  final cut = List<bool>.filled(w * h, false);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (background[y * w + x]) continue;
      if (touches(background, x, y)) cut[y * w + x] = true;
    }
  }
  final gone = List<bool>.filled(w * h, false);
  for (var at = 0; at < gone.length; at++) {
    gone[at] = background[at] || cut[at];
  }
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final at = y * w + x;
      if (gone[at]) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }
      if (!touches(gone, x, y)) continue;
      final p = image.getPixel(x, y);
      image.setPixelRgba(x, y, p.r, p.g, p.b, rimAlpha);
    }
  }
}

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('usage: cut_prop_background.dart <src.png> <dst.png>');
    exitCode = 64;
    return;
  }
  // Генератор кладёт в файл с расширением .png и JPEG тоже.
  final decoded = img.decodeImage(File(args[0]).readAsBytesSync());
  if (decoded == null) throw StateError('cannot decode ${args[0]}');
  final image = decoded.convert(numChannels: 4, noAnimation: true);

  final key = _keyColor(image);
  final background = _background(image, key);
  _trimFringe(image, background);

  var left = image.width;
  var top = image.height;
  var right = -1;
  var bottom = -1;
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a <= 0) continue;
      left = math.min(left, x);
      right = math.max(right, x);
      top = math.min(top, y);
      bottom = math.max(bottom, y);
    }
  }
  if (right < left) throw StateError('nothing left in ${args[0]}');

  final cropped = img.copyCrop(
    image,
    x: left,
    y: top,
    width: right - left + 1,
    height: bottom - top + 1,
  );
  final side = math.max(cropped.width, cropped.height);
  final canvas = img.Image(width: side, height: side, numChannels: 4);
  img.compositeImage(
    canvas,
    cropped,
    dstX: (side - cropped.width) ~/ 2,
    dstY: side - cropped.height,
  );
  File(args[1]).writeAsBytesSync(img.encodePng(canvas));

  final removed = background.where((v) => v).length;
  stdout.writeln(
    '${args[1]}  key=${key.r.round()},${key.g.round()},${key.b.round()}  '
    'cut=$removed  content=${cropped.width}x${cropped.height}  canvas=$side',
  );
}
