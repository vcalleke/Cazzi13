import 'dart:math';

import 'package:flutter/material.dart';
import 'package:cazzi13/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_screen.dart';

class AceRaceScreen extends StatefulWidget {
  final int startBalance;

  const AceRaceScreen({super.key, required this.startBalance});

  @override
  State<AceRaceScreen> createState() => _AceRaceScreenState();
}

class _AceRaceScreenState extends State<AceRaceScreen> {
  // deel een presentatie
  static const horses = [
    '⚡ White Lightning',
    '⚫ Blackthunder',
    '🌿 Green Blaze',
    '🔥 Pablo',
  ];
  static const finishLine = 35; // afstand tot finish line
  final Map<String, int> positions = {
    for (var h in horses) h: 0,
  }; // start posities op 0 zetten
  String? selectedHorse;
  int bet = 10;
  int balance = 0;
  String _username = '';
  String message = '';
  String commentary = '';
  bool racing = false; //zijn we aan het racen?
  final rng = Random();
  DateTime? _lastCommentaryTime;

  @override
  void initState() {
    super.initState();
    balance = widget.startBalance;
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('username') ?? '';
    final key = 'balance_${name.isEmpty ? 'guest' : name}';
    final stored = prefs.getInt(key);
    if (!mounted) return;
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

  void _startRace() async {
    if (selectedHorse == null) {
      setState(() => message = 'Kies eerst een paard om op in te zetten!');
      return;
    }

    if (balance < bet) {
      setState(() => message = 'Niet genoeg chips! Je hebt $balance chips.');
      return;
    }
    //Deel 3 ---------------------------------------------------------------------------------------------------------------------------------
    // Trek inzet af aan het begin
    setState(() {
      racing = true; //past status aan
      balance -= bet;
      _lastCommentaryTime = DateTime.now();
      for (var h in horses) positions[h] = 0; // reset posities
      message = 'De race is begonnen!';
      commentary = '🏁 En ze zijn weg!';
    });

    await _saveBalance(); // Save immediately after deducting bet

    // Race loop Deel 4 ---------------------------------------------------------------------------------------------------------------------------------
    while (true) {
      await Future.delayed(const Duration(milliseconds: 1000));

      bool hasWinner = false; //checkt voor winnar

      setState(() {
        Map<String, int> moves = {};
        for (var h in horses) {
          final move = rng.nextInt(3) + 1;
          moves[h] = move;
          positions[h] =
              (positions[h] ?? 0) +
              move; //doet voor elk horse een move 1-3 en update die positie

          if (positions[h]! >= finishLine) {
            hasWinner = true; //check for winner
          }
        }

        // Commentaar elke 4.5 seconden oo
        if (_lastCommentaryTime != null &&
            DateTime.now().difference(_lastCommentaryTime!).inMilliseconds >=
                4500) {
          commentary = _generateCommentary(moves);
          _lastCommentaryTime =
              DateTime.now(); // als de tijd (4.5 sec) is verstreken, update commentaarS
        }
      });

      if (hasWinner) {
        // Find winner (highest position)
        final winner = positions.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;

        final won = winner == selectedHorse; //true als speler heeft gewonnen
        setState(() {
          racing = false;
          if (won) {
            // Add winnings (bet was already deducted, so add total payout)
            balance +=
                bet * 4; // 4x because bet was already deducted, so net is 4x
          }
          // If lost, bet was already deducted, so do nothing
          message = won
              ? '🎉 Gewonnen! $winner wint — je wint ${bet * 4} chips! (inzet teruggekregen + ${bet * 3} winst)'
              : '😞 Verloren — $winner wint. Je verliest $bet chips.';
          commentary = '🏆 $winner kruist de finish!';
        });
        await _saveBalance();
        break;
      }
    }
  }

  String _generateCommentary(Map<String, int> moves) {
    // Sorteer paarden op positie
    final sorted = positions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final leader = sorted[0].key;
    final lastPlace = sorted[3].key;

    final commentaries = [
      '💨 $leader is aan de leiding!',
      '🔥 $leader neemt de kop!',
      '😰 $lastPlace blijft achter!',
      '⚡ $leader maakt snelheid!',
      '🐌 $lastPlace vertraagt nu even!',
      '👀 Het is nog spannend!',
      '💪 ${sorted[1].key} probeert in te halen!',
      '🎯 $leader houdt de leiding vast!',
    ];

    // Extra commentaar voor grote sprongen
    for (var entry in moves.entries) {
      if (entry.value == 3) {
        return '🚀 ${entry.key} maakt een enorme sprong!';
      }
    }

    return commentaries[rng.nextInt(commentaries.length)];
  }

  void _resetRace() {
    setState(() {
      for (var h in horses) positions[h] = 0;
      selectedHorse = null;
      message = '';
      commentary = '';
      racing = false;
      _lastCommentaryTime = null;
    });
  }

  Widget _buildLane(String horse) {
    final pos = positions[horse] ?? 0;
    final progress = (pos / finishLine).clamp(0.0, 1.0);

    // Different colors for each horse
    Color laneColor;
    if (horse.contains('White')) {
      laneColor = Colors.blue.shade100;
    } else if (horse.contains('Black')) {
      laneColor = Colors.grey.shade300;
    } else if (horse.contains('Green')) {
      laneColor = Colors.green.shade100;
    } else {
      laneColor = Colors.orange.shade100;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: selectedHorse == horse
                      ? Colors.amber.shade400
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedHorse == horse
                        ? Colors.amber.shade700
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: Text(
                  horse,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: selectedHorse == horse
                        ? Colors.black
                        : Colors.black87,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Text(
                  '$pos/$finishLine',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: laneColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade500, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              // Progress indicator
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accent.withOpacity(0.3),
                        AppTheme.accent.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              // Horse emoji - same for all
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 50,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 6),
                  child: const Text('🏇', style: TextStyle(fontSize: 32)),
                ),
              ),
              // Finish line
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black, Colors.white, Colors.black],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const headerBg = AppTheme.cardBg;
    const chipYellow = AppTheme.accent;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(balance);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('🏇 Paarden Race'),
          backgroundColor: AppTheme.primary,
        ),
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
                        child: Container(
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Kies je paard:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          //Deel 2 uitleg pretensatie ---------------------------------------------------------------------------------------------
                          spacing: 8,
                          runSpacing: 8,
                          children: horses.map((h) {
                            final isSelected = selectedHorse == h;
                            return ChoiceChip(
                              label: Text(h),
                              selected: isSelected,
                              labelStyle: const TextStyle(color: Colors.black),
                              selectedColor: AppTheme.accent,
                              backgroundColor: AppTheme.primary,
                              visualDensity: VisualDensity.compact,
                              onSelected: racing
                                  ? null
                                  : (_) => setState(
                                      () => selectedHorse = h,
                                    ), //zet een paard als geselecteerd
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 16),

                        _buildLane(horses[0]),
                        _buildLane(horses[1]),
                        _buildLane(horses[2]),
                        _buildLane(horses[3]),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            const Text(
                              'Inzet:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Slider(
                                value: bet.toDouble(),
                                min: 10,
                                max: 100,
                                divisions: 9,
                                activeColor: AppTheme.accent,
                                label: bet.toString(),
                                onChanged: racing
                                    ? null
                                    : (v) => setState(() => bet = v.toInt()),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$bet chips',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (commentary.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.orange.shade300,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '📢 ',
                                  style: TextStyle(fontSize: 18),
                                ),
                                Expanded(
                                  child: Text(
                                    commentary,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (message.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: message.contains('Gewonnen')
                                  ? Colors.green.shade100
                                  : message.contains('Verloren')
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: message.contains('Gewonnen')
                                    ? Colors.green
                                    : message.contains('Verloren')
                                    ? Colors.red
                                    : Colors.blue,
                                width: 2,
                              ),
                            ),
                            child: Text(
                              message,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: racing ? null : _startRace,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: Text(
                                  racing ? 'Race bezig...' : '🏁 Start Race!',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: racing ? null : _resetRace,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 16,
                                ),
                              ),
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
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
