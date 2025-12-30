import 'package:flutter/material.dart';

import '../data/games.dart';
import 'game_screen.dart';
import 'slots_screen.dart';
import 'roulette_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int balance = 1000; // initial chips/credits

  @override
  Widget build(BuildContext context) {
    final headerBg = const Color(0xFFBDBDB0); // muted khaki/grey from mock
    final cardBg = const Color(0xFFE0E0E0); // light grey for game cards
    final chipYellow = const Color(0xFFF4D03F);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              // Top header with username and chips pill
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: headerBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Username text left
                    Expanded(
                      child: Text(
                        '_Username',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),

                    // Chips amount pill on right
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: chipYellow,
                        borderRadius: BorderRadius.circular(12),
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

              // Centered title
              const Text(
                'Games',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 14),

              // Game list
              Expanded(
                child: ListView.builder(
                  itemCount: games.length,
                  padding: const EdgeInsets.only(top: 8),
                  itemBuilder: (context, index) {
                    final g = games[index];
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          if (g.id == 'slots') {
                            final res = await Navigator.of(context).push<int?>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    SlotsScreen(game: g, startBalance: balance),
                              ),
                            );
                            if (res != null) setState(() => balance = res);
                          } else if (g.id == 'roulette') {
                            final res = await Navigator.of(context).push<int?>(
                              MaterialPageRoute(
                                builder: (_) => RouletteScreen(
                                  game: g,
                                  startBalance: balance,
                                ),
                              ),
                            );
                            if (res != null) setState(() => balance = res);
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => GameScreen(game: g),
                              ),
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 18.0,
                            ),
                            child: Row(
                              children: [
                                // Title on left
                                Expanded(
                                  child: Text(
                                    g.title.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),

                                // Right-side small button label
                                TextButton(
                                  onPressed: () async {
                                    if (g.id == 'slots') {
                                      final res = await Navigator.of(context)
                                          .push<int?>(
                                            MaterialPageRoute(
                                              builder: (_) => SlotsScreen(
                                                game: g,
                                                startBalance: balance,
                                              ),
                                            ),
                                          );
                                      if (res != null)
                                        setState(() => balance = res);
                                    } else if (g.id == 'roulette') {
                                      final res = await Navigator.of(context)
                                          .push<int?>(
                                            MaterialPageRoute(
                                              builder: (_) => RouletteScreen(
                                                game: g,
                                                startBalance: balance,
                                              ),
                                            ),
                                          );
                                      if (res != null)
                                        setState(() => balance = res);
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => GameScreen(game: g),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    '(Button)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
