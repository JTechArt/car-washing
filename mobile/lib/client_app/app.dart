import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';

class ClientApp extends ConsumerWidget {
  const ClientApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Lva',
      routerConfig: router,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B4F72),
        useMaterial3: true,
      ),
    );
  }
}
