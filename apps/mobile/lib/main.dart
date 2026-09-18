import 'package:flutter/material.dart';

void main() {
  runApp(const HesablyApp());
}

class HesablyApp extends StatelessWidget {
  const HesablyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hesably',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0A7A3D)),
        useMaterial3: true,
      ),
      home: const PlaceholderPage(),
    );
  }
}

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesably Foundation'),
      ),
      body: const Center(
        child: Text('Flutter Architecture Scaffolding Complete.'),
      ),
    );
  }
}
