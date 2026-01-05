import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game.dart';
import 'payment_screen.dart';

class GameScreen extends StatefulWidget {
  final Game game;

  const GameScreen({super.key, required this.game});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int balance = 0;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('username') ?? '';
    final key = 'balance_${name.isEmpty ? 'guest' : name}';
    final stored = prefs.getInt(key) ?? 0;
    if (!mounted) return;
    setState(() {
      _username = name;
      balance = stored;
    });
  }

  Future<void> _saveBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'balance_${_username.isEmpty ? 'guest' : _username}';
    await prefs.setInt(key, balance);
  }

  @override
  Widget build(BuildContext context) {
    const chipYellow = Color(0xFFF4D03F);
    const headerBg = Color(0xFFBDBDB0);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game.title),
        backgroundColor: headerBg,
        actions: [
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
                await _saveBalance();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.game.title,
              style:
                  Theme.of(context).textTheme.titleLarge ??
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(widget.game.description),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Start game (placeholder)')),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }
}
