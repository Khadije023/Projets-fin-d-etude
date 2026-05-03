import 'package:flutter/material.dart';

class HeartBeatLine extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const HeartBeatLine({
    super.key,
    this.width = 200,
    this.height = 50,
    this.color = Colors.red,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _HeartBeatPainter(color),
    );
  }
}

class _HeartBeatPainter extends CustomPainter {
  final Color color;

  _HeartBeatPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final midY = size.height / 2;

    path.moveTo(0, midY);
    path.lineTo(size.width * 0.1, midY);
    path.lineTo(size.width * 0.15, midY - 20);
    path.lineTo(size.width * 0.2, midY + 20);
    path.lineTo(size.width * 0.25, midY - 10);
    path.lineTo(size.width * 0.3, midY);
    path.lineTo(size.width, midY);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
