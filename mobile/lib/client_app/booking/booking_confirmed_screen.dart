import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookingConfirmedScreen extends StatelessWidget {
  final String bookingId;
  final String carWashName;

  const BookingConfirmedScreen({
    super.key,
    required this.bookingId,
    required this.carWashName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    size: 56, color: Colors.green.shade600),
              ),
              const SizedBox(height: 28),
              const Text('Booking Confirmed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text(
                'Head to the car wash — your bay will be ready',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _row(
                        'Booking ID',
                        bookingId.length > 8
                            ? '#${bookingId.substring(0, 8).toUpperCase()}…'
                            : '#${bookingId.toUpperCase()}'),
                    const Divider(height: 20),
                    _row('Status', 'Pending — head over any time'),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/bookings'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4F72),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('View My Bookings',
                    style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back to Find'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
}
