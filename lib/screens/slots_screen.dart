import 'dart:math';

import 'package:flutter/material.dart';

import '../models/game.dart';

class SlotsScreen extends StatefulWidget {
  final Game game;
  final int startBalance;

  const SlotsScreen({
    super.key,
    required this.game,
    required this.startBalance,
  });

  @override
  State<SlotsScreen> createState() => _SlotsScreenState();
}

class _SlotsScreenState extends State<SlotsScreen> {
  late int balance;
  final Random _rnd = Random();
  final List<String> _symbols = ['🍒', '🍋', '7️⃣', '🍊', '⭐'];
  List<String> reels = ['', '', ''];
  bool spinning = false;

  @override
  void initState() {
    super.initState();
    balance = widget.startBalance;
    reels = List.generate(3, (_) => _symbols[_rnd.nextInt(_symbols.length)]);
  }

  Future<void> _spin() async {
    if (spinning) return;
    setState(() => spinning = true);

    // quick animation: update reels several times
    for (var i = 0; i < 12; i++) {
      setState(() {
        reels = List.generate(
          3,
          (_) => _symbols[_rnd.nextInt(_symbols.length)],
        );
      });
      await Future.delayed(Duration(milliseconds: 80 + i * 5));
    }

    // compute result
    final a = reels[0];
    final b = reels[1];
    final c = reels[2];

    int delta = -10; // default lose
    String message = 'You lost 10 chips';
    if (a == b && b == c) {
      delta = 100;
      message = 'JACKPOT! +100 chips';
    } else if (a == b || b == c || a == c) {
      delta = 20;
      message = '+20 chips';
    }

    setState(() {
      balance += delta;
      spinning = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
                // Header similar to home
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

                // Slots area
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

                      // reels
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: reels
                            .map(
                              (s) => Container(
                                width: 70,
                                height: 70,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 30),
                                ),
                              ),
                            )
                            .toList(),
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
