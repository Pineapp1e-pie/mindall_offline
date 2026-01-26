//
//
// import 'package:flutter/material.dart';
//
// class PixelCircle extends StatelessWidget {
//   final double size;
//   final double pixelSize;
//   final Color color;
//   final String text;
//   final double textSize;
//   final String fontText;
//
//   const PixelCircle({
//     super.key,
//     required this.size,
//     required this.color,
//     required this.text,
//     required this.textSize,
//     required this.fontText, required this.pixelSize,
//
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//       width: size,
//       height: size,
//       child: CustomPaint(
//         painter: _PixelCirclePainter(color,   pixelSize,),
//         child: text == null
//             ? null
//             : Center(
//           child: Text(
//             text!,
//             textAlign: TextAlign.center,
//             style: TextStyle(
//
//               fontFamily: fontText ,
//               fontSize: textSize, //'DotGothic'
//               color: Colors.black,
//
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
// }
//
// class _PixelCirclePainter extends CustomPainter {
//   final Color color;
//   final double pixelSize;
//
//   _PixelCirclePainter( this.color,
//       this.pixelSize,);
//
//
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()..color = color;
//     final pixel = pixelSize;//8
//     final centerX = size.width / 2;
//     final centerY = size.height / 2;
// // радиус, кратный пикселю
//     final radius = (size.width / 2 / pixel).floor() * pixel;
//     final radiusSquared = radius * radius;
//
//     for (double x = 0; x < size.width; x += pixel) {
//       for (double y = 0; y < size.height; y += pixel) {
//         final dx = (x + pixel / 2) - centerX;
//         final dy = (y + pixel / 2) - centerY;
//
//         if (dx * dx + dy * dy <= radiusSquared) {
//           canvas.drawRect(
//             Rect.fromLTWH(x, y, pixel, pixel),
//             paint,
//           );
//         }
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(_) => false;
// }



import 'dart:math';
import 'package:flutter/material.dart';

class PixelCircle extends StatelessWidget {
  final double size;
  final double pixelSize;
  final Color color;
  final String text;
  final double textSize;
  final String fontText;

  /// 0 → обычный
  /// 1 → выбранный
  final double highlightProgress;

  const PixelCircle({
    super.key,
    required this.size,
    required this.pixelSize,
    required this.color,
    required this.text,
    required this.textSize,
    required this.fontText,
    this.highlightProgress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PixelCirclePainter(
          color: color,
          pixelSize: pixelSize,
          highlightProgress: highlightProgress,
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: fontText,
              fontSize: textSize,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

class _PixelCirclePainter extends CustomPainter {
  final Color color;
  final double pixelSize;
  final double highlightProgress;

  late final List<_HaloPixel> haloPixels;

  _PixelCirclePainter({
    required this.color,
    required this.pixelSize,
    required this.highlightProgress,
  }) {
    haloPixels = _generateHaloPixels();
  }

  List<_HaloPixel> _generateHaloPixels() {
    final rand = Random();
    final pixels = <_HaloPixel>[];

    const int count = 8; // сколько пикселей вокруг
    for (int i = 0; i < count; i++) {
      pixels.add(
        _HaloPixel(
          angle: rand.nextDouble() * 2 * pi,
          // distanceMultiplier: 1.8 + rand.nextDouble() * 0.6,
          offset: 1 + rand.nextInt(2), // 1 или 2 пикселя

        ),
      );
    }
    return pixels;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final pixel = pixelSize;

    final cx = size.width / 2;
    final cy = size.height / 2;

    final baseRadius =
        (size.width / 2 / pixel).floor() * pixel;
    final baseRadiusSq = baseRadius * baseRadius;

    /// ОСНОВНОЙ КРУГ
    for (double x = 0; x < size.width; x += pixel) {
      for (double y = 0; y < size.height; y += pixel) {
        final dx = (x + pixel / 2) - cx;
        final dy = (y + pixel / 2) - cy;

        if (dx * dx + dy * dy <= baseRadiusSq) {
          canvas.drawRect(
            Rect.fromLTWH(x, y, pixel, pixel),
            paint,
          );
        }
      }
    }

    /// 🌟 РАНДОМНЫЕ ПИКСЕЛИ ВОКРУГ
    if (highlightProgress > 0) {
      final haloPaint = Paint()
        ..color = color;

      for (final p in haloPixels) {
        final r = baseRadius + pixelSize * p.offset;

        final x = cx + cos(p.angle) * r;
        final y = cy + sin(p.angle) * r;

        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(x, y),
            width: pixel,
            height: pixel,
          ),
          haloPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelCirclePainter old) {
    return old.highlightProgress != highlightProgress;
  }
}

class _HaloPixel {
  final double angle;
  final int offset;

  _HaloPixel({
    required this.angle,
    required this.offset,
  });
}
