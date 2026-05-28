# Lva Moderator App — Subsystem Spec

**Date:** 2026-05-28
**Stack:** Flutter 3, Dart, Riverpod, Dio, STOMP, Hive (offline cache)
**Flavor entry point:** lib/main_moderator.dart
**Target device:** Android/iOS tablet (10"+ screen)
**Depends on:** Backend API, shared mobile/lib/core/

---

## Epic 1: Moderator Authentication

### Story 1.1 — Login screen
**As a** moderator **I want** to log in with phone and password **So that** I can access the bay management panel

**Acceptance criteria:**
- Phone + password login form, tablet-optimized layout (centered card)
- Submits to POST /api/auth/login
- JWT stored in Flutter Secure Storage
- Role check: if JWT role is CUSTOMER, show error "Not authorized for staff access"
- On success, navigates to bay status panel

---

## Epic 2: Bay Status Panel

### Story 2.1 — Real-time bay status grid
**As a** moderator **I want** to see all bays at my car wash on one screen **So that** I can manage the queue

**Acceptance criteria:**
- All bays displayed as large cards in a responsive grid (2 columns on tablet)
- Each bay card shows: bay name, current status badge, active booking info (vehicle plate, service type, estimated time remaining)
- Status colors: Green border = IDLE, Blue border = OCCUPIED, Red border = BLOCKED
- Bay data fetched from GET /api/owner/car-washes/{carWashId}/bays on load
- Status updates received in real time via WebSocket `/topic/carwash/{carWashId}/bays`
- Live indicator shown in header ("● Live")

### Story 2.2 — One-tap status transition
**As a** moderator **I want** to tap once to advance a booking's status **So that** the customer app updates instantly

**Status flow:** PENDING → ARRIVED → WASHING → FINISHING → COMPLETED

**Acceptance criteria:**
- Each occupied bay card shows the next logical action as a prominent button
  - If status is PENDING or ARRIVED: show "Start Washing" (blue)
  - If status is WASHING: show "Mark Finishing" (orange)
  - If status is FINISHING: show "Complete" (green)
- Tap calls PUT /api/moderator/bookings/{id}/status
- Card updates immediately (optimistic UI), confirmed via WebSocket echo

---

## Epic 3: Walk-In Override

### Story 3.1 — Log a walk-in customer on an idle bay
**As a** moderator **I want** to block an idle bay for a walk-in customer **So that** the booking engine doesn't assign it to someone online

**Acceptance criteria:**
- "＋ Walk-In" button visible on every IDLE bay card
- Tapping opens a modal asking: estimated duration (15 / 25 / 45 / 60 min selector)
- Confirms via "Block Bay" button
- Calls POST /api/moderator/bays/{bayId}/walk-ins with { estimatedDurationMinutes }
- Bay immediately transitions to BLOCKED status with countdown timer
- Walk-in can be released early via "Release Bay" button on the blocked card

---

## Epic 4: Offline Resilience

### Story 4.1 — Queue status changes when offline
**As a** moderator **I want** the app to continue accepting my taps when internet is down **So that** I don't lose my workflow

**Acceptance criteria:**
- Status transition taps while offline are queued locally in Hive
- A banner shows: "You're offline — changes will sync when reconnected"
- On reconnect, queued actions are replayed in order via the API
- WebSocket reconnects automatically with exponential backoff (1s, 2s, 4s, 8s, max 30s)
- Banner dismisses once sync is complete
