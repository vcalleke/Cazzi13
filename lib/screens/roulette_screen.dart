import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _username = '';
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
  String? _betParity; // 'even' or 'odd'
  final TextEditingController _amountController = TextEditingController(text: '10');
  final TextEditingController _numberController = TextEditingController();

  final List<_Bet> _bets = [];

  @override
  void initState() {
    super.initState();
    balance = widget.startBalance;
    _loadUsername();
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
    _amountController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('username') ?? '';
    if (!mounted) return;
    final key = 'balance_${name.isEmpty ? 'guest' : name}';
    final stored = prefs.getInt(key);
    setState(() {
      _username = name;
      if (stored != null) balance = stored;
    });
  }

  Future<void> _saveBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'balance_${_username.isEmpty ? 'guest' : _username}';
    await prefs.setInt(key, balance);
  }

  void _onSpinEnd() {
    final landed = _targetIndex ?? 0;
    final landedNumber = landed + 1;
    final landedColor = _colorForIndex(landed);
    final landedParity = _parityForIndex(landed);

    final baseLoss = _bets.fold<int>(0, (sum, b) => sum + b.amount);

    var winnings = 0;
    final hits = <String>[];
    for (final bet in _bets) {
      switch (bet.kind) {
        case 'color':
          if (bet.value == landedColor) {
            winnings += bet.amount * 2;
            hits.add('kleur ${_colorLabel(bet.value)} (+${bet.amount * 2})');
          }
          break;
        case 'parity':
          if (bet.value == landedParity) {
            winnings += bet.amount * 2;
            hits.add('even/oneven ${_parityLabel(bet.value)} (+${bet.amount * 2})');
          }
          break;
        case 'number':
          final target = int.tryParse(bet.value) ?? -1;
          if (target == landedNumber) {
            winnings += bet.amount * 36; // 35:1 + stake
            hits.add('nummer $target (+${bet.amount * 36})');
          }
          break;
      }
    }

    final delta = winnings - baseLoss;
    final msg = hits.isEmpty
        ? 'Verlies $baseLoss chips'
        : 'Raak ${hits.join(' & ')} +$winnings, netto ${delta >= 0 ? '+' : ''}$delta';

    setState(() {
      _spinning = false;
      _rotation = _rotation % (2 * pi);
      balance += delta;
    });
    // persist updated balance
    _saveBalance();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Resultaat: $landedNumber (${_colorLabel(landedColor)}, ${_parityLabel(landedParity)}) — $msg',
        ),
      ),
    );
  }

  void _spin() {
    if (_spinning) return;
    if (_bets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voeg minstens één bet toe.')),
      );
      return;
    }

    final needed = _bets.fold<int>(0, (sum, b) => sum + b.amount);
    if (balance < needed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Onvoldoende chips: inzet $needed, balans $balance')),
      );
      return;
    }

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

  String _colorForIndex(int index) => (index % 2 == 0) ? 'red' : 'black';

  String _parityForIndex(int index) => ((index + 1) % 2 == 0) ? 'even' : 'odd';

  String _colorLabel(String color) => color == 'red' ? 'Rood' : 'Zwart';

  String _parityLabel(String parity) => parity == 'even' ? 'Even' : 'Oneven';

  void _addBet() {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    final numberInput = _numberController.text.trim();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voer een inzetbedrag > 0 in.')),
      );
      return;
    }

    // Determine bet kind priority: number text > color selection > parity selection
    if (numberInput.isNotEmpty) {
      final n = int.tryParse(numberInput);
      if (n == null || n < 1 || n > 36) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nummer moet tussen 1 en 36 liggen.')),
        );
        return;
      }
      setState(() {
        _bets.add(_Bet(kind: 'number', value: '$n', amount: amount));
        _numberController.clear();
      });
      return;
    }

    if (_betColor != null) {
      setState(() {
        _bets.add(_Bet(kind: 'color', value: _betColor!, amount: amount));
      });
      return;
    }

    if (_betParity != null) {
      setState(() {
        _bets.add(_Bet(kind: 'parity', value: _betParity!, amount: amount));
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kies een kleur, even/oneven of nummer.')),
    );
  }

  void _removeBet(int index) {
    setState(() {
      _bets.removeAt(index);
    });
  }

  String _describeBet(_Bet bet) {
    switch (bet.kind) {
      case 'color':
        return 'Kleur ${_colorLabel(bet.value)} - ${bet.amount}';
      case 'parity':
        return 'Even/Oneven ${_parityLabel(bet.value)} - ${bet.amount}';
      case 'number':
        return 'Nummer ${bet.value} - ${bet.amount}';
      default:
        return '${bet.kind} ${bet.value} - ${bet.amount}';
    }
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
                      Expanded(
                        child: Text(
                          _username.isEmpty ? 'Player' : _username,
                          style: const TextStyle(
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
                            textAlign: TextAlign.center,
                          ),
                          if (_spinning) ...[
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SizedBox(
                                height: 200,
                                child: Center(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Transform.rotate(
                                        angle: _rotation,
                                        child: CustomPaint(
                                          size: const Size(180, 180),
                                          painter: _WheelPainter(
                                            segments: _segments,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        child: CustomPaint(
                                          size: const Size(24, 24),
                                          painter: _PointerPainter(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ChoiceChip(
                                label: const Text('Rood'),
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
                                label: const Text('Zwart'),
                                selected: _betColor == 'black',
                                onSelected: _spinning
                                    ? null
                                    : (v) => setState(
                                          () => _betColor = v ? 'black' : null,
                                        ),
                                selectedColor: Colors.black12,
                              ),
                              const SizedBox(width: 12),
                              ChoiceChip(
                                label: const Text('Even'),
                                selected: _betParity == 'even',
                                onSelected: _spinning
                                    ? null
                                    : (v) => setState(
                                          () => _betParity = v ? 'even' : null,
                                        ),
                                selectedColor: Colors.blue.shade200,
                              ),
                              const SizedBox(width: 12),
                              ChoiceChip(
                                label: const Text('Oneven'),
                                selected: _betParity == 'odd',
                                onSelected: _spinning
                                    ? null
                                    : (v) => setState(
                                          () => _betParity = v ? 'odd' : null,
                                        ),
                                selectedColor: Colors.blueGrey.shade200,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _numberController,
                                  enabled: !_spinning,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: const InputDecoration(
                                    labelText: 'Nummer (1-36, optioneel)',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _amountController,
                                  enabled: !_spinning,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.black),
                                  decoration: const InputDecoration(
                                    labelText: 'Inzet bedrag',
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: _spinning ? null : _addBet,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: chipYellow,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                                child: const Text('Voeg bet toe'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_bets.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Bets (${_bets.length}) — totaal inzet: ${_bets.fold<int>(0, (s, b) => s + b.amount)}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (var i = 0; i < _bets.length; i++)
                                    Chip(
                                      label: Text(_describeBet(_bets[i])),
                                      onDeleted: _spinning ? null : () => _removeBet(i),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _spinning ? null : _spin,
                        style: ElevatedButton.styleFrom(
                          elevation: 10,
                          shadowColor: Colors.black45,
                          backgroundColor: chipYellow,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40),
                        ),
                        child: Text(
                          _spinning ? 'Spinning...' : 'SPIN',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _targetIndex == null
                            ? 'Kies kleur, even/oneven of nummer + inzet en druk op SPIN'
                            : 'Laatste: ${_targetIndex! + 1} — ${_colorLabel(_colorForIndex(_targetIndex!))} / ${_parityLabel(_parityForIndex(_targetIndex!))}',
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

class _Bet {
  final String kind; // 'color', 'parity', 'number'
  final String value;
  final int amount;

  _Bet({required this.kind, required this.value, required this.amount});
}
