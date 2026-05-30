import 'package:flutter/material.dart';
class BookingFlowScreen extends StatelessWidget {
  final String carWashId;
  const BookingFlowScreen({super.key, required this.carWashId});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Booking Flow for $carWashId')));
}
