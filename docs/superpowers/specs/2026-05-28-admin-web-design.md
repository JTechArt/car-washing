# Lva Admin Web — Subsystem Spec

**Date:** 2026-05-28
**Stack:** Next.js 14, TypeScript, Tailwind CSS, React Query, Zustand, STOMP.js, Jose (JWT)
**Depends on:** Backend API

---

## Epic 1: Project Setup & Auth Infrastructure

### Story 1.1 — App builds and protected routes work
**Acceptance criteria:**
- `npm run dev` runs on localhost:3000
- `npm run build` succeeds with no TypeScript errors
- Middleware redirects /owner/* and /superadmin/* to /login if no lva_token cookie
- JWT decoded from cookie using jose; role claim used for routing

### Story 1.2 — Login page
**As a** wash owner or super admin **I want** to log in **So that** I access my portal

**Acceptance criteria:**
- Phone + password form at /login
- Calls POST /api/auth/login
- On success, sets httpOnly cookie lva_token, redirects to /owner or /superadmin based on role
- Error toast on 401

---

## Epic 2: Owner — Bay Management

### Story 2.1 — Live bay status view
**As an** owner **I want** to see all my bays in real time **So that** I monitor operations remotely

**Acceptance criteria:**
- /owner/bays page lists all bays for the owner's car wash
- Status displayed as colored dot + label (Green=IDLE, Blue=OCCUPIED, Red=BLOCKED)
- Active booking summary shown per bay (vehicle plate, service, time remaining)
- Status updates via WebSocket /topic/carwash/{carWashId}/bays (same broker as mobile)
- Add/Edit/Delete bay via modal forms calling /api/owner/car-washes/{id}/bays

---

## Epic 3: Owner — Pricing Management

### Story 3.1 — Edit prices by vehicle type and service
**As an** owner **I want** to set prices per vehicle type and service **So that** the booking app reflects current rates

**Acceptance criteria:**
- /owner/pricing shows an editable grid: rows = vehicle types (Sedan/Crossover/SUV/Coupe), columns = service types (Exterior/Interior/Full/Premium)
- Each cell shows price in ֏ and slot duration in minutes — both editable inline
- Save calls PUT /api/owner/pricing
- Discard button reverts unsaved changes

---

## Epic 4: Owner — Analytics Dashboard

### Story 4.1 — Revenue summary with date range
**As an** owner **I want** to see revenue totals and breakdown **So that** I understand my business

**Acceptance criteria:**
- /owner/analytics shows total revenue for selected date range
- Breakdown by payment channel: Cash / App Wallet / Corporate (bar chart + table)
- Date range picker: today / this week / this month / custom
- Data from GET /api/owner/analytics/revenue?from=&to=

### Story 4.2 — Booking volume chart
**Acceptance criteria:**
- Line chart showing bookings per day in selected range
- Breakdown available by service type

---

## Epic 5: Owner — Dashboard Overview

### Story 5.1 — Dashboard home page
**As an** owner **I want** a summary view when I log in **So that** I see today's key metrics immediately

**Acceptance criteria:**
- /owner page shows: today's revenue, bookings count, active bays count, average wait time
- Live bay status widget (same data as /owner/bays)
- Recent bookings list (last 5)
- Quick-access nav to Pricing, Analytics, Bay config

---

## Epic 6: Super Admin — Tenant Management

### Story 6.1 — White-label tenant CRUD
**As a** super admin **I want** to manage white-label tenants **So that** I can configure standalone operator apps

**Acceptance criteria:**
- /superadmin/tenants lists all tenants: name, slug, status
- Create new tenant: name, slug, logo URL, theme hex color
- Edit existing tenant assets
- Calls POST/PUT /api/superadmin/tenants

---

## Epic 7: Super Admin — Corporate Accounts

### Story 7.1 — Manage corporate accounts and billing
**As a** super admin **I want** to manage B2B accounts **So that** corporate fleets are billed correctly

**Acceptance criteria:**
- /superadmin/corporate lists accounts with company name, balance, billing cycle
- Create new account: company name, billing cycle (MONTHLY/QUARTERLY)
- View usage: bookings per billing period
- "Mark Invoice Paid" action updates balance

---

## Epic 8: Super Admin — Operator Onboarding

### Story 8.1 — Register a new wash operator
**As a** super admin **I want** to onboard new car wash owners **So that** they can use the platform

**Acceptance criteria:**
- /superadmin/operators lists all car wash owners with their wash names
- Invite form: name, phone, car wash name, address, lat/lng
- Creates OWNER user + associated car_wash record via POST /api/superadmin/operators
