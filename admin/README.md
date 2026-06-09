# ART-LAVKA Admin

Web admin panel for the ART-LAVKA marketplace.

**Stack:** Next.js 16 (App Router) · TypeScript · Tailwind v4 · Zustand (auth) ·
TanStack Query (data).

## What it does
- **Login** — phone-OTP against the API (`/auth/otp/request` + `/auth/otp/verify`);
  only `admin`/`moderator` accounts are allowed in. The OTP is delivered to
  Telegram (or the server logs).
- **Dashboard** — headline stats (customers, designers, applications, orders, revenue).
- **Designers** — seller applications with **Approve / Reject** (verify/reject KYC),
  filterable by status.
- **Customers** — list with order counts.

## Run
```bash
npm install
cp .env.example .env.local      # NEXT_PUBLIC_API_URL (defaults to the Render API)
npm run dev                     # http://localhost:3000
```

## Auth / admin account
Log in with the seeded admin phone (`ADMIN_PHONE`, default `+998900000000`) — the
backend seed grants it the `admin` role. Read the OTP from the Telegram group (or
Render logs). The JWT is kept in `localStorage` via Zustand; requests attach it as
a Bearer token (see `src/lib/api.ts`).

## Deploy
Ideal on **Vercel** (root directory `admin`). Set `NEXT_PUBLIC_API_URL` to the API
URL. It's a separate Node app — not part of the Flutter pub workspace or the NestJS
backend.
