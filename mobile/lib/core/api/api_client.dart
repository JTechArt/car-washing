import 'package:dio/dio.dart';
import '../config.dart';
import '../storage/auth_storage.dart';
import '../models/car_wash.dart';
import '../models/vehicle.dart';
import '../models/slot.dart';
import '../models/booking.dart';
import 'api_exception.dart';
import '../../moderator_app/models/moderator_bay.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late final Dio _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
    ..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await AuthStorage.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        final resp = error.response;
        if (resp != null) {
          throw ApiException(
            statusCode: resp.statusCode ?? 0,
            message: resp.data?.toString() ?? error.message ?? 'Unknown error',
          );
        }
        throw ApiException(statusCode: 0, message: error.message ?? 'Network error');
      },
    ));

  // Auth
  Future<Map<String, dynamic>> login(String phone, String password) async {
    final resp = await _dio.post('/api/auth/login',
        data: {'phone': phone, 'password': password});
    return resp.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(String phone, String password) async {
    final resp = await _dio.post('/api/auth/register',
        data: {'phone': phone, 'password': password});
    return resp.data as Map<String, dynamic>;
  }

  // Car washes
  Future<List<CarWash>> getCarWashes() async {
    final resp = await _dio.get('/api/client/car-washes');
    return (resp.data as List)
        .map((j) => CarWash.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<Slot>> getSlots(
      String carWashId, String vehicleType, String serviceType) async {
    final resp = await _dio.get(
      '/api/client/car-washes/$carWashId/slots',
      queryParameters: {
        'vehicleType': vehicleType,
        'serviceType': serviceType,
      },
    );
    return (resp.data as List)
        .map((j) => Slot.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // Vehicles
  Future<List<Vehicle>> getVehicles() async {
    final resp = await _dio.get('/api/client/vehicles');
    return (resp.data as List)
        .map((j) => Vehicle.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<Vehicle> addVehicle(
      String plate, String type, String? nickname) async {
    final resp = await _dio.post('/api/client/vehicles', data: {
      'plate': plate,
      'type': type,
      if (nickname != null) 'nickname': nickname,
    });
    return Vehicle.fromJson(resp.data as Map<String, dynamic>);
  }

  // Bookings
  Future<Booking> createBooking({
    required String carWashId,
    required String vehicleId,
    required String serviceType,
    required DateTime slotStartsAt,
  }) async {
    final resp = await _dio.post('/api/client/bookings', data: {
      'carWashId': carWashId,
      'vehicleId': vehicleId,
      'serviceType': serviceType,
      'slotStartsAt': slotStartsAt.toUtc().toIso8601String(),
    });
    return Booking.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<Booking>> getMyBookings() async {
    final resp = await _dio.get('/api/client/bookings');
    return (resp.data as List)
        .map((j) => Booking.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // Moderator: car washes managed by this user
  Future<List<CarWash>> getOwnerCarWashes() async {
    final resp = await _dio.get('/api/owner/car-washes');
    return (resp.data as List)
        .map((j) => CarWash.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // Moderator: bays with active booking info
  Future<List<ModeratorBay>> getModeratorBays(String carWashId) async {
    final resp =
        await _dio.get('/api/owner/car-washes/$carWashId/bays');
    return (resp.data as List)
        .map((j) => ModeratorBay.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // Moderator: update booking status
  Future<void> updateBookingStatus(
      String bookingId, String status) async {
    await _dio.put(
      '/api/moderator/bookings/$bookingId/status',
      data: {'status': status},
    );
  }

  // Moderator: create walk-in block
  Future<void> createWalkIn(
      String bayId, int estimatedDurationMinutes) async {
    await _dio.post(
      '/api/moderator/bays/$bayId/walk-ins',
      data: {'estimatedDurationMinutes': estimatedDurationMinutes},
    );
  }
}
