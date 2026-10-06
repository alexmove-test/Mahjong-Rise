/// Разряды баллов разделены узким пробелом: 12 450 читается с одного взгляда.
String formatPoints(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) buffer.write('\u2009');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
