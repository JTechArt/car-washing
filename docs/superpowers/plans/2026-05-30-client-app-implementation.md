# Lva Client Mobile App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Lva customer-facing Flutter app (iOS + Android) covering car wash discovery, garage management, 3-tap booking, and live booking status — backed by the running Spring Boot API at localhost:9080.

**Architecture:** Riverpod (plain AsyncNotifier, no code generation) for state, go_router with auth redirect guard for navigation, Dio with a bearer-token interceptor for HTTP, stomp_dart_client for WebSocket bay updates. No map SDK yet — discovery uses a scrollable card list (TODO comment marks where Yandex Maps integrates later).

**Tech Stack:** Flutter 3.19, Dart 3.3, flutter_riverpod 2.5, go_router 13, dio 5.4, flutter_secure_storage 9, stomp_dart_client 1.0, hive_flutter 1.1

---

## File Map

```
mobile/
├── pubspec.yaml                                       (modify: add intl)
├── lib/
│   ├── main_client.dart                               (replace: wire providers + router)
│   ├── core/
│   │   ├── config.dart                                (create: API URLs, constants)
│   │   ├── models/
│   │   │   ├── car_wash.dart                          (create)
│   │   │   ├── vehicle.dart                           (create)
│   │   │   ├── booking.dart                           (create)
│   │   │   └── slot.dart                              (create)
│   │   ├── api/
│   │   │   ├── api_client.dart                        (create: Dio singleton + interceptor)
│   │   │   └── api_exception.dart                     (create)
│   │   ├── storage/
│   │   │   └── auth_storage.dart                      (create: FlutterSecureStorage wrapper)
│   │   └── websocket/
│   │       └── stomp_service.dart                     (create: STOMP client wrapper)
│   └── client_app/
│       ├── router.dart                                (create: go_router + auth guard)
│       ├── app.dart                                   (create: MaterialApp.router)
│       ├── auth/
│       │   ├── auth_provider.dart                     (create: AuthNotifier + provider)
│       │   ├── login_screen.dart                      (create)
│       │   └── register_screen.dart                   (create)
│       ├── discovery/
│       │   ├── discovery_provider.dart                (create: CarWashNotifier)
│       │   ├── discovery_screen.dart                  (create: car wash list)
│       │   └── car_wash_card.dart                     (create)
│       ├── garage/
│       │   ├── garage_provider.dart                   (create: VehicleNotifier)
│       │   ├── garage_screen.dart                     (create)
│       │   └── add_vehicle_screen.dart                (create)
│       ├── booking/
│       │   ├── booking_provider.dart                  (create: BookingNotifier)
│       │   ├── booking_flow_screen.dart               (create: slot + vehicle picker)
│       │   └── booking_confirmed_screen.dart          (create)
│       └── history/
│           ├── history_provider.dart                  (create: HistoryNotifier)
│           └── history_screen.dart                    (create)

backend/src/main/java/am/lva/booking/
├── dto/BookingListResponse.java                       (create: Task 9)
└── BookingController.java                             (modify: add GET /api/client/bookings)
```

---

## Task 1: Core Config + Models

**Files:**
- Modify: `mobile/pubspec.yaml`
- Create: `mobile/lib/core/config.dart`
- Create: `mobile/lib/core/models/car_wash.dart`
- Create: `mobile/lib/core/models/vehicle.dart`
- Create: `mobile/lib/core/models/booking.dart`
- Create: `mobile/lib/core/models/slot.dart`

- [ ] **Step 1: Add `intl` to pubspec.yaml**

Open `mobile/pubspec.yaml` and add under `dependencies:`:
```yaml
  intl: ^0.19.0
```

- [ ] **Step 2: Run `flutter pub get`**

```bash
cd /path/to/mobile && flutter pub get
```

Expected: resolves without errors.

- [ ] **Step 3: Create `lib/core/config.dart`**

```dart
class AppConfig {
  static const String apiBaseUrl = 'http://localhost:9080';
  // Raw WebSocket endpoint (bypasses SockJS negotiation)
  static const String wsUrl = 'ws://localhost:9080/ws/websocket';
  static const String tokenKey = 'lva_jwt';
}
```

- [ ] **Step 4: Create `lib/core/models/car_wash.dart`**

```dart
class CarWash {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String availabilityStatus; // GREEN | YELLOW | RED
  final int nextSlotMinutes;

  const CarWash({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.availabilityStatus,
    required this.nextSlotMinutes,
  });

  factory CarWash.fromJson(Map<String, dynamic> json) => CarWash(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        availabilityStatus: json['availabilityStatus'] as String? ?? 'RED',
        nextSlotMinutes: json['nextSlotMinutes'] as int? ?? 0,
      );
}
```

- [ ] **Step 5: Create `lib/core/models/vehicle.dart`**

```dart
class Vehicle {
  final String id;
  final String plate;
  final String type; // SEDAN | CROSSOVER | SUV | COUPE
  final String? nickname;

  const Vehicle({
    required this.id,
    required this.plate,
    required this.type,
    this.nickname,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
        id: json['id'] as String,
        plate: json['plate'] as String,
        type: json['type'] as String,
        nickname: json['nickname'] as String?,
      );

  String get displayName => nickname?.isNotEmpty == true ? nickname! : plate;
}
```

- [ ] **Step 6: Create `lib/core/models/slot.dart`**

```dart
class Slot {
  final DateTime startsAt;
  final int durationMinutes;
  final int amountAmd;

  const Slot({
    required this.startsAt,
    required this.durationMinutes,
    required this.amountAmd,
  });

  factory Slot.fromJson(Map<String, dynamic> json) => Slot(
        startsAt: DateTime.parse(json['startsAt'] as String),
        durationMinutes: json['durationMinutes'] as int,
        amountAmd: json['amountAmd'] as int,
      );
}
```

- [ ] **Step 7: Create `lib/core/models/booking.dart`**

```dart
class Booking {
  final String id;
  final String bayId;
  final String status;
  final DateTime startsAt;
  final DateTime endsAt;

  const Booking({
    required this.id,
    required this.bayId,
    required this.status,
    required this.startsAt,
    required this.endsAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'] as String,
        bayId: json['bayId'] as String,
        status: json['status'] as String,
        startsAt: DateTime.parse(json['startsAt'] as String),
        endsAt: DateTime.parse(json['endsAt'] as String),
      );

  bool get isActive => !['COMPLETED', 'CANCELLED'].contains(status);
}
```

- [ ] **Step 8: Write widget test to verify models parse correctly**

Create `mobile/test/core/models_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/core/models/car_wash.dart';
import 'package:lva_mobile/core/models/vehicle.dart';
import 'package:lva_mobile/core/models/slot.dart';
import 'package:lva_mobile/core/models/booking.dart';

void main() {
  test('CarWash parses from JSON', () {
    final cw = CarWash.fromJson({
      'id': 'abc',
      'name': 'AutoSpa',
      'address': 'Tigranyan 5',
      'lat': 40.18,
      'lng': 44.51,
      'availabilityStatus': 'GREEN',
      'nextSlotMinutes': 5,
    });
    expect(cw.id, 'abc');
    expect(cw.availabilityStatus, 'GREEN');
  });

  test('Vehicle displayName uses nickname when set', () {
    final v = Vehicle.fromJson({'id': '1', 'plate': 'AM1234', 'type': 'SEDAN', 'nickname': 'My Car'});
    expect(v.displayName, 'My Car');
  });

  test('Vehicle displayName falls back to plate', () {
    final v = Vehicle.fromJson({'id': '2', 'plate': 'AM5678', 'type': 'SUV'});
    expect(v.displayName, 'AM5678');
  });

  test('Booking isActive is false for COMPLETED', () {
    final b = Booking.fromJson({
      'id': 'b1', 'bayId': 'bay1', 'status': 'COMPLETED',
      'startsAt': '2024-01-01T10:00:00Z', 'endsAt': '2024-01-01T10:25:00Z',
    });
    expect(b.isActive, false);
  });

  test('Slot parses amountAmd', () {
    final s = Slot.fromJson({'startsAt': '2024-01-01T10:00:00Z', 'durationMinutes': 25, 'amountAmd': 3500});
    expect(s.amountAmd, 3500);
  });
}
```

- [ ] **Step 9: Run tests**

```bash
cd mobile && flutter test test/core/models_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 10: Commit**

```bash
git add mobile/
git commit -m "feat(mobile): add core config and domain models"
```

---

## Task 2: Core API Client + Auth Storage

**Files:**
- Create: `mobile/lib/core/api/api_exception.dart`
- Create: `mobile/lib/core/api/api_client.dart`
- Create: `mobile/lib/core/storage/auth_storage.dart`

- [ ] **Step 1: Create `lib/core/api/api_exception.dart`**

```dart
class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException({required this.statusCode, required this.message});

  @override
  String toString() => 'ApiException($statusCode): $message';

  bool get isUnauthorized => statusCode == 401;
  bool get isConflict => statusCode == 409;
}
```

- [ ] **Step 2: Create `lib/core/storage/auth_storage.dart`**

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) =>
      _storage.write(key: AppConfig.tokenKey, value: token);

  static Future<String?> getToken() =>
      _storage.read(key: AppConfig.tokenKey);

  static Future<void> clearToken() =>
      _storage.delete(key: AppConfig.tokenKey);

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
```

- [ ] **Step 3: Create `lib/core/api/api_client.dart`**

```dart
import 'package:dio/dio.dart';
import '../config.dart';
import '../storage/auth_storage.dart';
import '../models/car_wash.dart';
import '../models/vehicle.dart';
import '../models/slot.dart';
import '../models/booking.dart';
import 'api_exception.dart';

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
        handler.next(error);
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
    return (resp.data as List).map((j) => CarWash.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<Slot>> getSlots(String carWashId, String vehicleType, String serviceType) async {
    final resp = await _dio.get(
      '/api/client/car-washes/$carWashId/slots',
      queryParameters: {'vehicleType': vehicleType, 'serviceType': serviceType},
    );
    return (resp.data as List).map((j) => Slot.fromJson(j as Map<String, dynamic>)).toList();
  }

  // Vehicles
  Future<List<Vehicle>> getVehicles() async {
    final resp = await _dio.get('/api/client/vehicles');
    return (resp.data as List).map((j) => Vehicle.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<Vehicle> addVehicle(String plate, String type, String? nickname) async {
    final resp = await _dio.post('/api/client/vehicles',
        data: {'plate': plate, 'type': type, if (nickname != null) 'nickname': nickname});
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
    return (resp.data as List).map((j) => Booking.fromJson(j as Map<String, dynamic>)).toList();
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/core/
git commit -m "feat(mobile): add Dio API client with auth interceptor and secure token storage"
```

---

## Task 3: Auth Feature (Notifier + Screens)

**Files:**
- Create: `mobile/lib/client_app/auth/auth_provider.dart`
- Create: `mobile/lib/client_app/auth/login_screen.dart`
- Create: `mobile/lib/client_app/auth/register_screen.dart`

- [ ] **Step 1: Create `lib/client_app/auth/auth_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/auth_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? token;

  const AuthState({required this.status, this.token});

  factory AuthState.unknown() => const AuthState(status: AuthStatus.unknown);
  factory AuthState.authenticated(String token) =>
      AuthState(status: AuthStatus.authenticated, token: token);
  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final token = await AuthStorage.getToken();
    if (token != null && token.isNotEmpty) {
      return AuthState.authenticated(token);
    }
    return AuthState.unauthenticated();
  }

  Future<void> login(String phone, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await ApiClient().login(phone, password);
      final token = data['token'] as String;
      await AuthStorage.saveToken(token);
      return AuthState.authenticated(token);
    });
  }

  Future<void> register(String phone, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await ApiClient().register(phone, password);
      final token = data['token'] as String;
      await AuthStorage.saveToken(token);
      return AuthState.authenticated(token);
    });
  }

  Future<void> logout() async {
    await AuthStorage.clearToken();
    state = AsyncData(AuthState.unauthenticated());
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
```

- [ ] **Step 2: Create `lib/client_app/auth/login_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(authProvider.notifier).login(
          _phoneCtrl.text.trim(),
          _passCtrl.text,
        );
    if (mounted && ref.read(authProvider).hasValue &&
        ref.read(authProvider).value?.status == AuthStatus.authenticated) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.isLoading;
    final error = auth.error?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Container(
                  width: 64, height: 64,
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B4F72),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Text('Լ',
                        style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
                  ),
                ),
                const Text('Welcome back',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Sign in to book your car wash',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 32),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+374 77 123 456',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(error,
                        style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: isLoading ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1B4F72),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: isLoading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Sign In', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => context.push('/register'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Create Account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Create `lib/client_app/auth/register_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passCtrl.text != _confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    await ref.read(authProvider.notifier).register(
          _phoneCtrl.text.trim(),
          _passCtrl.text,
        );
    if (mounted && ref.read(authProvider).value?.status == AuthStatus.authenticated) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final isLoading = auth.isLoading;
    final error = auth.error?.toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Phone Number', hintText: '+374 77 123 456', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error, style: TextStyle(color: Colors.red.shade700)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B4F72),
                minimumSize: const Size.fromHeight(52),
              ),
              child: isLoading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Account', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Write auth notifier unit test**

Create `mobile/test/auth/auth_notifier_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lva_mobile/client_app/auth/auth_provider.dart';

void main() {
  test('AuthState.unknown has unknown status', () {
    final s = AuthState.unknown();
    expect(s.status, AuthStatus.unknown);
    expect(s.token, isNull);
  });

  test('AuthState.authenticated carries token', () {
    final s = AuthState.authenticated('my-token');
    expect(s.status, AuthStatus.authenticated);
    expect(s.token, 'my-token');
  });

  test('AuthState.unauthenticated has no token', () {
    final s = AuthState.unauthenticated();
    expect(s.status, AuthStatus.unauthenticated);
    expect(s.token, isNull);
  });
}
```

- [ ] **Step 5: Run test**

```bash
flutter test test/auth/auth_notifier_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/client_app/auth/ mobile/test/auth/
git commit -m "feat(mobile): add auth notifier, login and register screens"
```

---

## Task 4: Router + App Shell

**Files:**
- Create: `mobile/lib/client_app/router.dart`
- Create: `mobile/lib/client_app/app.dart`
- Replace: `mobile/lib/main_client.dart`

- [ ] **Step 1: Create `lib/client_app/router.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth/auth_provider.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'discovery/discovery_screen.dart';
import 'garage/garage_screen.dart';
import 'garage/add_vehicle_screen.dart';
import 'history/history_screen.dart';
import 'booking/booking_flow_screen.dart';
import 'booking/booking_confirmed_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final status = authState.value?.status ?? AuthStatus.unauthenticated;
      final isAuth = status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ScaffoldWithNav(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const DiscoveryScreen(),
              routes: [
                GoRoute(
                  path: 'booking/:carWashId',
                  builder: (_, s) => BookingFlowScreen(carWashId: s.pathParameters['carWashId']!),
                ),
                GoRoute(
                  path: 'confirmed',
                  builder: (_, s) => BookingConfirmedScreen(
                    bookingId: s.uri.queryParameters['bookingId'] ?? '',
                    carWashName: s.uri.queryParameters['name'] ?? '',
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/bookings',
              builder: (_, __) => const HistoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/garage',
              builder: (_, __) => const GarageScreen(),
              routes: [
                GoRoute(path: 'add', builder: (_, __) => const AddVehicleScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});

class ScaffoldWithNav extends StatelessWidget {
  final StatefulNavigationShell shell;
  const ScaffoldWithNav({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.local_car_wash_outlined), label: 'Find'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.directions_car_outlined), label: 'Garage'),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create `lib/client_app/app.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';

class ClientApp extends ConsumerWidget {
  const ClientApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Lva',
      routerConfig: router,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B4F72),
        useMaterial3: true,
      ),
    );
  }
}
```

- [ ] **Step 3: Replace `lib/main_client.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'client_app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: ClientApp()));
}
```

- [ ] **Step 4: Create stub screens** so the router compiles. These will be replaced in later tasks. Create these files now with minimal content:

`mobile/lib/client_app/discovery/discovery_screen.dart`:
```dart
import 'package:flutter/material.dart';
class DiscoveryScreen extends StatelessWidget {
  const DiscoveryScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Discovery')));
}
```

`mobile/lib/client_app/garage/garage_screen.dart`:
```dart
import 'package:flutter/material.dart';
class GarageScreen extends StatelessWidget {
  const GarageScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Garage')));
}
```

`mobile/lib/client_app/garage/add_vehicle_screen.dart`:
```dart
import 'package:flutter/material.dart';
class AddVehicleScreen extends StatelessWidget {
  const AddVehicleScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Add Vehicle')));
}
```

`mobile/lib/client_app/history/history_screen.dart`:
```dart
import 'package:flutter/material.dart';
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('History')));
}
```

`mobile/lib/client_app/booking/booking_flow_screen.dart`:
```dart
import 'package:flutter/material.dart';
class BookingFlowScreen extends StatelessWidget {
  final String carWashId;
  const BookingFlowScreen({super.key, required this.carWashId});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Booking Flow')));
}
```

`mobile/lib/client_app/booking/booking_confirmed_screen.dart`:
```dart
import 'package:flutter/material.dart';
class BookingConfirmedScreen extends StatelessWidget {
  final String bookingId;
  final String carWashName;
  const BookingConfirmedScreen({super.key, required this.bookingId, required this.carWashName});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Confirmed')));
}
```

- [ ] **Step 5: Verify app compiles**

```bash
cd mobile && flutter analyze && flutter build apk --debug 2>&1 | tail -5
```

Or if running on simulator:
```bash
flutter run --target lib/main_client.dart
```

Expected: app launches showing login screen (since no token stored).

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/
git commit -m "feat(mobile): add go_router with auth guard, app shell with bottom nav"
```

---

## Task 5: WebSocket STOMP Service

**Files:**
- Create: `mobile/lib/core/websocket/stomp_service.dart`

- [ ] **Step 1: Create `lib/core/websocket/stomp_service.dart`**

```dart
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config.dart';
import '../storage/auth_storage.dart';

typedef BayStatusCallback = void Function(String bayId, String status);

class StompService {
  StompClient? _client;
  final Map<String, StompUnsubscribe> _subscriptions = {};

  Future<void> connect() async {
    final token = await AuthStorage.getToken();
    _client = StompClient(
      config: StompConfig(
        url: AppConfig.wsUrl,
        stompConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
        webSocketConnectHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
        reconnectDelay: const Duration(seconds: 5),
        onConnect: (_) {},
        onDisconnect: (_) {},
        onStompError: (frame) {},
        onWebSocketError: (e) {},
      ),
    );
    _client!.activate();
  }

  void subscribeToBayUpdates(String carWashId, BayStatusCallback onUpdate) {
    final topic = '/topic/carwash/$carWashId/bays';
    if (_subscriptions.containsKey(topic)) return;

    final unsub = _client!.subscribe(
      destination: topic,
      callback: (frame) {
        if (frame.body == null) return;
        final data = jsonDecode(frame.body!) as Map<String, dynamic>;
        onUpdate(data['bayId'] as String, data['status'] as String);
      },
    );
    _subscriptions[topic] = unsub;
  }

  void unsubscribeFromCarWash(String carWashId) {
    final topic = '/topic/carwash/$carWashId/bays';
    _subscriptions.remove(topic)?.call();
  }

  void disconnect() {
    _subscriptions.clear();
    _client?.deactivate();
    _client = null;
  }
}

// Singleton provider — call StompService() anywhere for the same instance
final _stompSingleton = StompService();
StompService get stompService => _stompSingleton;
```

- [ ] **Step 2: Write unit test**

Create `mobile/test/core/stomp_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/core/websocket/stomp_service.dart';

void main() {
  test('StompService singleton returns same instance', () {
    final a = stompService;
    final b = stompService;
    expect(identical(a, b), isTrue);
  });

  test('disconnect can be called when not connected', () {
    // Should not throw
    expect(() => stompService.disconnect(), returnsNormally);
  });
}
```

- [ ] **Step 3: Run test**

```bash
flutter test test/core/stomp_service_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/core/websocket/ mobile/test/core/stomp_service_test.dart
git commit -m "feat(mobile): add STOMP WebSocket service for live bay updates"
```

---

## Task 6: Discovery Screen (Car Wash List)

**Files:**
- Create: `mobile/lib/client_app/discovery/discovery_provider.dart`
- Create: `mobile/lib/client_app/discovery/car_wash_card.dart`
- Replace: `mobile/lib/client_app/discovery/discovery_screen.dart`

- [ ] **Step 1: Create `lib/client_app/discovery/discovery_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/car_wash.dart';
import '../../core/websocket/stomp_service.dart';

class DiscoveryNotifier extends AsyncNotifier<List<CarWash>> {
  @override
  Future<List<CarWash>> build() async {
    final washes = await ApiClient().getCarWashes();
    _connectWebSocket(washes);
    return washes;
  }

  void _connectWebSocket(List<CarWash> washes) {
    stompService.connect().then((_) {
      for (final w in washes) {
        stompService.subscribeToBayUpdates(w.id, (bayId, status) {
          // When any bay in a car wash changes, refresh availability
          reload();
        });
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
    AsyncNotifierProvider<DiscoveryNotifier, List<CarWash>>(DiscoveryNotifier.new);
```

- [ ] **Step 2: Create `lib/client_app/discovery/car_wash_card.dart`**

```dart
import 'package:flutter/material.dart';
import '../../../core/models/car_wash.dart';

class CarWashCard extends StatelessWidget {
  final CarWash carWash;
  final VoidCallback onTap;

  const CarWashCard({super.key, required this.carWash, required this.onTap});

  Color get _statusColor => switch (carWash.availabilityStatus) {
        'GREEN' => const Color(0xFF27AE60),
        'YELLOW' => const Color(0xFFF39C12),
        _ => const Color(0xFFE74C3C),
      };

  String get _statusLabel => switch (carWash.availabilityStatus) {
        'GREEN' => carWash.nextSlotMinutes == 0
            ? 'Available now'
            : '~${carWash.nextSlotMinutes} min',
        'YELLOW' => '< 1 hr wait',
        _ => 'Fully booked',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_car_wash, color: _statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(carWash.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(carWash.address,
                        style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(color: _statusColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 5),
                        Text(_statusLabel,
                            style: TextStyle(
                                color: _statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  if (carWash.availabilityStatus != 'RED') ...[
                    const SizedBox(height: 4),
                    Text('Book →',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Replace `lib/client_app/discovery/discovery_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import 'discovery_provider.dart';
import 'car_wash_card.dart';

class DiscoveryScreen extends ConsumerWidget {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final carWashes = ref.watch(discoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Car Wash'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: carWashes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(discoveryProvider.notifier).reload(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (washes) {
          if (washes.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_car_wash, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No car washes available yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(discoveryProvider.notifier).reload(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: washes.length,
              itemBuilder: (ctx, i) => CarWashCard(
                carWash: washes[i],
                onTap: washes[i].availabilityStatus == 'RED'
                    ? () {}
                    : () => context.push('/booking/${washes[i].id}'),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Write widget test**

Create `mobile/test/discovery/car_wash_card_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/client_app/discovery/car_wash_card.dart';
import 'package:lva_mobile/core/models/car_wash.dart';

void main() {
  final greenWash = CarWash(
    id: '1', name: 'AutoSpa', address: 'Tigranyan 5',
    lat: 40.18, lng: 44.51,
    availabilityStatus: 'GREEN', nextSlotMinutes: 0,
  );

  testWidgets('CarWashCard shows name and address', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CarWashCard(carWash: greenWash, onTap: () {}),
      ),
    ));
    expect(find.text('AutoSpa'), findsOneWidget);
    expect(find.text('Tigranyan 5'), findsOneWidget);
    expect(find.text('Available now'), findsOneWidget);
  });

  testWidgets('CarWashCard shows fully booked for RED', (tester) async {
    final redWash = CarWash(
      id: '2', name: 'Full Wash', address: 'Addr',
      lat: 40.0, lng: 44.0,
      availabilityStatus: 'RED', nextSlotMinutes: 0,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: CarWashCard(carWash: redWash, onTap: () {})),
    ));
    expect(find.text('Fully booked'), findsOneWidget);
  });
}
```

- [ ] **Step 5: Run test**

```bash
flutter test test/discovery/car_wash_card_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/client_app/discovery/ mobile/test/discovery/
git commit -m "feat(mobile): add discovery screen with car wash list and live availability"
```

---

## Task 7: Garage Management

**Files:**
- Create: `mobile/lib/client_app/garage/garage_provider.dart`
- Replace: `mobile/lib/client_app/garage/garage_screen.dart`
- Replace: `mobile/lib/client_app/garage/add_vehicle_screen.dart`

- [ ] **Step 1: Create `lib/client_app/garage/garage_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/vehicle.dart';

class GarageNotifier extends AsyncNotifier<List<Vehicle>> {
  @override
  Future<List<Vehicle>> build() => ApiClient().getVehicles();

  Future<void> addVehicle(String plate, String type, String? nickname) async {
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
```

- [ ] **Step 2: Replace `lib/client_app/garage/garage_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'garage_provider.dart';

const _typeIcons = {
  'SEDAN': Icons.directions_car,
  'CROSSOVER': Icons.directions_car_filled,
  'SUV': Icons.airport_shuttle,
  'COUPE': Icons.sports_car_outlined,
};

class GarageScreen extends ConsumerWidget {
  const GarageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(garageProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Garage')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/garage/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
        backgroundColor: const Color(0xFF1B4F72),
        foregroundColor: Colors.white,
      ),
      body: vehicles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No vehicles yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  SizedBox(height: 8),
                  Text('Add your car to start booking',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final v = list[i];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF1B4F72).withOpacity(0.1),
                    child: Icon(_typeIcons[v.type] ?? Icons.directions_car,
                        color: const Color(0xFF1B4F72)),
                  ),
                  title: Text(v.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${v.plate} · ${v.type}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 3: Replace `lib/client_app/garage/add_vehicle_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'garage_provider.dart';

const _vehicleTypes = ['SEDAN', 'CROSSOVER', 'SUV', 'COUPE'];

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _plateCtrl = TextEditingController();
  final _nicknameCtrl = TextEditingController();
  String _selectedType = 'SEDAN';
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _plateCtrl.dispose();
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_plateCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Plate number is required');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(garageProvider.notifier).addVehicle(
            _plateCtrl.text.trim(),
            _selectedType,
            _nicknameCtrl.text.trim().isEmpty ? null : _nicknameCtrl.text.trim(),
          );
      if (mounted) context.pop();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Vehicle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Vehicle Type',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: _vehicleTypes.map((type) {
                final selected = _selectedType == type;
                return FilterChip(
                  label: Text(type),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedType = type),
                  selectedColor: const Color(0xFF1B4F72).withOpacity(0.15),
                  checkmarkColor: const Color(0xFF1B4F72),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _plateCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Plate Number *',
                hintText: 'AM 1234 AB',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nickname (optional)',
                hintText: 'My Sedan',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Colors.red.shade700)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1B4F72),
                minimumSize: const Size.fromHeight(52),
              ),
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add to Garage', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Write test**

Create `mobile/test/garage/garage_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/core/models/vehicle.dart';

void main() {
  test('Vehicle displayName prefers nickname', () {
    const v = Vehicle(id: '1', plate: 'AM1234', type: 'SEDAN', nickname: 'Work Car');
    expect(v.displayName, 'Work Car');
  });

  test('Vehicle displayName uses plate when nickname is null', () {
    const v = Vehicle(id: '2', plate: 'AM9999', type: 'SUV');
    expect(v.displayName, 'AM9999');
  });

  test('Vehicle displayName uses plate when nickname is empty', () {
    const v = Vehicle(id: '3', plate: 'AM8888', type: 'COUPE', nickname: '');
    expect(v.displayName, 'AM8888');
  });
}
```

- [ ] **Step 5: Run test**

```bash
flutter test test/garage/garage_provider_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/client_app/garage/ mobile/test/garage/
git commit -m "feat(mobile): add garage management screens (list and add vehicle)"
```

---

## Task 8: Booking Flow (3-tap)

**Files:**
- Create: `mobile/lib/client_app/booking/booking_provider.dart`
- Replace: `mobile/lib/client_app/booking/booking_flow_screen.dart`
- Replace: `mobile/lib/client_app/booking/booking_confirmed_screen.dart`

- [ ] **Step 1: Create `lib/client_app/booking/booking_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/slot.dart';
import '../../core/models/booking.dart';

// Slots for a given car wash + vehicle type + service type
final slotsProvider = FutureProvider.family<List<Slot>, SlotQuery>((ref, query) async {
  return ApiClient().getSlots(query.carWashId, query.vehicleType, query.serviceType);
});

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
```

- [ ] **Step 2: Replace `lib/client_app/booking/booking_flow_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../garage/garage_provider.dart';
import '../../core/models/vehicle.dart';
import '../../core/models/slot.dart';
import 'booking_provider.dart';

const _serviceTypes = ['EXTERIOR', 'INTERIOR', 'FULL', 'PREMIUM'];
const _serviceLabels = {
  'EXTERIOR': 'Exterior Wash',
  'INTERIOR': 'Interior Clean',
  'FULL': 'Full Wash',
  'PREMIUM': 'Premium Detail',
};

class BookingFlowScreen extends ConsumerStatefulWidget {
  final String carWashId;
  const BookingFlowScreen({super.key, required this.carWashId});

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  Vehicle? _selectedVehicle;
  String _selectedService = 'EXTERIOR';
  Slot? _selectedSlot;

  SlotQuery get _slotQuery => SlotQuery(
        carWashId: widget.carWashId,
        vehicleType: _selectedVehicle?.type ?? 'SEDAN',
        serviceType: _selectedService,
      );

  Future<void> _confirm() async {
    if (_selectedVehicle == null || _selectedSlot == null) return;
    try {
      final booking = await ref.read(bookingNotifierProvider.notifier).createBooking(
            carWashId: widget.carWashId,
            vehicleId: _selectedVehicle!.id,
            serviceType: _selectedService,
            slotStartsAt: _selectedSlot!.startsAt,
          );
      if (mounted) {
        context.go('/confirmed?bookingId=${booking.id}&name=Car+Wash');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Booking failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(garageProvider);
    final slotsAsync = ref.watch(slotsProvider(_slotQuery));
    final bookingState = ref.watch(bookingNotifierProvider);
    final fmt = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Book a Wash')),
      body: vehiclesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading vehicles: $e')),
        data: (vehicles) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step 1: Vehicle
              const Text('1. Select your vehicle',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              if (vehicles.isEmpty)
                OutlinedButton.icon(
                  onPressed: () => context.push('/garage/add'),
                  icon: const Icon(Icons.add),
                  label: const Text('Add a vehicle first'),
                )
              else
                ...vehicles.map((v) => RadioListTile<Vehicle>(
                      value: v,
                      groupValue: _selectedVehicle,
                      onChanged: (val) => setState(() {
                        _selectedVehicle = val;
                        _selectedSlot = null;
                      }),
                      title: Text(v.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${v.plate} · ${v.type}'),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    )),

              const Divider(height: 32),

              // Step 2: Service type
              const Text('2. Select service',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: _serviceTypes.map((s) => ChoiceChip(
                      label: Text(_serviceLabels[s] ?? s),
                      selected: _selectedService == s,
                      onSelected: (_) => setState(() {
                        _selectedService = s;
                        _selectedSlot = null;
                      }),
                    )).toList(),
              ),

              const Divider(height: 32),

              // Step 3: Slot
              const Text('3. Pick a time slot',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              if (_selectedVehicle == null)
                const Text('Select a vehicle first',
                    style: TextStyle(color: Colors.grey))
              else
                slotsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                  data: (slots) {
                    if (slots.isEmpty) {
                      return const Text('No slots available',
                          style: TextStyle(color: Colors.grey));
                    }
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: slots.take(6).map((slot) {
                        final selected = _selectedSlot == slot;
                        return ChoiceChip(
                          label: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(fmt.format(slot.startsAt.toLocal()),
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('${slot.durationMinutes} min',
                                  style: const TextStyle(fontSize: 11)),
                              Text('${slot.amountAmd} ֏',
                                  style: const TextStyle(fontSize: 11)),
                            ],
                          ),
                          selected: selected,
                          onSelected: (_) => setState(() => _selectedSlot = slot),
                        );
                      }).toList(),
                    );
                  },
                ),

              const SizedBox(height: 32),

              FilledButton(
                onPressed: (_selectedVehicle != null &&
                        _selectedSlot != null &&
                        !bookingState.isLoading)
                    ? _confirm
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4F72),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: bookingState.isLoading
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(
                        _selectedSlot != null
                            ? 'Confirm Booking — ${fmt.format(_selectedSlot!.startsAt.toLocal())}'
                            : 'Confirm Booking',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Replace `lib/client_app/booking/booking_confirmed_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BookingConfirmedScreen extends StatelessWidget {
  final String bookingId;
  final String carWashName;

  const BookingConfirmedScreen({
    super.key,
    required this.bookingId,
    required this.carWashName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 96, height: 96,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded,
                    size: 56, color: Colors.green.shade600),
              ),
              const SizedBox(height: 28),
              const Text('Booking Confirmed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                carWashName.isNotEmpty
                    ? 'Head to $carWashName — your bay will be ready'
                    : 'Head to the car wash — your bay will be ready',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 36),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _row('Booking ID', bookingId.length > 8
                        ? '#${bookingId.substring(0, 8).toUpperCase()}…'
                        : '#${bookingId.toUpperCase()}'),
                    const Divider(height: 20),
                    _row('Status', 'Pending — show up any time'),
                  ],
                ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go('/bookings'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1B4F72),
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('View My Bookings',
                    style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back to Find'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
}
```

- [ ] **Step 4: Write test**

Create `mobile/test/booking/slot_query_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/client_app/booking/booking_provider.dart';

void main() {
  test('SlotQuery equality works for FutureProvider.family caching', () {
    const q1 = SlotQuery(carWashId: 'abc', vehicleType: 'SEDAN', serviceType: 'EXTERIOR');
    const q2 = SlotQuery(carWashId: 'abc', vehicleType: 'SEDAN', serviceType: 'EXTERIOR');
    final q3 = SlotQuery(carWashId: 'abc', vehicleType: 'SUV', serviceType: 'EXTERIOR');
    expect(q1, equals(q2));
    expect(q1, isNot(equals(q3)));
  });
}
```

- [ ] **Step 5: Run test**

```bash
flutter test test/booking/slot_query_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/client_app/booking/ mobile/test/booking/
git commit -m "feat(mobile): add 3-step booking flow with slot picker and confirmation screen"
```

---

## Task 9: Backend — Add GET /api/client/bookings

**Files:**
- Create: `backend/src/main/java/am/lva/booking/dto/BookingListResponse.java`
- Modify: `backend/src/main/java/am/lva/booking/BookingController.java`
- Modify: `backend/src/main/java/am/lva/booking/BookingRepository.java`

- [ ] **Step 1: Create `BookingListResponse.java`**

```java
package am.lva.booking.dto;

import am.lva.booking.Booking;
import am.lva.booking.BookingStatus;
import java.time.OffsetDateTime;
import java.util.UUID;

public record BookingListResponse(
        UUID id,
        UUID bayId,
        String carWashName,
        String bayName,
        BookingStatus status,
        OffsetDateTime startsAt,
        OffsetDateTime endsAt,
        String serviceType,
        UUID vehicleId) {

    public static BookingListResponse from(Booking b) {
        return new BookingListResponse(
                b.getId(),
                b.getBay().getId(),
                b.getBay().getCarWash().getName(),
                b.getBay().getName(),
                b.getStatus(),
                b.getStartsAt(),
                b.getEndsAt(),
                b.getServiceType().name(),
                b.getVehicle().getId());
    }
}
```

- [ ] **Step 2: Add `findByUserId` to `BookingRepository.java`**

Read the file and add:

```java
import org.springframework.data.jpa.repository.EntityGraph;

@EntityGraph(attributePaths = {"bay", "bay.carWash", "vehicle"})
List<Booking> findByUserIdOrderByStartsAtDesc(UUID userId);
```

The complete updated file:

```java
package am.lva.booking;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

public interface BookingRepository extends JpaRepository<Booking, UUID> {

    @Query("""
        SELECT b FROM Booking b
        WHERE b.bay.id = :bayId
        AND b.status NOT IN ('COMPLETED', 'CANCELLED')
        AND b.startsAt < :endsAt AND b.endsAt > :startsAt
        """)
    List<Booking> findOverlapping(@Param("bayId") UUID bayId,
                                  @Param("startsAt") OffsetDateTime startsAt,
                                  @Param("endsAt") OffsetDateTime endsAt);

    @EntityGraph(attributePaths = {"bay", "bay.carWash", "vehicle"})
    List<Booking> findByUserIdOrderByStartsAtDesc(UUID userId);
}
```

- [ ] **Step 3: Add `GET /api/client/bookings` to `BookingController.java`**

Add this method to the existing BookingController:

```java
@GetMapping("/api/client/bookings")
public List<BookingListResponse> myBookings(@AuthenticationPrincipal UUID userId) {
    return bookingService.getMyBookings(userId);
}
```

Also add `getMyBookings(UUID userId)` to `BookingService.java`:

```java
@Transactional(readOnly = true)
public List<BookingListResponse> getMyBookings(UUID userId) {
    return bookingRepository.findByUserIdOrderByStartsAtDesc(userId).stream()
            .map(BookingListResponse::from).toList();
}
```

And add the import in BookingService:
```java
import am.lva.booking.dto.BookingListResponse;
```

- [ ] **Step 4: Run backend tests**

```bash
cd backend && mvn test -q 2>&1 | tail -5
```

Expected: `Tests run: 24, Failures: 0, Errors: 0, Skipped: 0`

- [ ] **Step 5: Commit**

```bash
git add backend/src/
git commit -m "feat(backend): add GET /api/client/bookings endpoint for booking history"
```

---

## Task 10: Booking History + Live Status

**Files:**
- Create: `mobile/lib/client_app/history/history_provider.dart`
- Replace: `mobile/lib/client_app/history/history_screen.dart`

- [ ] **Step 1: Create `lib/client_app/history/history_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/booking.dart';
import '../../core/websocket/stomp_service.dart';

class HistoryNotifier extends AsyncNotifier<List<Booking>> {
  final Map<String, String> _liveStatuses = {};

  @override
  Future<List<Booking>> build() async {
    final bookings = await ApiClient().getMyBookings();
    _subscribeToActive(bookings);
    return bookings;
  }

  void _subscribeToActive(List<Booking> bookings) {
    final activeCarWashIds = bookings
        .where((b) => b.isActive)
        .map((b) => b.bayId) // We'll use carWashId when we have it
        .toSet();
    // Subscribe to bay updates for active bookings
    for (final b in bookings.where((b) => b.isActive)) {
      stompService.subscribeToBayUpdates(b.bayId, (bayId, newStatus) {
        _liveStatuses[bayId] = newStatus;
        // Rebuild with live status
        if (state.hasValue) {
          state = AsyncData(state.value!
              .map((booking) => booking.bayId == bayId
                  ? _withStatus(booking, newStatus)
                  : booking)
              .toList());
        }
      });
    }
  }

  Booking _withStatus(Booking b, String status) => Booking(
        id: b.id,
        bayId: b.bayId,
        status: status,
        startsAt: b.startsAt,
        endsAt: b.endsAt,
      );

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final bookings = await ApiClient().getMyBookings();
      _subscribeToActive(bookings);
      return bookings;
    });
  }
}

final historyProvider =
    AsyncNotifierProvider<HistoryNotifier, List<Booking>>(HistoryNotifier.new);
```

- [ ] **Step 2: Replace `lib/client_app/history/history_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'history_provider.dart';
import '../../core/models/booking.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(historyProvider);
    final fmt = DateFormat('MMM d · HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(e.toString(), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(historyProvider.notifier).reload(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No bookings yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final active = bookings.where((b) => b.isActive).toList();
          final past = bookings.where((b) => !b.isActive).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(historyProvider.notifier).reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (active.isNotEmpty) ...[
                  const Text('Active',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...active.map((b) => _BookingCard(booking: b, fmt: fmt)),
                  const SizedBox(height: 20),
                ],
                if (past.isNotEmpty) ...[
                  const Text('Past',
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 16, color: Colors.grey)),
                  const SizedBox(height: 8),
                  ...past.map((b) => _BookingCard(booking: b, fmt: fmt, dimmed: true)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final DateFormat fmt;
  final bool dimmed;

  const _BookingCard({
    required this.booking,
    required this.fmt,
    this.dimmed = false,
  });

  Color get _statusColor => switch (booking.status) {
        'PENDING' => Colors.orange,
        'ARRIVED' => Colors.blue,
        'WASHING' => const Color(0xFF1B4F72),
        'FINISHING' => Colors.teal,
        'COMPLETED' => Colors.green,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: dimmed ? 0.65 : 1.0,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: _statusColor.withOpacity(0.12),
                child: Icon(Icons.directions_car, color: _statusColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fmt.format(booking.startsAt.toLocal()),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('Bay: ${booking.bayId.substring(0, 8)}…',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (booking.isActive) ...[
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                            color: _statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(booking.status,
                        style: TextStyle(
                            color: _statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Write test**

Create `mobile/test/history/history_screen_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/core/models/booking.dart';

void main() {
  test('Booking.isActive returns true for PENDING', () {
    final b = Booking.fromJson({
      'id': '1', 'bayId': 'b1', 'status': 'PENDING',
      'startsAt': '2024-01-01T10:00:00Z', 'endsAt': '2024-01-01T10:25:00Z',
    });
    expect(b.isActive, true);
  });

  test('Booking.isActive returns true for WASHING', () {
    final b = Booking.fromJson({
      'id': '2', 'bayId': 'b2', 'status': 'WASHING',
      'startsAt': '2024-01-01T10:00:00Z', 'endsAt': '2024-01-01T10:25:00Z',
    });
    expect(b.isActive, true);
  });

  test('Booking.isActive returns false for CANCELLED', () {
    final b = Booking.fromJson({
      'id': '3', 'bayId': 'b3', 'status': 'CANCELLED',
      'startsAt': '2024-01-01T10:00:00Z', 'endsAt': '2024-01-01T10:25:00Z',
    });
    expect(b.isActive, false);
  });
}
```

- [ ] **Step 4: Run all mobile tests**

```bash
cd mobile && flutter test
```

Expected: all tests pass (models, auth, garage, booking, stomp, history).

- [ ] **Step 5: Run backend tests**

```bash
cd backend && mvn test -q 2>&1 | tail -3
```

Expected: `Tests run: 24, Failures: 0, Errors: 0, Skipped: 0`

- [ ] **Step 6: Final commit**

```bash
git add mobile/ backend/
git commit -m "feat(mobile): add booking history screen with live status via WebSocket"
```

---

## Self-Review

**Spec coverage (Epics 1–6):**
- ✅ Epic 1: Core setup — AppConfig, all models, Dio client with auth interceptor, auth storage
- ✅ Epic 2: Auth — login screen, register screen, JWT in FlutterSecureStorage, session persistence via AsyncNotifier build()
- ✅ Epic 3: Map & discovery — ListView car wash cards with GREEN/YELLOW/RED availability, WebSocket refresh on bay change (Yandex Maps marked as TODO)
- ✅ Epic 4: Garage — list vehicles, add vehicle (plate/type/nickname), delete not implemented yet (see note below)
- ✅ Epic 5: 3-tap booking — select car wash → select vehicle + service → pick slot → confirm
- ✅ Epic 6: Booking history + live status via WebSocket subscription

**Minor gap — delete vehicle:** Spec says "swipe to delete" in Story 4.2. The backend has no DELETE /api/client/vehicles/{id} endpoint and VehicleRepository has no delete method. This is a Phase 2 backend addition. The garage screen is built without delete for now.

**Type consistency checks:**
- `SlotQuery` is defined in `booking_provider.dart` and used only in the same file ✅
- `stompService` singleton accessed via top-level getter in `stomp_service.dart` ✅
- `Booking.isActive` used in both `history_provider.dart` and `_BookingCard` ✅
- `ApiClient().getMyBookings()` called in both `api_client.dart` (defined) and `history_provider.dart` (called) ✅
