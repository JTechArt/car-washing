import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'garage_provider.dart';

final _typeIcons = {
  'SEDAN': Icons.directions_car,
  'CROSSOVER': Icons.directions_car_filled,
  'SUV': Icons.airport_shuttle,
  'COUPE': Icons.directions_car_outlined,
};

class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(garageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Garage')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/garage/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
        backgroundColor: const Color(0xFF1B4F72),
        foregroundColor: Colors.white,
      ),
      body: vehicles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car_outlined,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No vehicles yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Add your car to start booking',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final v = list[i];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        const Color(0xFF1B4F72).withValues(alpha: 0.1),
                    child: Icon(
                        _typeIcons[v.type] ?? Icons.directions_car,
                        color: const Color(0xFF1B4F72)),
                  ),
                  title: Text(v.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${v.plate} · ${v.type}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
