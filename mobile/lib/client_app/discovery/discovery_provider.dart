import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/car_wash.dart';
import '../../core/websocket/stomp_service.dart';

class DiscoveryNotifier extends AsyncNotifier<List<CarWash>> {
  @override
  Future<List<CarWash>> build() async {
    final washes = await ApiClient().getCarWashes();
    _connectWs(washes);
    return washes;
  }

  void _connectWs(List<CarWash> washes) {
    stompService.connect().then((_) {
      for (final w in washes) {
        stompService.subscribeToBayUpdates(w.id, (_, __) => reload());
      }
    });
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final washes = await ApiClient().getCarWashes();
      return washes;
    });
  }
}

final discoveryProvider =
    AsyncNotifierProvider<DiscoveryNotifier, List<CarWash>>(
        DiscoveryNotifier.new);
