import 'package:flutter/material.dart';
import '../models/game.dart';

class GameScreen extends StatelessWidget {
  final Game game;

  const GameScreen({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(game.title)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              game.title,
              style:
                  Theme.of(context).textTheme.titleLarge ??
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Text(game.description),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // placeholder action
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
