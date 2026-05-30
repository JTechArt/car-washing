import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/moderator_app/models/moderator_bay.dart';

void main() {
  test('ModeratorBay.isIdle is true for IDLE status', () {
    const bay = ModeratorBay(id: '1', name: 'Bay 1', status: 'IDLE');
    expect(bay.isIdle, true);
    expect(bay.isOccupied, false);
    expect(bay.hasActiveBooking, false);
  });

  test('nextActionLabel for ARRIVED is Start Washing', () {
    const bay = ModeratorBay(
      id: '1', name: 'Bay 1', status: 'OCCUPIED',
      activeBookingId: 'b1', activeBookingStatus: 'ARRIVED',
    );
    expect(bay.nextActionLabel, 'Start Washing');
    expect(bay.nextStatus, 'WASHING');
  });

  test('nextActionLabel for WASHING is Mark Finishing', () {
    const bay = ModeratorBay(
      id: '1', name: 'Bay 1', status: 'OCCUPIED',
      activeBookingId: 'b1', activeBookingStatus: 'WASHING',
    );
    expect(bay.nextActionLabel, 'Mark Finishing');
    expect(bay.nextStatus, 'FINISHING');
  });

  test('nextActionLabel is null for BLOCKED with no booking', () {
    const bay = ModeratorBay(id: '1', name: 'Bay 1', status: 'BLOCKED');
    expect(bay.nextActionLabel, isNull);
    expect(bay.nextStatus, isNull);
  });

  test('ModeratorBay parses from JSON with booking info', () {
    final bay = ModeratorBay.fromJson({
      'id': 'abc', 'name': 'Bay 2', 'status': 'OCCUPIED',
      'activeBookingId': 'booking-123', 'activeBookingStatus': 'WASHING',
    });
    expect(bay.activeBookingId, 'booking-123');
    expect(bay.nextActionLabel, 'Mark Finishing');
  });
}
