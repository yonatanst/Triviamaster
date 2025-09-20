// lib/src/app.dart
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class TriviaApp extends StatelessWidget {
  const TriviaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Trivia',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const HomeScreen(),
    );
  }
}
