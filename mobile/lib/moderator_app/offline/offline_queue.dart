import 'package:hive_flutter/hive_flutter.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';

const _boxName = 'moderator_offline_queue';

class QueuedAction {
  final String type; // 'STATUS_UPDATE' | 'WALK_IN'
  final Map<String, dynamic> payload;
  final int timestamp;

  const QueuedAction({
    required this.type,
    required this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'payload': payload,
        'timestamp': timestamp,
      };

  factory QueuedAction.fromMap(Map<dynamic, dynamic> map) => QueuedAction(
        type: map['type'] as String,
        payload: Map<String, dynamic>.from(map['payload'] as Map),
        timestamp: map['timestamp'] as int,
      );
}

class OfflineQueue {
  static Box? _box;

  static Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  static Future<void> enqueueStatusUpdate(
      String bookingId, String status) async {
    await _box?.add(QueuedAction(
      type: 'STATUS_UPDATE',
      payload: {'bookingId': bookingId, 'status': status},
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ).toMap());
  }

  static Future<void> enqueueWalkIn(
      String bayId, int durationMinutes) async {
    await _box?.add(QueuedAction(
      type: 'WALK_IN',
      payload: {'bayId': bayId, 'durationMinutes': durationMinutes},
      timestamp: DateTime.now().millisecondsSinceEpoch,
    ).toMap());
  }

  static bool get hasActions => (_box?.length ?? 0) > 0;

  static int get pendingCount => _box?.length ?? 0;

  static Future<void> replayAll() async {
    if (_box == null || _box!.isEmpty) return;
    final keys = _box!.keys.toList();
    for (final key in keys) {
      final raw = _box!.get(key);
      if (raw == null) continue;
      final action = QueuedAction.fromMap(raw as Map);
      try {
        await _executeAction(action);
        await _box!.delete(key);
      } on ApiException catch (e) {
        if (e.statusCode == 0) break; // Still offline — stop
        await _box!.delete(key); // Server error — discard
      }
    }
  }

  static Future<void> _executeAction(QueuedAction action) async {
    switch (action.type) {
      case 'STATUS_UPDATE':
        await ApiClient().updateBookingStatus(
          action.payload['bookingId'] as String,
          action.payload['status'] as String,
        );
      case 'WALK_IN':
        await ApiClient().createWalkIn(
          action.payload['bayId'] as String,
          action.payload['durationMinutes'] as int,
        );
    }
  }
}
