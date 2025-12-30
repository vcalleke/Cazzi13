import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game.dart';

class RouletteScreen extends StatefulWidget {
  final Game game;
  final int startBalance;

  const RouletteScreen({
    super.key,
    required this.game,
    required this.startBalance,
  });

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen>
    with SingleTickerProviderStateMixin {
  late int balance;
  final Random _rnd = Random();

  // Wheel & animation
  static const int segments = 36; // 1..36 (no green zero for simplicity)
  late AnimationController _controller;
  Animation<double>? _animation;
  double _rotation = 0.0; // current rotation radians
  int? _targetIndex;
  bool spinning = false;

  // Bet
  String? _betColor; // 'red' or 'black'

  @override
  void initState() {
    super.initState();
    balance = widget.startBalance;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _controller.addListener(() {
      if (_animation != null) {
        setState(() => _rotation = _animation!.value);
      }
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSpinEnd();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSpinEnd() {
    spinning = false;
    final landed = _targetIndex ?? 0;
    final landedColor = (landed % 2 == 0) ? 'red' : 'black';
    int delta = -10;
    String message = 'Lost 10 chips';
    if (_betColor != null && _betColor == landedColor) {
      delta = 20;
      message = 'You won +20 chips!';
    }

    setState(() {
      balance += delta;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Result: ${landed + 1} ($landedColor) — $message'),
      ),
    );
  }

  void _spin() {
    if (spinning) return;
    if (_betColor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a color to bet on (Red or Black)'),
        ),
      );
      return;
    }

    spinning = true;
    // choose a random target segment 0..segments-1
    _targetIndex = _rnd.nextInt(segments);

    // compute an end rotation so that the wheel spins several rounds and lands on target
    final segmentAngle = 2 * pi / segments;
    final targetCenterAngle = (_targetIndex! + 0.5) * segmentAngle;

    // We rotate the wheel clockwise but Transform.rotate uses radians positive as clockwise,
    // so add rotations * 2pi then add offset so targetCenterAngle aligns with pointer at -pi/2.
    final rotations = 5 + _rnd.nextInt(3); // 5..7 full spins
    final endRotation = rotations * 2 * pi + (pi / 2) + targetCenterAngle;

    _animation = Tween<double>(
      begin: _rotation,
      end: _rotation + endRotation,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate));
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final headerBg = const Color(0xFFBDBDB0);
    final cardBg = const Color(0xFFE0E0E0);
    final chipYellow = const Color(0xFFF4D03F);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(balance);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text(widget.game.title)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: headerBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          '_Username',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: chipYellow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Chips',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              '$balance',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        widget.game.description,
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 18),

                      // Wheel
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: 260,
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Transform.rotate(
                                      angle: _rotation,
                                      child: CustomPaint(
                                        size: const Size(240, 240),
                                        painter: _WheelPainter(
                                          segments: segments,
                                        ),
                                      ),
                                    ),
                                    // pointer
                                    Positioned(
                                      top: 16,
                                      child: Container(
                                        width: 16,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ChoiceChip(
                                  label: const Text('Red'),
                                  selected: _betColor == 'red',
                                  onSelected: spinning
                                      ? null
                                      : (v) => setState(
                                          () => _betColor = v ? 'red' : null,
                                        ),
                                  selectedColor: Colors.red.shade300,
                                ),
                                const SizedBox(width: 12),
                                ChoiceChip(
                                  label: const Text('Black'),
                                  selected: _betColor == 'black',
                                  onSelected: spinning
                                      ? null
                                      : (v) => setState(
                                          () => _betColor = v ? 'black' : null,
                                        ),
                                  selectedColor: Colors.black12,
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: spinning ? null : _spin,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12.0,
                                  horizontal: 20,
                                ),
                                child: Text(
                                  spinning ? 'Spinning...' : 'SPIN',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),
                            Text(
                              _targetIndex == null
                                  ? 'Choose Red or Black and press SPIN'
                                  : 'Last result: ${_targetIndex! + 1} — ${((_targetIndex! % 2) == 0) ? 'Red' : 'Black'}',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final int segments;

  _WheelPainter({this.segments = 36});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final paint = Paint()..style = PaintingStyle.fill;
    final segmentAngle = 2 * pi / segments;

    // start angle so first segment begins at right and pointer at top
    double startAngle = -pi / 2;

    for (int i = 0; i < segments; i++) {
      final isRed = (i % 2) == 0;
      paint.color = isRed ? Colors.red : Colors.black;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          segmentAngle,
          false,
        )
        ..close();
      canvas.drawPath(path, paint);

      // draw number label
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: Colors.white,
            fontSize: max(10, radius * 0.09),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final angle = startAngle + segmentAngle / 2;
      final textOffset = Offset(
        center.dx + (radius * 0.65) * cos(angle) - textPainter.width / 2,
        center.dy + (radius * 0.65) * sin(angle) - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);

      startAngle += segmentAngle;
    }

    // inner circle for aesthetics
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.2, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
