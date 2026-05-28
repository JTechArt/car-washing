# Lva Backend — Subsystem Spec

**Date:** 2026-05-28
**Stack:** Java 21, Spring Boot 3.2, PostgreSQL 16, Flyway, WebSockets (STOMP), JWT
**Depends on:** None (foundational)

---

## Module Map

| Module        | Package                | Responsibility                                             |
|---------------|------------------------|------------------------------------------------------------|
| auth          | am.lva.auth            | JWT issuance, Spring Security config, user roles           |
| tenancy       | am.lva.tenancy         | tenant_id resolution, Hibernate filter, white-label config |
| booking       | am.lva.booking         | slot engine, bay CRUD, walk-in blocks                      |
| notifications | am.lva.notifications   | STOMP WebSocket broker, push notification dispatch         |
| payments      | am.lva.payments        | ArCa, Idram, Telcell gateway adapters                      |
| analytics     | am.lva.analytics       | revenue reports, booking stats                             |

---

## Epic 1: Project Bootstrap

### Story 1.1 — Spring Boot project compiles and connects to PostgreSQL
As a developer, I want a running Spring Boot app connected to PostgreSQL via Docker Compose so that I have a working foundation for all modules.

Acceptance criteria:
- `docker compose up` starts postgres and backend
- `GET /actuator/health` returns {"status":"UP"}
- Flyway runs migrations on startup without errors
- OpenAPI spec available at `GET /v3/api-docs`

### Story 1.2 — Database migration baseline
As a developer, I want all core tables created via Flyway migrations so that the schema is version-controlled.

Tables to create in V1__baseline.sql: tenants, users, car_washes, bays, vehicles, bookings, walk_ins, subscriptions, corporate_accounts, prices

```sql
CREATE TABLE tenants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  slug VARCHAR(100) UNIQUE NOT NULL,
  logo_url TEXT,
  theme_color VARCHAR(7),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  phone VARCHAR(20) UNIQUE NOT NULL,
  email VARCHAR(255),
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(20) NOT NULL CHECK (role IN ('CUSTOMER','MODERATOR','OWNER','SUPER_ADMIN')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE car_washes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  name VARCHAR(255) NOT NULL,
  address TEXT NOT NULL,
  lat DOUBLE PRECISION NOT NULL,
  lng DOUBLE PRECISION NOT NULL,
  owner_user_id UUID NOT NULL REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE bays (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  car_wash_id UUID NOT NULL REFERENCES car_washes(id),
  name VARCHAR(100) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'IDLE' CHECK (status IN ('IDLE','OCCUPIED','BLOCKED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE vehicles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  plate VARCHAR(20) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('SEDAN','CROSSOVER','SUV','COUPE')),
  nickname VARCHAR(100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  bay_id UUID NOT NULL REFERENCES bays(id),
  user_id UUID NOT NULL REFERENCES users(id),
  vehicle_id UUID NOT NULL REFERENCES vehicles(id),
  service_type VARCHAR(50) NOT NULL,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (status IN ('PENDING','ARRIVED','WASHING','FINISHING','COMPLETED','CANCELLED')),
  payment_status VARCHAR(20) NOT NULL DEFAULT 'UNPAID' CHECK (payment_status IN ('UNPAID','PAID','REFUNDED')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE walk_ins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  bay_id UUID NOT NULL REFERENCES bays(id),
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE prices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  car_wash_id UUID NOT NULL REFERENCES car_washes(id),
  vehicle_type VARCHAR(20) NOT NULL CHECK (vehicle_type IN ('SEDAN','CROSSOVER','SUV','COUPE')),
  service_type VARCHAR(50) NOT NULL,
  duration_minutes INT NOT NULL,
  amount_amd INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (car_wash_id, vehicle_type, service_type)
);

CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id),
  plan_id VARCHAR(50) NOT NULL,
  valid_from TIMESTAMPTZ NOT NULL,
  valid_to TIMESTAMPTZ NOT NULL,
  washes_remaining INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE corporate_accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES tenants(id),
  company_name VARCHAR(255) NOT NULL,
  billing_cycle VARCHAR(20) NOT NULL CHECK (billing_cycle IN ('MONTHLY','QUARTERLY')),
  balance_amd INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_bookings_bay_time ON bookings(bay_id, starts_at, ends_at);
CREATE INDEX idx_bookings_user ON bookings(user_id);
CREATE INDEX idx_bays_car_wash ON bays(car_wash_id);
CREATE INDEX idx_car_washes_location ON car_washes(lat, lng);
```

---

## Epic 2: Authentication & Authorization

### Story 2.1 — User registration via phone number
As a new user, I want to register with my phone number so that I have an account.

Acceptance criteria:
- POST /api/auth/register accepts { phone, password, role }
- Password stored as bcrypt hash
- Returns JWT on success
- Returns 409 if phone already registered

### Story 2.2 — User login
As a registered user, I want to log in with phone and password so that I receive a JWT.

Acceptance criteria:
- POST /api/auth/login accepts { phone, password }
- Returns { token, expiresAt, role }
- Returns 401 on invalid credentials

### Story 2.3 — Role-based endpoint protection
Role hierarchy: CUSTOMER < MODERATOR < OWNER < SUPER_ADMIN

Protected routes:
- /api/owner/** — requires OWNER or SUPER_ADMIN
- /api/superadmin/** — requires SUPER_ADMIN
- /api/moderator/** — requires MODERATOR, OWNER, or SUPER_ADMIN
- /api/client/** — requires CUSTOMER or above

---

## Epic 3: Multi-Tenancy Infrastructure

### Story 3.1 — TenantContext resolved from JWT
As a system, I want the current tenant_id extracted from the JWT on every request so that all queries are automatically scoped.

Acceptance criteria:
- JWT contains tenantId claim (null for marketplace users)
- A Spring HandlerInterceptor sets TenantContext.set(tenantId) before each request
- TenantContext.clear() called after each request

### Story 3.2 — Hibernate tenant filter
As a system, I want all JPA queries on tenant-scoped entities filtered by tenant_id automatically so that no application code needs WHERE tenant_id = ? clauses.

Acceptance criteria:
- Hibernate filter tenantFilter defined with parameter tenantId
- Filter enabled on all tenant-scoped entities via @Filter annotation
- When tenantId is null (marketplace), filter is disabled and all records returned

---

## Epic 4: Car Wash & Bay Management

### Story 4.1 — CRUD for car washes
Endpoints:
- POST /api/owner/car-washes — create
- GET /api/owner/car-washes — list owned
- PUT /api/owner/car-washes/{id} — update
- DELETE /api/owner/car-washes/{id} — delete

Fields: name, address, lat, lng

### Story 4.2 — CRUD for bays
Endpoints:
- POST /api/owner/car-washes/{carWashId}/bays
- GET /api/owner/car-washes/{carWashId}/bays
- PUT /api/owner/bays/{id}
- DELETE /api/owner/bays/{id}

Bay statuses: IDLE, OCCUPIED, BLOCKED

### Story 4.3 — Public car wash listing for map
Endpoint: GET /api/client/car-washes
Response: id, name, lat, lng, availabilityStatus (GREEN/YELLOW/RED), nextSlotMinutes

Logic: GREEN = slot available < 15min, YELLOW = slot < 1hr, RED = no slots

---

## Epic 5: Booking Engine

### Story 5.1 — Slot availability calculation
Endpoint: GET /api/client/car-washes/{id}/slots?vehicleType=SEDAN&serviceType=EXTERIOR

Logic: duration from prices table, available slots = bays with no overlapping booking or walk-in in next 2 hours

### Story 5.2 — Create booking
Endpoint: POST /api/client/bookings
Body: { carWashId, vehicleId, serviceType, slotStartsAt }

Logic: finds first available bay, creates booking with status PENDING, broadcasts bay update via WebSocket

### Story 5.3 — Walk-in override (moderator)
Endpoint: POST /api/moderator/bays/{bayId}/walk-ins
Body: { estimatedDurationMinutes }

Logic: creates walk_ins record, sets bay status to OCCUPIED, broadcasts via WebSocket within 1.5s

### Story 5.4 — Booking status transitions (moderator)
Endpoint: PUT /api/moderator/bookings/{id}/status
Body: { status } — one of: ARRIVED, WASHING, FINISHING, COMPLETED

Logic: updates booking status, broadcasts to /topic/carwash/{carWashId}/bays via STOMP

---

## Epic 6: Vehicle & Garage Management

### Story 6.1 — Add vehicle to garage
Endpoint: POST /api/client/vehicles
Body: { plate, type (SEDAN|CROSSOVER|SUV|COUPE), nickname }

### Story 6.2 — List my vehicles
Endpoint: GET /api/client/vehicles

---

## Epic 7: Subscriptions & Corporate Accounts

### Story 7.1 — Purchase monthly subscription
Endpoint: POST /api/client/subscriptions
Body: { planId }

Logic: deducts payment, creates subscription with washes_remaining and valid_to = now + 30 days

### Story 7.2 — Corporate block booking reserve
Endpoint: POST /api/superadmin/corporate-accounts/{id}/reserves
Body: { carWashId, bayId, dayOfWeek, startTime, endTime }

---

## Epic 8: Payment Gateway Integration

### Story 8.1 — Payment gateway abstraction
Interface:

```java
public interface PaymentGateway {
    PaymentResult charge(PaymentRequest request);
    RefundResult refund(String transactionId);
}
```

Implementations: ArcaPaymentGateway, IdramPaymentGateway, TelcellPaymentGateway

---

## Epic 9: Real-Time WebSocket Infrastructure

### Story 9.1 — STOMP broker setup
- WebSocket endpoint: /ws
- STOMP broker prefix: /topic
- App destination prefix: /app
- JWT validated in STOMP CONNECT handshake

### Story 9.2 — Bay status broadcast
Topic: /topic/carwash/{carWashId}/bays
Payload: { bayId, status, bookingId? }
NFR: broadcast within ≤1.5 seconds

---

## Epic 10: Weather Notifications

### Story 10.1 — Weather check scheduled job
Schedule: every 6 hours
Yerevan coordinates: 40.1872, 44.5152

Trigger: if precipitation probability > 70% in next 24h, send push notification offering interior-only discount

---

## Epic 11: Analytics

### Story 11.1 — Revenue report by payment channel
Endpoint: GET /api/owner/analytics/revenue?from=2024-01-01&to=2024-01-31
Response: { total, breakdown: { CASH, APP_WALLET, CORPORATE } }
