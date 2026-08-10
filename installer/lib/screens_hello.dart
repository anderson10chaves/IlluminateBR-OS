import 'dart:async';
import 'package:flutter/material.dart';

class HelloWelcomeScreen extends StatefulWidget {
  const HelloWelcomeScreen({super.key});

  @override
  State<HelloWelcomeScreen> createState() => _HelloWelcomeScreenState();
}

class _HelloWelcomeScreenState extends State<HelloWelcomeScreen> {
  int _languageIndex = 0;
  final List<String> _greetings = [
    'Hello',
    'Bem-vindo',
    'Bienvenido',
    'Bonjour',
    'Willkommen',
    'Ciao',
    'Olá'
  ];

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1800), (timer) {
      if (mounted) {
        setState(() {
          _languageIndex = (_languageIndex + 1) % _greetings.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(opacity: animation, child: child);
              },
              child: Text(
                _greetings[_languageIndex],
                key: ValueKey<String>(_greetings[_languageIndex]),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 2.0,
                  fontFamily: 'sans-serif-light',
                ),
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Começar / Start',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
