import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/moderator_app/offline/offline_queue.dart';

void main() {
  test('QueuedAction round-trips through toMap/fromMap for STATUS_UPDATE', () {
    final original = QueuedAction(
      type: 'STATUS_UPDATE',
      payload: {'bookingId': 'b1', 'status': 'WASHING'},
      timestamp: 1000,
    );
    final restored = QueuedAction.fromMap(original.toMap());
    expect(restored.type, 'STATUS_UPDATE');
    expect(restored.payload['bookingId'], 'b1');
    expect(restored.payload['status'], 'WASHING');
    expect(restored.timestamp, 1000);
  });

  test('QueuedAction round-trips for WALK_IN', () {
    final original = QueuedAction(
      type: 'WALK_IN',
      payload: {'bayId': 'bay1', 'durationMinutes': 30},
      timestamp: 2000,
    );
    final restored = QueuedAction.fromMap(original.toMap());
    expect(restored.type, 'WALK_IN');
    expect(restored.payload['bayId'], 'bay1');
    expect(restored.payload['durationMinutes'], 30);
  });

  test('OfflineQueue.hasActions is false when box is not initialized', () {
    expect(OfflineQueue.hasActions, false);
    expect(OfflineQueue.pendingCount, 0);
  });
}
