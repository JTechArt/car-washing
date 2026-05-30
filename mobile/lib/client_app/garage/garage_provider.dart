import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/vehicle.dart';

class GarageNotifier extends AsyncNotifier<List<Vehicle>> {
  @override
  Future<List<Vehicle>> build() => ApiClient().getVehicles();

  Future<void> addVehicle(
      String plate, String type, String? nickname) async {
    final vehicle = await ApiClient().addVehicle(plate, type, nickname);
    final current = state.value ?? [];
    state = AsyncData([...current, vehicle]);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ApiClient().getVehicles());
  }
}

final garageProvider =
    AsyncNotifierProvider<GarageNotifier, List<Vehicle>>(GarageNotifier.new);
