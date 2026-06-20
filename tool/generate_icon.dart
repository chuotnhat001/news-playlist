// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

void main() {
  final size = 1024;
  final image = img.Image(width: size, height: size);

  // Background: dark navy gradient
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final t = (x + y) / (2 * size);
      final r = (26 + (22 - 26) * t).round();
      final g = (26 + (33 - 26) * t).round();
      final b = (46 + (62 - 46) * t).round();
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // Draw circle (headphone band) - white arc top half
  final cx = size ~/ 2;
  final cy = 420;
  final radius = 220;
  final thickness = 28;
  for (var angle = 180; angle <= 360; angle++) {
    final rad = angle * pi / 180;
    for (var t = -thickness; t <= thickness; t++) {
      final px = (cx + (radius + t) * cos(rad)).round();
      final py = (cy + (radius + t) * sin(rad)).round();
      if (px >= 0 && px < size && py >= 0 && py < size) {
        image.setPixelRgba(px, py, 255, 255, 255, 255);
      }
    }
  }

  // Left earpiece (rounded rectangle)
  _drawFilledRoundedRect(image, 260, 520, 380, 720, 30, 255, 255, 255);

  // Right earpiece
  _drawFilledRoundedRect(image, 644, 520, 764, 720, 30, 255, 255, 255);

  // Play triangle in center
  _drawFilledTriangle(image, 460, 560, 460, 700, 590, 630, 26, 26, 46);

  // Save full icon
  final pngBytes = img.encodePng(image);
  File('assets/icon/app_icon.png').writeAsBytesSync(pngBytes);
  print('Generated: assets/icon/app_icon.png');

  // Save foreground only (transparent background for adaptive icon)
  final foreground = img.Image(width: size, height: size);
  // Copy only the white pixels from image
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final pixel = image.getPixel(x, y);
      if (pixel.r > 200 && pixel.g > 200 && pixel.b > 200) {
        foreground.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
  }
  final fgBytes = img.encodePng(foreground);
  File('assets/icon/app_icon_foreground.png').writeAsBytesSync(fgBytes);
  print('Generated: assets/icon/app_icon_foreground.png');

  // Splash logo (288x288 from center)
  final splashSize = 288;
  final splash = img.Image(width: splashSize, height: splashSize);
  final offset = (size - splashSize) ~/ 2;
  for (var y = 0; y < splashSize; y++) {
    for (var x = 0; x < splashSize; x++) {
      final pixel = image.getPixel(x + offset, y + offset);
      if (pixel.r > 200 && pixel.g > 200 && pixel.b > 200) {
        splash.setPixelRgba(x, y, 255, 255, 255, 255);
      }
    }
  }
  final splashBytes = img.encodePng(splash);
  File('assets/splash/splash_logo.png').writeAsBytesSync(splashBytes);
  print('Generated: assets/splash/splash_logo.png');
}

void _drawFilledRoundedRect(
  img.Image image,
  int x1, int y1, int x2, int y2, int radius,
  int r, int g, int b,
) {
  for (var y = y1; y <= y2; y++) {
    for (var x = x1; x <= x2; x++) {
      // Check if inside rounded corners
      var inside = true;
      if (x < x1 + radius && y < y1 + radius) {
        inside = _inCircle(x, y, x1 + radius, y1 + radius, radius);
      } else if (x > x2 - radius && y < y1 + radius) {
        inside = _inCircle(x, y, x2 - radius, y1 + radius, radius);
      } else if (x < x1 + radius && y > y2 - radius) {
        inside = _inCircle(x, y, x1 + radius, y2 - radius, radius);
      } else if (x > x2 - radius && y > y2 - radius) {
        inside = _inCircle(x, y, x2 - radius, y2 - radius, radius);
      }
      if (inside) {
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
  }
}

bool _inCircle(int x, int y, int cx, int cy, int r) {
  return (x - cx) * (x - cx) + (y - cy) * (y - cy) <= r * r;
}

void _drawFilledTriangle(
  img.Image image,
  int x1, int y1, int x2, int y2, int x3, int y3,
  int r, int g, int b,
) {
  final minX = [x1, x2, x3].reduce(min);
  final maxX = [x1, x2, x3].reduce(max);
  final minY = [y1, y2, y3].reduce(min);
  final maxY = [y1, y2, y3].reduce(max);

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      if (_pointInTriangle(x, y, x1, y1, x2, y2, x3, y3)) {
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
  }
}

bool _pointInTriangle(int px, int py, int x1, int y1, int x2, int y2, int x3, int y3) {
  final d1 = _sign(px, py, x1, y1, x2, y2);
  final d2 = _sign(px, py, x2, y2, x3, y3);
  final d3 = _sign(px, py, x3, y3, x1, y1);
  final hasNeg = (d1 < 0) || (d2 < 0) || (d3 < 0);
  final hasPos = (d1 > 0) || (d2 > 0) || (d3 > 0);
  return !(hasNeg && hasPos);
}

double _sign(int x1, int y1, int x2, int y2, int x3, int y3) {
  return (x1 - x3) * (y2 - y3) - (x2 - x3) * (y1 - y3).toDouble();
}
