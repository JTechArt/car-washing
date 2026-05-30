import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/slot.dart';
import '../../core/models/booking.dart';

class SlotQuery {
  final String carWashId;
  final String vehicleType;
  final String serviceType;

  const SlotQuery({
    required this.carWashId,
    required this.vehicleType,
    required this.serviceType,
  });

  @override
  bool operator ==(Object other) =>
      other is SlotQuery &&
      other.carWashId == carWashId &&
      other.vehicleType == vehicleType &&
      other.serviceType == serviceType;

  @override
  int get hashCode => Object.hash(carWashId, vehicleType, serviceType);
}

final slotsProvider =
    FutureProvider.family<List<Slot>, SlotQuery>((ref, query) async {
  return ApiClient().getSlots(
      query.carWashId, query.vehicleType, query.serviceType);
});

class BookingNotifier extends AsyncNotifier<Booking?> {
  @override
  Future<Booking?> build() async => null;

  Future<Booking> createBooking({
    required String carWashId,
    required String vehicleId,
    required String serviceType,
    required DateTime slotStartsAt,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => ApiClient().createBooking(
          carWashId: carWashId,
          vehicleId: vehicleId,
          serviceType: serviceType,
          slotStartsAt: slotStartsAt,
        ));
    state = result;
    return result.value!;
  }
}

final bookingNotifierProvider =
    AsyncNotifierProvider<BookingNotifier, Booking?>(BookingNotifier.new);
