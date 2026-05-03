import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({super.key, required this.nextScreen});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late AnimationController _ecgController;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _ecgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => widget.nextScreen),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _ecgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 30,
              child: AnimatedBuilder(
                animation: _ecgController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ECGPainter(
                      progress: _ecgController.value,
                      color: Colors.red,
                    ),
                    size: Size(MediaQuery.of(context).size.width, 30),
                  );
                },
              ),
            ),
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _animation.value,
                  child: Image.asset(
                    'assets/img/PFE logo.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class ECGPainter extends CustomPainter {
  final double progress;
  final Color color;

  ECGPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = Path();

    path.moveTo(0, size.height / 2);

    final width = size.width;
    final currentX = width * progress;

    double x = 0;
    double step = width / 8;

    int picNumber = 0;

    while (x < currentX) {
      path.lineTo(x + step * 0.1, size.height / 2);

      if (picNumber == 2) {
        path.lineTo(x + step * 0.2, size.height * 0.05);
        path.lineTo(x + step * 0.3, size.height * 0.95);
      } else {
        path.lineTo(x + step * 0.2, size.height * 0.2);
        path.lineTo(x + step * 0.3, size.height * 0.8);
      }

      path.lineTo(x + step * 0.4, size.height / 2);
      path.lineTo(x + step * 1.0, size.height / 2);

      x += step;
      picNumber++;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
