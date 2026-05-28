# Lva Client App — Subsystem Spec

**Date:** 2026-05-28
**Stack:** Flutter 3, Dart, Riverpod, Dio, STOMP, Yandex Maps SDK, Hive
**Flavor entry point:** lib/main_client.dart
**Depends on:** Backend API

---

## Epic 1: Project Setup

### Story 1.1 — Flutter client flavor runs
**Acceptance criteria:**
- `flutter run --target lib/main_client.dart` launches the client app on iOS and Android
- Shared core/ layer (API client, WebSocket, models, auth) imports without errors

### Story 1.2 — API client generated from OpenAPI spec
**Acceptance criteria:**
- `make generate-api` or equivalent pulls spec from `GET http://localhost:8080/v3/api-docs`
- All models and endpoints available as typed Dart classes in lib/core/api/

---

## Epic 2: Authentication

### Story 2.1 — Login screen
**As a** user **I want** to log in with phone and password **So that** I can access the app

**Acceptance criteria:**
- Phone input with Armenian +374 prefix pre-filled
- Password field with show/hide toggle
- Submits to POST /api/auth/login
- JWT stored in Flutter Secure Storage on success
- Error banner on 401

### Story 2.2 — Registration screen
**Acceptance criteria:**
- Phone, password, confirm password fields
- Submits to POST /api/auth/register
- Navigates to map on success
- Inline validation: phone format, password match

### Story 2.3 — Auth state persistence
**Acceptance criteria:**
- On app launch, checks Secure Storage for existing JWT
- If valid (not expired), navigates directly to map screen
- If missing or expired, shows login screen

---

## Epic 3: Map & Car Wash Discovery

### Story 3.1 — Yandex Map with availability pins
**As a** customer **I want** to see car washes on a map **So that** I can find the nearest one

**Acceptance criteria:**
- Map rendered using Yandex Maps Flutter SDK centered on Yerevan (40.1872, 44.5152)
- Car wash pins colored by availability: Green (< 15 min), Yellow (< 1 hr), Red (fully booked)
- Pins fetched from GET /api/client/car-washes on map load
- Pins re-color in real time via WebSocket `/topic/carwash/{id}/bays`

### Story 3.2 — Car wash detail bottom sheet
**Acceptance criteria:**
- Tapping a pin opens a bottom sheet: name, address, ETA, available slots count, price preview
- "Book Now" button initiates the booking flow

### Story 3.3 — ETA display
**Acceptance criteria:**
- ETA calculated from user's current GPS location to the car wash using Yandex Routing API
- Displayed as "~12 min" on the pin and in the detail sheet

---

## Epic 4: Garage Management

### Story 4.1 — Add vehicle
**Acceptance criteria:**
- Form: plate number, vehicle type (Sedan / Crossover / SUV / Coupe), nickname
- Submits to POST /api/client/vehicles
- Appears in garage list immediately

### Story 4.2 — Garage list
**Acceptance criteria:**
- Lists all saved vehicles with type icon and nickname
- Swipe to delete (calls DELETE /api/client/vehicles/{id})
- Tap to set as default for quick booking

---

## Epic 5: 3-Tap Booking Flow

### Story 5.1 — Book in 3 taps
**As a** customer **I want** to book a wash in 3 taps **So that** the process is instant

Tap 1: Tap car wash pin on map
Tap 2: Tap saved vehicle in bottom sheet (+ service type selector)
Tap 3: Tap "Confirm Booking"

**Acceptance criteria:**
- Booking created via POST /api/client/bookings
- Confirmation screen shown with bay number, start time
- Error shown if no slots available

### Story 5.2 — Dynamic slot duration display
**Acceptance criteria:**
- Slot duration shown based on vehicleType + serviceType (from prices API)
- Example: Sedan Exterior = 25 min, SUV Full = 45 min

---

## Epic 6: Booking History & Live Status

### Story 6.1 — Booking list
**Acceptance criteria:**
- Lists upcoming and past bookings
- Each row: car wash name, vehicle, date/time, status badge
- Separate tabs for Upcoming / Past

### Story 6.2 — Live status on active booking
**Acceptance criteria:**
- Active booking shows real-time status via WebSocket (no manual refresh)
- Status values: Pending → Arrived → Washing → Finishing → Completed

---

## Epic 7: Subscriptions & Payments

### Story 7.1 — Subscription plans
**Acceptance criteria:**
- Lists available monthly pass plans with price and wash count
- "Buy" triggers payment (ArCa / Idram / Telcell selector)
- Active subscription shows remaining washes and expiry date
- Booking flow auto-applies active subscription when available

---

## Epic 8: Weather Push Notifications

### Story 8.1 — Receive discount notification
**Acceptance criteria:**
- App receives FCM push notification when backend triggers rain-based discount
- Notification shows: "Rain expected — 20% off interior cleaning today"
- Tapping notification opens subscription/booking screen with discount pre-applied
