import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: ModeratorApp()));
}

class ModeratorApp extends StatelessWidget {
  const ModeratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lva Moderator',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B4F72),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('Lva Moderator App'))),
    );
  }
}
