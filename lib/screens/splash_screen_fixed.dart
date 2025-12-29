import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreenFixed extends StatefulWidget {
  const SplashScreenFixed({super.key});

  @override
  State<SplashScreenFixed> createState() => _SplashScreenFixedState();
}

class _SplashScreenFixedState extends State<SplashScreenFixed> {
  double _progress = 0.0;
  Timer? _timer;
  bool _seenLogin = false;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      setState(() {
        _progress += 0.03;
        if (_progress >= 1.0) {
          _progress = 1.0;
          _timer?.cancel();
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            if (_seenLogin) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            }
          });
        }
      });
    });
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('seenLogin') ?? false;
    final name = prefs.getString('username') ?? '';
    if (!mounted) return;
    setState(() {
      _seenLogin = seen;
      _username = name;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFBFBFBF);
    final lavender = const Color(0xFFEADCF7);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Center(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    children: [
                      TextSpan(text: 'CA', style: TextStyle(color: Colors.red[700])),
                      const TextSpan(text: 'ZZI13', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Container(
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.grey[350],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.casino, size: 92, color: Colors.black87),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Container(
                height: 320,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black87, width: 4),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _username.isEmpty ? 'Welcome back _USERNAME' : 'Welcome back $_username',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CustomPaint(
                        painter: _RingPainter(progress: _progress, lavender: lavender),
                        child: const Center(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text('Shuffling cards and counting ships...', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color lavender;

  _RingPainter({required this.progress, required this.lavender});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 6;

    final bgPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final arcPaint = Paint()
      ..color = lavender
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final blackPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final startAngle = -3.14 / 2; // start at top
    final sweep = 2 * 3.141592653589793 * progress;

    // draw lavender arc for progress
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle,
        sweep, false, arcPaint);

    // draw a small black accent at the end of the arc (if progress > 0)
    if (progress > 0.02) {
      final accentSweep = 2 * 3.141592653589793 * (0.06); // small segment
      final accentStart = startAngle + sweep - accentSweep;
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), accentStart,
          accentSweep, false, blackPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.lavender != lavender;
  }
}
