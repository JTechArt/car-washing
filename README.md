# Lva (Լվա) — Car Wash Booking Platform

Real-time car wash booking platform for Yerevan, Armenia. Eliminates phantom availability by linking online bookings to a live bay-management system operated by wash staff.

## Architecture

```
┌─────────────────────┐   ┌─────────────────────┐
│   Client App        │   │   Moderator App      │
│   Flutter · iOS/Android│   │   Flutter · iPad    │
│   (Phase 2)         │   │   (Phase 3)          │
└──────────┬──────────┘   └──────────┬──────────┘
           │                          │
           │      HTTP + WebSocket    │
           └──────────┬───────────────┘
                      │
         ┌────────────▼──────────────┐
         │      Spring Boot API      │
         │   Java 21 · Port 9080     │
         │  /api/**  /ws (STOMP)     │
         └────────────┬──────────────┘
                      │
         ┌────────────▼──────────────┐    ┌─────────────────────┐
         │      PostgreSQL 16        │    │   Admin Web         │
         │      Port 5432            │    │   Next.js 14 · 3000 │
         └───────────────────────────┘    └─────────────────────┘
```

## Monorepo Structure

| Folder | Description | Port |
|---|---|---|
| `backend/` | Java 21 + Spring Boot API | 9080 |
| `admin-web/` | Next.js owner & super-admin portal | 3000 |
| `mobile/` | Flutter client + moderator apps | n/a |
| `docs/` | Architecture specs, plans, mockups | n/a |

## Quick Start (Full Stack)

**Prerequisites:** Java 21, Maven 3.9+, Docker, Node.js 20+

```bash
# 1. Start PostgreSQL
docker compose up postgres -d

# 2. Start backend (new terminal)
cd backend && mvn spring-boot:run

# 3. Start admin web (new terminal)
cd admin-web && npm install && npm run dev
```

Visit http://localhost:3000 for the admin portal.
Backend API docs: http://localhost:9080/swagger-ui.html

## Environment Variables

See `backend/README.md` and `admin-web/README.md` for required variables per service.

## Testing

```bash
# Backend unit + integration tests
cd backend && mvn test

# Admin web lint
cd admin-web && npm run lint
```

See `docs/testing/manual-test-checklist.md` for end-to-end manual testing flows.
