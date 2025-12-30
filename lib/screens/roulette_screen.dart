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
  final _rnd = Random();

  // Wheel
  static const int _segments = 36; // simple 36-segment wheel (no zero)
  late final AnimationController _controller;
  Animation<double>? _animation;
  double _rotation = 0.0; // radians
  int? _targetIndex;
  bool _spinning = false;

  // Bet
  String? _betColor; // 'red' or 'black'

  @override
  void initState() {
    super.initState();
    balance = widget.startBalance;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    _controller.addListener(() {
      if (_animation != null) setState(() => _rotation = _animation!.value);
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) _onSpinEnd();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSpinEnd() {
    final landed = _targetIndex ?? 0;
    final landedColor = (landed % 2 == 0) ? 'red' : 'black';
    var delta = -10;
    var msg = 'Lost 10 chips';
    if (_betColor != null && _betColor == landedColor) {
      delta = 20;
      msg = 'You won +20 chips!';
    }
    setState(() {
      _spinning = false;
      _rotation = _rotation % (2 * pi);
      balance += delta;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Result: ${landed + 1} ($landedColor) — $msg')),
    );
  }

  void _spin() {
    if (_spinning) return;

    final chosen = _rnd.nextInt(_segments);
    setState(() {
      _spinning = true;
      _targetIndex = chosen;
    });

    final segAngle = 2 * pi / _segments;
    final targetCenter = (chosen + 0.5) * segAngle;
    final rotations = 5 + _rnd.nextInt(3); // 5..7
    final desired = -targetCenter + rotations * 2 * pi;

    _animation = Tween<double>(
      begin: _rotation,
      end: _rotation + desired,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate));
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    const headerBg = Color(0xFFBDBDB0);
    const cardBg = Color(0xFFE0E0E0);
    const chipYellow = Color(0xFFF4D03F);

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(balance);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.game.title)),
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with balance
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

                const SizedBox(height: 16),

                // Wheel area (scrollable so controls remain tappable on small screens)
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
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

                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SizedBox(
                              height: 240,
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Transform.rotate(
                                      angle: _rotation,
                                      child: CustomPaint(
                                        size: const Size(220, 220),
                                        painter: _WheelPainter(
                                          segments: _segments,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      child: CustomPaint(
                                        size: const Size(28, 28),
                                        painter: _PointerPainter(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Fixed bottom controls
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Red'),
                            selected: _betColor == 'red',
                            onSelected: _spinning
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
                            onSelected: _spinning
                                ? null
                                : (v) => setState(
                                    () => _betColor = v ? 'black' : null,
                                  ),
                            selectedColor: Colors.black12,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _spinning ? null : _spin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: chipYellow,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 40,
                          ),
                        ),
                        child: Text(
                          _spinning ? 'Spinning...' : 'SPIN',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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
    final segAngle = 2 * pi / segments;

    var start = -pi / 2; // pointer at top
    for (var i = 0; i < segments; i++) {
      paint.color = (i % 2 == 0) ? Colors.red : Colors.black;
      final path = Path()..moveTo(center.dx, center.dy);
      path.arcTo(
        Rect.fromCircle(center: center, radius: radius),
        start,
        segAngle,
        false,
      );
      path.close();
      canvas.drawPath(path, paint);

      // label toward rim
      final label = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: Colors.white,
            fontSize: max(10, radius * 0.08),
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      label.layout();
      final mid = start + segAngle / 2;
      final textPos = Offset(
        center.dx + (radius * 0.82) * cos(mid) - label.width / 2,
        center.dy + (radius * 0.82) * sin(mid) - label.height / 2,
      );
      label.paint(canvas, textPos);

      start += segAngle;
    }

    // small inner circle
    canvas.drawCircle(center, radius * 0.12, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
