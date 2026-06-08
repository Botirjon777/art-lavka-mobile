# ART-LAVKA — Node REST Backend Specification

> Replaces the Supabase backend. Same data model, same principles, Node/NestJS implementation.
> Keep at `/docs/BACKEND_NODE.md`. This is the source of truth for the API.

---

## 0. Why Node (decision record)

The team knows Node best, and the previous Supabase backend was scaffolding, not tested/proven code — so migration cost is low and the long-term win (a backend the team maintains confidently) is high. The data model, integer-UZS rule, append-only ledger, and "server is the only price authority" principle all carry over unchanged.

**The one thing we lose and must rebuild deliberately:** Supabase RLS enforced per-user data access at the database level. In Node, that becomes authorization logic in code. Rule: **a guard on every protected route + an ownership check in every service method that touches user-scoped data.** A missed check leaks another user's data or money. Non-negotiable.

---

## 1. Stack

| Concern | Choice | Why |
|---|---|---|
| Framework | **NestJS** | Modules, DI, guards — matches the layered design; guards are where authz lives |
| Language | **TypeScript** | Type safety end to end |
| Database | **PostgreSQL** | Keep the existing schema; integer-UZS + ledger design is sound |
| ORM | **Prisma** | Type-safe queries + migrations |
| Auth | **JWT** (access + refresh) | Stateless, works well with Flutter |
| OTP / SMS | **Eskiz.uz** or **Play Mobile** | Local providers that deliver to +998 |
| File storage | **S3-compatible** (presigned URLs) | Private print files, public mockups |
| Validation | **class-validator** + DTOs | Reject bad input at the edge |
| Payments | Click / Payme / Uzum merchant APIs | Server verifies every callback signature |
| Cache/queues (later) | Redis + BullMQ | Mockup generation, payout batches |

---

## 2. Project Structure

A separate repo (or `/backend` in the monorepo). NestJS module-per-domain.

```
backend/
├── package.json
├── tsconfig.json
├── .env.example                    # DB_URL, JWT secrets, SMS keys, S3, payment keys
├── prisma/
│   ├── schema.prisma               # the data model (see §3)
│   ├── migrations/
│   └── seed.ts
├── src/
│   ├── main.ts                     # bootstrap, global pipes, CORS
│   ├── app.module.ts
│   ├── common/
│   │   ├── guards/                 # JwtAuthGuard, RolesGuard, OwnershipGuard
│   │   ├── decorators/             # @CurrentUser, @Roles
│   │   ├── interceptors/           # logging, response shape
│   │   ├── filters/                # global exception → typed error response
│   │   └── money.ts                # int-UZS helpers (mirror of Dart Money)
│   ├── config/                     # env validation, constants (royalty bounds, payout min)
│   ├── prisma/                     # PrismaService (singleton)
│   ├── auth/                       # OTP request/verify, JWT issue/refresh, profile
│   ├── users/
│   ├── designers/                  # profiles, KYC, e-signature
│   ├── catalog/                    # categories, listings, search, storefronts
│   ├── designs/                    # upload, moderation status
│   ├── products/                   # product types, print-zone metadata
│   ├── orders/                     # create-order, status, tracking
│   ├── payments/                   # provider integrations + webhooks
│   ├── ledger/                     # append-only writes, balance reads
│   ├── payouts/                    # request + process
│   ├── reviews/
│   ├── storage/                    # presigned URL issuing
│   └── moderation/                 # admin queue
└── test/
```

Each domain module: `*.controller.ts` (routes + guards), `*.service.ts` (logic + ownership checks), `dto/` (validated request shapes), `entities`/Prisma types.

---

## 3. Data Model (Prisma)

Keep the schema from the platform plan — `users`, `designerProfiles`, `designs`, `productTypes`, `listings`, `orders`, `orderItems`, `ledger`, `payouts`, `categories`, `designCategories`, `reviews`, `banners`, `carts`.

Non-negotiable rules carried over:
- **All money is `BigInt` UZS, no decimals.** Prisma `BigInt`. Serialize as string in JSON to avoid JS number overflow; the Flutter side parses to `int`.
- **`ledger` is append-only.** No update/delete. A designer's balance = `SUM(amount)` of their ledger rows. Add a DB-level safeguard: revoke UPDATE/DELETE on the ledger table for the app role, or enforce in a repository that only ever inserts.
- **Order items snapshot** `unitBasePrice`, `unitRoyalty`, `unitPrice`, `designerId` at purchase time. Later changes to a listing never alter past orders.
- Indexes on `orderItems.designId`, `ledger.designerId`, `listings.designId`, `orders.customerId`.

---

## 4. Auth & Authorization

### Phone OTP flow (server side)
```
POST /auth/otp/request   { phone }
  → rate-limit per phone + per IP
  → generate 6-digit code, hash + store with short TTL (e.g. 2 min)
  → send via SMS provider (Eskiz/Play Mobile)
  → 200 (never reveal whether the phone exists)

POST /auth/otp/verify    { phone, code }
  → check hash + TTL + attempt count
  → on success: create/find user, issue { accessToken, refreshToken }
  → on fail: increment attempts; lock after N tries

POST /auth/refresh        { refreshToken } → new access token
POST /auth/logout         → invalidate refresh token
```

### The two non-negotiable layers
1. **`JwtAuthGuard`** on every protected route — no valid token, no entry.
2. **`RolesGuard` + `OwnershipGuard`** — role check (customer/designer/moderator/admin) AND, for any user-scoped resource, verify the authenticated user owns it. Example: `GET /designers/me/earnings` reads earnings for `req.user.id` only — never an id from the request body or params for someone else's data.

Write a reusable ownership check and apply it in every service method that returns user-scoped data. This is the replacement for RLS — treat its absence on any such endpoint as a bug.

---

## 5. Key Endpoints (the ones with real logic)

### Catalog (public)
- `GET /catalog/categories`
- `GET /catalog/listings?category=&sort=&page=` — paginated cards (mockup, title, designer, price, rating). Falls back to design preview for `mockupUrl` until server mockups exist.
- `GET /catalog/listings/:id` — product page detail + reviews.
- `GET /storefronts/:designerSlug` — a designer's public listings.
- Search: `GET /catalog/search?q=` — debounced client side; server does a trigram/ILIKE search, paginated.

### Orders — the price authority (replaces `create-order` edge fn)
```
POST /orders   (auth: customer)
  body: { items: [{ listingId, variant, qty }], addressId, deliveryMethod, paymentProvider }
  server:
    1. load each listing fresh; reject inactive/removed
    2. recompute price = base_cost + royalty (NEVER trust client price)
    3. snapshot base/royalty/price + designerId onto each order_item
    4. create order (status: pending_payment), compute totals server-side
    5. create payment intent with the chosen provider
    6. return { orderId, paymentIntent }
```
- `GET /orders/me?page=` — caller's orders only (ownership).
- `GET /orders/:id` — only if it belongs to the caller.

### Payments (replaces `payment-webhook`)
```
POST /payments/webhook/:provider   (public, but SIGNATURE-VERIFIED)
  → verify provider signature/HMAC — reject if invalid (this is critical; stubbed until creds)
  → match to order, mark paid, enqueue to production
  → idempotent: same callback twice must not double-process
```

### Ledger & payouts (money — replaces `accrue-royalty` / `request-payout`)
- Royalty accrual: triggered when an order is marked **delivered** and the return window passes → insert `royalty_accrued` ledger rows. Never on order creation.
- `GET /designers/me/balance` → `SUM(ledger.amount)` for caller.
- `POST /payouts/request` (auth: designer) → validate balance ≥ payout minimum, insert payout + `payout` ledger debit (negative), status `requested`. Runs on a fixed schedule, not instantly.
- Refund/return → `royalty_clawback` ledger row (negative) reversing the accrual.

### Designs & moderation
- `POST /designs` (auth: designer) → upload metadata + request presigned URL for the private print file; status `pending_review`.
- `GET /designs/me` → caller's designs + statuses.
- `GET /moderation/queue` (auth: moderator) → pending designs.
- `POST /moderation/:designId/decision` → approve/reject (+ reason). Enforces content rules (no 18+, religion, war, IP).

### Storage (replaces `generate-signed-url`)
- `POST /storage/presign-upload` → presigned PUT for `print-files` (private) or `print-previews` (public).
- `GET /storage/print-file/:designId` (auth: operations/admin only) → short-lived signed GET. Customers/designers never get the raw print file.

---

## 6. Error & Response Shape (match the Flutter `Result<T>`)

Global exception filter returns a consistent shape so the Flutter `ErrorMapper` keeps working:
```json
{ "error": { "code": "OTP_INVALID", "message": "..." } }
```
Codes map 1:1 to the `FailureCode` enum already in `artlavka_core` and to the copy in `docs/COPY.md`. Success responses return the data directly (or `{ data, page, total }` for lists). Money fields serialize as strings.

---

## 7. What Changes on the Flutter Side

Minimal, because the architecture anticipated this:
- Swap `supabase_service` for an `api_client` (Dio) in `artlavka_core/services/` — base URL, JWT attach/refresh interceptor, error → `Result.Failure` mapping.
- `auth_service`, `storage_service`, `payment_service`, and the repositories keep their **public method signatures**; only their internals change from Supabase calls to REST calls. Controllers/UI don't change at all.
- Store JWT in `flutter_secure_storage`; refresh on 401.
- `--dart-define=API_BASE_URL=...` replaces the Supabase URL/key defines.

Because widgets → controllers → repositories was enforced, the UI work Claude is doing now (auth screens, catalog) is unaffected — it talks to repositories, not to Supabase.

---

## 8. Migration Plan (low-risk order)

1. Stand up NestJS skeleton + Prisma + the existing schema (port `schema.prisma`).
2. Auth module (OTP + JWT) with a **mock SMS provider** behind an env flag (same approach as the Flutter side) so it's testable before live SMS.
3. Catalog read endpoints (unblocks the Step 4 work).
4. Orders + payments (sandbox/mock payment until provider creds arrive).
5. Ledger + payouts.
6. Designs + moderation + storage presigning.
7. Swap the Flutter `supabase_service` → `api_client`; point repositories at REST.
8. Delete the unused `supabase/` folder once parity is verified.

Run gate unchanged on the Flutter side (`melos run analyze/test/format`). Add backend gates: `npm run lint`, `npm run test`, `prisma migrate` clean.

---

## 9. Security checklist (the RLS replacement)

- [ ] `JwtAuthGuard` on every non-public route.
- [ ] Ownership check in every service method returning user-scoped data (orders, earnings, designs, payouts).
- [ ] Never accept a user id from the request for "my data" endpoints — use `req.user.id`.
- [ ] Payment webhooks signature-verified + idempotent.
- [ ] Ledger insert-only at the DB role level.
- [ ] Private print files only via short-lived signed URLs for operations/admin.
- [ ] Rate-limit OTP request + verify.
- [ ] Validate every DTO; reject unknown fields.
- [ ] Server is the only price authority (recompute in `POST /orders`).
- [ ] Secrets via env; nothing committed.
```
