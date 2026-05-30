# Lva Backend

Java 21 + Spring Boot 3.2 modular monolith. Handles booking, real-time bay status (WebSocket), auth (JWT), and multi-tenancy.

## Architecture

```
am.lva/
├── auth/          JWT issuance, Spring Security, User entity
├── tenancy/       TenantContext ThreadLocal, request interceptor
├── booking/       Car wash, bay, vehicle, price, booking, slot engine
├── notifications/ STOMP WebSocket broker, bay status broadcast
├── payments/      (Phase 2) ArCa, Idram, Telcell adapters
└── analytics/     (Phase 2) Revenue reports
```

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| Java | 21+ | https://adoptium.net |
| Maven | 3.9+ | https://maven.apache.org |
| Docker | 24+ | https://docker.com |
| PostgreSQL | 16 (via Docker) | included in docker-compose.yml |

## Start Locally

```bash
# From repo root — start PostgreSQL (creates the 'lva' database automatically)
docker compose up postgres -d

# Run the backend (Flyway will create all tables on first start)
cd backend
mvn spring-boot:run
```

The API will be available at http://localhost:9080.
Swagger UI: http://localhost:9080/swagger-ui.html
OpenAPI JSON: http://localhost:9080/v3/api-docs

> **PostgreSQL requirement:** The database server must be PostgreSQL **13 or newer** because `gen_random_uuid()` is used for UUIDs. The `docker-compose.yml` uses PostgreSQL 16. If you are running PostgreSQL manually, make sure the `lva` database exists before starting the app:
> ```sql
> CREATE DATABASE lva;
> ```

## Database Migrations

Flyway manages all schema changes under `src/main/resources/db/migration/`.  
**Do not** run SQL scripts manually — let Flyway apply them on startup.

If Flyway reports a failed migration (e.g. after a bad manual change), repair the history table:
```bash
mvn flyway:repair
```

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `DB_URL` | `jdbc:postgresql://localhost:5432/lva` | PostgreSQL JDBC URL |
| `DB_USER` | `lva` | Database username |
| `DB_PASS` | `lva` | Database password |
| `JWT_SECRET` | *(required in prod)* | HS256 signing key, min 32 chars |
| `JWT_EXPIRY_MS` | `86400000` | Token lifetime in ms (24h) |

Defaults in `src/main/resources/application.yml` are safe for local dev.

## Run Tests

```bash
mvn test
```

Uses H2 in-memory database — no Docker required for tests.

## Key API Endpoints

| Method | Path | Role | Description |
|---|---|---|---|
| POST | /api/auth/register | — | Register (returns JWT) |
| POST | /api/auth/login | — | Login (returns JWT) |
| GET | /api/client/car-washes | CUSTOMER+ | Map listing with availability |
| GET | /api/client/car-washes/{id}/slots | CUSTOMER+ | Available booking slots |
| POST | /api/client/bookings | CUSTOMER+ | Create booking |
| POST | /api/moderator/bays/{id}/walk-ins | MODERATOR+ | Log walk-in |
| PUT | /api/moderator/bookings/{id}/status | MODERATOR+ | Update booking status |
| POST | /api/owner/car-washes | OWNER+ | Create car wash |
| GET/POST | /api/owner/car-washes/{id}/bays | OWNER+ | Manage bays |
| GET/PUT | /api/owner/car-washes/{id}/prices | OWNER+ | Pricing management |

## WebSocket

Connect: `ws://localhost:9080/ws` (SockJS)
Auth: Pass `Authorization: Bearer <token>` in STOMP CONNECT headers.
Subscribe: `/topic/carwash/{carWashId}/bays` for live bay status.
Payload: `{ "bayId": "uuid", "status": "IDLE|OCCUPIED|BLOCKED" }`

## Build Docker Image

```bash
mvn package -DskipTests
docker build -t lva-backend .
```
