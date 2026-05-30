import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/moderator_auth_provider.dart';
import 'bays_provider.dart';
import 'bay_card.dart';

class BaysScreen extends ConsumerWidget {
  const BaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baysAsync = ref.watch(baysProvider);
    final notifier = ref.read(baysProvider.notifier);
    final pendingCount = ref.watch(offlinePendingProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4F72),
        foregroundColor: Colors.white,
        title: const Text('Bay Status',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          if (baysAsync.hasValue)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Chip(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                side: BorderSide.none,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Color(0xFF27AE60), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    const Text('Live',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign out',
            onPressed: () =>
                ref.read(moderatorAuthProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner
          if (pendingCount > 0)
            Container(
              color: Colors.orange.shade100,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline — $pendingCount action${pendingCount > 1 ? 's' : ''} queued, will sync on reconnect',
                      style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Bay grid
          Expanded(
            child: baysAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(e.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(baysProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (bays) {
                if (bays.isEmpty) {
                  return const Center(
                    child: Text('No bays configured.',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.05,
                  ),
                  itemCount: bays.length,
                  itemBuilder: (_, i) => BayCard(
                    bay: bays[i],
                    onUpdateStatus: notifier.updateStatus,
                    onWalkIn: notifier.createWalkIn,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
