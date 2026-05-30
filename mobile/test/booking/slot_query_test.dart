import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/client_app/booking/booking_provider.dart';

void main() {
  test('SlotQuery equality works for FutureProvider.family caching', () {
    const q1 = SlotQuery(
        carWashId: 'abc', vehicleType: 'SEDAN', serviceType: 'EXTERIOR');
    const q2 = SlotQuery(
        carWashId: 'abc', vehicleType: 'SEDAN', serviceType: 'EXTERIOR');
    const q3 = SlotQuery(
        carWashId: 'abc', vehicleType: 'SUV', serviceType: 'EXTERIOR');
    expect(q1, equals(q2));
    expect(q1, isNot(equals(q3)));
  });
}
