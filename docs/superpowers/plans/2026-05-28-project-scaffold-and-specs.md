# Lva Project Scaffold & Specs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the 3 project folder scaffolds (backend, mobile, admin-web) and write 4 subsystem spec documents with epics, user stories, and HTML mockups for each app.

**Architecture:** Monorepo with three independent projects sharing an OpenAPI contract. Backend is a Java 21 Spring Boot modular monolith. Mobile is a Flutter project with client_app and moderator_app flavors. Admin web is Next.js + TypeScript.

**Tech Stack:** Java 21 + Spring Boot 3, PostgreSQL, Flutter 3, Dart, Next.js 14, TypeScript, Docker, GitHub Actions

---

## Phase 1: Project Scaffolding

### Task 1: Create backend/ scaffold

**Files:**
- Create: `backend/pom.xml`
- Create: `backend/src/main/java/am/lva/LvaApplication.java`
- Create: `backend/src/main/resources/application.yml`
- Create: `backend/Dockerfile`
- Create: `backend/.gitignore`
- Create: `backend/README.md`

- [ ] **Step 1: Create backend/pom.xml**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 https://maven.apache.org/xsd/maven-4.0.0.xsd">
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.2.5</version>
  </parent>
  <groupId>am.lva</groupId>
  <artifactId>lva-backend</artifactId>
  <version>0.0.1-SNAPSHOT</version>
  <name>lva-backend</name>
  <properties>
    <java.version>21</java.version>
    <jjwt.version>0.12.5</jjwt.version>
  </properties>
  <dependencies>
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-web</artifactId></dependency>
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-data-jpa</artifactId></dependency>
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-security</artifactId></dependency>
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-websocket</artifactId></dependency>
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-validation</artifactId></dependency>
    <dependency><groupId>org.postgresql</groupId><artifactId>postgresql</artifactId><scope>runtime</scope></dependency>
    <dependency><groupId>org.flywaydb</groupId><artifactId>flyway-core</artifactId></dependency>
    <dependency><groupId>org.flywaydb</groupId><artifactId>flyway-database-postgresql</artifactId></dependency>
    <dependency><groupId>org.projectlombok</groupId><artifactId>lombok</artifactId><optional>true</optional></dependency>
    <dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-api</artifactId><version>${jjwt.version}</version></dependency>
    <dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-impl</artifactId><version>${jjwt.version}</version><scope>runtime</scope></dependency>
    <dependency><groupId>io.jsonwebtoken</groupId><artifactId>jjwt-jackson</artifactId><version>${jjwt.version}</version><scope>runtime</scope></dependency>
    <dependency><groupId>org.springdoc</groupId><artifactId>springdoc-openapi-starter-webmvc-ui</artifactId><version>2.5.0</version></dependency>
    <dependency><groupId>org.springframework.boot</groupId><artifactId>spring-boot-starter-test</artifactId><scope>test</scope></dependency>
    <dependency><groupId>org.springframework.security</groupId><artifactId>spring-security-test</artifactId><scope>test</scope></dependency>
  </dependencies>
  <build>
    <plugins>
      <plugin><groupId>org.springframework.boot</groupId><artifactId>spring-boot-maven-plugin</artifactId></plugin>
    </plugins>
  </build>
</project>
```

- [ ] **Step 2: Create backend/src/main/java/am/lva/LvaApplication.java**

```java
package am.lva;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class LvaApplication {
    public static void main(String[] args) {
        SpringApplication.run(LvaApplication.class, args);
    }
}
```

- [ ] **Step 3: Create backend/src/main/resources/application.yml**

```yaml
spring:
  application:
    name: lva-backend
  datasource:
    url: ${DB_URL:jdbc:postgresql://localhost:5432/lva}
    username: ${DB_USER:lva}
    password: ${DB_PASS:lva}
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
  flyway:
    enabled: true
    locations: classpath:db/migration

server:
  port: 8080

lva:
  jwt:
    secret: ${JWT_SECRET:change-me-in-production-min-32-chars}
    expiry-ms: 86400000

springdoc:
  api-docs:
    path: /v3/api-docs
  swagger-ui:
    path: /swagger-ui.html
```

- [ ] **Step 4: Create backend/Dockerfile**

```dockerfile
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY target/lva-backend-*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

- [ ] **Step 5: Create backend/.gitignore**

```
target/
*.class
*.jar
.env
.idea/
*.iml
```

- [ ] **Step 6: Create backend/README.md**

```markdown
# Lva Backend

Java 21 + Spring Boot 3 modular monolith.

## Run locally
docker compose up

## Build
./mvnw clean package -DskipTests

## API docs
http://localhost:8080/swagger-ui.html
```

- [ ] **Step 7: Create docker-compose.yml at repo root**

```yaml
version: '3.9'
services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: lva
      POSTGRES_USER: lva
      POSTGRES_PASSWORD: lva
    ports:
      - "5432:5432"
    volumes:
      - pgdata:/var/lib/postgresql/data

  backend:
    build: ./backend
    ports:
      - "8080:8080"
    environment:
      DB_URL: jdbc:postgresql://postgres:5432/lva
      DB_USER: lva
      DB_PASS: lva
      JWT_SECRET: dev-secret-change-in-production
    depends_on:
      - postgres

volumes:
  pgdata:
```

- [ ] **Step 8: Commit**

```bash
git add backend/ docker-compose.yml
git commit -m "chore: scaffold backend Spring Boot project"
```

---

### Task 2: Create mobile/ scaffold

**Files:**
- Create: `mobile/pubspec.yaml`
- Create: `mobile/lib/main_client.dart`
- Create: `mobile/lib/main_moderator.dart`
- Create: `mobile/lib/core/.gitkeep`
- Create: `mobile/lib/client_app/.gitkeep`
- Create: `mobile/lib/moderator_app/.gitkeep`
- Create: `mobile/mockups/client/.gitkeep`
- Create: `mobile/mockups/moderator/.gitkeep`
- Create: `mobile/README.md`

- [ ] **Step 1: Create mobile/pubspec.yaml**

```yaml
name: lva_mobile
description: Lva car wash booking — client and moderator apps
publish_to: none
version: 1.0.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"
  flutter: ">=3.19.0"

dependencies:
  flutter:
    sdk: flutter
  flutter_secure_storage: ^9.0.0
  dio: ^5.4.3
  stomp_dart_client: ^1.0.0
  hive_flutter: ^1.1.0
  go_router: ^13.2.0
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  flutter_local_notifications: ^17.1.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0

flutter:
  uses-material-design: true
```

- [ ] **Step 2: Create mobile/lib/main_client.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: ClientApp()));
}

class ClientApp extends StatelessWidget {
  const ClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lva',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B4F72),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('Lva Client App'))),
    );
  }
}
```

- [ ] **Step 3: Create mobile/lib/main_moderator.dart**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: ModeratorApp()));
}

class ModeratorApp extends StatelessWidget {
  const ModeratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lva Moderator',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1B4F72),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('Lva Moderator App'))),
    );
  }
}
```

- [ ] **Step 4: Create placeholder directories**

```bash
mkdir -p mobile/lib/core mobile/lib/client_app mobile/lib/moderator_app
mkdir -p mobile/mockups/client mobile/mockups/moderator
touch mobile/lib/core/.gitkeep mobile/lib/client_app/.gitkeep mobile/lib/moderator_app/.gitkeep
touch mobile/mockups/client/.gitkeep mobile/mockups/moderator/.gitkeep
```

- [ ] **Step 5: Create mobile/README.md**

```markdown
# Lva Mobile

Flutter project with two flavors: client_app (customer) and moderator_app (operator tablet).

## Run client app
flutter run --target lib/main_client.dart

## Run moderator app
flutter run --target lib/main_moderator.dart

## Install dependencies
flutter pub get
```

- [ ] **Step 6: Commit**

```bash
git add mobile/
git commit -m "chore: scaffold Flutter mobile project with client and moderator flavors"
```

---

### Task 3: Create admin-web/ scaffold

**Files:**
- Create: `admin-web/package.json`
- Create: `admin-web/tsconfig.json`
- Create: `admin-web/next.config.ts`
- Create: `admin-web/app/layout.tsx`
- Create: `admin-web/app/page.tsx`
- Create: `admin-web/middleware.ts`
- Create: `admin-web/Dockerfile`
- Create: `admin-web/mockups/.gitkeep`
- Create: `admin-web/README.md`

- [ ] **Step 1: Create admin-web/package.json**

```json
{
  "name": "lva-admin-web",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "generate-api": "openapi-generator-cli generate -i http://localhost:8080/v3/api-docs -g typescript-fetch -o lib/api/generated"
  },
  "dependencies": {
    "next": "14.2.3",
    "react": "^18",
    "react-dom": "^18",
    "jose": "^5.3.0",
    "@stomp/stompjs": "^7.0.0",
    "@tanstack/react-query": "^5.40.0",
    "zustand": "^4.5.2"
  },
  "devDependencies": {
    "typescript": "^5",
    "@types/node": "^20",
    "@types/react": "^18",
    "@types/react-dom": "^18",
    "tailwindcss": "^3.4.1",
    "autoprefixer": "^10.4.19",
    "postcss": "^8.4.38",
    "eslint": "^8",
    "eslint-config-next": "14.2.3",
    "@openapitools/openapi-generator-cli": "^2.13.4"
  }
}
```

- [ ] **Step 2: Create admin-web/tsconfig.json**

```json
{
  "compilerOptions": {
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

- [ ] **Step 3: Create admin-web/next.config.ts**

```ts
import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
  output: 'standalone',
}

export default nextConfig
```

- [ ] **Step 4: Create admin-web/app/layout.tsx**

```tsx
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Lva Admin',
  description: 'Lva car wash operations portal',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
```

- [ ] **Step 5: Create admin-web/app/page.tsx**

```tsx
export default function Home() {
  return <main><h1>Lva Admin</h1></main>
}
```

- [ ] **Step 6: Create admin-web/middleware.ts**

```ts
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const token = request.cookies.get('lva_token')?.value
  const { pathname } = request.nextUrl

  if (pathname.startsWith('/owner') || pathname.startsWith('/superadmin')) {
    if (!token) {
      return NextResponse.redirect(new URL('/login', request.url))
    }
  }
  return NextResponse.next()
}

export const config = {
  matcher: ['/owner/:path*', '/superadmin/:path*'],
}
```

- [ ] **Step 7: Create admin-web/Dockerfile**

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
EXPOSE 3000
CMD ["node", "server.js"]
```

- [ ] **Step 8: Create admin-web/README.md**

```markdown
# Lva Admin Web

Next.js 14 + TypeScript admin portal for wash owners and super admins.

## Run locally
npm install && npm run dev

## Regenerate API client (backend must be running)
npm run generate-api
```

- [ ] **Step 9: Commit**

```bash
git add admin-web/
git commit -m "chore: scaffold Next.js admin web project"
```

---

## Phase 2: Backend Spec

### Task 4: Write backend spec document

**Files:**
- Create: `docs/superpowers/specs/2026-05-28-backend-design.md`

- [ ] **Step 1: Write the spec**

Create `docs/superpowers/specs/2026-05-28-backend-design.md` with the following content:

```markdown
# Lva Backend — Subsystem Spec

**Date:** 2026-05-28
**Stack:** Java 21, Spring Boot 3.2, PostgreSQL 16, Flyway, WebSockets (STOMP), JWT
**Depends on:** None (foundational)

---

## Module Map

| Module | Package | Responsibility |
|---|---|---|
| auth | am.lva.auth | JWT issuance, Spring Security config, user roles |
| tenancy | am.lva.tenancy | tenant_id resolution, Hibernate filter, white-label config |
| booking | am.lva.booking | slot engine, bay CRUD, walk-in blocks |
| notifications | am.lva.notifications | STOMP WebSocket broker, push notification dispatch |
| payments | am.lva.payments | ArCa, Idram, Telcell gateway adapters |
| analytics | am.lva.analytics | revenue reports, booking stats |

---

## Epic 1: Project Bootstrap

### Story 1.1 — Spring Boot project compiles and connects to PostgreSQL
**As a** developer
**I want** a running Spring Boot app connected to PostgreSQL via Docker Compose
**So that** I have a working foundation for all modules

**Acceptance criteria:**
- `docker compose up` starts postgres and backend
- `GET /actuator/health` returns `{"status":"UP"}`
- Flyway runs migrations on startup without errors
- OpenAPI spec available at `GET /v3/api-docs`

### Story 1.2 — Database migration baseline
**As a** developer
**I want** all core tables created via Flyway migrations
**So that** the schema is version-controlled

**Tables to create in V1__baseline.sql:**
- tenants, users, car_washes, bays, vehicles, bookings, walk_ins, subscriptions, corporate_accounts, prices

---

## Epic 2: Authentication & Authorization

### Story 2.1 — User registration via phone number
**As a** new user
**I want** to register with my phone number
**So that** I have an account on the platform

**Acceptance criteria:**
- `POST /api/auth/register` accepts `{ phone, password, role }`
- Password stored as bcrypt hash
- Returns JWT on success
- Returns 409 if phone already registered

### Story 2.2 — User login
**As a** registered user
**I want** to log in with phone and password
**So that** I receive a JWT for subsequent requests

**Acceptance criteria:**
- `POST /api/auth/login` accepts `{ phone, password }`
- Returns `{ token, expiresAt, role }`
- Returns 401 on invalid credentials

### Story 2.3 — Role-based endpoint protection
**As a** system
**I want** endpoints protected by role
**So that** customers cannot access owner or admin endpoints

**Role hierarchy:** CUSTOMER < MODERATOR < OWNER < SUPER_ADMIN

**Protected routes:**
- `/api/owner/**` — requires OWNER or SUPER_ADMIN
- `/api/superadmin/**` — requires SUPER_ADMIN
- `/api/moderator/**` — requires MODERATOR, OWNER, or SUPER_ADMIN
- `/api/client/**` — requires CUSTOMER or above

---

## Epic 3: Multi-Tenancy Infrastructure

### Story 3.1 — TenantContext resolved from JWT
**As a** system
**I want** the current tenant_id extracted from the JWT on every request
**So that** all queries are automatically scoped

**Acceptance criteria:**
- JWT contains `tenantId` claim (null for marketplace users)
- A Spring `HandlerInterceptor` sets `TenantContext.set(tenantId)` before each request
- `TenantContext.clear()` is called after each request

### Story 3.2 — Hibernate tenant filter
**As a** system
**I want** all JPA queries on tenant-scoped entities filtered by tenant_id automatically
**So that** no application code needs WHERE tenant_id = ? clauses

**Acceptance criteria:**
- Hibernate filter `tenantFilter` defined with parameter `tenantId`
- Filter enabled on all tenant-scoped entities via `@Filter` annotation
- When `tenantId` is null (marketplace), filter is disabled and all records are returned

---

## Epic 4: Car Wash & Bay Management

### Story 4.1 — CRUD for car washes
**As an** owner
**I want** to create and manage my car wash locations
**So that** they appear on the client app map

**Endpoints:**
- `POST /api/owner/car-washes` — create
- `GET /api/owner/car-washes` — list owned
- `PUT /api/owner/car-washes/{id}` — update
- `DELETE /api/owner/car-washes/{id}` — delete

**Fields:** name, address, lat, lng

### Story 4.2 — CRUD for bays
**As an** owner
**I want** to define the washing bays at my car wash
**So that** the booking engine knows capacity

**Endpoints:**
- `POST /api/owner/car-washes/{carWashId}/bays` — create bay
- `GET /api/owner/car-washes/{carWashId}/bays` — list bays
- `PUT /api/owner/bays/{id}` — update
- `DELETE /api/owner/bays/{id}` — delete

**Bay statuses:** IDLE, OCCUPIED, BLOCKED

### Story 4.3 — Public car wash listing for map
**As a** customer
**I want** to see all car washes with current slot availability
**So that** I can pick one on the map

**Endpoint:** `GET /api/client/car-washes`
**Response:** id, name, lat, lng, availabilityStatus (GREEN/YELLOW/RED), nextSlotMinutes

---

## Epic 5: Booking Engine

### Story 5.1 — Slot availability calculation
**As a** customer
**I want** to see available time slots at a car wash
**So that** I can pick a time that works

**Endpoint:** `GET /api/client/car-washes/{id}/slots?vehicleType=SEDAN&serviceType=EXTERIOR`
**Logic:** Slot duration = derived from prices table by vehicleType + serviceType. Available slots = bays with no overlapping booking or walk-in in the next 2 hours.

### Story 5.2 — Create booking
**As a** customer
**I want** to book a slot
**So that** my bay is reserved

**Endpoint:** `POST /api/client/bookings`
**Body:** `{ carWashId, vehicleId, serviceType, slotStartsAt }`
**Logic:** Finds first available bay for the slot, creates booking with status PENDING, broadcasts bay update via WebSocket.

### Story 5.3 — Walk-in override (moderator)
**As a** moderator
**I want** to log a walk-in customer
**So that** the slot is blocked and online users cannot double-book

**Endpoint:** `POST /api/moderator/bays/{bayId}/walk-ins`
**Body:** `{ estimatedDurationMinutes }`
**Logic:** Creates a walk_ins record, sets bay status to OCCUPIED, broadcasts via WebSocket within 1.5s.

### Story 5.4 — Booking status transitions (moderator)
**As a** moderator
**I want** to update booking status with one tap
**So that** the customer app reflects the real state

**Endpoint:** `PUT /api/moderator/bookings/{id}/status`
**Body:** `{ status }` — one of: ARRIVED, WASHING, FINISHING, COMPLETED
**Logic:** Updates booking status, broadcasts to `/topic/carwash/{carWashId}/bays` via STOMP.

---

## Epic 6: Vehicle & Garage Management

### Story 6.1 — Add vehicle to garage
**As a** customer
**I want** to save my vehicles
**So that** I can book quickly without re-entering details

**Endpoint:** `POST /api/client/vehicles`
**Body:** `{ plate, type (SEDAN|CROSSOVER|SUV|COUPE), nickname }`

### Story 6.2 — List my vehicles
**Endpoint:** `GET /api/client/vehicles`

---

## Epic 7: Subscriptions & Corporate Accounts

### Story 7.1 — Purchase monthly subscription
**As a** customer
**I want** to buy a monthly wash pass
**So that** I get discounted washes

**Endpoint:** `POST /api/client/subscriptions`
**Body:** `{ planId }`
**Logic:** Deducts payment, creates subscription record with washes_remaining and valid_to = now + 30 days.

### Story 7.2 — Corporate block booking reserve
**As a** corporate account
**I want** to reserve a bay for a recurring time block
**So that** my employees can use it without pre-booking

**Endpoint:** `POST /api/superadmin/corporate-accounts/{id}/reserves`
**Body:** `{ carWashId, bayId, dayOfWeek, startTime, endTime }`

---

## Epic 8: Payment Gateway Integration

### Story 8.1 — Payment gateway abstraction
**As a** developer
**I want** a single PaymentGateway interface
**So that** adding a new provider does not touch booking logic

**Interface:**
```java
public interface PaymentGateway {
    PaymentResult charge(PaymentRequest request);
    RefundResult refund(String transactionId);
}
```

**Implementations:** ArcaPaymentGateway, IdramPaymentGateway, TelcellPaymentGateway

---

## Epic 9: Real-Time WebSocket Infrastructure

### Story 9.1 — STOMP broker setup
**As a** developer
**I want** a STOMP WebSocket endpoint
**So that** mobile and web clients receive live bay updates

**Config:**
- WebSocket endpoint: `/ws`
- STOMP broker prefix: `/topic`
- App destination prefix: `/app`
- JWT validated in STOMP CONNECT handshake

### Story 9.2 — Bay status broadcast
**As a** system
**I want** bay status changes broadcast to subscribers within 1.5s
**So that** client app map pins update in real time

**Topic:** `/topic/carwash/{carWashId}/bays`
**Payload:** `{ bayId, status, bookingId? }`

---

## Epic 10: Weather Notifications

### Story 10.1 — Weather check job
**As a** system
**I want** a scheduled job that checks Yerevan precipitation forecast
**So that** discount notifications are triggered when rain probability > 70%

**Schedule:** Every 6 hours
**API:** OpenWeatherMap or similar, Yerevan coordinates (40.1872, 44.5152)
**Action:** If precipitation probability > 0.70 for next 24h, send push notification to all active customers offering interior-only discount.

---

## Epic 11: Analytics

### Story 11.1 — Revenue report by payment channel
**As an** owner
**I want** to see revenue split by cash vs app wallet vs corporate
**So that** I understand my payment mix

**Endpoint:** `GET /api/owner/analytics/revenue?from=2024-01-01&to=2024-01-31`
**Response:** `{ total, breakdown: { CASH, APP_WALLET, CORPORATE } }`
```

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/specs/2026-05-28-backend-design.md
git commit -m "docs: add backend subsystem spec with epics and stories"
```

---

## Phase 3: Client App Spec & Mockups

### Task 5: Write client app spec

**Files:**
- Create: `docs/superpowers/specs/2026-05-28-client-app-design.md`

- [ ] **Step 1: Write the spec**

Create `docs/superpowers/specs/2026-05-28-client-app-design.md`:

```markdown
# Lva Client App — Subsystem Spec

**Date:** 2026-05-28
**Stack:** Flutter 3, Dart, Riverpod, Dio, STOMP, Yandex Maps SDK, Hive
**Depends on:** backend API running at configured base URL

---

## Epic 1: Project Setup

### Story 1.1 — Flutter project runs both flavors
**Acceptance criteria:**
- `flutter run --target lib/main_client.dart` launches client app
- `flutter run --target lib/main_moderator.dart` launches moderator app (separate epic)
- Shared `core/` layer imports cleanly in both

### Story 1.2 — API client generated from OpenAPI spec
**Acceptance criteria:**
- `make generate-api` pulls spec from backend and generates `lib/core/api/`
- All models and endpoints typed

---

## Epic 2: Authentication

### Story 2.1 — Phone + password login screen
**As a** user
**I want** to log in with my phone number and password
**So that** I can access the app

**Acceptance criteria:**
- Phone input with Armenian +374 prefix
- Password field with toggle visibility
- Submits to `POST /api/auth/login`
- JWT stored in Flutter Secure Storage on success
- Error banner shown on 401

### Story 2.2 — Registration screen
**Acceptance criteria:**
- Phone, password, confirm password fields
- Submits to `POST /api/auth/register`
- Navigates to map on success

### Story 2.3 — Auth state persistence
**Acceptance criteria:**
- On app launch, checks Secure Storage for existing JWT
- If valid (not expired), goes directly to map screen
- If missing/expired, shows login screen

---

## Epic 3: Map & Car Wash Discovery

### Story 3.1 — Yandex Map with car wash pins
**As a** customer
**I want** to see car washes on a map
**So that** I can find the nearest one

**Acceptance criteria:**
- Map rendered using Yandex Maps Flutter SDK centered on Yerevan (40.1872, 44.5152)
- Car wash pins colored by availability: Green (< 15 min), Yellow (< 1 hr), Red (fully booked)
- Pins fetched from `GET /api/client/car-washes` on map load
- Pins update in real time via WebSocket `/topic/carwash/{id}/bays`

### Story 3.2 — Car wash detail bottom sheet
**Acceptance criteria:**
- Tapping a pin opens a bottom sheet with: name, address, ETA, available slots, price preview
- "Book Now" button initiates booking flow

### Story 3.3 — ETA display
**Acceptance criteria:**
- ETA calculated using Yandex Routing API from user's current location to car wash
- Displayed as "~12 min" on the pin and in the detail sheet

---

## Epic 4: Garage Management

### Story 4.1 — Add vehicle
**As a** customer
**I want** to save my car details
**So that** I can book without re-entering them

**Acceptance criteria:**
- Form: plate number, vehicle type (Sedan/Crossover/SUV/Coupe), nickname
- Submits to `POST /api/client/vehicles`
- Vehicle appears in garage list

### Story 4.2 — Garage list screen
**Acceptance criteria:**
- Lists all saved vehicles with type icon and nickname
- Swipe to delete
- Tap to set as default for booking

---

## Epic 5: 3-Tap Booking Flow

### Story 5.1 — 3-tap booking: tap vehicle on pin → confirm
**As a** customer
**I want** to book a wash in 3 taps
**So that** the process is fast

**Tap 1:** Tap car wash pin on map
**Tap 2:** Tap saved vehicle in bottom sheet (shows vehicle list + service type selector)
**Tap 3:** Tap "Confirm Booking" button

**Acceptance criteria:**
- Booking created via `POST /api/client/bookings`
- Confirmation screen shown with bay number, start time, and QR code (booking ID encoded)
- Push notification sent confirming booking

### Story 5.2 — Dynamic slot duration
**Acceptance criteria:**
- Slot duration shown based on vehicleType + serviceType (from prices API)
- e.g., Sedan Exterior = 25 min, SUV Full = 45 min

---

## Epic 6: Booking History

### Story 6.1 — Booking list screen
**Acceptance criteria:**
- Lists upcoming and past bookings
- Each row: car wash name, vehicle, date/time, status badge
- Tap to see booking detail

### Story 6.2 — Live status updates on active booking
**Acceptance criteria:**
- Active booking shows live status (Arrived / Washing / Finishing / Completed)
- Status updates via WebSocket without refresh

---

## Epic 7: Subscriptions & Payments

### Story 7.1 — Subscription plans screen
**Acceptance criteria:**
- Lists available monthly pass plans with price and wash count
- "Buy" triggers payment flow (ArCa / Idram / Telcell selector)
- Active subscription shown with remaining washes and expiry date

---

## Epic 8: Weather Push Notifications

### Story 8.1 — Receive weather discount notification
**Acceptance criteria:**
- App receives push notification when backend triggers rain discount
- Notification tap opens subscription/booking screen with discount pre-applied
```

- [ ] **Step 2: Commit**

```bash
git add docs/superpowers/specs/2026-05-28-client-app-design.md
git commit -m "docs: add client app subsystem spec"
```

---

### Task 6: Create client app HTML mockups

**Files:**
- Create: `mobile/mockups/client/01-login.html`
- Create: `mobile/mockups/client/02-map.html`
- Create: `mobile/mockups/client/03-wash-detail.html`
- Create: `mobile/mockups/client/04-booking-flow.html`
- Create: `mobile/mockups/client/05-garage.html`
- Create: `mobile/mockups/client/06-booking-history.html`

- [ ] **Step 1: Create mobile/mockups/client/01-login.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Lva — Login</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #0f1923; display: flex; justify-content: center; align-items: center; min-height: 100vh; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
  .phone { width: 390px; height: 844px; background: #fff; border-radius: 44px; overflow: hidden; box-shadow: 0 30px 80px rgba(0,0,0,0.6); position: relative; display: flex; flex-direction: column; }
  .status-bar { height: 48px; background: #1B4F72; display: flex; align-items: flex-end; justify-content: space-between; padding: 0 28px 8px; }
  .status-bar span { color: white; font-size: 12px; font-weight: 600; }
  .content { flex: 1; background: #fff; display: flex; flex-direction: column; padding: 40px 28px; }
  .logo { width: 72px; height: 72px; background: #1B4F72; border-radius: 20px; display: flex; align-items: center; justify-content: center; margin-bottom: 32px; }
  .logo span { color: white; font-size: 28px; font-weight: 800; }
  h1 { font-size: 28px; font-weight: 700; color: #1a1a2e; margin-bottom: 6px; }
  .subtitle { font-size: 15px; color: #6b7280; margin-bottom: 40px; }
  label { font-size: 13px; font-weight: 600; color: #374151; margin-bottom: 6px; display: block; }
  .input-group { margin-bottom: 20px; }
  .phone-input { display: flex; gap: 8px; }
  .prefix { height: 52px; width: 72px; border: 1.5px solid #e5e7eb; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-weight: 600; color: #374151; font-size: 15px; background: #f9fafb; }
  input { height: 52px; border: 1.5px solid #e5e7eb; border-radius: 12px; padding: 0 16px; font-size: 16px; color: #1a1a2e; width: 100%; outline: none; }
  input:focus { border-color: #1B4F72; }
  .btn-primary { width: 100%; height: 56px; background: #1B4F72; color: white; border: none; border-radius: 16px; font-size: 17px; font-weight: 700; cursor: pointer; margin-top: 8px; }
  .divider { text-align: center; color: #9ca3af; font-size: 13px; margin: 20px 0; }
  .btn-secondary { width: 100%; height: 52px; background: #f3f4f6; color: #374151; border: none; border-radius: 16px; font-size: 15px; font-weight: 600; cursor: pointer; }
  .footer { text-align: center; margin-top: 24px; font-size: 13px; color: #6b7280; }
  .footer a { color: #1B4F72; font-weight: 600; text-decoration: none; }
</style>
</head>
<body>
<div class="phone">
  <div class="status-bar">
    <span>9:41</span>
    <span>●●●</span>
  </div>
  <div class="content">
    <div class="logo"><span>Լ</span></div>
    <h1>Welcome back</h1>
    <p class="subtitle">Sign in to book your car wash</p>
    <div class="input-group">
      <label>Phone number</label>
      <div class="phone-input">
        <div class="prefix">+374</div>
        <input type="tel" placeholder="77 123 456" style="flex:1;">
      </div>
    </div>
    <div class="input-group">
      <label>Password</label>
      <input type="password" placeholder="••••••••">
    </div>
    <button class="btn-primary">Sign In</button>
    <div class="divider">or</div>
    <button class="btn-secondary">Create Account</button>
    <p class="footer">Forgot password? <a href="#">Reset</a></p>
  </div>
</div>
</body>
</html>
```

- [ ] **Step 2: Create mobile/mockups/client/02-map.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Lva — Map</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #0f1923; display: flex; justify-content: center; align-items: center; min-height: 100vh; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
  .phone { width: 390px; height: 844px; background: #e8f0f7; border-radius: 44px; overflow: hidden; box-shadow: 0 30px 80px rgba(0,0,0,0.6); position: relative; display: flex; flex-direction: column; }
  .status-bar { height: 48px; background: rgba(255,255,255,0.9); display: flex; align-items: flex-end; justify-content: space-between; padding: 0 28px 8px; position: absolute; top: 0; left: 0; right: 0; z-index: 10; }
  .status-bar span { font-size: 12px; font-weight: 600; color: #1a1a2e; }
  .map-bg { flex: 1; background: linear-gradient(135deg, #d4e6f1 0%, #c8dff0 30%, #d8e8d8 60%, #e0d8c0 100%); position: relative; overflow: hidden; }
  .road-h { position: absolute; height: 8px; background: rgba(255,255,255,0.6); left: 0; right: 0; }
  .road-v { position: absolute; width: 8px; background: rgba(255,255,255,0.6); top: 0; bottom: 0; }
  .pin { position: absolute; display: flex; flex-direction: column; align-items: center; cursor: pointer; }
  .pin-dot { width: 44px; height: 44px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 20px; box-shadow: 0 4px 12px rgba(0,0,0,0.25); border: 3px solid white; }
  .pin-label { background: white; border-radius: 8px; padding: 2px 8px; font-size: 11px; font-weight: 700; margin-top: 4px; box-shadow: 0 2px 6px rgba(0,0,0,0.15); }
  .green .pin-dot { background: #27AE60; }
  .yellow .pin-dot { background: #F39C12; }
  .red .pin-dot { background: #E74C3C; }
  .search-bar { position: absolute; top: 60px; left: 16px; right: 16px; background: white; border-radius: 16px; height: 48px; display: flex; align-items: center; padding: 0 16px; gap: 10px; box-shadow: 0 4px 16px rgba(0,0,0,0.12); z-index: 9; }
  .search-bar span { color: #9ca3af; font-size: 14px; flex: 1; }
  .my-location { position: absolute; right: 16px; bottom: 180px; width: 48px; height: 48px; background: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 12px rgba(0,0,0,0.2); font-size: 22px; }
  .bottom-bar { height: 140px; background: white; padding: 16px 20px; }
  .quick-book { background: #1B4F72; border-radius: 16px; padding: 16px; display: flex; align-items: center; gap: 12px; }
  .car-icon { width: 48px; height: 48px; background: rgba(255,255,255,0.15); border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 24px; }
  .quick-book-text h3 { color: white; font-size: 15px; font-weight: 700; }
  .quick-book-text p { color: rgba(255,255,255,0.7); font-size: 12px; margin-top: 2px; }
  .arrow { margin-left: auto; color: white; font-size: 20px; }
  .nav-bar { height: 68px; background: white; border-top: 1px solid #f3f4f6; display: flex; align-items: center; justify-content: space-around; padding-bottom: 8px; }
  .nav-item { display: flex; flex-direction: column; align-items: center; gap: 3px; }
  .nav-item span:first-child { font-size: 22px; }
  .nav-item span:last-child { font-size: 10px; color: #9ca3af; }
  .nav-item.active span:last-child { color: #1B4F72; font-weight: 700; }
  .legend { position: absolute; left: 16px; bottom: 220px; background: white; border-radius: 12px; padding: 10px 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.12); }
  .legend-row { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; font-size: 11px; color: #374151; }
  .legend-dot { width: 10px; height: 10px; border-radius: 50%; }
</style>
</head>
<body>
<div class="phone">
  <div class="status-bar"><span>9:41</span><span>●●●</span></div>
  <div class="map-bg">
    <div class="road-h" style="top:38%"></div>
    <div class="road-h" style="top:62%"></div>
    <div class="road-v" style="left:30%"></div>
    <div class="road-v" style="left:65%"></div>
    <div class="search-bar">
      <span>🔍</span>
      <span>Search car washes in Yerevan...</span>
    </div>
    <div class="pin green" style="top:25%; left:22%">
      <div class="pin-dot">🚗</div>
      <div class="pin-label">~5 min</div>
    </div>
    <div class="pin yellow" style="top:40%; left:58%">
      <div class="pin-dot">🚗</div>
      <div class="pin-label">~45 min</div>
    </div>
    <div class="pin red" style="top:55%; left:35%">
      <div class="pin-dot">🚗</div>
      <div class="pin-label">Full</div>
    </div>
    <div class="pin green" style="top:20%; left:68%">
      <div class="pin-dot">🚗</div>
      <div class="pin-label">~2 min</div>
    </div>
    <div class="legend">
      <div class="legend-row"><div class="legend-dot" style="background:#27AE60"></div> Available now</div>
      <div class="legend-row"><div class="legend-dot" style="background:#F39C12"></div> Wait &lt; 1hr</div>
      <div class="legend-row" style="margin-bottom:0"><div class="legend-dot" style="background:#E74C3C"></div> Fully booked</div>
    </div>
    <div class="my-location">📍</div>
  </div>
  <div class="bottom-bar">
    <div class="quick-book">
      <div class="car-icon">🚙</div>
      <div class="quick-book-text">
        <h3>My Sedan — AM 1234 AB</h3>
        <p>Tap a green pin to book instantly</p>
      </div>
      <div class="arrow">›</div>
    </div>
  </div>
  <div class="nav-bar">
    <div class="nav-item active"><span>🗺️</span><span>Map</span></div>
    <div class="nav-item"><span>📋</span><span>Bookings</span></div>
    <div class="nav-item"><span>🚗</span><span>Garage</span></div>
    <div class="nav-item"><span>👤</span><span>Profile</span></div>
  </div>
</div>
</body>
</html>
```

- [ ] **Step 3: Create mobile/mockups/client/03-wash-detail.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Lva — Wash Detail</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #0f1923; display: flex; justify-content: center; align-items: center; min-height: 100vh; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
  .phone { width: 390px; height: 844px; background: #e8f0f7; border-radius: 44px; overflow: hidden; box-shadow: 0 30px 80px rgba(0,0,0,0.6); position: relative; display: flex; flex-direction: column; }
  .map-preview { height: 280px; background: linear-gradient(135deg, #d4e6f1, #c8dff0, #d8e8d8); position: relative; }
  .back-btn { position: absolute; top: 56px; left: 16px; width: 40px; height: 40px; background: white; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; box-shadow: 0 2px 8px rgba(0,0,0,0.2); }
  .map-pin { position: absolute; top: 50%; left: 50%; transform: translate(-50%,-50%); font-size: 40px; }
  .sheet { flex: 1; background: white; border-radius: 24px 24px 0 0; margin-top: -24px; padding: 24px 24px 0; overflow-y: auto; }
  .handle { width: 40px; height: 4px; background: #e5e7eb; border-radius: 2px; margin: 0 auto 20px; }
  .wash-header { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 6px; }
  h2 { font-size: 22px; font-weight: 700; color: #1a1a2e; }
  .badge { background: #dcfce7; color: #166534; font-size: 12px; font-weight: 700; padding: 4px 10px; border-radius: 20px; }
  .address { color: #6b7280; font-size: 14px; margin-bottom: 20px; }
  .stats { display: flex; gap: 12px; margin-bottom: 24px; }
  .stat { flex: 1; background: #f9fafb; border-radius: 12px; padding: 12px; text-align: center; }
  .stat-val { font-size: 20px; font-weight: 700; color: #1B4F72; }
  .stat-label { font-size: 11px; color: #9ca3af; margin-top: 2px; }
  .section-title { font-size: 15px; font-weight: 700; color: #1a1a2e; margin-bottom: 12px; }
  .service-row { display: flex; justify-content: space-between; align-items: center; padding: 12px 0; border-bottom: 1px solid #f3f4f6; }
  .service-name { font-size: 14px; color: #374151; }
  .service-detail { font-size: 13px; color: #9ca3af; }
  .service-price { font-size: 15px; font-weight: 700; color: #1a1a2e; }
  .vehicle-selector { margin: 20px 0; }
  .vehicle-chip { display: inline-flex; align-items: center; gap: 6px; background: #1B4F72; color: white; border-radius: 20px; padding: 8px 14px; font-size: 13px; font-weight: 600; margin-right: 8px; }
  .vehicle-chip-other { background: #f3f4f6; color: #374151; }
  .book-btn { width: 100%; height: 56px; background: #27AE60; color: white; border: none; border-radius: 16px; font-size: 17px; font-weight: 700; cursor: pointer; margin-top: 20px; display: flex; align-items: center; justify-content: center; gap: 8px; }
  .eta-bar { background: #eff6ff; border-radius: 12px; padding: 10px 14px; display: flex; align-items: center; gap: 8px; margin-bottom: 20px; font-size: 13px; color: #1e40af; font-weight: 600; }
</style>
</head>
<body>
<div class="phone">
  <div class="map-preview">
    <div class="back-btn">‹</div>
    <div class="map-pin">📍</div>
  </div>
  <div class="sheet">
    <div class="handle"></div>
    <div class="wash-header">
      <h2>AutoSpa Kentron</h2>
      <div class="badge">● Open</div>
    </div>
    <div class="address">📍 Tigranyan St 5, Yerevan</div>
    <div class="eta-bar">🚗 ~8 min away · 3 bays available right now</div>
    <div class="stats">
      <div class="stat"><div class="stat-val">3</div><div class="stat-label">Free bays</div></div>
      <div class="stat"><div class="stat-val">5 min</div><div class="stat-label">Next slot</div></div>
      <div class="stat"><div class="stat-val">4.8★</div><div class="stat-label">Rating</div></div>
    </div>
    <div class="section-title">Select service</div>
    <div class="service-row">
      <div><div class="service-name">Exterior Wash</div><div class="service-detail">25 min · Sedan</div></div>
      <div class="service-price">3,500 ֏</div>
    </div>
    <div class="service-row">
      <div><div class="service-name">Full Wash + Interior</div><div class="service-detail">45 min · Sedan</div></div>
      <div class="service-price">6,500 ֏</div>
    </div>
    <div class="vehicle-selector">
      <div class="section-title">Your vehicle</div>
      <div class="vehicle-chip">🚗 AM 1234 AB</div>
      <div class="vehicle-chip vehicle-chip-other">+ Add</div>
    </div>
    <button class="book-btn">⚡ Book Now — 5 min slot</button>
  </div>
</div>
</body>
</html>
```

- [ ] **Step 4: Create mobile/mockups/client/04-booking-flow.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Lva — Booking Confirmed</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #0f1923; display: flex; justify-content: center; align-items: center; min-height: 100vh; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
  .phone { width: 390px; height: 844px; background: #fff; border-radius: 44px; overflow: hidden; box-shadow: 0 30px 80px rgba(0,0,0,0.6); display: flex; flex-direction: column; }
  .status-bar { height: 48px; background: #fff; display: flex; align-items: flex-end; justify-content: space-between; padding: 0 28px 8px; }
  .status-bar span { font-size: 12px; font-weight: 600; color: #1a1a2e; }
  .content { flex: 1; display: flex; flex-direction: column; align-items: center; padding: 32px 28px; }
  .success-icon { width: 96px; height: 96px; background: #dcfce7; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 48px; margin-bottom: 20px; }
  h2 { font-size: 26px; font-weight: 800; color: #1a1a2e; margin-bottom: 6px; }
  .subtitle { font-size: 15px; color: #6b7280; margin-bottom: 32px; text-align: center; }
  .booking-card { width: 100%; background: #f9fafb; border-radius: 20px; padding: 20px; margin-bottom: 24px; }
  .booking-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #e5e7eb; }
  .booking-row:last-child { border-bottom: none; }
  .booking-label { font-size: 13px; color: #9ca3af; }
  .booking-value { font-size: 14px; font-weight: 600; color: #1a1a2e; }
  .qr-box { width: 140px; height: 140px; background: white; border: 2px solid #e5e7eb; border-radius: 16px; display: flex; align-items: center; justify-content: center; font-size: 80px; margin-bottom: 24px; }
  .status-tracker { width: 100%; display: flex; justify-content: space-between; position: relative; margin-bottom: 32px; }
  .status-tracker::before { content: ''; position: absolute; top: 16px; left: 16px; right: 16px; height: 2px; background: #e5e7eb; z-index: 0; }
  .step { display: flex; flex-direction: column; align-items: center; gap: 6px; z-index: 1; }
  .step-dot { width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 700; }
  .step.done .step-dot { background: #27AE60; color: white; }
  .step.current .step-dot { background: #1B4F72; color: white; }
  .step.pending .step-dot { background: #e5e7eb; color: #9ca3af; }
  .step span:last-child { font-size: 10px; color: #6b7280; text-align: center; }
  .btn-primary { width: 100%; height: 52px; background: #1B4F72; color: white; border: none; border-radius: 16px; font-size: 16px; font-weight: 700; cursor: pointer; }
</style>
</head>
<body>
<div class="phone">
  <div class="status-bar"><span>9:41</span><span>●●●</span></div>
  <div class="content">
    <div class="success-icon">✅</div>
    <h2>Booking Confirmed!</h2>
    <p class="subtitle">Head to AutoSpa Kentron — your bay will be ready</p>
    <div class="booking-card">
      <div class="booking-row"><span class="booking-label">Car Wash</span><span class="booking-value">AutoSpa Kentron</span></div>
      <div class="booking-row"><span class="booking-label">Bay</span><span class="booking-value">Bay 2</span></div>
      <div class="booking-row"><span class="booking-label">Time</span><span class="booking-value">Today, 10:15 AM</span></div>
      <div class="booking-row"><span class="booking-label">Vehicle</span><span class="booking-value">AM 1234 AB (Sedan)</span></div>
      <div class="booking-row"><span class="booking-label">Service</span><span class="booking-value">Exterior Wash · 25 min</span></div>
      <div class="booking-row"><span class="booking-label">Price</span><span class="booking-value">3,500 ֏</span></div>
    </div>
    <div class="status-tracker">
      <div class="step done"><div class="step-dot">✓</div><span>Booked</span></div>
      <div class="step current"><div class="step-dot">2</div><span>Arrive</span></div>
      <div class="step pending"><div class="step-dot">3</div><span>Washing</span></div>
      <div class="step pending"><div class="step-dot">4</div><span>Done</span></div>
    </div>
    <button class="btn-primary">Get Directions</button>
  </div>
</div>
</body>
</html>
```

- [ ] **Step 5: Create mobile/mockups/client/05-garage.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Lva — Garage</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #0f1923; display: flex; justify-content: center; align-items: center; min-height: 100vh; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
  .phone { width: 390px; height: 844px; background: #fff; border-radius: 44px; overflow: hidden; box-shadow: 0 30px 80px rgba(0,0,0,0.6); display: flex; flex-direction: column; }
  .header { background: #fff; padding: 56px 24px 16px; border-bottom: 1px solid #f3f4f6; }
  h2 { font-size: 26px; font-weight: 800; color: #1a1a2e; }
  .vehicle-card { margin: 12px 20px; background: #f9fafb; border-radius: 20px; padding: 18px; display: flex; gap: 16px; align-items: center; border: 2px solid transparent; }
  .vehicle-card.default { border-color: #1B4F72; background: #eff6ff; }
  .vehicle-icon { width: 56px; height: 56px; background: #dbeafe; border-radius: 14px; display: flex; align-items: center; justify-content: center; font-size: 28px; }
  .vehicle-info h3 { font-size: 16px; font-weight: 700; color: #1a1a2e; }
  .vehicle-info p { font-size: 13px; color: #6b7280; margin-top: 3px; }
  .default-badge { background: #1B4F72; color: white; font-size: 10px; font-weight: 700; padding: 3px 8px; border-radius: 10px; margin-top: 4px; display: inline-block; }
  .vehicle-actions { margin-left: auto; display: flex; flex-direction: column; gap: 6px; }
  .icon-btn { width: 32px; height: 32px; border-radius: 50%; border: none; cursor: pointer; display: flex; align-items: center; justify-content: center; font-size: 14px; background: white; }
  .add-card { margin: 12px 20px; border: 2px dashed #e5e7eb; border-radius: 20px; padding: 20px; display: flex; align-items: center; justify-content: center; gap: 10px; cursor: pointer; }
  .add-card span { font-size: 15px; color: #9ca3af; font-weight: 600; }
  .nav-bar { height: 68px; background: white; border-top: 1px solid #f3f4f6; display: flex; align-items: center; justify-content: space-around; padding-bottom: 8px; margin-top: auto; }
  .nav-item { display: flex; flex-direction: column; align-items: center; gap: 3px; }
  .nav-item span:first-child { font-size: 22px; }
  .nav-item span:last-child { font-size: 10px; color: #9ca3af; }
  .nav-item.active span:last-child { color: #1B4F72; font-weight: 700; }
</style>
</head>
<body>
<div class="phone">
  <div class="header"><h2>My Garage</h2></div>
  <div class="vehicle-card default">
    <div class="vehicle-icon">🚗</div>
    <div class="vehicle-info">
      <h3>My Sedan</h3>
      <p>AM 1234 AB · Sedan</p>
      <div class="default-badge">Default</div>
    </div>
    <div class="vehicle-actions">
      <div class="icon-btn">✏️</div>
      <div class="icon-btn">🗑️</div>
    </div>
  </div>
  <div class="vehicle-card">
    <div class="vehicle-icon">🚙</div>
    <div class="vehicle-info">
      <h3>Wife's SUV</h3>
      <p>AM 5678 CD · SUV</p>
    </div>
    <div class="vehicle-actions">
      <div class="icon-btn">✏️</div>
      <div class="icon-btn">🗑️</div>
    </div>
  </div>
  <div class="add-card">
    <span>＋</span>
    <span>Add Vehicle</span>
  </div>
  <div class="nav-bar">
    <div class="nav-item"><span>🗺️</span><span>Map</span></div>
    <div class="nav-item"><span>📋</span><span>Bookings</span></div>
    <div class="nav-item active"><span>🚗</span><span>Garage</span></div>
    <div class="nav-item"><span>👤</span><span>Profile</span></div>
  </div>
</div>
</body>
</html>
```

- [ ] **Step 6: Create mobile/mockups/client/06-booking-history.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Lva — Bookings</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #0f1923; display: flex; justify-content: center; align-items: center; min-height: 100vh; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
  .phone { width: 390px; height: 844px; background: #fff; border-radius: 44px; overflow: hidden; box-shadow: 0 30px 80px rgba(0,0,0,0.6); display: flex; flex-direction: column; }
  .header { background: #fff; padding: 56px 24px 16px; }
  h2 { font-size: 26px; font-weight: 800; color: #1a1a2e; margin-bottom: 12px; }
  .tabs { display: flex; gap: 8px; }
  .tab { padding: 8px 16px; border-radius: 20px; font-size: 14px; font-weight: 600; cursor: pointer; }
  .tab.active { background: #1B4F72; color: white; }
  .tab.inactive { background: #f3f4f6; color: #6b7280; }
  .list { flex: 1; overflow-y: auto; padding: 12px 16px; }
  .booking-item { background: #f9fafb; border-radius: 16px; padding: 16px; margin-bottom: 10px; display: flex; gap: 14px; align-items: flex-start; }
  .booking-icon { width: 48px; height: 48px; border-radius: 12px; display: flex; align-items: center; justify-content: center; font-size: 22px; background: #dbeafe; flex-shrink: 0; }
  .booking-info h3 { font-size: 15px; font-weight: 700; color: #1a1a2e; }
  .booking-info p { font-size: 13px; color: #6b7280; margin-top: 3px; }
  .booking-meta { margin-top: 8px; display: flex; gap: 8px; }
  .status-badge { font-size: 11px; font-weight: 700; padding: 3px 10px; border-radius: 20px; }
  .status-washing { background: #dbeafe; color: #1e40af; }
  .status-completed { background: #dcfce7; color: #166534; }
  .status-upcoming { background: #fef3c7; color: #92400e; }
  .booking-price { margin-left: auto; font-size: 15px; font-weight: 700; color: #1a1a2e; flex-shrink: 0; }
  .live-indicator { display: flex; align-items: center; gap: 4px; font-size: 11px; color: #1e40af; font-weight: 600; }
  .pulse { width: 8px; height: 8px; background: #3b82f6; border-radius: 50%; animation: pulse 1.5s infinite; }
  @keyframes pulse { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }
  .nav-bar { height: 68px; background: white; border-top: 1px solid #f3f4f6; display: flex; align-items: center; justify-content: space-around; padding-bottom: 8px; }
  .nav-item { display: flex; flex-direction: column; align-items: center; gap: 3px; }
  .nav-item span:first-child { font-size: 22px; }
  .nav-item span:last-child { font-size: 10px; color: #9ca3af; }
  .nav-item.active span:last-child { color: #1B4F72; font-weight: 700; }
</style>
</head>
<body>
<div class="phone">
  <div class="header">
    <h2>My Bookings</h2>
    <div class="tabs">
      <div class="tab active">Upcoming</div>
      <div class="tab inactive">Past</div>
    </div>
  </div>
  <div class="list">
    <div class="booking-item">
      <div class="booking-icon">🚗</div>
      <div class="booking-info">
        <h3>AutoSpa Kentron</h3>
        <p>Today · Bay 2 · AM 1234 AB</p>
        <div class="booking-meta">
          <div class="status-badge status-washing">Washing</div>
          <div class="live-indicator"><div class="pulse"></div>Live</div>
        </div>
      </div>
      <div class="booking-price">3,500 ֏</div>
    </div>
    <div class="booking-item">
      <div class="booking-icon">🚙</div>
      <div class="booking-info">
        <h3>CleanCar Malatia</h3>
        <p>Tomorrow · 14:30 · AM 5678 CD</p>
        <div class="booking-meta">
          <div class="status-badge status-upcoming">Upcoming</div>
        </div>
      </div>
      <div class="booking-price">6,500 ֏</div>
    </div>
    <div class="booking-item" style="opacity:0.6">
      <div class="booking-icon">🚗</div>
      <div class="booking-info">
        <h3>AutoSpa Kentron</h3>
        <p>Yesterday · AM 1234 AB</p>
        <div class="booking-meta">
          <div class="status-badge status-completed">Completed</div>
        </div>
      </div>
      <div class="booking-price">3,500 ֏</div>
    </div>
  </div>
  <div class="nav-bar">
    <div class="nav-item"><span>🗺️</span><span>Map</span></div>
    <div class="nav-item active"><span>📋</span><span>Bookings</span></div>
    <div class="nav-item"><span>🚗</span><span>Garage</span></div>
    <div class="nav-item"><span>👤</span><span>Profile</span></div>
  </div>
</div>
</body>
</html>
```

- [ ] **Step 7: Commit**

```bash
git add mobile/mockups/client/ docs/superpowers/specs/2026-05-28-client-app-design.md
git commit -m "docs: add client app spec and HTML mockups"
```

---

## Phase 4: Moderator App Spec & Mockups

### Task 7: Write moderator app spec

**Files:**
- Create: `docs/superpowers/specs/2026-05-28-moderator-app-design.md`

- [ ] **Step 1: Write the spec**

Create `docs/superpowers/specs/2026-05-28-moderator-app-design.md`:

```markdown
# Lva Moderator App — Subsystem Spec

**Date:** 2026-05-28
**Stack:** Flutter 3, Dart, Riverpod, Dio, STOMP, Hive (offline cache)
**Flavor:** moderator_app (entry: lib/main_moderator.dart)
**Depends on:** backend API, shared mobile/lib/core/

---

## Epic 1: Moderator Authentication

### Story 1.1 — Login screen
**As a** moderator
**I want** to log in with phone and password
**So that** I can access the bay management panel

**Acceptance criteria:**
- Phone + password form
- Submits to `POST /api/auth/login`
- JWT stored in Flutter Secure Storage
- Role must be MODERATOR or OWNER — show error if CUSTOMER logs in

---

## Epic 2: Bay Status Panel

### Story 2.1 — Real-time bay status grid
**As a** moderator
**I want** to see all bays at my car wash on one screen
**So that** I know which bays are free, occupied, or blocked

**Acceptance criteria:**
- Shows all bays as large cards (tablet-optimized)
- Bay card shows: bay name, current status, active booking info (vehicle plate, service, time remaining)
- Colors: Green = IDLE, Blue = OCCUPIED, Red = BLOCKED
- Updates in real time via WebSocket `/topic/carwash/{carWashId}/bays`

### Story 2.2 — One-tap status transition
**As a** moderator
**I want** to update a booking status with one tap
**So that** the customer sees their car's progress instantly

**Status flow:** ARRIVED → WASHING → FINISHING → COMPLETED

**Acceptance criteria:**
- Each bay card shows the next logical status action as a large button
- Tap calls `PUT /api/moderator/bookings/{id}/status`
- Bay card updates immediately (optimistic UI) and confirms via WebSocket

---

## Epic 3: Walk-In Override

### Story 3.1 — Log a walk-in customer
**As a** moderator
**I want** to register a walk-in customer on a bay
**So that** online users cannot book the occupied bay

**Acceptance criteria:**
- "+ Walk-In" button on each IDLE bay card
- Modal asks: estimated duration (15 / 25 / 45 / 60 min)
- Calls `POST /api/moderator/bays/{bayId}/walk-ins`
- Bay card transitions to OCCUPIED immediately

---

## Epic 4: Offline Resilience

### Story 4.1 — Cache state locally when offline
**As a** moderator
**I want** the app to keep working when internet drops
**So that** I can still log status transitions

**Acceptance criteria:**
- Status transition taps while offline are queued in Hive
- Banner shown: "Offline — changes will sync when reconnected"
- On reconnect, queued actions are replayed in order
- WebSocket reconnects automatically with exponential backoff
```

- [ ] **Step 2: Create mobile/mockups/moderator/01-login.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Lva Moderator — Login</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #0f1923; display: flex; justify-content: center; align-items: center; min-height: 100vh; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
  .tablet { width: 768px; height: 1024px; background: #1B4F72; border-radius: 24px; overflow: hidden; box-shadow: 0 30px 80px rgba(0,0,0,0.6); display: flex; align-items: center; justify-content: center; }
  .card { background: white; border-radius: 24px; padding: 48px; width: 420px; }
  .logo { display: flex; align-items: center; gap: 14px; margin-bottom: 36px; }
  .logo-icon { width: 56px; height: 56px; background: #1B4F72; border-radius: 14px; display: flex; align-items: center; justify-content: center; color: white; font-size: 24px; font-weight: 800; }
  .logo-text h1 { font-size: 22px; font-weight: 800; color: #1a1a2e; }
  .logo-text p { font-size: 13px; color: #6b7280; }
  label { display: block; font-size: 14px; font-weight: 600; color: #374151; margin-bottom: 6px; }
  input { display: block; width: 100%; height: 52px; border: 1.5px solid #e5e7eb; border-radius: 12px; padding: 0 16px; font-size: 16px; margin-bottom: 20px; outline: none; }
  input:focus { border-color: #1B4F72; }
  .btn { width: 100%; height: 56px; background: #1B4F72; color: white; border: none; border-radius: 14px; font-size: 18px; font-weight: 700; cursor: pointer; }
  .note { text-align: center; font-size: 13px; color: #9ca3af; margin-top: 16px; }
</style>
</head>
<body>
<div class="tablet">
  <div class="card">
    <div class="logo">
      <div class="logo-icon">Լ</div>
      <div class="logo-text"><h1>Lva Moderator</h1><p>Staff Operations Panel</p></div>
    </div>
    <label>Phone Number</label>
    <input type="tel" placeholder="+374 77 123 456">
    <label>Password</label>
    <input type="password" placeholder="••••••••">
    <button class="btn">Sign In</button>
    <p class="note">For authorized staff only</p>
  </div>
</div>
</body>
</html>
```

- [ ] **Step 3: Create mobile/mockups/moderator/02-bay-status.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Lva Moderator — Bay Status</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #0f1923; display: flex; justify-content: center; align-items: center; min-height: 100vh; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
  .tablet { width: 768px; height: 1024px; background: #f5f7fa; border-radius: 24px; overflow: hidden; box-shadow: 0 30px 80px rgba(0,0,0,0.6); display: flex; flex-direction: column; }
  .topbar { height: 72px; background: #1B4F72; display: flex; align-items: center; padding: 0 28px; gap: 16px; }
  .topbar h1 { color: white; font-size: 22px; font-weight: 700; }
  .topbar-sub { color: rgba(255,255,255,0.7); font-size: 14px; margin-left: 4px; }
  .live-badge { margin-left: auto; background: rgba(255,255,255,0.15); color: white; border-radius: 20px; padding: 6px 14px; font-size: 13px; font-weight: 600; display: flex; align-items: center; gap: 6px; }
  .pulse { width: 8px; height: 8px; background: #27AE60; border-radius: 50%; }
  .time { color: rgba(255,255,255,0.8); font-size: 13px; }
  .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; padding: 24px; flex: 1; }
  .bay-card { background: white; border-radius: 20px; padding: 24px; display: flex; flex-direction: column; box-shadow: 0 2px 8px rgba(0,0,0,0.06); border: 3px solid transparent; }
  .bay-card.idle { border-color: #27AE60; }
  .bay-card.occupied { border-color: #1B4F72; }
  .bay-card.blocked { border-color: #E74C3C; }
  .bay-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
  .bay-name { font-size: 20px; font-weight: 800; color: #1a1a2e; }
  .bay-status-badge { font-size: 13px; font-weight: 700; padding: 5px 14px; border-radius: 20px; }
  .badge-idle { background: #dcfce7; color: #166534; }
  .badge-occupied { background: #dbeafe; color: #1e40af; }
  .badge-blocked { background: #fee2e2; color: #991b1b; }
  .booking-info { background: #f9fafb; border-radius: 12px; padding: 14px; margin-bottom: 16px; }
  .info-row { display: flex; gap: 8px; align-items: center; margin-bottom: 6px; font-size: 14px; color: #374151; }
  .info-row:last-child { margin-bottom: 0; }
  .info-label { color: #9ca3af; font-size: 13px; width: 70px; flex-shrink: 0; }
  .timer { font-size: 28px; font-weight: 800; color: #1B4F72; margin-bottom: 4px; }
  .timer-label { font-size: 12px; color: #9ca3af; margin-bottom: 16px; }
  .action-btn { width: 100%; height: 52px; border: none; border-radius: 14px; font-size: 16px; font-weight: 700; cursor: pointer; margin-top: auto; }
  .btn-green { background: #27AE60; color: white; }
  .btn-blue { background: #1B4F72; color: white; }
  .btn-orange { background: #F39C12; color: white; }
  .btn-gray { background: #f3f4f6; color: #9ca3af; }
  .walk-in-btn { width: 100%; height: 44px; border: 2px dashed #d1d5db; background: none; border-radius: 12px; font-size: 14px; font-weight: 600; color: #6b7280; cursor: pointer; margin-top: 8px; }
  .empty-state { color: #9ca3af; font-size: 14px; text-align: center; flex: 1; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 8px; padding: 20px 0; }
  .empty-icon { font-size: 36px; }
</style>
</head>
<body>
<div class="tablet">
  <div class="topbar">
    <h1>AutoSpa Kentron</h1>
    <span class="topbar-sub">· 4 bays</span>
    <div class="live-badge"><div class="pulse"></div> Live</div>
    <span class="time">10:32 AM</span>
  </div>
  <div class="grid">
    <!-- Bay 1: Occupied -->
    <div class="bay-card occupied">
      <div class="bay-header">
        <div class="bay-name">Bay 1</div>
        <div class="bay-status-badge badge-occupied">Washing</div>
      </div>
      <div class="booking-info">
        <div class="info-row"><span class="info-label">Vehicle</span> AM 1234 AB · Sedan</div>
        <div class="info-row"><span class="info-label">Service</span> Exterior Wash</div>
        <div class="info-row"><span class="info-label">Booked by</span> App · Booking #2041</div>
      </div>
      <div class="timer">12:30</div>
      <div class="timer-label">Time remaining</div>
      <button class="action-btn btn-orange">Mark as Finishing</button>
    </div>
    <!-- Bay 2: Idle -->
    <div class="bay-card idle">
      <div class="bay-header">
        <div class="bay-name">Bay 2</div>
        <div class="bay-status-badge badge-idle">Available</div>
      </div>
      <div class="empty-state">
        <div class="empty-icon">✅</div>
        <span>Ready for next vehicle</span>
        <span>Next booking: 11:00 AM</span>
      </div>
      <button class="action-btn btn-green">Mark Arrived</button>
      <button class="walk-in-btn">+ Walk-In Customer</button>
    </div>
    <!-- Bay 3: Arriving -->
    <div class="bay-card occupied">
      <div class="bay-header">
        <div class="bay-name">Bay 3</div>
        <div class="bay-status-badge badge-occupied">Arrived</div>
      </div>
      <div class="booking-info">
        <div class="info-row"><span class="info-label">Vehicle</span> AM 5678 CD · SUV</div>
        <div class="info-row"><span class="info-label">Service</span> Full Wash + Interior</div>
        <div class="info-row"><span class="info-label">Booked by</span> App · Booking #2042</div>
      </div>
      <div class="empty-state" style="flex:0;padding:12px 0">
        <span style="font-size:13px;color:#6b7280">Vehicle on site, ready to start</span>
      </div>
      <button class="action-btn btn-blue">Start Washing</button>
    </div>
    <!-- Bay 4: Blocked -->
    <div class="bay-card blocked">
      <div class="bay-header">
        <div class="bay-name">Bay 4</div>
        <div class="bay-status-badge badge-blocked">Blocked</div>
      </div>
      <div class="booking-info">
        <div class="info-row"><span class="info-label">Reason</span> Walk-in customer</div>
        <div class="info-row"><span class="info-label">Duration</span> ~45 min remaining</div>
      </div>
      <div class="timer">43:10</div>
      <div class="timer-label">Estimated remaining</div>
      <button class="action-btn btn-gray" style="background:#f3f4f6;color:#6b7280">Release Bay</button>
    </div>
  </div>
</div>
</body>
</html>
```

- [ ] **Step 4: Commit**

```bash
git add docs/superpowers/specs/2026-05-28-moderator-app-design.md mobile/mockups/moderator/
git commit -m "docs: add moderator app spec and HTML mockups"
```

---

## Phase 5: Admin Web Spec & Mockups

### Task 8: Write admin web spec

**Files:**
- Create: `docs/superpowers/specs/2026-05-28-admin-web-design.md`

- [ ] **Step 1: Write the spec**

Create `docs/superpowers/specs/2026-05-28-admin-web-design.md`:

```markdown
# Lva Admin Web — Subsystem Spec

**Date:** 2026-05-28
**Stack:** Next.js 14, TypeScript, Tailwind CSS, React Query, Zustand, STOMP.js
**Depends on:** backend API

---

## Epic 1: Project Setup

### Story 1.1 — Next.js app builds and deploys
**Acceptance criteria:**
- `npm run dev` runs on localhost:3000
- `npm run build` succeeds
- Middleware protects /owner and /superadmin routes
- Unauthenticated users redirected to /login

---

## Epic 2: Authentication

### Story 2.1 — Login page
**As a** wash owner or super admin
**I want** to log in with phone and password
**So that** I access the admin portal

**Acceptance criteria:**
- `POST /api/auth/login` called on submit
- JWT stored in httpOnly cookie `lva_token`
- Redirected to /owner or /superadmin based on role claim
- Error message on 401

---

## Epic 3: Owner — Bay Management

### Story 3.1 — View and configure bays
**Acceptance criteria:**
- `/owner/bays` page lists all bays for the owner's car wash
- Each bay shows: name, current status, active booking summary
- Live bay status via WebSocket (same broker as mobile)
- Add / Edit / Delete bay via inline forms

---

## Epic 4: Owner — Pricing Management

### Story 4.1 — Set prices by vehicle type and service
**Acceptance criteria:**
- `/owner/pricing` shows a grid: rows = vehicle types, columns = service types
- Prices editable inline
- Save calls `PUT /api/owner/pricing`
- Changes reflected immediately in mobile booking flow

---

## Epic 5: Owner — Analytics Dashboard

### Story 5.1 — Revenue summary
**Acceptance criteria:**
- `/owner/analytics` shows total revenue for selected date range
- Breakdown: Cash vs App Wallet vs Corporate (bar chart + table)
- Date range picker (today / this week / this month / custom)
- Data from `GET /api/owner/analytics/revenue`

### Story 5.2 — Booking volume chart
**Acceptance criteria:**
- Line chart showing bookings per day for selected range
- Breakdown by service type

---

## Epic 6: Super Admin — Tenant Management

### Story 6.1 — List and configure white-label tenants
**Acceptance criteria:**
- `/superadmin/tenants` lists all tenants with name, slug, status
- Create new tenant: name, slug, logo URL, theme hex color
- Edit existing tenant assets
- Calls `POST/PUT /api/superadmin/tenants`

---

## Epic 7: Super Admin — Corporate Accounts

### Story 7.1 — Manage corporate accounts and billing
**Acceptance criteria:**
- `/superadmin/corporate` lists corporate accounts with balance and billing cycle
- Create new corporate account: company name, billing cycle (MONTHLY/QUARTERLY)
- View usage: bookings per billing period
- Mark invoice as paid

---

## Epic 8: Super Admin — Operator Onboarding

### Story 8.1 — Register a new wash operator
**Acceptance criteria:**
- `/superadmin/operators` lists all car wash owners
- Invite new owner: name, phone, car wash name/location
- Creates user with role OWNER and associated car_wash record
```

- [ ] **Step 2: Create admin-web/mockups/01-login.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Lva Admin — Login</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #f5f7fa; display: flex; justify-content: center; align-items: center; min-height: 100vh; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; }
  .container { display: flex; width: 100%; max-width: 1100px; height: 600px; border-radius: 24px; overflow: hidden; box-shadow: 0 20px 60px rgba(0,0,0,0.15); }
  .left { width: 480px; background: #1B4F72; padding: 60px; display: flex; flex-direction: column; justify-content: center; }
  .left h1 { color: white; font-size: 36px; font-weight: 800; margin-bottom: 12px; }
  .left p { color: rgba(255,255,255,0.7); font-size: 16px; line-height: 1.6; margin-bottom: 40px; }
  .feature { display: flex; align-items: center; gap: 12px; margin-bottom: 16px; }
  .feature-icon { width: 36px; height: 36px; background: rgba(255,255,255,0.15); border-radius: 10px; display: flex; align-items: center; justify-content: center; font-size: 18px; flex-shrink: 0; }
  .feature span { color: rgba(255,255,255,0.85); font-size: 14px; }
  .right { flex: 1; background: white; padding: 60px; display: flex; flex-direction: column; justify-content: center; }
  .logo { display: flex; align-items: center; gap: 12px; margin-bottom: 36px; }
  .logo-box { width: 44px; height: 44px; background: #1B4F72; border-radius: 12px; display: flex; align-items: center; justify-content: center; color: white; font-size: 20px; font-weight: 800; }
  .logo h2 { font-size: 20px; font-weight: 700; color: #1a1a2e; }
  h3 { font-size: 24px; font-weight: 700; color: #1a1a2e; margin-bottom: 6px; }
  .subtitle { font-size: 14px; color: #6b7280; margin-bottom: 32px; }
  label { display: block; font-size: 13px; font-weight: 600; color: #374151; margin-bottom: 6px; }
  input { display: block; width: 100%; height: 48px; border: 1.5px solid #e5e7eb; border-radius: 10px; padding: 0 14px; font-size: 15px; margin-bottom: 18px; outline: none; }
  input:focus { border-color: #1B4F72; }
  .btn { width: 100%; height: 48px; background: #1B4F72; color: white; border: none; border-radius: 10px; font-size: 16px; font-weight: 700; cursor: pointer; }
</style>
</head>
<body>
<div class="container">
  <div class="left">
    <h1>Lva Admin Portal</h1>
    <p>Manage your car wash operations, pricing, and analytics in one place.</p>
    <div class="feature"><div class="feature-icon">📊</div><span>Real-time revenue analytics</span></div>
    <div class="feature"><div class="feature-icon">🔴</div><span>Live bay status monitoring</span></div>
    <div class="feature"><div class="feature-icon">💳</div><span>Multi-channel payment tracking</span></div>
    <div class="feature"><div class="feature-icon">🏢</div><span>Corporate account management</span></div>
  </div>
  <div class="right">
    <div class="logo"><div class="logo-box">Լ</div><h2>Lva</h2></div>
    <h3>Welcome back</h3>
    <p class="subtitle">Sign in to your operations portal</p>
    <label>Phone Number</label>
    <input type="tel" placeholder="+374 77 123 456">
    <label>Password</label>
    <input type="password" placeholder="••••••••">
    <button class="btn">Sign In</button>
  </div>
</div>
</body>
</html>
```

- [ ] **Step 3: Create admin-web/mockups/02-owner-dashboard.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Lva Admin — Owner Dashboard</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #f5f7fa; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; display: flex; }
  .sidebar { width: 220px; min-height: 100vh; background: #1B4F72; padding: 24px 0; flex-shrink: 0; }
  .sidebar-logo { display: flex; align-items: center; gap: 10px; padding: 0 20px 28px; border-bottom: 1px solid rgba(255,255,255,0.1); }
  .logo-box { width: 36px; height: 36px; background: rgba(255,255,255,0.15); border-radius: 10px; display: flex; align-items: center; justify-content: center; color: white; font-weight: 800; font-size: 16px; }
  .sidebar-logo span { color: white; font-weight: 700; font-size: 18px; }
  .nav-section { padding: 20px 12px 8px; font-size: 11px; font-weight: 700; color: rgba(255,255,255,0.4); text-transform: uppercase; letter-spacing: 1px; }
  .nav-item { display: flex; align-items: center; gap: 10px; padding: 10px 20px; color: rgba(255,255,255,0.7); font-size: 14px; cursor: pointer; border-radius: 0; margin-bottom: 2px; }
  .nav-item.active { background: rgba(255,255,255,0.15); color: white; font-weight: 600; }
  .nav-item:hover { background: rgba(255,255,255,0.08); }
  .main { flex: 1; padding: 32px; }
  .topbar { display: flex; justify-content: space-between; align-items: center; margin-bottom: 28px; }
  .topbar h1 { font-size: 24px; font-weight: 800; color: #1a1a2e; }
  .topbar-right { display: flex; align-items: center; gap: 12px; }
  .live-chip { display: flex; align-items: center; gap: 6px; background: #dcfce7; color: #166534; border-radius: 20px; padding: 6px 14px; font-size: 13px; font-weight: 700; }
  .pulse { width: 8px; height: 8px; background: #27AE60; border-radius: 50%; }
  .avatar { width: 36px; height: 36px; background: #1B4F72; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: white; font-weight: 700; font-size: 14px; }
  .stats-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 24px; }
  .stat-card { background: white; border-radius: 16px; padding: 20px; box-shadow: 0 1px 4px rgba(0,0,0,0.06); }
  .stat-label { font-size: 13px; color: #9ca3af; margin-bottom: 8px; }
  .stat-value { font-size: 28px; font-weight: 800; color: #1a1a2e; }
  .stat-sub { font-size: 12px; color: #27AE60; margin-top: 4px; font-weight: 600; }
  .grid-2 { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
  .card { background: white; border-radius: 16px; padding: 24px; box-shadow: 0 1px 4px rgba(0,0,0,0.06); }
  .card-title { font-size: 16px; font-weight: 700; color: #1a1a2e; margin-bottom: 16px; display: flex; justify-content: space-between; align-items: center; }
  .card-title a { font-size: 13px; font-weight: 600; color: #1B4F72; text-decoration: none; }
  .bay-row { display: flex; align-items: center; gap: 12px; padding: 12px 0; border-bottom: 1px solid #f3f4f6; }
  .bay-row:last-child { border-bottom: none; }
  .bay-dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }
  .dot-green { background: #27AE60; }
  .dot-blue { background: #3b82f6; }
  .dot-red { background: #E74C3C; }
  .bay-name { font-size: 14px; font-weight: 600; color: #1a1a2e; width: 60px; }
  .bay-status { font-size: 13px; color: #6b7280; flex: 1; }
  .bay-action { font-size: 12px; color: #9ca3af; }
  .chart-placeholder { height: 160px; background: #f9fafb; border-radius: 12px; display: flex; align-items: flex-end; padding: 16px; gap: 8px; }
  .bar { flex: 1; border-radius: 4px 4px 0 0; }
  .booking-row { display: flex; align-items: center; gap: 12px; padding: 10px 0; border-bottom: 1px solid #f3f4f6; }
  .booking-row:last-child { border-bottom: none; }
  .booking-avatar { width: 36px; height: 36px; background: #dbeafe; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; flex-shrink: 0; }
  .booking-info { flex: 1; }
  .booking-info p { font-size: 13px; font-weight: 600; color: #1a1a2e; }
  .booking-info span { font-size: 12px; color: #9ca3af; }
  .booking-amount { font-size: 14px; font-weight: 700; color: #1a1a2e; }
</style>
</head>
<body>
<div class="sidebar">
  <div class="sidebar-logo"><div class="logo-box">Լ</div><span>Lva</span></div>
  <div class="nav-section">Operations</div>
  <div class="nav-item active">📊 Dashboard</div>
  <div class="nav-item">🔴 Bay Status</div>
  <div class="nav-item">📋 Bookings</div>
  <div class="nav-section">Settings</div>
  <div class="nav-item">💰 Pricing</div>
  <div class="nav-item">📈 Analytics</div>
  <div class="nav-item">⚙️ Settings</div>
</div>
<div class="main">
  <div class="topbar">
    <div>
      <h1>AutoSpa Kentron</h1>
      <div style="font-size:14px;color:#6b7280;margin-top:4px;">Thursday, May 28 · Good morning 👋</div>
    </div>
    <div class="topbar-right">
      <div class="live-chip"><div class="pulse"></div>4 bays live</div>
      <div class="avatar">AK</div>
    </div>
  </div>
  <div class="stats-row">
    <div class="stat-card"><div class="stat-label">Today's Revenue</div><div class="stat-value">47,500 ֏</div><div class="stat-sub">↑ 12% vs yesterday</div></div>
    <div class="stat-card"><div class="stat-label">Bookings Today</div><div class="stat-value">18</div><div class="stat-sub">↑ 3 vs yesterday</div></div>
    <div class="stat-card"><div class="stat-label">Active Now</div><div class="stat-value">2</div><div class="stat-sub">2 bays occupied</div></div>
    <div class="stat-card"><div class="stat-label">Avg Wait Time</div><div class="stat-value">7 min</div><div class="stat-sub">↓ 5 min vs last week</div></div>
  </div>
  <div class="grid-2">
    <div class="card">
      <div class="card-title">Live Bay Status <a href="#">View all →</a></div>
      <div class="bay-row"><div class="bay-dot dot-blue"></div><div class="bay-name">Bay 1</div><div class="bay-status">Washing · AM 1234 AB · 12 min left</div></div>
      <div class="bay-row"><div class="bay-dot dot-green"></div><div class="bay-name">Bay 2</div><div class="bay-status">Available · Next at 11:00</div></div>
      <div class="bay-row"><div class="bay-dot dot-blue"></div><div class="bay-name">Bay 3</div><div class="bay-status">Arrived · AM 5678 CD</div></div>
      <div class="bay-row"><div class="bay-dot dot-red"></div><div class="bay-name">Bay 4</div><div class="bay-status">Walk-in · ~43 min remaining</div></div>
    </div>
    <div class="card">
      <div class="card-title">Revenue This Week</div>
      <div class="chart-placeholder">
        <div class="bar" style="height:60%;background:#dbeafe;"></div>
        <div class="bar" style="height:75%;background:#dbeafe;"></div>
        <div class="bar" style="height:55%;background:#dbeafe;"></div>
        <div class="bar" style="height:90%;background:#1B4F72;"></div>
        <div class="bar" style="height:70%;background:#dbeafe;"></div>
        <div class="bar" style="height:85%;background:#dbeafe;"></div>
        <div class="bar" style="height:40%;background:#e5e7eb;"></div>
      </div>
      <div style="display:flex;justify-content:space-between;margin-top:8px;font-size:11px;color:#9ca3af;">
        <span>Mon</span><span>Tue</span><span>Wed</span><span style="color:#1B4F72;font-weight:700;">Thu</span><span>Fri</span><span>Sat</span><span>Sun</span>
      </div>
    </div>
  </div>
</div>
</body>
</html>
```

- [ ] **Step 4: Create admin-web/mockups/03-pricing.html**

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Lva Admin — Pricing</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { background: #f5f7fa; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; display: flex; }
  .sidebar { width: 220px; min-height: 100vh; background: #1B4F72; padding: 24px 0; flex-shrink: 0; }
  .sidebar-logo { display: flex; align-items: center; gap: 10px; padding: 0 20px 28px; border-bottom: 1px solid rgba(255,255,255,0.1); }
  .logo-box { width: 36px; height: 36px; background: rgba(255,255,255,0.15); border-radius: 10px; display: flex; align-items: center; justify-content: center; color: white; font-weight: 800; font-size: 16px; }
  .sidebar-logo span { color: white; font-weight: 700; font-size: 18px; }
  .nav-item { display: flex; align-items: center; gap: 10px; padding: 10px 20px; color: rgba(255,255,255,0.7); font-size: 14px; cursor: pointer; }
  .nav-item.active { background: rgba(255,255,255,0.15); color: white; font-weight: 600; }
  .main { flex: 1; padding: 32px; }
  h1 { font-size: 24px; font-weight: 800; color: #1a1a2e; margin-bottom: 8px; }
  .sub { font-size: 14px; color: #6b7280; margin-bottom: 28px; }
  .card { background: white; border-radius: 16px; box-shadow: 0 1px 4px rgba(0,0,0,0.06); overflow: hidden; }
  table { width: 100%; border-collapse: collapse; }
  th { background: #f9fafb; padding: 14px 20px; text-align: left; font-size: 13px; font-weight: 700; color: #6b7280; text-transform: uppercase; letter-spacing: 0.5px; }
  td { padding: 16px 20px; border-top: 1px solid #f3f4f6; font-size: 14px; color: #1a1a2e; }
  .vehicle-type { display: flex; align-items: center; gap: 8px; }
  .type-icon { font-size: 20px; }
  .price-input { width: 120px; height: 36px; border: 1.5px solid #e5e7eb; border-radius: 8px; padding: 0 12px; font-size: 14px; font-weight: 600; text-align: right; outline: none; }
  .price-input:focus { border-color: #1B4F72; }
  .currency { color: #9ca3af; font-size: 13px; margin-left: 4px; }
  .duration { font-size: 12px; color: #9ca3af; margin-top: 2px; }
  .save-bar { display: flex; justify-content: flex-end; gap: 12px; padding: 20px 24px; background: #f9fafb; border-top: 1px solid #f3f4f6; }
  .btn-cancel { height: 40px; padding: 0 20px; background: white; border: 1.5px solid #e5e7eb; border-radius: 10px; font-size: 14px; font-weight: 600; cursor: pointer; }
  .btn-save { height: 40px; padding: 0 24px; background: #1B4F72; color: white; border: none; border-radius: 10px; font-size: 14px; font-weight: 700; cursor: pointer; }
</style>
</head>
<body>
<div class="sidebar">
  <div class="sidebar-logo"><div class="logo-box">Լ</div><span>Lva</span></div>
  <div class="nav-item">📊 Dashboard</div>
  <div class="nav-item">🔴 Bay Status</div>
  <div class="nav-item">📋 Bookings</div>
  <div class="nav-item active">💰 Pricing</div>
  <div class="nav-item">📈 Analytics</div>
</div>
<div class="main">
  <h1>Pricing Management</h1>
  <p class="sub">Set prices per vehicle type and service. Changes apply immediately to the booking app.</p>
  <div class="card">
    <table>
      <thead>
        <tr>
          <th>Vehicle Type</th>
          <th>Exterior Wash</th>
          <th>Interior Clean</th>
          <th>Full Wash + Interior</th>
          <th>Premium Detail</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td><div class="vehicle-type"><span class="type-icon">🚗</span><div><div>Sedan</div><div class="duration">25 / 20 / 45 / 90 min</div></div></div></td>
          <td><input class="price-input" value="3,500"><span class="currency">֏</span></td>
          <td><input class="price-input" value="2,500"><span class="currency">֏</span></td>
          <td><input class="price-input" value="6,500"><span class="currency">֏</span></td>
          <td><input class="price-input" value="12,000"><span class="currency">֏</span></td>
        </tr>
        <tr>
          <td><div class="vehicle-type"><span class="type-icon">🚙</span><div><div>Crossover</div><div class="duration">30 / 25 / 55 / 100 min</div></div></div></td>
          <td><input class="price-input" value="4,000"><span class="currency">֏</span></td>
          <td><input class="price-input" value="3,000"><span class="currency">֏</span></td>
          <td><input class="price-input" value="7,500"><span class="currency">֏</span></td>
          <td><input class="price-input" value="14,000"><span class="currency">֏</span></td>
        </tr>
        <tr>
          <td><div class="vehicle-type"><span class="type-icon">🛻</span><div><div>SUV</div><div class="duration">35 / 30 / 65 / 120 min</div></div></div></td>
          <td><input class="price-input" value="5,000"><span class="currency">֏</span></td>
          <td><input class="price-input" value="3,500"><span class="currency">֏</span></td>
          <td><input class="price-input" value="9,000"><span class="currency">֏</span></td>
          <td><input class="price-input" value="16,000"><span class="currency">֏</span></td>
        </tr>
        <tr>
          <td><div class="vehicle-type"><span class="type-icon">🏎️</span><div><div>Coupe</div><div class="duration">25 / 20 / 45 / 90 min</div></div></div></td>
          <td><input class="price-input" value="3,500"><span class="currency">֏</span></td>
          <td><input class="price-input" value="2,500"><span class="currency">֏</span></td>
          <td><input class="price-input" value="6,500"><span class="currency">֏</span></td>
          <td><input class="price-input" value="13,000"><span class="currency">֏</span></td>
        </tr>
      </tbody>
    </table>
    <div class="save-bar">
      <button class="btn-cancel">Discard</button>
      <button class="btn-save">Save Prices</button>
    </div>
  </div>
</div>
</body>
</html>
```

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/specs/2026-05-28-admin-web-design.md admin-web/mockups/
git commit -m "docs: add admin web spec and HTML mockups"
```

---

## Final Verification

- [ ] **Check all 3 project folders exist**

```bash
ls -la backend/ mobile/ admin-web/
```

Expected: all three directories present with files inside.

- [ ] **Check all 4 spec docs exist**

```bash
ls docs/superpowers/specs/
```

Expected: architecture design + 4 subsystem specs.

- [ ] **Check all mockup files**

```bash
find mobile/mockups admin-web/mockups -name "*.html" | sort
```

Expected: 6 client mockups, 2 moderator mockups, 3 admin web mockups.

- [ ] **Final commit**

```bash
git add .
git commit -m "docs: complete project scaffold and all subsystem specs with mockups"
```
