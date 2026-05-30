import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import 'discovery_provider.dart';
import 'car_wash_card.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carWashes = ref.watch(discoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Car Wash'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: carWashes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.read(discoveryProvider.notifier).reload(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (washes) {
          if (washes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_car_wash, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No car washes available yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.read(discoveryProvider.notifier).reload(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: washes.length,
              itemBuilder: (_, i) => CarWashCard(
                carWash: washes[i],
                onTap: washes[i].availabilityStatus == 'RED'
                    ? () {}
                    : () => context.push('/booking/${washes[i].id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}
