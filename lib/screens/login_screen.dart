import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  bool _saving = false;

  Future<void> _saveAndContinue() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', name);
    await prefs.setBool('seenLogin', true);

    if (!mounted) return;
    final context0 = context;
    await showDialog<void>(
      context: context0,
      barrierDismissible: false,
      builder: (ctx) {
        // Start a progress timer to close the dialog and continue
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) Navigator.of(ctx).pop();
        });
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(height: 8),
                CircularProgressIndicator(strokeWidth: 6),
                SizedBox(height: 16),
                Text('Loading app...', style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bg = const Color(0xFFBFBFBF);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header logo text
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                    children: [
                      TextSpan(text: 'CA', style: TextStyle(color: Colors.red[700])),
                      const TextSpan(text: 'ZZI13', style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Big icon
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.casino, size: 84, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 28),

                // Input card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black87, width: 3),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Enter your username',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.done,
                        decoration: InputDecoration(
                          hintText: 'Username',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.black87,
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          onPressed: _saving ? null : _saveAndContinue,
                          child: _saving
                              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Continue'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('By continuing you accept the terms.', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
