import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';

class ModeratorApp extends ConsumerWidget {
  const ModeratorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(moderatorRouterProvider);
    return MaterialApp.router(
      title: 'Lva Moderator',
      routerConfig: router,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B4F72),
        useMaterial3: true,
      ),
    );
  }
}
