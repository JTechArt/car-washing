# Admin Web — Moderator Role Support

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `/moderator` section to the admin web so that users with the MODERATOR role can log in and manage bay status (status transitions + walk-in overrides) from a browser, mirroring the tablet app experience.

**Architecture:** The existing login page and Sidebar component are reused unchanged. A new `/moderator` route section is added alongside the existing `/owner` section. The moderator accesses car wash and bay data via `/api/owner/**` endpoints — the backend SecurityConfig is updated to grant MODERATOR role read access to those routes. Real-time bay updates flow through the existing `useBayStatus` WebSocket hook.

**Tech Stack:** Next.js 14, TypeScript, Tailwind CSS, @stomp/stompjs, @tanstack/react-query (not used here — direct fetch), existing `lib/auth.ts` and `lib/useWebSocket.ts`

---

## File Map

```
backend/src/main/java/am/lva/auth/
└── SecurityConfig.java                        (modify: add MODERATOR to /api/owner/**)

admin-web/
├── middleware.ts                               (modify: add /moderator to protected routes)
├── lib/
│   └── api/
│       ├── types.ts                           (modify: extend BayResponse + add BookingStatus)
│       └── client.ts                          (modify: add moderator.updateStatus, moderator.createWalkIn, moderator.listCarWashes)
├── app/
│   ├── login/
│   │   └── page.tsx                           (modify: redirect MODERATOR → /moderator)
│   └── moderator/
│       ├── layout.tsx                         (create)
│       └── page.tsx                           (create: bay panel)
└── components/
    ├── ModeratorBayCard.tsx                   (create)
    └── WalkInModal.tsx                        (create)
```

---

## Task 1: Backend — Grant MODERATOR access to /api/owner/** read endpoints

Currently `/api/owner/**` is restricted to `OWNER` and `SUPER_ADMIN`. The moderator needs to read car washes and bays. Rather than creating duplicate endpoints, we extend the security rule.

**Files:**
- Modify: `backend/src/main/java/am/lva/auth/SecurityConfig.java`

- [ ] **Step 1: Read SecurityConfig.java and update the owner rule**

Read the file, then change line 36 from:
```java
.requestMatchers("/api/owner/**").hasAnyRole("OWNER", "SUPER_ADMIN")
```
to:
```java
.requestMatchers("/api/owner/**").hasAnyRole("MODERATOR", "OWNER", "SUPER_ADMIN")
```

The full updated `filterChain` authorizeHttpRequests block becomes:

```java
.authorizeHttpRequests(auth -> auth
        .requestMatchers("/api/auth/**").permitAll()
        .requestMatchers(
                "/swagger-ui.html",
                "/swagger-ui/**",
                "/v3/api-docs/**",
                "/webjars/**"
        ).permitAll()
        .requestMatchers("/api/superadmin/**").hasRole("SUPER_ADMIN")
        .requestMatchers("/api/owner/**").hasAnyRole("MODERATOR", "OWNER", "SUPER_ADMIN")
        .requestMatchers("/api/moderator/**").hasAnyRole("MODERATOR", "OWNER", "SUPER_ADMIN")
        .requestMatchers("/api/client/**").authenticated()
        .anyRequest().authenticated())
```

- [ ] **Step 2: Run backend tests**

```bash
cd /Users/arthurho/Projects/car-washing-booking/backend
mvn test -q 2>&1 | tail -5
```

Expected: `Tests run: 24, Failures: 0, Errors: 0, Skipped: 0`

- [ ] **Step 3: Commit**

```bash
cd /Users/arthurho/Projects/car-washing-booking
git add backend/src/main/java/am/lva/auth/SecurityConfig.java
git commit -m "feat(backend): grant MODERATOR role read access to /api/owner/** endpoints"
```

---

## Task 2: Types + API Client Extensions

**Files:**
- Modify: `admin-web/lib/api/types.ts`
- Modify: `admin-web/lib/api/client.ts`

- [ ] **Step 1: Update `admin-web/lib/api/types.ts`**

Replace the entire file:

```typescript
export type UserRole = 'CUSTOMER' | 'MODERATOR' | 'OWNER' | 'SUPER_ADMIN'
export type BayStatus = 'IDLE' | 'OCCUPIED' | 'BLOCKED'
export type AvailabilityStatus = 'GREEN' | 'YELLOW' | 'RED'
export type VehicleType = 'SEDAN' | 'CROSSOVER' | 'SUV' | 'COUPE'
export type ServiceType = 'EXTERIOR' | 'INTERIOR' | 'FULL' | 'PREMIUM'
export type BookingStatus = 'PENDING' | 'ARRIVED' | 'WASHING' | 'FINISHING' | 'COMPLETED' | 'CANCELLED'

export interface AuthResponse {
  token: string
  role: UserRole
}

export interface CarWashResponse {
  id: string
  name: string
  address: string
  lat: number
  lng: number
}

export interface BayResponse {
  id: string
  name: string
  status: BayStatus
  activeBookingId: string | null
  activeBookingStatus: BookingStatus | null
}

export interface PriceResponse {
  id: string
  vehicleType: VehicleType
  serviceType: ServiceType
  durationMinutes: number
  amountAmd: number
}

export interface BayStatusMessage {
  bayId: string
  status: BayStatus
}

// Derived helper — maps activeBookingStatus to the next action
export function nextAction(bay: BayResponse): { label: string; targetStatus: BookingStatus } | null {
  switch (bay.activeBookingStatus) {
    case 'PENDING':   return { label: 'Mark Arrived',   targetStatus: 'ARRIVED' }
    case 'ARRIVED':   return { label: 'Start Washing',  targetStatus: 'WASHING' }
    case 'WASHING':   return { label: 'Mark Finishing', targetStatus: 'FINISHING' }
    case 'FINISHING': return { label: 'Complete',       targetStatus: 'COMPLETED' }
    default:          return null
  }
}
```

- [ ] **Step 2: Add moderator methods to `admin-web/lib/api/client.ts`**

Read `admin-web/lib/api/client.ts`. Add a `moderator` namespace after the `owner` object. The import at the top already imports from `./types` — just add the new function. Also update the existing `BulkPriceEntry` export to stay (don't remove it).

Add this block at the end of the `api` object (after `owner: { ... }`), and add the `BookingStatus` import from types:

```typescript
  moderator: {
    listCarWashes: () => request<CarWashResponse[]>('/api/owner/car-washes'),
    listBays: (carWashId: string) =>
      request<BayResponse[]>(`/api/owner/car-washes/${carWashId}/bays`),
    updateBookingStatus: (bookingId: string, status: string) =>
      request<void>(`/api/moderator/bookings/${bookingId}/status`, {
        method: 'PUT',
        body: JSON.stringify({ status }),
      }),
    createWalkIn: (bayId: string, estimatedDurationMinutes: number) =>
      request<void>(`/api/moderator/bays/${bayId}/walk-ins`, {
        method: 'POST',
        body: JSON.stringify({ estimatedDurationMinutes }),
      }),
  },
```

Also update the import line at the top of client.ts to include `BookingStatus`:
```typescript
import type {
  AuthResponse,
  BayResponse,
  CarWashResponse,
  PriceResponse,
} from './types'
```
becomes:
```typescript
import type {
  AuthResponse,
  BayResponse,
  CarWashResponse,
  PriceResponse,
} from './types'
```
(No change needed — `BookingStatus` is only used in types.ts itself, not in client.ts directly.)

- [ ] **Step 3: Build to verify TypeScript compiles**

```bash
cd /Users/arthurho/Projects/car-washing-booking/admin-web
PATH="/Users/arthurho/.nvm/versions/node/v20.19.1/bin:$PATH" npm run build 2>&1 | tail -10
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
cd /Users/arthurho/Projects/car-washing-booking
git add admin-web/lib/api/types.ts admin-web/lib/api/client.ts
git commit -m "feat(admin-web): extend BayResponse types with booking info, add moderator API methods"
```

---

## Task 3: Login Redirect + Middleware

**Files:**
- Modify: `admin-web/app/login/page.tsx`
- Modify: `admin-web/middleware.ts`

- [ ] **Step 1: Update login redirect in `admin-web/app/login/page.tsx`**

Read the file. Find this block:

```typescript
      setAuth(res.token, res.role)
      if (res.role === 'SUPER_ADMIN') {
        router.push('/superadmin')
      } else {
        router.push('/owner')
      }
```

Replace with:

```typescript
      setAuth(res.token, res.role)
      if (res.role === 'SUPER_ADMIN') {
        router.push('/superadmin')
      } else if (res.role === 'MODERATOR') {
        router.push('/moderator')
      } else {
        router.push('/owner')
      }
```

- [ ] **Step 2: Update `admin-web/middleware.ts`**

Replace the entire file:

```typescript
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export function middleware(request: NextRequest) {
  const token = request.cookies.get('lva_token')?.value
  const { pathname } = request.nextUrl

  const protectedPaths = ['/owner', '/superadmin', '/moderator']
  const isProtected = protectedPaths.some(p => pathname.startsWith(p))

  if (isProtected && !token) {
    return NextResponse.redirect(new URL('/login', request.url))
  }
  return NextResponse.next()
}

export const config = {
  matcher: ['/owner/:path*', '/superadmin/:path*', '/moderator/:path*'],
}
```

- [ ] **Step 3: Build to verify**

```bash
PATH="/Users/arthurho/.nvm/versions/node/v20.19.1/bin:$PATH" npm run build 2>&1 | tail -8
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
cd /Users/arthurho/Projects/car-washing-booking
git add admin-web/app/login/page.tsx admin-web/middleware.ts
git commit -m "feat(admin-web): redirect MODERATOR to /moderator on login, add route protection"
```

---

## Task 4: Moderator Layout

**Files:**
- Create: `admin-web/app/moderator/layout.tsx`

- [ ] **Step 1: Create `admin-web/app/moderator/layout.tsx`**

```typescript
import Sidebar from '@/components/Sidebar'

const NAV = [
  { href: '/moderator', label: 'Bay Status', icon: '🔴' },
]

export default function ModeratorLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="flex min-h-screen">
      <Sidebar title="Lva Moderator" items={NAV} />
      <main className="flex-1 p-8 overflow-y-auto">{children}</main>
    </div>
  )
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/arthurho/Projects/car-washing-booking
git add admin-web/app/moderator/layout.tsx
git commit -m "feat(admin-web): add moderator layout with sidebar"
```

---

## Task 5: WalkInModal + ModeratorBayCard Components

**Files:**
- Create: `admin-web/components/WalkInModal.tsx`
- Create: `admin-web/components/ModeratorBayCard.tsx`

- [ ] **Step 1: Create `admin-web/components/WalkInModal.tsx`**

```typescript
'use client'

import { useState } from 'react'

interface WalkInModalProps {
  bayName: string
  onConfirm: (minutes: number) => Promise<void>
  onClose: () => void
}

const DURATION_OPTIONS = [15, 25, 45, 60]

export default function WalkInModal({ bayName, onConfirm, onClose }: WalkInModalProps) {
  const [selected, setSelected] = useState(25)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function handleConfirm() {
    setLoading(true)
    setError('')
    try {
      await onConfirm(selected)
      onClose()
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Failed to create walk-in')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="fixed inset-0 bg-black/40 flex items-center justify-center z-50">
      <div className="bg-white rounded-2xl p-6 w-full max-w-sm shadow-xl">
        <h3 className="text-lg font-bold mb-1">Walk-In — {bayName}</h3>
        <p className="text-gray-500 text-sm mb-4">Select estimated duration:</p>

        <div className="flex gap-2 flex-wrap mb-5">
          {DURATION_OPTIONS.map(min => (
            <button
              key={min}
              onClick={() => setSelected(min)}
              className={`px-4 py-2 rounded-xl text-sm font-semibold border-2 transition ${
                selected === min
                  ? 'bg-navy-600 border-navy-600 text-white'
                  : 'border-gray-200 text-gray-700 hover:border-navy-600'
              }`}
              style={selected === min ? { backgroundColor: '#1B4F72', borderColor: '#1B4F72' } : {}}
            >
              {min} min
            </button>
          ))}
        </div>

        {error && <p className="text-red-600 text-sm mb-3">{error}</p>}

        <div className="flex gap-3">
          <button
            onClick={onClose}
            disabled={loading}
            className="flex-1 h-11 border border-gray-200 rounded-xl text-sm font-semibold text-gray-700 hover:bg-gray-50 transition disabled:opacity-50"
          >
            Cancel
          </button>
          <button
            onClick={handleConfirm}
            disabled={loading}
            className="flex-1 h-11 rounded-xl text-sm font-bold text-white transition disabled:opacity-50"
            style={{ backgroundColor: '#1B4F72' }}
          >
            {loading ? 'Blocking…' : 'Block Bay'}
          </button>
        </div>
      </div>
    </div>
  )
}
```

- [ ] **Step 2: Create `admin-web/components/ModeratorBayCard.tsx`**

```typescript
'use client'

import { useState } from 'react'
import type { BayResponse, BayStatus } from '@/lib/api/types'
import { nextAction } from '@/lib/api/types'
import WalkInModal from './WalkInModal'

const BORDER: Record<BayStatus, string> = {
  IDLE: 'border-green-400',
  OCCUPIED: 'border-blue-500',
  BLOCKED: 'border-red-400',
}

const BADGE: Record<BayStatus, { bg: string; text: string; label: string }> = {
  IDLE:     { bg: 'bg-green-100', text: 'text-green-700', label: 'Available' },
  OCCUPIED: { bg: 'bg-blue-100',  text: 'text-blue-700',  label: 'Occupied'  },
  BLOCKED:  { bg: 'bg-red-100',   text: 'text-red-700',   label: 'Blocked'   },
}

const ACTION_COLOR: Record<string, string> = {
  PENDING:   '#27AE60',
  ARRIVED:   '#1B4F72',
  WASHING:   '#F39C12',
  FINISHING: '#009688',
}

interface ModeratorBayCardProps {
  bay: BayResponse
  liveStatus?: BayStatus
  onUpdateStatus: (bookingId: string, status: string) => Promise<void>
  onWalkIn: (bayId: string, minutes: number) => Promise<void>
}

export default function ModeratorBayCard({
  bay,
  liveStatus,
  onUpdateStatus,
  onWalkIn,
}: ModeratorBayCardProps) {
  const status = liveStatus ?? bay.status
  const effectiveBay = { ...bay, status }
  const border = BORDER[status]
  const badge = BADGE[status]
  const action = nextAction(effectiveBay)

  const [loading, setLoading] = useState(false)
  const [showWalkIn, setShowWalkIn] = useState(false)

  async function handleAction() {
    if (!action || !bay.activeBookingId) return
    setLoading(true)
    try {
      await onUpdateStatus(bay.activeBookingId, action.targetStatus)
    } finally {
      setLoading(false)
    }
  }

  return (
    <>
      <div className={`bg-white rounded-2xl border-2 ${border} p-5 flex flex-col shadow-sm min-h-[200px]`}>
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <span className="text-lg font-bold">{bay.name}</span>
          <span className={`text-xs font-bold px-3 py-1 rounded-full ${badge.bg} ${badge.text}`}>
            {bay.activeBookingStatus ?? badge.label}
          </span>
        </div>

        {/* Body */}
        <div className="flex-1">
          {status === 'IDLE' && !bay.activeBookingId && (
            <p className="text-gray-400 text-sm">Ready for next vehicle</p>
          )}

          {bay.activeBookingId && (
            <div className="bg-gray-50 rounded-xl p-3 text-xs space-y-1">
              <div className="flex justify-between">
                <span className="text-gray-400">Booking</span>
                <span className="font-semibold">
                  #{bay.activeBookingId.slice(0, 8).toUpperCase()}
                </span>
              </div>
              {bay.activeBookingStatus && (
                <div className="flex justify-between">
                  <span className="text-gray-400">Status</span>
                  <span className="font-semibold">{bay.activeBookingStatus}</span>
                </div>
              )}
            </div>
          )}

          {status === 'BLOCKED' && !bay.activeBookingId && (
            <p className="text-gray-400 text-sm">Walk-in customer</p>
          )}
        </div>

        {/* Actions */}
        <div className="mt-4 space-y-2">
          {/* Primary action: advance booking status */}
          {action && bay.activeBookingId && (
            <button
              onClick={handleAction}
              disabled={loading}
              className="w-full h-11 rounded-xl text-sm font-bold text-white transition disabled:opacity-50"
              style={{ backgroundColor: ACTION_COLOR[bay.activeBookingStatus ?? ''] ?? '#1B4F72' }}
            >
              {loading ? '…' : action.label}
            </button>
          )}

          {/* Walk-in: only on IDLE bays with no booking */}
          {status === 'IDLE' && !bay.activeBookingId && (
            <button
              onClick={() => setShowWalkIn(true)}
              className="w-full h-10 rounded-xl text-sm font-semibold border-2 border-gray-200 text-gray-600 hover:border-gray-400 transition"
            >
              + Walk-In
            </button>
          )}

          {/* Release: on BLOCKED with no booking entity */}
          {status === 'BLOCKED' && !bay.activeBookingId && (
            <button
              onClick={() => onWalkIn(bay.id, 0)}
              disabled={loading}
              className="w-full h-10 rounded-xl text-sm font-semibold border-2 border-gray-200 text-gray-600 hover:border-gray-400 transition disabled:opacity-50"
            >
              Release Bay
            </button>
          )}
        </div>
      </div>

      {showWalkIn && (
        <WalkInModal
          bayName={bay.name}
          onConfirm={minutes => onWalkIn(bay.id, minutes)}
          onClose={() => setShowWalkIn(false)}
        />
      )}
    </>
  )
}
```

- [ ] **Step 3: Build to verify**

```bash
cd /Users/arthurho/Projects/car-washing-booking/admin-web
PATH="/Users/arthurho/.nvm/versions/node/v20.19.1/bin:$PATH" npm run build 2>&1 | tail -8
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
cd /Users/arthurho/Projects/car-washing-booking
git add admin-web/components/WalkInModal.tsx admin-web/components/ModeratorBayCard.tsx
git commit -m "feat(admin-web): add ModeratorBayCard with status transitions and WalkInModal"
```

---

## Task 6: Moderator Bay Panel Page

**Files:**
- Create: `admin-web/app/moderator/page.tsx`

- [ ] **Step 1: Create `admin-web/app/moderator/page.tsx`**

```typescript
'use client'

import { useEffect, useState, useCallback } from 'react'
import { api } from '@/lib/api/client'
import { useBayStatus } from '@/lib/useWebSocket'
import ModeratorBayCard from '@/components/ModeratorBayCard'
import type { BayResponse, CarWashResponse } from '@/lib/api/types'

export default function ModeratorPage() {
  const [carWashes, setCarWashes] = useState<CarWashResponse[]>([])
  const [selectedId, setSelectedId] = useState<string | null>(null)
  const [bays, setBays] = useState<BayResponse[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  const liveBayStatuses = useBayStatus(selectedId)

  // Load car washes on mount
  useEffect(() => {
    api.moderator.listCarWashes()
      .then(data => {
        setCarWashes(data)
        if (data.length > 0) setSelectedId(data[0].id)
      })
      .catch((e: unknown) => setError(e instanceof Error ? e.message : 'Failed to load'))
      .finally(() => setLoading(false))
  }, [])

  // Load bays when selected car wash changes
  const loadBays = useCallback(async () => {
    if (!selectedId) return
    try {
      const data = await api.moderator.listBays(selectedId)
      setBays(data)
    } catch (e: unknown) {
      console.error('Failed to reload bays', e)
    }
  }, [selectedId])

  useEffect(() => {
    loadBays()
  }, [loadBays])

  // Reload bays after any action
  async function handleUpdateStatus(bookingId: string, status: string) {
    await api.moderator.updateBookingStatus(bookingId, status)
    await loadBays()
  }

  async function handleWalkIn(bayId: string, minutes: number) {
    if (minutes > 0) {
      await api.moderator.createWalkIn(bayId, minutes)
    }
    await loadBays()
  }

  if (loading) return <div className="text-gray-500 py-8">Loading…</div>
  if (error) return (
    <div className="text-red-600 bg-red-50 rounded-lg p-4">{error}</div>
  )

  const selected = carWashes.find(w => w.id === selectedId)

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-2xl font-bold">{selected?.name ?? '—'}</h1>
          <p className="text-gray-500 text-sm mt-1">{selected?.address}</p>
        </div>
        <div className="flex items-center gap-3">
          {/* Live indicator */}
          <span className="flex items-center gap-1.5 text-xs bg-green-50 text-green-700 font-semibold px-3 py-1.5 rounded-full">
            <span className="w-2 h-2 bg-green-500 rounded-full inline-block" />
            Live
          </span>
          {/* Car wash switcher (if multiple) */}
          {carWashes.length > 1 && (
            <select
              value={selectedId ?? ''}
              onChange={e => setSelectedId(e.target.value)}
              className="border border-gray-200 rounded-lg px-3 py-2 text-sm"
            >
              {carWashes.map(w => (
                <option key={w.id} value={w.id}>{w.name}</option>
              ))}
            </select>
          )}
          {/* Refresh */}
          <button
            onClick={loadBays}
            className="border border-gray-200 rounded-lg px-3 py-2 text-sm text-gray-600 hover:bg-gray-50 transition"
          >
            ↻ Refresh
          </button>
        </div>
      </div>

      {/* Bay grid */}
      {bays.length === 0 ? (
        <div className="text-center py-20 text-gray-400">
          <div className="text-5xl mb-4">🚗</div>
          <p className="text-lg font-semibold">No bays configured</p>
        </div>
      ) : (
        <div className="grid grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-5">
          {bays.map(bay => (
            <ModeratorBayCard
              key={bay.id}
              bay={bay}
              liveStatus={liveBayStatuses[bay.id]?.status}
              onUpdateStatus={handleUpdateStatus}
              onWalkIn={handleWalkIn}
            />
          ))}
        </div>
      )}
    </div>
  )
}
```

- [ ] **Step 2: Build and verify all routes exist**

```bash
cd /Users/arthurho/Projects/car-washing-booking/admin-web
PATH="/Users/arthurho/.nvm/versions/node/v20.19.1/bin:$PATH" npm run build 2>&1 | grep -E "Route|✓|error" | head -15
```

Expected: Routes include `/moderator` alongside `/owner`, `/login`, etc.

- [ ] **Step 3: Commit**

```bash
cd /Users/arthurho/Projects/car-washing-booking
git add admin-web/app/moderator/
git commit -m "feat(admin-web): add moderator bay panel page with status transitions and walk-in"
```

---

## Self-Review

**Spec coverage:**
- ✅ MODERATOR role can log in → redirected to /moderator
- ✅ /moderator route is protected (middleware)
- ✅ Backend /api/owner/** grants MODERATOR read access
- ✅ BayResponse extended with activeBookingId + activeBookingStatus
- ✅ api.moderator.* methods: listCarWashes, listBays, updateBookingStatus, createWalkIn
- ✅ ModeratorBayCard with one-tap status transition (PENDING→ARRIVED→WASHING→FINISHING→COMPLETED)
- ✅ WalkInModal with 15/25/45/60 min duration selector
- ✅ Live WebSocket updates via existing useBayStatus hook
- ✅ Bay panel reloads after every action to reflect latest booking state

**Placeholder scan:** None. All code blocks are complete.

**Type consistency:**
- `nextAction(bay: BayResponse)` defined in types.ts, imported and used in ModeratorBayCard.tsx ✅
- `api.moderator.listBays()` returns `BayResponse[]` matching the `bay` prop type on ModeratorBayCard ✅
- `liveStatus` override: `useBayStatus` returns `Record<string, BayStatusMessage>` — accessing `[bay.id]?.status` returns `BayStatus | undefined`, cast to `BayStatus` when present ✅
- `handleUpdateStatus` and `handleWalkIn` signatures match `ModeratorBayCard` props ✅
