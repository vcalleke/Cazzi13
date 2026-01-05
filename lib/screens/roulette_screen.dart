import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game.dart';
import '../theme/app_theme.dart';
import 'payment_screen.dart';

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
  final rng = Random();

  static const int _segments = 36;
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
      duration: const Duration(milliseconds: 12000),
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
            hits.add('Kleur ${_colorLabel(landedColor)}');
          }
        case 'parity':
          if (bet.value == landedParity) {
            winnings += bet.amount * 2;
            hits.add('Even/Oneven ${_parityLabel(landedParity)}');
          }
        case 'number':
          if (int.parse(bet.value) == landedNumber) {
            winnings += bet.amount * 36;
            hits.add('Nummer $landedNumber');
          }
      }
    }

    final delta = winnings - baseLoss;
    setState(() {
      balance += delta;
      _spinning = false;
    });
    _saveBalance();

    final message = delta >= 0
        ? 'Je wint ${delta} chips! ${hits.isNotEmpty ? hits.join(", ") : ""}'
        : 'Je verliest ${delta.abs()} chips!';

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _spin() {
    if (_bets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Je moet minstens 1 bet doen!')),
      );
      return;
    }

    final totalBet = _bets.fold<int>(0, (sum, b) => sum + b.amount);
    if (totalBet > balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Je hebt niet genoeg chips!')),
      );
      return;
    }

    setState(() {
      _spinning = true;
      _targetIndex = rng.nextInt(_segments);
    });

    _animation = Tween<double>(begin: 0, end: (2 * pi * 5) + (_targetIndex! * (2 * pi / _segments))).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward(from: 0);
  }

  void _addBet() {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Het inzet bedrag moet groter zijn dan 0.')),
      );
      return;
    }

    final numberInput = _numberController.text.trim();

    // Priority: number > color > parity
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
        _amountController.clear();
        _amountController.text = '10';
      });
      return;
    }

    if (_betColor != null) {
      setState(() {
        _bets.add(_Bet(kind: 'color', value: _betColor!, amount: amount));
        _amountController.clear();
        _amountController.text = '10';
      });
      return;
    }

    if (_betParity != null) {
      setState(() {
        _bets.add(_Bet(kind: 'parity', value: _betParity!, amount: amount));
        _amountController.clear();
        _amountController.text = '10';
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voer een nummer in (1-36) of kies een kleur/even/oneven.')),
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

  String _describeBetShort(_Bet bet) {
    switch (bet.kind) {
      case 'color':
        return '${_colorLabel(bet.value)} - ${bet.amount}';
      case 'parity':
        return '${_parityLabel(bet.value)} - ${bet.amount}';
      case 'number':
        return '${bet.value} - ${bet.amount}';
      default:
        return '${bet.value} - ${bet.amount}';
    }
  }

  String _colorForIndex(int index) {
    final number = index + 1;
    // Real roulette color distribution
    const redNumbers = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36];
    return redNumbers.contains(number) ? 'red' : 'black';
  }

  String _parityForIndex(int index) {
    return ((index + 1) % 2 == 0) ? 'even' : 'odd';
  }

  String _colorLabel(String color) => color == 'red' ? 'Rood' : 'Zwart';
  String _parityLabel(String parity) => parity == 'even' ? 'Even' : 'Oneven';

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(balance);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(title: Text(widget.game.title)),
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_spinning) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _username.isEmpty ? 'Player' : _username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => PaymentScreen(
                                  currentBalance: balance,
                                  username: _username,
                                ),
                              ),
                            );
                            if (result != null) {
                              setState(() => balance = result);
                              final prefs = await SharedPreferences.getInstance();
                              final key = 'balance_${_username.isEmpty ? 'guest' : _username}';
                              await prefs.setInt(key, balance);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Chips',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                Text(
                                  '$balance',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                ],

                // Main scrollable area (wheel + controls)
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Wheel area
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
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
                                              painter: _WheelPainter(segments: _segments),
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

                        const SizedBox(height: 12),

                        // Bottom controls (hidden during spin)
                        if (!_spinning) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                            child: Column(
                              children: [
                                Column(
                                  children: [
                                    Text('Kies je inzet type:', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.black) ?? const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      alignment: WrapAlignment.center,
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        ChoiceChip(
                                          label: const Text('Rood'),
                                          selected: _betColor == 'red',
                                          onSelected: _spinning ? null : (v) => setState(() {
                                            _betColor = v ? 'red' : null;
                                            if (v) _betParity = null;
                                          }),
                                          selectedColor: Colors.grey.shade600,
                                          backgroundColor: Colors.grey.shade400,
                                        ),
                                        ChoiceChip(
                                          label: const Text('Zwart'),
                                          selected: _betColor == 'black',
                                          onSelected: _spinning ? null : (v) => setState(() {
                                            _betColor = v ? 'black' : null;
                                            if (v) _betParity = null;
                                          }),
                                          selectedColor: Colors.grey.shade600,
                                          backgroundColor: Colors.grey.shade400,
                                        ),
                                        ChoiceChip(
                                          label: const Text('Even'),
                                          selected: _betParity == 'even',
                                          onSelected: _spinning ? null : (v) => setState(() {
                                            _betParity = v ? 'even' : null;
                                            if (v) _betColor = null;
                                          }),
                                          selectedColor: Colors.grey.shade600,
                                          backgroundColor: Colors.grey.shade400,
                                        ),
                                        ChoiceChip(
                                          label: const Text('Oneven'),
                                          selected: _betParity == 'odd',
                                          onSelected: _spinning ? null : (v) => setState(() {
                                            _betParity = v ? 'odd' : null;
                                            if (v) _betColor = null;
                                          }),
                                          selectedColor: Colors.grey.shade600,
                                          backgroundColor: Colors.grey.shade400,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.yellow.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.black, width: 2),
                                      ),
                                      child: Column(
                                        children: [
                                          Text('Of kies een specifiek nummer:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                                          const SizedBox(height: 12),
                                          TextField(
                                            controller: _numberController,
                                            enabled: !_spinning,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                                            decoration: InputDecoration(
                                              labelText: 'Nummer (1 tot 36)',
                                              labelStyle: const TextStyle(color: Colors.black87, fontSize: 14),
                                              hintText: 'bijv. 17',
                                              hintStyle: const TextStyle(color: Colors.black38),
                                              border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                                              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                                              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 3)),
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.black, width: 2),
                                      ),
                                      child: Column(
                                        children: [
                                          Text('Inzet bedrag:', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                                          const SizedBox(height: 12),
                                          TextField(
                                            controller: _amountController,
                                            enabled: !_spinning,
                                            keyboardType: TextInputType.number,
                                            style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                                            decoration: InputDecoration(
                                              labelText: 'Hoeveel chips inzetten?',
                                              labelStyle: const TextStyle(color: Colors.black87, fontSize: 14),
                                              hintText: '10',
                                              hintStyle: const TextStyle(color: Colors.black38),
                                              border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                                              enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 2)),
                                              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.blue, width: 3)),
                                              filled: true,
                                              fillColor: Colors.white,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          ElevatedButton(onPressed: _spinning ? null : _addBet, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: AppTheme.textDark, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)), child: const Text('Voeg deze bet toe')),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        if (_bets.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.grey.shade800, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Bets (${_bets.length}) — totaal inzet: ${_bets.fold<int>(0, (s, b) => s + b.amount)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Wrap(spacing: 8, runSpacing: 8, children: [for (var i = 0; i < _bets.length; i++) Chip(label: Text(_spinning ? _describeBetShort(_bets[i]) : _describeBet(_bets[i]), style: const TextStyle(color: Colors.black)), backgroundColor: Colors.grey.shade300, onDeleted: _spinning ? null : () => _removeBet(i))]),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _spinning ? null : _spin, style: ElevatedButton.styleFrom(elevation: 10, shadowColor: Colors.black45, backgroundColor: AppTheme.accent, foregroundColor: AppTheme.textDark, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 40)), child: Text(_spinning ? 'Spinning...' : 'SPIN', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                        const SizedBox(height: 8),
                        Text(_targetIndex == null ? 'Kies kleur, even/oneven of nummer + inzet en druk op SPIN' : 'Laatste: ${_targetIndex! + 1} — ${_colorLabel(_colorForIndex(_targetIndex!))} / ${_parityLabel(_parityForIndex(_targetIndex!))}', style: const TextStyle(color: Colors.black)),
                      ],
                    ),
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
