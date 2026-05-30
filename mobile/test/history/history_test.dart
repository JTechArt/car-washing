import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/core/models/booking.dart';

void main() {
  test('Booking.isActive is true for PENDING', () {
    final b = Booking.fromJson({
      'id': '1', 'bayId': 'b1', 'status': 'PENDING',
      'startsAt': '2024-01-01T10:00:00Z', 'endsAt': '2024-01-01T10:25:00Z',
    });
    expect(b.isActive, true);
  });

  test('Booking.isActive is true for WASHING', () {
    final b = Booking.fromJson({
      'id': '2', 'bayId': 'b2', 'status': 'WASHING',
      'startsAt': '2024-01-01T10:00:00Z', 'endsAt': '2024-01-01T10:25:00Z',
    });
    expect(b.isActive, true);
  });

  test('Booking.isActive is false for CANCELLED', () {
    final b = Booking.fromJson({
      'id': '3', 'bayId': 'b3', 'status': 'CANCELLED',
      'startsAt': '2024-01-01T10:00:00Z', 'endsAt': '2024-01-01T10:25:00Z',
    });
    expect(b.isActive, false);
  });
}
