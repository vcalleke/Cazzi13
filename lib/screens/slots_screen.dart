import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game.dart';
import '../theme/app_theme.dart';
import 'payment_screen.dart';

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
  String _username = '';
  final random = Random();
  final List<String> _symbols = ['🍒', '🍋', '7️⃣', '🍊', '⭐', '💎', '🔔'];
  List<String> reels = ['', '', ''];
  bool spinning = false;
  int betAmount = 10;
  int totalWins = 0;
  int totalSpins = 0;

  @override
  void initState() {
    super.initState();
    balance = widget.startBalance;
    reels = List.generate(3, (_) => _symbols[random.nextInt(_symbols.length)]);
    _loadUsername();
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

  Future<void> _spin() async {
    if (spinning || balance < betAmount) {
      if (balance < betAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Niet genoeg chips!')),
        );
      }
      return;
    }
    
    setState(() {
      spinning = true;
      balance -= betAmount;
      totalSpins++;
    });

    for (var i = 0; i < 15; i++) {
      setState(() {
        reels = List.generate(3, (_) => _symbols[random.nextInt(_symbols.length)]);
      });
      await Future.delayed(Duration(milliseconds: 80 + i * 8));
    }

    final a = reels[0];
    final b = reels[1];
    final c = reels[2];

    int winAmount = 0;
    String message = 'Verloren!';
    
    if (a == b && b == c) {
      if (a == '💎') {
        winAmount = betAmount * 50;
        message = '💎 MEGA JACKPOT! +$winAmount chips! 💎';
      } else if (a == '7️⃣') {
        winAmount = betAmount * 25;
        message = '🎰 JACKPOT! +$winAmount chips! 🎰';
      } else {
        winAmount = betAmount * 10;
        message = '⭐ Triple! +$winAmount chips! ⭐';
      }
    } else if (a == b || b == c || a == c) {
      winAmount = betAmount * 2;
      message = '✅ Paar! +$winAmount chips!';
    }

    if (winAmount > 0) {
      totalWins++;
    }

    setState(() {
      balance += winAmount;
      spinning = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'balance_${_username.isEmpty ? 'guest' : _username}';
      await prefs.setInt(key, balance);
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: winAmount > 0 ? AppTheme.success : AppTheme.danger,
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _buildPayoutRow(String combo, int payout) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            combo,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.success,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$payout chips',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(balance);
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: Text(widget.game.title)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        color: Colors.black.withValues(alpha: 0.1),
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

                const SizedBox(height: 16),

                // Slots area
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('Spins', '$totalSpins', AppTheme.textDark),
                          _buildStatColumn('Wins', '$totalWins', AppTheme.success),
                          _buildStatColumn('Win%', totalSpins > 0 ? '${((totalWins / totalSpins) * 100).toStringAsFixed(0)}%' : '0%', AppTheme.primary),
                        ],
                      ),
                      
                      const SizedBox(height: 20),

                      // reels - 3 reels
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primary, Colors.blue.shade900],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: reels
                              .map(
                                (s) => Container(
                                  width: 70,
                                  height: 80,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppTheme.accent,
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 3,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    s,
                                    style: const TextStyle(fontSize: 36),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Bet amount selector
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.accent, width: 2),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Inzet per spin',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              alignment: WrapAlignment.center,
                              children: [10, 25, 50, 100].map((amount) {
                                final isSelected = betAmount == amount;
                                return ElevatedButton(
                                  onPressed: spinning ? null : () {
                                    setState(() => betAmount = amount);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected ? AppTheme.accent : Colors.grey.shade300,
                                    foregroundColor: isSelected ? AppTheme.textDark : Colors.black54,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    elevation: isSelected ? 6 : 2,
                                    minimumSize: const Size(60, 36),
                                  ),
                                  child: Text(
                                    '$amount',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      ElevatedButton(
                        onPressed: spinning ? null : _spin,
                        style: ElevatedButton.styleFrom(
                          elevation: 8,
                          shadowColor: Colors.black45,
                          backgroundColor: AppTheme.accent,
                          foregroundColor: AppTheme.textDark,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          spinning ? 'SPINNING...' : '🎰 SPIN 🎰',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Paytable info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber.shade100, Colors.yellow.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.accent, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accent.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '💰 UITBETALINGEN 💰',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Divider(thickness: 2, color: AppTheme.accent, height: 12),
                            _buildPayoutRow('💎💎💎', betAmount * 50),
                            _buildPayoutRow('7️⃣7️⃣7️⃣', betAmount * 25),
                            _buildPayoutRow('🍒🍒🍒', betAmount * 10),
                            _buildPayoutRow('🍋🍋', betAmount * 2),
                          ],
                        ),
                      ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
