import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cazzi13/theme/app_theme.dart';

class AceRaceScreen extends StatefulWidget {
  const AceRaceScreen({super.key});

  @override
  State<AceRaceScreen> createState() => _AceRaceScreenState();
}

class _AceRaceScreenState extends State<AceRaceScreen> {
  static const suits = ['Harten', 'Koeken', 'Schoppen', 'Klaveren'];
  final Map<String, int> positions = {for (var s in suits) s: 0};
  String? selectedSuit;
  int bet = 1;
  late List<String> deck;
  String lastDraw = '';
  String message = '';
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _resetDeck();
  }

  void _resetDeck() {
    deck = [];
    const ranks = [
      'A',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K',
    ];
    final suitsShort = ['H', 'D', 'S', 'C'];
    for (var s in suitsShort) {
      for (var r in ranks) {
        deck.add('$r-$s');
      }
    }
    deck.shuffle(_rand);
    for (var s in suits) positions[s] = 0;
    selectedSuit = null;
    lastDraw = '';
    message = '';
  }

  String _drawCard() {
    if (deck.isEmpty) _resetDeck();
    return deck.removeLast();
  }

  void _onDraw() {
    if (selectedSuit == null) {
      setState(() => message = 'Kies eerst een aas om op in te zetten.');
      return;
    }

    setState(() {
      final card = _drawCard();
      lastDraw = card;
      final suitChar = card.split('-').last; // H, D, S, C
      String movedSuit;
      switch (suitChar) {
        case 'H':
          movedSuit = 'Harten';
          break;
        case 'D':
          movedSuit = 'Koeken';
          break;
        case 'S':
          movedSuit = 'Schoppen';
          break;
        default:
          movedSuit = 'Klaveren';
      }

      positions[movedSuit] = (positions[movedSuit] ?? 0) + 1;
      message = '$movedSuit krijgt 1 stap (kaart: $card)';

      final winner = positions.entries.firstWhere(
        (e) => e.value >= 5,
        orElse: () => const MapEntry('', 0),
      );

      if (winner.key != '') {
        final won = winner.key == selectedSuit;
        final payout = won ? bet * 4 : 0;
        message = won
            ? 'Gewonnen! ${winner.key} won — uitbetaling: ${payout}x'
            : 'Verloren — ${winner.key} won. Uitbetaling: 0';
      }
    });
  }

  void _resetRace() {
    setState(() {
      for (var s in suits) positions[s] = 0;
      selectedSuit = null;
      lastDraw = '';
      message = '';
      _resetDeck();
    });
  }

  Widget _buildLane(String suit) {
    final pos = positions[suit] ?? 0;
    final tiles = List.generate(5, (i) => i < pos);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(suit, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          children: tiles
              .map(
                (filled) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    height: 28,
                    decoration: BoxDecoration(
                      color: filled ? AppTheme.accent : AppTheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ace Race'),
        backgroundColor: AppTheme.primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: suits.map((s) {
                    final isSelected = selectedSuit == s;
                    return ChoiceChip(
                      label: Text(s),
                      selected: isSelected,
                      labelStyle: TextStyle(color: Colors.black),
                      selectedColor: AppTheme.accent,
                      backgroundColor: AppTheme.primary,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => selectedSuit = s),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                _buildLane(suits[0]),
                const SizedBox(height: 8),
                _buildLane(suits[1]),
                const SizedBox(height: 8),
                _buildLane(suits[2]),
                const SizedBox(height: 8),
                _buildLane(suits[3]),

                const SizedBox(height: 12),

                Row(
                  children: [
                    const Text('Inzet:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: bet.toDouble(),
                        min: 1,
                        max: 100,
                        divisions: 99,
                        activeColor: AppTheme.accent,
                        label: bet.toString(),
                        onChanged: (v) => setState(() => bet = v.toInt()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$bet'),
                  ],
                ),

                const SizedBox(height: 8),
                Text('Laatste kaart: $lastDraw'),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accent,
                  ),
                ),

                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onDraw,
                        child: const Text('Trek kaart'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _resetRace,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
