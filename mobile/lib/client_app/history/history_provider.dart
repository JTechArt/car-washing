import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/booking.dart';

class HistoryNotifier extends AsyncNotifier<List<Booking>> {
  @override
  Future<List<Booking>> build() async {
    return ApiClient().getMyBookings();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ApiClient().getMyBookings());
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<Booking>>(HistoryNotifier.new);
