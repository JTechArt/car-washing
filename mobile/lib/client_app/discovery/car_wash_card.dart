import 'package:flutter/material.dart';
import '../../core/models/car_wash.dart';

class CarWashCard extends StatelessWidget {
  final CarWash carWash;
  final VoidCallback onTap;

  const CarWashCard({super.key, required this.carWash, required this.onTap});

  Color get _statusColor => switch (carWash.availabilityStatus) {
        'GREEN' => const Color(0xFF27AE60),
        'YELLOW' => const Color(0xFFF39C12),
        _ => const Color(0xFFE74C3C),
      };

  String get _statusLabel => switch (carWash.availabilityStatus) {
        'GREEN' => carWash.nextSlotMinutes == 0
            ? 'Available now'
            : '~${carWash.nextSlotMinutes} min',
        'YELLOW' => '< 1 hr wait',
        _ => 'Fully booked',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_car_wash, color: _statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(carWash.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(carWash.address,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                          color: _statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    Text(_statusLabel,
                        style: TextStyle(
                            color: _statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
