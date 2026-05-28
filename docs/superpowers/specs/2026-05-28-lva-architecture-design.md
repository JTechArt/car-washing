# Lva — Overall Architecture Design

**Date:** 2026-05-28  
**Status:** Approved  
**Scope:** Monorepo structure, tech stack, and cross-cutting architecture for all four subsystems

---

## 1. Product Summary

**Lva (Լվա)** is a multi-tenant car wash booking and operations platform for the Armenian market (initially Yerevan). It solves the "phantom availability" problem by unifying a B2C marketplace with a live bay-management system controlled directly by wash operators. It is architected as a SaaS platform that can split into white-label standalone deployments for individual car wash operators.

---

## 2. Tech Stack

| Layer | Technology |
|---|---|
| Backend API | Java 21 + Spring Boot (modular monolith) |
| Database | PostgreSQL |
| Real-time | WebSockets over STOMP |
| Authentication | JWT + Spring Security |
| Mobile (Client + Moderator) | Flutter (single project, two flavors) |
| Admin Web | Next.js + TypeScript |
| Containerization | Docker / Docker Compose |
| CI/CD | GitHub Actions |
| Cloud Target (post-MVP) | AWS ECS or EKS |

---

## 3. Monorepo Folder Structure

```
/
├── backend/                    # Java 21 + Spring Boot modular monolith
├── mobile/                     # Flutter — flavors: client_app + moderator_app
├── admin-web/                  # Next.js + TypeScript
└── docs/
    ├── idea.md                 # Original PRD
    └── superpowers/
        └── specs/
            ├── 2026-05-28-lva-architecture-design.md   ← this file
            ├── 2026-05-28-backend-design.md
            ├── 2026-05-28-client-app-design.md
            ├── 2026-05-28-moderator-app-design.md
            └── 2026-05-28-admin-web-design.md
```

Each project folder is fully self-contained with its own build config, Dockerfile, and README. The four subsystem specs (listed above) each contain their own epics, user stories, and HTML mockups.

---

## 4. Backend Architecture

### 4.1 Module Structure

Single Spring Boot application, internally divided into six modules (Java packages with defined service interfaces — no cross-module direct class references):

```
backend/src/main/java/am/lva/
├── auth/           # JWT issuance, Spring Security config, user roles
├── tenancy/        # tenant_id resolution, white-label config
├── booking/        # slot engine, bay management, walk-in override
├── notifications/  # WebSocket broker (STOMP), push notifications
├── payments/       # ArCa, Idram, Telcell gateway adapters
└── analytics/      # revenue reports, booking stats (admin only)
```

Modules are **not microservices** — they share the same PostgreSQL database and JVM. Boundaries exist for navigability and future splitability.

### 4.2 Multi-Tenancy

Every tenant-scoped DB table carries a nullable `tenant_id` column:
- `NULL` = global Lva marketplace record
- Non-null = scoped to a specific white-label operator

A Spring `TenantContext` (thread-local, resolved from the JWT on each request) is applied as a Hibernate filter globally. No query-level `WHERE tenant_id = ?` is written in application code.

### 4.3 Real-Time Sync

WebSocket connections use STOMP over `/ws`. JWT is passed in the STOMP `CONNECT` handshake header. The `notifications` module broadcasts bay status changes to topic subscribers within ≤1.5 seconds (NFR requirement). Topics follow the pattern `/topic/carwash/{carWashId}/bays`.

### 4.4 Payment Gateways

ArCa, Idram, and Telcell are implemented as adapters behind a single `PaymentGateway` interface. Adding a new provider requires only a new adapter class — booking logic is not touched.

### 4.5 API Contract

Spring Boot generates an OpenAPI 3.0 spec at `/v3/api-docs`. Both `mobile/` and `admin-web/` use a `make generate-api` command to pull the spec and regenerate typed clients. This is the single source of truth for request/response shapes across all clients.

---

## 5. Mobile Architecture (Flutter)

### 5.1 Project Structure

```
mobile/
├── lib/
│   ├── core/               # Shared: API client, WebSocket service, auth, models
│   ├── client_app/         # Customer UI: map, booking flow, garage, subscriptions
│   └── moderator_app/      # Operator UI: bay status panel, walk-in override
├── flavors/
│   ├── client/             # main_client.dart, flavor constants
│   └── moderator/          # main_moderator.dart, flavor constants
├── mockups/                # Static HTML UX mockups per screen
└── pubspec.yaml
```

### 5.2 Shared Core

`core/` contains:
- HTTP API client (generated from OpenAPI spec)
- WebSocket client (STOMP connection to Spring broker)
- JWT storage (Flutter Secure Storage)
- Domain models (Booking, Bay, Vehicle, User)

Both flavors import exclusively from `core/` for networking and data — no duplication.

### 5.3 Client App (Customer-Facing)

- Yandex Maps Flutter SDK for interactive map with color-coded bay availability pins: Green (slot < 15 min), Yellow (slot < 1 hr), Red (fully booked)
- 3-tap booking flow: Open App → Tap saved vehicle on nearest wash pin → Confirm
- Garage management: save vehicles by type (Sedan, Crossover, SUV, Coupe)
- Subscription management (monthly pass, corporate reserve)
- Weather-triggered push notifications for interior-only discount offers (precipitation > 70%)

### 5.4 Moderator App (Operator Tablet-Facing)

- Tablet-optimized layout, large touch targets
- Single-screen bay status panel with one-tap status transitions: `Arrived → Start Wash → Finishing → Completed`
- Walk-in override button: creates an instant block on the server to prevent overbooking
- Offline resilience: state changes cached locally (Hive) and synced on reconnect

### 5.5 White-Label Tenant Config

The `tenant_id` for white-label builds is a compile-time Dart constant injected via flavor config. No runtime resolution needed on the client.

---

## 6. Admin Web Architecture

### 6.1 Project Structure

```
admin-web/
├── app/
│   ├── (auth)/             # Login page
│   ├── owner/              # Wash owner dashboard
│   │   ├── pricing/        # Vehicle tier pricing management
│   │   ├── analytics/      # Revenue splits by payment channel
│   │   └── bays/           # Bay configuration
│   └── superadmin/         # Super admin portal
│       ├── tenants/        # White-label asset management
│       ├── corporate/      # B2B invoicing, post-paid billing cycles
│       └── operators/      # Wash operator onboarding
├── components/             # Shared UI components
├── lib/
│   ├── api/                # Typed client (generated from OpenAPI spec)
│   └── websocket/          # Live bay status for owner dashboard
├── mockups/                # Static HTML UX mockups per screen
└── middleware.ts            # Role-based route protection
```

### 6.2 Key Decisions

- **Role-based routing** via Next.js middleware. JWT claim (`role: OWNER | SUPER_ADMIN`) gates portal areas server-side. Additional roles will be added in future phases.
- **Client-rendered pages** (`"use client"`) — no SSR needed for a back-office dashboard. Next.js is used for routing and TypeScript DX, not server rendering.
- **Live bay view** on the owner dashboard uses the same WebSocket broker as the mobile apps.
- **White-label asset config** (logo SVG URL, theme hex color) stored per tenant by super admin; injected as Flutter flavor constants at mobile build time.

---

## 7. Core Data Model

```sql
tenants             id, name, slug, logo_url, theme_color, created_at
users               id, tenant_id*, phone, email, role, created_at
car_washes          id, tenant_id*, name, address, lat, lng, owner_user_id
bays                id, tenant_id*, car_wash_id, name, status (IDLE|OCCUPIED|BLOCKED)
vehicles            id, user_id, plate, type (SEDAN|CROSSOVER|SUV|COUPE), nickname
bookings            id, tenant_id*, bay_id, user_id, vehicle_id, starts_at, ends_at, status, payment_status
walk_ins            id, tenant_id*, bay_id, starts_at, ends_at
subscriptions       id, user_id, plan_id, valid_from, valid_to, washes_remaining
corporate_accounts  id, tenant_id*, company_name, billing_cycle, balance
prices              id, tenant_id*, car_wash_id, vehicle_type, service_type, amount_amd
```

`tenant_id*` = nullable. NULL means global marketplace scope. Booking slot duration is derived at runtime from `prices.vehicle_type + service_type` — not stored on the booking.

---

## 8. CI/CD

### 8.1 MVP (Docker Compose)

```
docker-compose.yml    # postgres + spring boot app + adminer
```

Each project has a `Dockerfile`. Developers run `docker compose up` for a full local environment.

### 8.2 Post-MVP (GitHub Actions → AWS)

```
.github/workflows/
├── backend.yml       # Test → Build JAR → Docker push → Deploy to ECS/EKS
├── admin-web.yml     # Lint → Build → Deploy to S3+CloudFront or ECS
└── mobile.yml        # Flutter test → Build APK/IPA → Upload to TestFlight/Play
```

Three independent pipelines with path filtering — a change in `mobile/` does not trigger the backend pipeline.

---

## 9. MVP Scope vs Post-MVP

### MVP (Phase 1)
- Backend API with all 6 modules
- Client mobile app (iOS + Android): map, booking, garage, subscriptions
- Moderator tablet app: bay status panel, walk-in override
- Admin web: owner dashboard (pricing, analytics, bays), super admin (tenants, corporate, operators)
- ArCa, Idram, Telcell payment integration
- Weather-triggered discount notifications
- Docker Compose local + single-server deployment

### Post-MVP (Phase 2)
- Live CCTV stream per booking bay (HLS/RTSP in client app)
- White-label pipeline automation (scripted standalone app generation)
- AWS ECS/EKS deployment via GitHub Actions
- Additional user roles

---

## 10. Subsystem Implementation Order

1. **Backend API** — foundation; all other subsystems depend on it
2. **Client Mobile App** — highest user-facing value, drives adoption
3. **Moderator Tablet App** — operationalizes the "zero-wait" guarantee
4. **Admin Web** — operations and business management layer
