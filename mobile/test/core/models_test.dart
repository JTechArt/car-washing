import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/core/models/car_wash.dart';
import 'package:lva_mobile/core/models/vehicle.dart';
import 'package:lva_mobile/core/models/slot.dart';
import 'package:lva_mobile/core/models/booking.dart';

void main() {
  test('CarWash parses from JSON', () {
    final cw = CarWash.fromJson({
      'id': 'abc',
      'name': 'AutoSpa',
      'address': 'Tigranyan 5',
      'lat': 40.18,
      'lng': 44.51,
      'availabilityStatus': 'GREEN',
      'nextSlotMinutes': 5,
    });
    expect(cw.id, 'abc');
    expect(cw.availabilityStatus, 'GREEN');
    expect(cw.nextSlotMinutes, 5);
  });

  test('Vehicle displayName uses nickname when set', () {
    final v = Vehicle.fromJson({'id': '1', 'plate': 'AM1234', 'type': 'SEDAN', 'nickname': 'My Car'});
    expect(v.displayName, 'My Car');
  });

  test('Vehicle displayName falls back to plate', () {
    final v = Vehicle.fromJson({'id': '2', 'plate': 'AM5678', 'type': 'SUV'});
    expect(v.displayName, 'AM5678');
  });

  test('Booking isActive is false for COMPLETED', () {
    final b = Booking.fromJson({
      'id': 'b1', 'bayId': 'bay1', 'status': 'COMPLETED',
      'startsAt': '2024-01-01T10:00:00Z', 'endsAt': '2024-01-01T10:25:00Z',
    });
    expect(b.isActive, false);
  });

  test('Booking isActive is true for WASHING', () {
    final b = Booking.fromJson({
      'id': 'b2', 'bayId': 'bay1', 'status': 'WASHING',
      'startsAt': '2024-01-01T10:00:00Z', 'endsAt': '2024-01-01T10:25:00Z',
    });
    expect(b.isActive, true);
  });

  test('Slot parses amountAmd', () {
    final s = Slot.fromJson({'startsAt': '2024-01-01T10:00:00Z', 'durationMinutes': 25, 'amountAmd': 3500});
    expect(s.amountAmd, 3500);
    expect(s.durationMinutes, 25);
  });
}
