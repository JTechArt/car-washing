# Lva Admin Web

Next.js 14 + TypeScript operations portal for wash owners and super admins.

## Prerequisites

| Tool | Version |
|---|---|
| Node.js | 20+ |
| npm | 10+ |
| Lva Backend | running on :8080 |

## Start Locally

```bash
cd admin-web
npm install
npm run dev
```

Visit http://localhost:3000. Log in with an OWNER or SUPER_ADMIN account.

## Environment Variables

Create `.env.local` in the `admin-web/` directory:

```env
NEXT_PUBLIC_API_URL=http://localhost:8080
NEXT_PUBLIC_WS_URL=ws://localhost:8080/ws
```

## Pages

| Path | Role | Description |
|---|---|---|
| `/login` | — | JWT login |
| `/owner` | OWNER | Dashboard: bay status, car washes |
| `/owner/pricing` | OWNER | Set prices by vehicle type and service |
| `/superadmin` | SUPER_ADMIN | Tenant management |

## Regenerate API Client

With backend running:

```bash
npm run generate-api
```

Reads `http://localhost:8080/v3/api-docs` and writes typed TypeScript to `lib/api/generated/`.

## Build

```bash
npm run build
npm start
```
