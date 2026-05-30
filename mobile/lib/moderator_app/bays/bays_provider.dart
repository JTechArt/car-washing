import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/websocket/stomp_service.dart';
import '../models/moderator_bay.dart';
import '../offline/offline_queue.dart';

class BaysNotifier extends AsyncNotifier<List<ModeratorBay>> {
  String? _carWashId;

  @override
  Future<List<ModeratorBay>> build() async {
    final washes = await ApiClient().getOwnerCarWashes();
    if (washes.isEmpty) return [];
    _carWashId = washes.first.id;
    final bays = await ApiClient().getModeratorBays(_carWashId!);
    _connectWebSocket();
    _replayOfflineQueue();
    return bays;
  }

  void _connectWebSocket() {
    if (_carWashId == null) return;
    stompService.connect().then((_) {
      stompService.subscribeToBayUpdates(_carWashId!, (_, __) => _reload());
    });
  }

  Future<void> _replayOfflineQueue() async {
    if (!OfflineQueue.hasActions) return;
    await OfflineQueue.replayAll();
    await _reload();
  }

  Future<void> _reload() async {
    if (_carWashId == null) return;
    final bays = await ApiClient().getModeratorBays(_carWashId!);
    state = AsyncData(bays);
  }

  Future<bool> updateStatus(String bookingId, String newStatus) async {
    try {
      await ApiClient().updateBookingStatus(bookingId, newStatus);
      await _reload();
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 0) {
        await OfflineQueue.enqueueStatusUpdate(bookingId, newStatus);
        return true;
      }
      rethrow;
    }
  }

  Future<bool> createWalkIn(String bayId, int durationMinutes) async {
    try {
      await ApiClient().createWalkIn(bayId, durationMinutes);
      await _reload();
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 0) {
        await OfflineQueue.enqueueWalkIn(bayId, durationMinutes);
        return true;
      }
      rethrow;
    }
  }

  String? get carWashId => _carWashId;
}

final baysProvider =
    AsyncNotifierProvider<BaysNotifier, List<ModeratorBay>>(BaysNotifier.new);

final offlinePendingProvider = Provider<int>((ref) {
  ref.watch(baysProvider);
  return OfflineQueue.pendingCount;
});
