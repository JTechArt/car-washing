import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/client_app/discovery/car_wash_card.dart';
import 'package:lva_mobile/core/models/car_wash.dart';

void main() {
  const greenWash = CarWash(
    id: '1', name: 'AutoSpa', address: 'Tigranyan 5',
    lat: 40.18, lng: 44.51,
    availabilityStatus: 'GREEN', nextSlotMinutes: 0,
  );

  testWidgets('CarWashCard shows name and available now label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CarWashCard(carWash: greenWash, onTap: () {})),
    ));
    expect(find.text('AutoSpa'), findsOneWidget);
    expect(find.text('Tigranyan 5'), findsOneWidget);
    expect(find.text('Available now'), findsOneWidget);
  });

  testWidgets('CarWashCard shows fully booked for RED', (tester) async {
    const redWash = CarWash(
      id: '2', name: 'Full Wash', address: 'Addr',
      lat: 40.0, lng: 44.0,
      availabilityStatus: 'RED', nextSlotMinutes: 0,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CarWashCard(carWash: redWash, onTap: () {})),
    ));
    expect(find.text('Fully booked'), findsOneWidget);
  });

  testWidgets('CarWashCard shows wait time for YELLOW', (tester) async {
    const yellowWash = CarWash(
      id: '3', name: 'Busy Wash', address: 'Some St',
      lat: 40.0, lng: 44.0,
      availabilityStatus: 'YELLOW', nextSlotMinutes: 0,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CarWashCard(carWash: yellowWash, onTap: () {})),
    ));
    expect(find.text('< 1 hr wait'), findsOneWidget);
  });
}
