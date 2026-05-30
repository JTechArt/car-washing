import 'package:flutter/material.dart';
class BookingConfirmedScreen extends StatelessWidget {
  final String bookingId;
  final String carWashName;
  const BookingConfirmedScreen({super.key, required this.bookingId, required this.carWashName});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Booking Confirmed!')));
}
