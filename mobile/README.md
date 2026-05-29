# Lva Mobile

Flutter project with two apps in one codebase:
- **Client App** — customer-facing: map, booking, garage, subscriptions
- **Moderator App** — operator tablet: bay status, walk-in override

## Prerequisites

| Tool | Version |
|---|---|
| Flutter | 3.19+ |
| Dart | 3.3+ |
| Xcode | 15+ (iOS) |
| Android Studio | Hedgehog+ (Android) |

## Architecture

```
lib/
├── core/              Shared: API client, WebSocket, auth, models
├── client_app/        Customer screens
└── moderator_app/     Operator tablet screens
```

## Run Client App (iOS/Android)

```bash
cd mobile
flutter pub get
flutter run --target lib/main_client.dart
```

## Run Moderator App

```bash
flutter run --target lib/main_moderator.dart
```

## Configuration

Set backend URL in `lib/core/config.dart` (create this file):

```dart
class AppConfig {
  static const String apiBaseUrl = 'http://localhost:8080';
  static const String wsUrl = 'ws://localhost:8080/ws';
}
```

## WebSocket

Connects to backend STOMP broker via `stomp_dart_client`.
Subscribes to `/topic/carwash/{carWashId}/bays` for live bay updates.
JWT passed in STOMP CONNECT headers.
