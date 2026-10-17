import 'package:flutter/material.dart';

class CrownIcon extends StatelessWidget {
  const CrownIcon({super.key, this.size = 16, this.color = Colors.white});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _CrownPainter(color),
    );
  }
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.08, h * 0.72)
      ..lineTo(w * 0.18, h * 0.34)
      ..lineTo(w * 0.34, h * 0.52)
      ..lineTo(w * 0.50, h * 0.18)
      ..lineTo(w * 0.66, h * 0.52)
      ..lineTo(w * 0.82, h * 0.34)
      ..lineTo(w * 0.92, h * 0.72)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.16, h * 0.76, w * 0.68, h * 0.12),
        Radius.circular(h * 0.04),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _CrownPainter oldDelegate) => oldDelegate.color != color;
}
