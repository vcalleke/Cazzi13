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

class _RouletteScreenState extends State<RouletteScreen> {
  late int balance;
  final Random _rnd = Random();
  int? resultNumber;
  bool spinning = false;

  @override
  void initState() {
    super.initState();
    balance = widget.startBalance;
    resultNumber = null;
  }

  Future<void> _spin() async {
    if (spinning) return;
    setState(() => spinning = true);

    // simple spin animation (randomly change number a few times)
    for (var i = 0; i < 12; i++) {
      setState(() => resultNumber = _rnd.nextInt(37));
      await Future.delayed(Duration(milliseconds: 80 + i * 6));
    }

    final n = _rnd.nextInt(37); // 0..36
    setState(() => resultNumber = n);

    // simple payout rules:
    // - jackpot on 7 (+100)
    // - even number => small win (+20)
    // - else lose (-10)
    int delta = -10;
    String message = 'Lost 10 chips';
    if (n == 7) {
      delta = 100;
      message = 'JACKPOT! +100 chips';
    } else if (n % 2 == 0) {
      delta = 20;
      message = '+20 chips (even)';
    }

    setState(() {
      balance += delta;
      spinning = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Result: $n — $message')));
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

                const SizedBox(height: 24),

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

                      // wheel/result
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              resultNumber == null
                                  ? '-'
                                  : resultNumber.toString(),
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              resultNumber == null
                                  ? 'Spin to play'
                                  : (resultNumber! == 7
                                        ? 'Lucky 7!'
                                        : (resultNumber! % 2 == 0
                                              ? 'Even'
                                              : 'Odd')),
                              style: const TextStyle(color: Colors.black),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

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
