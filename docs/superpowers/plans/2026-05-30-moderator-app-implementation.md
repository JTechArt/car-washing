# Lva Moderator Tablet App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Lva moderator tablet app — a real-time bay management panel for wash staff, with walk-in override and offline resilience, running from `lib/main_moderator.dart`.

**Architecture:** Shares `lib/core/` with the client app (same API client, auth storage, STOMP service). Moderator-specific code lives in `lib/moderator_app/`. A simple two-screen router (login → bay panel) replaces the client app's bottom-nav shell. The bay panel subscribes to WebSocket and shows a 2-column grid of bay cards with one-tap status transitions. Offline actions are queued in a Hive box and replayed on reconnect.

**Tech Stack:** Flutter 3.19, flutter_riverpod 2.5, go_router 13, hive_flutter 1.1, stomp_dart_client 1.0, dio 5.4

---

## File Map

```
mobile/
├── lib/
│   ├── main_moderator.dart                              (replace)
│   ├── core/
│   │   └── api/
│   │       └── api_client.dart                          (modify: add moderator methods)
│   └── moderator_app/
│       ├── app.dart                                     (create)
│       ├── router.dart                                  (create)
│       ├── auth/
│       │   ├── moderator_auth_provider.dart             (create)
│       │   └── moderator_login_screen.dart              (create)
│       ├── models/
│       │   └── moderator_bay.dart                       (create)
│       ├── bays/
│       │   ├── bays_provider.dart                       (create)
│       │   ├── bays_screen.dart                         (create)
│       │   ├── bay_card.dart                            (create)
│       │   └── walk_in_dialog.dart                      (create)
│       └── offline/
│           └── offline_queue.dart                       (create)
└── test/
    └── moderator/
        ├── moderator_auth_test.dart                     (create)
        ├── moderator_bay_test.dart                      (create)
        └── offline_queue_test.dart                      (create)

backend/src/main/java/am/lva/booking/
├── dto/BayResponse.java                                 (modify: add activeBookingId + activeBookingStatus)
├── BookingRepository.java                               (modify: add findActiveByBayId)
└── CarWashService.java                                  (modify: listBays includes booking info)
```

---

## Task 1: Backend — Extend BayResponse with active booking info

The moderator app needs to know which booking is active on a bay (to call `PUT /api/moderator/bookings/{bookingId}/status`). Extend `BayResponse` with two nullable fields.

**Files:**
- Modify: `backend/src/main/java/am/lva/booking/dto/BayResponse.java`
- Modify: `backend/src/main/java/am/lva/booking/BookingRepository.java`
- Modify: `backend/src/main/java/am/lva/booking/CarWashService.java`

- [ ] **Step 1: Replace `BayResponse.java`**

```java
package am.lva.booking.dto;

import am.lva.booking.Bay;
import am.lva.booking.BayStatus;

import java.util.UUID;

public record BayResponse(
        UUID id,
        String name,
        BayStatus status,
        UUID activeBookingId,       // null when bay is IDLE with no pending booking
        String activeBookingStatus  // null when no active booking
) {
    // Used when creating a new bay (no active booking yet)
    public static BayResponse from(Bay b) {
        return new BayResponse(b.getId(), b.getName(), b.getStatus(), null, null);
    }

    // Used when listing bays with booking context
    public static BayResponse from(Bay b, UUID bookingId, String bookingStatus) {
        return new BayResponse(b.getId(), b.getName(), b.getStatus(), bookingId, bookingStatus);
    }
}
```

- [ ] **Step 2: Add `findActiveByBayId` to `BookingRepository.java`**

Read the file, then add this method inside the interface:

```java
@Query("""
    SELECT b FROM Booking b
    WHERE b.bay.id = :bayId
    AND b.status NOT IN ('COMPLETED', 'CANCELLED')
    ORDER BY b.startsAt DESC
    """)
List<Booking> findActiveByBayId(@Param("bayId") UUID bayId);
```

- [ ] **Step 3: Update `CarWashService.listBays`**

Read `src/main/java/am/lva/booking/CarWashService.java`. Replace the `listBays` method with:

```java
@Transactional(readOnly = true)
public List<BayResponse> listBays(UUID carWashId) {
    return bayRepository.findByCarWashId(carWashId).stream()
            .map(bay -> {
                var activeBookings = bookingRepository.findActiveByBayId(bay.getId());
                if (activeBookings.isEmpty()) {
                    return BayResponse.from(bay);
                }
                var booking = activeBookings.get(0);
                return BayResponse.from(bay, booking.getId(), booking.getStatus().name());
            }).toList();
}
```

Also add `BookingRepository` as a dependency in CarWashService. Read the class and add `private final BookingRepository bookingRepository;` to the field list (Lombok `@RequiredArgsConstructor` handles constructor injection).

- [ ] **Step 4: Run backend tests**

```bash
cd /Users/arthurho/Projects/car-washing-booking/backend
mvn test -q 2>&1 | tail -5
```

Expected: `Tests run: 24, Failures: 0, Errors: 0, Skipped: 0`

- [ ] **Step 5: Commit**

```bash
cd /Users/arthurho/Projects/car-washing-booking
git add backend/src/
git commit -m "feat(backend): extend BayResponse with active booking ID and status for moderator app"
```

---

## Task 2: Moderator Models + API Client Extensions

**Files:**
- Create: `mobile/lib/moderator_app/models/moderator_bay.dart`
- Modify: `mobile/lib/core/api/api_client.dart`

- [ ] **Step 1: Create `lib/moderator_app/models/moderator_bay.dart`**

```dart
import '../../core/models/car_wash.dart';

class ModeratorBay {
  final String id;
  final String name;
  final String status; // IDLE | OCCUPIED | BLOCKED
  final String? activeBookingId;
  final String? activeBookingStatus; // PENDING | ARRIVED | WASHING | FINISHING

  const ModeratorBay({
    required this.id,
    required this.name,
    required this.status,
    this.activeBookingId,
    this.activeBookingStatus,
  });

  factory ModeratorBay.fromJson(Map<String, dynamic> json) => ModeratorBay(
        id: json['id'] as String,
        name: json['name'] as String,
        status: json['status'] as String,
        activeBookingId: json['activeBookingId'] as String?,
        activeBookingStatus: json['activeBookingStatus'] as String?,
      );

  bool get isIdle => status == 'IDLE';
  bool get isOccupied => status == 'OCCUPIED';
  bool get isBlocked => status == 'BLOCKED';
  bool get hasActiveBooking => activeBookingId != null;

  // The next logical action label and target status for the action button
  String? get nextActionLabel => switch (activeBookingStatus) {
        'PENDING' => 'Mark Arrived',
        'ARRIVED' => 'Start Washing',
        'WASHING' => 'Mark Finishing',
        'FINISHING' => 'Complete',
        _ => null,
      };

  String? get nextStatus => switch (activeBookingStatus) {
        'PENDING' => 'ARRIVED',
        'ARRIVED' => 'WASHING',
        'WASHING' => 'FINISHING',
        'FINISHING' => 'COMPLETED',
        _ => null,
      };
}
```

- [ ] **Step 2: Write test for ModeratorBay**

Create `mobile/test/moderator/moderator_bay_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/moderator_app/models/moderator_bay.dart';

void main() {
  test('ModeratorBay.isIdle is true for IDLE status', () {
    const bay = ModeratorBay(id: '1', name: 'Bay 1', status: 'IDLE');
    expect(bay.isIdle, true);
    expect(bay.isOccupied, false);
    expect(bay.hasActiveBooking, false);
  });

  test('nextActionLabel returns correct label for ARRIVED', () {
    const bay = ModeratorBay(
      id: '1', name: 'Bay 1', status: 'OCCUPIED',
      activeBookingId: 'b1', activeBookingStatus: 'ARRIVED',
    );
    expect(bay.nextActionLabel, 'Start Washing');
    expect(bay.nextStatus, 'WASHING');
  });

  test('nextActionLabel returns correct label for WASHING', () {
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

  test('ModeratorBay parses from JSON', () {
    final bay = ModeratorBay.fromJson({
      'id': 'abc', 'name': 'Bay 2', 'status': 'OCCUPIED',
      'activeBookingId': 'booking-123', 'activeBookingStatus': 'WASHING',
    });
    expect(bay.id, 'abc');
    expect(bay.activeBookingId, 'booking-123');
    expect(bay.nextActionLabel, 'Mark Finishing');
  });
}
```

- [ ] **Step 3: Run test to verify it passes**

```bash
cd /Users/arthurho/Projects/car-washing-booking/mobile
flutter test test/moderator/moderator_bay_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 4: Add moderator methods to `lib/core/api/api_client.dart`**

Read the file, then add these methods to the `ApiClient` class after `getMyBookings()`:

```dart
  // Moderator: get car washes owned/managed by the authenticated user
  Future<List<CarWash>> getOwnerCarWashes() async {
    final resp = await _dio.get('/api/owner/car-washes');
    return (resp.data as List)
        .map((j) => CarWash.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // Moderator: get bays with active booking info
  Future<List<ModeratorBay>> getModeratorBays(String carWashId) async {
    final resp =
        await _dio.get('/api/owner/car-washes/$carWashId/bays');
    return (resp.data as List)
        .map((j) => ModeratorBay.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // Moderator: update booking status (ARRIVED | WASHING | FINISHING | COMPLETED)
  Future<void> updateBookingStatus(
      String bookingId, String status) async {
    await _dio.put('/api/moderator/bookings/$bookingId/status',
        data: {'status': status});
  }

  // Moderator: log a walk-in customer on a bay
  Future<void> createWalkIn(
      String bayId, int estimatedDurationMinutes) async {
    await _dio.post('/api/moderator/bays/$bayId/walk-ins',
        data: {'estimatedDurationMinutes': estimatedDurationMinutes});
  }
```

Also add the `ModeratorBay` import at the top of `api_client.dart`:
```dart
import '../../moderator_app/models/moderator_bay.dart';
```

- [ ] **Step 5: Verify analyze**

```bash
flutter analyze lib/ 2>&1 | tail -3
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add mobile/lib/ mobile/test/moderator/moderator_bay_test.dart
git commit -m "feat(mobile): add ModeratorBay model and moderator API methods"
```

---

## Task 3: Moderator Auth (Login + Role Validation)

**Files:**
- Create: `mobile/lib/moderator_app/auth/moderator_auth_provider.dart`
- Create: `mobile/lib/moderator_app/auth/moderator_login_screen.dart`

- [ ] **Step 1: Create `lib/moderator_app/auth/moderator_auth_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/storage/auth_storage.dart';

enum ModeratorAuthStatus { unknown, authenticated, unauthenticated }

class ModeratorAuthState {
  final ModeratorAuthStatus status;
  final String? token;
  final String? role;

  const ModeratorAuthState({
    required this.status,
    this.token,
    this.role,
  });

  factory ModeratorAuthState.unknown() =>
      const ModeratorAuthState(status: ModeratorAuthStatus.unknown);
  factory ModeratorAuthState.authenticated(String token, String role) =>
      ModeratorAuthState(
          status: ModeratorAuthStatus.authenticated,
          token: token,
          role: role);
  factory ModeratorAuthState.unauthenticated() =>
      const ModeratorAuthState(status: ModeratorAuthStatus.unauthenticated);
}

class ModeratorAuthNotifier
    extends AsyncNotifier<ModeratorAuthState> {
  @override
  Future<ModeratorAuthState> build() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      return ModeratorAuthState.unauthenticated();
    }
    // Token exists — assume authenticated (role checked on login)
    return ModeratorAuthState.authenticated(token, 'MODERATOR');
  }

  Future<void> login(String phone, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await ApiClient().login(phone, password);
      final token = data['token'] as String;
      final role = data['role'] as String;

      if (role == 'CUSTOMER') {
        throw const ApiException(
          statusCode: 403,
          message: 'Not authorized for staff access. Use the customer app instead.',
        );
      }

      await AuthStorage.saveToken(token);
      return ModeratorAuthState.authenticated(token, role);
    });
  }

  Future<void> logout() async {
    await AuthStorage.clearToken();
    state = AsyncData(ModeratorAuthState.unauthenticated());
  }
}

final moderatorAuthProvider =
    AsyncNotifierProvider<ModeratorAuthNotifier, ModeratorAuthState>(
        ModeratorAuthNotifier.new);
```

- [ ] **Step 2: Write auth unit test**

Create `mobile/test/moderator/moderator_auth_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/moderator_app/auth/moderator_auth_provider.dart';

void main() {
  test('ModeratorAuthState.unauthenticated has unauthenticated status', () {
    final s = ModeratorAuthState.unauthenticated();
    expect(s.status, ModeratorAuthStatus.unauthenticated);
    expect(s.token, isNull);
  });

  test('ModeratorAuthState.authenticated carries token and role', () {
    final s = ModeratorAuthState.authenticated('token-123', 'MODERATOR');
    expect(s.status, ModeratorAuthStatus.authenticated);
    expect(s.token, 'token-123');
    expect(s.role, 'MODERATOR');
  });

  test('OWNER role is allowed as authenticated', () {
    final s = ModeratorAuthState.authenticated('token-abc', 'OWNER');
    expect(s.status, ModeratorAuthStatus.authenticated);
    expect(s.role, 'OWNER');
  });
}
```

- [ ] **Step 3: Run test**

```bash
flutter test test/moderator/moderator_auth_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 4: Create `lib/moderator_app/auth/moderator_login_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'moderator_auth_provider.dart';

class ModeratorLoginScreen extends ConsumerStatefulWidget {
  const ModeratorLoginScreen({super.key});

  @override
  ConsumerState<ModeratorLoginScreen> createState() =>
      _ModeratorLoginScreenState();
}

class _ModeratorLoginScreenState
    extends ConsumerState<ModeratorLoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref
        .read(moderatorAuthProvider.notifier)
        .login(_phoneCtrl.text.trim(), _passCtrl.text);
    if (mounted &&
        ref.read(moderatorAuthProvider).value?.status ==
            ModeratorAuthStatus.authenticated) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(moderatorAuthProvider);
    final isLoading = auth.isLoading;
    final error = auth.hasError ? auth.error.toString() : null;

    return Scaffold(
      backgroundColor: const Color(0xFF1B4F72),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(48),
          child: SizedBox(
            width: 420,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B4F72),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text('Լ',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Lva Moderator',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text('Staff Operations Panel',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
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
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
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
                          style:
                              TextStyle(color: Colors.red.shade700)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: isLoading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4F72),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Sign In',
                            style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'For authorized staff only',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/moderator_app/auth/ mobile/test/moderator/moderator_auth_test.dart
git commit -m "feat(mobile): add moderator auth notifier with role validation and login screen"
```

---

## Task 4: Offline Queue (Hive)

**Files:**
- Create: `mobile/lib/moderator_app/offline/offline_queue.dart`

- [ ] **Step 1: Create `lib/moderator_app/offline/offline_queue.dart`**

```dart
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
        if (e.statusCode == 0) break; // Still offline — stop replaying
        await _box!.delete(key); // Server-side error — discard
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

  static int get pendingCount => _box?.length ?? 0;
}
```

- [ ] **Step 2: Write unit test**

Create `mobile/test/moderator/offline_queue_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/moderator_app/offline/offline_queue.dart';

void main() {
  test('QueuedAction round-trips through toMap/fromMap', () {
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
}
```

- [ ] **Step 3: Run test**

```bash
flutter test test/moderator/offline_queue_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/moderator_app/offline/ mobile/test/moderator/offline_queue_test.dart
git commit -m "feat(mobile): add Hive-backed offline action queue for moderator app"
```

---

## Task 5: Bay Status Provider

**Files:**
- Create: `mobile/lib/moderator_app/bays/bays_provider.dart`

- [ ] **Step 1: Create `lib/moderator_app/bays/bays_provider.dart`**

```dart
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
    _subscribeToWebSocket();
    _replayOfflineQueue();
    return bays;
  }

  void _subscribeToWebSocket() {
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
        // Offline — queue it
        await OfflineQueue.enqueueStatusUpdate(bookingId, newStatus);
        return true; // Optimistically report success
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
    AsyncNotifierProvider<BaysNotifier, List<ModeratorBay>>(
        BaysNotifier.new);

// Tracks how many actions are queued offline
final offlinePendingProvider = Provider<int>((ref) {
  ref.watch(baysProvider); // rebuild when bays refresh
  return OfflineQueue.pendingCount;
});
```

- [ ] **Step 2: Commit**

```bash
git add mobile/lib/moderator_app/bays/bays_provider.dart
git commit -m "feat(mobile): add BaysNotifier with WebSocket subscription and offline queue integration"
```

---

## Task 6: Bay Card + Walk-In Dialog

**Files:**
- Create: `mobile/lib/moderator_app/bays/bay_card.dart`
- Create: `mobile/lib/moderator_app/bays/walk_in_dialog.dart`

- [ ] **Step 1: Create `lib/moderator_app/bays/bay_card.dart`**

```dart
import 'package:flutter/material.dart';
import '../models/moderator_bay.dart';

class BayCard extends StatelessWidget {
  final ModeratorBay bay;
  final Future<bool> Function(String bookingId, String status) onUpdateStatus;
  final Future<bool> Function(String bayId, int minutes) onWalkIn;

  const BayCard({
    super.key,
    required this.bay,
    required this.onUpdateStatus,
    required this.onWalkIn,
  });

  Color get _borderColor => switch (bay.status) {
        'IDLE' => const Color(0xFF27AE60),
        'OCCUPIED' => const Color(0xFF1B4F72),
        _ => const Color(0xFFE74C3C),
      };

  Color get _badgeColor => switch (bay.status) {
        'IDLE' => Colors.green,
        'OCCUPIED' => const Color(0xFF1B4F72),
        _ => Colors.red,
      };

  String get _statusLabel => switch (bay.status) {
        'IDLE' => 'Available',
        'OCCUPIED' => bay.activeBookingStatus ?? 'Occupied',
        _ => 'Blocked',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _borderColor, width: 2.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(bay.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel,
                      style: TextStyle(
                          color: _badgeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Body
            if (bay.isIdle && !bay.hasActiveBooking) ...[
              const Text('Ready for next vehicle',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const Spacer(),
              // Walk-In button
              OutlinedButton.icon(
                onPressed: () => _showWalkInDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Walk-In'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else if (bay.hasActiveBooking) ...[
              // Booking info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Booking',
                        '#${bay.activeBookingId!.substring(0, 8).toUpperCase()}'),
                    if (bay.activeBookingStatus != null)
                      _infoRow('Status', bay.activeBookingStatus!),
                  ],
                ),
              ),
              const Spacer(),
              // Action button
              if (bay.nextActionLabel != null)
                _ActionButton(
                  label: bay.nextActionLabel!,
                  onPressed: () async {
                    await onUpdateStatus(
                        bay.activeBookingId!, bay.nextStatus!);
                  },
                  color: _actionColor,
                ),
            ] else ...[
              // Blocked (walk-in)
              const Text('Walk-in customer',
                  style: TextStyle(color: Colors.grey)),
              const Spacer(),
              OutlinedButton(
                onPressed: () async {
                  // Release bay — send COMPLETED walk-in
                  await onWalkIn(bay.id, 0);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                child: const Text('Release Bay'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color get _actionColor => switch (bay.activeBookingStatus) {
        'PENDING' => Colors.green,
        'ARRIVED' => const Color(0xFF1B4F72),
        'WASHING' => Colors.orange,
        'FINISHING' => Colors.teal,
        _ => Colors.grey,
      };

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text('$label: ',
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      );

  void _showWalkInDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => WalkInDialog(
        bayName: bay.name,
        onConfirm: (minutes) => onWalkIn(bay.id, minutes),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onPressed;
  final Color color;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                await widget.onPressed();
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
      style: FilledButton.styleFrom(
        backgroundColor: widget.color,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      child: _loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Text(widget.label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}

// Imported here to avoid circular reference in bay_card.dart
import 'walk_in_dialog.dart';
```

Wait — the import at the bottom creates a circular issue. Let me restructure: move the `_showWalkInDialog` call inline and import `walk_in_dialog.dart` at the top. Replace the step above with this corrected version:

- [ ] **Step 2: Create correct `lib/moderator_app/bays/bay_card.dart`** (consolidated, import at top)

```dart
import 'package:flutter/material.dart';
import '../models/moderator_bay.dart';
import 'walk_in_dialog.dart';

class BayCard extends StatelessWidget {
  final ModeratorBay bay;
  final Future<bool> Function(String bookingId, String status) onUpdateStatus;
  final Future<bool> Function(String bayId, int minutes) onWalkIn;

  const BayCard({
    super.key,
    required this.bay,
    required this.onUpdateStatus,
    required this.onWalkIn,
  });

  Color get _borderColor => switch (bay.status) {
        'IDLE' => const Color(0xFF27AE60),
        'OCCUPIED' => const Color(0xFF1B4F72),
        _ => const Color(0xFFE74C3C),
      };

  Color get _badgeColor => switch (bay.status) {
        'IDLE' => Colors.green,
        'OCCUPIED' => const Color(0xFF1B4F72),
        _ => Colors.red,
      };

  String get _statusLabel => switch (bay.status) {
        'IDLE' => 'Available',
        'OCCUPIED' => bay.activeBookingStatus ?? 'Occupied',
        _ => 'Blocked',
      };

  Color get _actionColor => switch (bay.activeBookingStatus) {
        'PENDING' => Colors.green,
        'ARRIVED' => const Color(0xFF1B4F72),
        'WASHING' => Colors.orange,
        'FINISHING' => Colors.teal,
        _ => Colors.grey,
      };

  Widget _infoRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text('$label: ',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _borderColor, width: 2.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(bay.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: _badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel,
                      style: TextStyle(
                          color: _badgeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (bay.isIdle && !bay.hasActiveBooking) ...[
              const Expanded(
                child: Center(
                  child: Text('Ready for next vehicle',
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => WalkInDialog(
                    bayName: bay.name,
                    onConfirm: (min) => onWalkIn(bay.id, min),
                  ),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Walk-In'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ] else if (bay.hasActiveBooking) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow('Booking',
                        '#${bay.activeBookingId!.substring(0, 8).toUpperCase()}'),
                    if (bay.activeBookingStatus != null)
                      _infoRow('Status', bay.activeBookingStatus!),
                  ],
                ),
              ),
              const Spacer(),
              if (bay.nextActionLabel != null)
                _ActionButton(
                  label: bay.nextActionLabel!,
                  color: _actionColor,
                  onPressed: () async {
                    await onUpdateStatus(
                        bay.activeBookingId!, bay.nextStatus!);
                  },
                ),
            ] else ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Walk-in customer',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () async => onWalkIn(bay.id, 0),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44)),
                child: const Text('Release Bay'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final Future<void> Function() onPressed;
  final Color color;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              try {
                await widget.onPressed();
              } finally {
                if (mounted) setState(() => _loading = false);
              }
            },
      style: FilledButton.styleFrom(
        backgroundColor: widget.color,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      child: _loading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : Text(widget.label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}
```

- [ ] **Step 3: Create `lib/moderator_app/bays/walk_in_dialog.dart`**

```dart
import 'package:flutter/material.dart';

class WalkInDialog extends StatefulWidget {
  final String bayName;
  final Future<bool> Function(int minutes) onConfirm;

  const WalkInDialog({
    super.key,
    required this.bayName,
    required this.onConfirm,
  });

  @override
  State<WalkInDialog> createState() => _WalkInDialogState();
}

class _WalkInDialogState extends State<WalkInDialog> {
  int _selectedMinutes = 25;
  bool _loading = false;

  static const _options = [15, 25, 45, 60];

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      await widget.onConfirm(_selectedMinutes);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Walk-In — ${widget.bayName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Estimated duration:',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: _options.map((min) {
              final selected = _selectedMinutes == min;
              return ChoiceChip(
                label: Text('$min min'),
                selected: selected,
                onSelected: (_) =>
                    setState(() => _selectedMinutes = min),
                selectedColor:
                    const Color(0xFF1B4F72).withValues(alpha: 0.15),
                checkmarkColor: const Color(0xFF1B4F72),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _confirm,
          style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1B4F72)),
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Block Bay'),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add mobile/lib/moderator_app/bays/bay_card.dart mobile/lib/moderator_app/bays/walk_in_dialog.dart
git commit -m "feat(mobile): add BayCard with one-tap status transitions and WalkInDialog"
```

---

## Task 7: Bay Status Screen + App Shell

**Files:**
- Create: `mobile/lib/moderator_app/bays/bays_screen.dart`
- Create: `mobile/lib/moderator_app/router.dart`
- Create: `mobile/lib/moderator_app/app.dart`
- Replace: `mobile/lib/main_moderator.dart`

- [ ] **Step 1: Create `lib/moderator_app/bays/bays_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/moderator_auth_provider.dart';
import '../offline/offline_queue.dart';
import 'bays_provider.dart';
import 'bay_card.dart';

class BaysScreen extends ConsumerWidget {
  const BaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baysAsync = ref.watch(baysProvider);
    final notifier = ref.read(baysProvider.notifier);
    final pendingCount = ref.watch(offlinePendingProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4F72),
        foregroundColor: Colors.white,
        title: baysAsync.whenOrNull(
              data: (_) => Text(
                notifier.carWashId != null ? 'Bay Status' : 'Bay Status',
                style: const TextStyle(color: Colors.white),
              ),
            ) ??
            const Text('Bay Status',
                style: TextStyle(color: Colors.white)),
        actions: [
          // Live indicator
          if (baysAsync.hasValue)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Color(0xFF27AE60),
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    const Text('Live',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                padding: EdgeInsets.zero,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () =>
                ref.read(moderatorAuthProvider.notifier).logout(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner
          if (pendingCount > 0)
            Container(
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Offline — $pendingCount action${pendingCount > 1 ? 's' : ''} queued, will sync on reconnect',
                      style: const TextStyle(
                          color: Colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

          // Bay grid
          Expanded(
            child: baysAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(e.toString(), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(baysProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (bays) {
                if (bays.isEmpty) {
                  return const Center(
                    child: Text('No bays configured.',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 16)),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: bays.length,
                  itemBuilder: (_, i) => BayCard(
                    bay: bays[i],
                    onUpdateStatus: notifier.updateStatus,
                    onWalkIn: notifier.createWalkIn,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create `lib/moderator_app/router.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth/moderator_auth_provider.dart';
import 'auth/moderator_login_screen.dart';
import 'bays/bays_screen.dart';

final moderatorRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(moderatorAuthProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) return null;
      final status =
          authState.value?.status ?? ModeratorAuthStatus.unauthenticated;
      final isAuth = status == ModeratorAuthStatus.authenticated;
      final isLogin = state.matchedLocation == '/login';
      if (!isAuth && !isLogin) return '/login';
      if (isAuth && isLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
          path: '/login',
          builder: (_, __) => const ModeratorLoginScreen()),
      GoRoute(path: '/', builder: (_, __) => const BaysScreen()),
    ],
  );
});
```

- [ ] **Step 3: Create `lib/moderator_app/app.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';

class ModeratorApp extends ConsumerWidget {
  const ModeratorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(moderatorRouterProvider);
    return MaterialApp.router(
      title: 'Lva Moderator',
      routerConfig: router,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B4F72),
        useMaterial3: true,
      ),
    );
  }
}
```

- [ ] **Step 4: Replace `lib/main_moderator.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'moderator_app/app.dart';
import 'moderator_app/offline/offline_queue.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await OfflineQueue.init();
  runApp(const ProviderScope(child: ModeratorApp()));
}
```

- [ ] **Step 5: Run analyze on all moderator_app files**

```bash
cd /Users/arthurho/Projects/car-washing-booking/mobile
flutter analyze lib/moderator_app/ 2>&1 | tail -5
```

Expected: `No issues found!`

- [ ] **Step 6: Run all tests**

```bash
flutter test 2>&1 | tail -5
```

Expected: All tests pass (21 existing + 7 new moderator tests = 28 total).

- [ ] **Step 7: Commit**

```bash
cd /Users/arthurho/Projects/car-washing-booking
git add mobile/lib/moderator_app/ mobile/lib/main_moderator.dart mobile/test/moderator/
git commit -m "feat(mobile): add moderator bay status screen, router, app shell, and main entry"
```

---

## Self-Review

**Spec coverage:**
- ✅ Epic 1: Moderator login with role guard (CUSTOMER rejected with error)
- ✅ Epic 2: Real-time bay status grid (2-column GridView, one-tap transitions ARRIVED→WASHING→FINISHING→COMPLETED via PUT /api/moderator/bookings/{id}/status, WebSocket subscription)
- ✅ Epic 3: Walk-in override ("+Walk-In" on IDLE bays, WalkInDialog with 15/25/45/60 min options, POST /api/moderator/bays/{bayId}/walk-ins)
- ✅ Epic 4: Offline resilience (Hive queue, enqueue on network error, replay on reconnect, offline banner showing pending count)
- ✅ Backend: BayResponse extended with activeBookingId + activeBookingStatus, 24 existing tests still pass

**Placeholder scan:** None. All code blocks are complete.

**Type consistency:**
- `ModeratorBay.nextActionLabel` / `nextStatus` used in `BayCard` ✅
- `BaysNotifier.updateStatus(bookingId, newStatus)` signature matches `BayCard.onUpdateStatus` callback type `Future<bool> Function(String, String)` ✅
- `BaysNotifier.createWalkIn(bayId, minutes)` matches `BayCard.onWalkIn` type `Future<bool> Function(String, int)` ✅
- `OfflineQueue.enqueueStatusUpdate / enqueueWalkIn` called correctly in `BaysNotifier` ✅
- `moderatorAuthProvider` used in both `ModeratorRouter` (for redirect) and `BaysScreen` (for logout) ✅
