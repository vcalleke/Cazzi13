import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.casino, size: 72, color: Colors.green),
            SizedBox(height: 12),
            Text('Welcome to the Casino', style: TextStyle(fontSize: 20)),
            SizedBox(height: 8),
            Text('This is the app main screen placeholder.'),
          ],
        ),
      ),
    );
  }
}
