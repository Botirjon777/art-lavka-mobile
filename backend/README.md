# ART-LAVKA API (NestJS)

REST backend replacing Supabase. Source of truth for the API is
[`docs/BACKEND_NODE.md`](../docs/BACKEND_NODE.md).

> Status: **§8 steps 1–7 done** — API feature-complete (auth, catalog, orders &
> payments, ledger & payouts, designs, moderation, storage, reviews) AND the
> Flutter side now talks to it via `artlavka_core`'s Dio `ApiClient` (no more
> Supabase). Remaining: **step 8** — delete the legacy `supabase/` folder once
> parity is verified against a running stack.
>
> Extra endpoint beyond §5: `POST /reviews` (JWT) — one review per delivered
> order item, for the Flutter `OrderRepository.submitReview`.

## Designs, moderation & storage (§5)
| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/designs` | JWT | Create a design (status `pending`); validates min print size. |
| GET | `/designs/me?page=` | JWT | Caller's designs + statuses. |
| POST | `/designs/listings` | JWT | Upsert a listing (design × product) at a royalty (bounds enforced). |
| PATCH | `/designs/listings/:id` | JWT (owner) | Update royalty/active. |
| GET | `/moderation/queue?page=` | JWT + moderator/admin | Pending designs (FIFO). |
| POST | `/moderation/:designId/decision` | JWT + moderator/admin | `{ decision: approve\|reject, reason? }`. |
| POST | `/storage/presign-upload` | JWT | Presigned PUT for an upload bucket. |
| GET | `/storage/print-file/:designId` | JWT + ops/admin | Short-lived signed GET for the private print file. |

Storage runs in **mock mode** until `S3_ENDPOINT` is set (returns placeholder
URLs); real presigning (`@aws-sdk/s3-request-presigner`) is a localized TODO.

## Ledger & payouts (§5 — money)
| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/designers/me/balance` | JWT | `{ balance }` = SUM of the caller's ledger rows. |
| GET | `/designers/me/ledger?page=` | JWT | Caller's ledger entries (append-only), paginated. |
| POST | `/ledger/accrue-royalties` | JWT + ops/admin | Manually trigger accrual (also a daily cron). Idempotent. |
| POST | `/payouts/request` | JWT | `{ amount }` → validates ≥ minimum & ≤ balance, writes payout + matching ledger debit atomically. |
| GET | `/payouts/me?page=` | JWT | Caller's payouts. |

The ledger is **insert-only** (`LedgerService` never updates/deletes). Royalties
accrue on **delivered + return-window-passed** (cron `EVERY_DAY_AT_3AM` or the ops
endpoint), never at payment. A refund (`PATCH /orders/:id/status` → `refunded`)
writes negative `refundReversal` clawback rows.

## Orders & payments (§5)
| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/orders` | JWT | `{ items:[{listingId,quantity,size?,color?}], paymentProvider, addressId?\|shippingAddress? }` → recomputes price server-side, snapshots base/royalty/designer onto items, returns a payment intent `{ order_id, provider, checkout_url, amount }`. |
| GET | `/orders/me?page=` | JWT | Caller's orders only (ownership), paginated. |
| GET | `/orders/:id` | JWT | One order, only if it belongs to the caller. |
| PATCH | `/orders/:id/status` | JWT + ops/admin | Advance status (sets `delivered_at` on delivered). |
| POST | `/payments/webhook/:provider` | public | Signature-verified (sandbox-only until creds), **idempotent** (only moves orders out of `pending`). Marks paid/cancelled. |

Orders are the **only price authority** — the client price is never trusted.
Items serialize under `order_items` to match the Flutter `Order` model. Royalty
is NOT accrued at payment — that happens on delivery via the ledger (step 5).

## Catalog endpoints (§5, all public)
| Method | Path | Notes |
|---|---|---|
| GET | `/catalog/categories` | All categories, ordered. |
| GET | `/catalog/product-types` | Product types + print-zone metadata. |
| GET | `/catalog/banners` | Active home banners. |
| GET | `/catalog/listings?category=&q=&sort=&page=` | Paginated cards `{ data, page, page_size, total }`. `sort` = `new`(default)\|`price_low`\|`price_high`. |
| GET | `/catalog/search?q=&page=` | Same shape, title search. |
| GET | `/catalog/listings/:id` | One card (active + approved only). |
| GET | `/catalog/designs/:designId/reviews` | Reviews for a design. |
| GET | `/storefronts/:slug` | A designer's public profile + listings. |

Cards mirror the old `listing_cards` view (title, designer name, base_cost +
royalty, rating, `category_slugs`); `mockup_url` falls back to the design
preview until server-rendered mockups exist (§6). Responses are snake_case so
the Flutter `Listing`/`Category`/`Review` models parse them unchanged.

## Auth endpoints (§4)
| Method | Path | Auth | Notes |
|---|---|---|---|
| POST | `/auth/otp/request` | public | `{ phone }` → sends OTP. Per-IP + per-phone rate limited. Never reveals if the phone exists. |
| POST | `/auth/otp/verify` | public | `{ phone, code }` → `{ user, access_token, refresh_token }`. |
| POST | `/auth/refresh` | public | `{ refreshToken }` → new token pair (rotates + revokes the old). |
| POST | `/auth/logout` | public | `{ refreshToken }` → revokes it. |
| GET | `/auth/me` | JWT | Current user. |
| PATCH | `/auth/me` | JWT | Complete/update profile (`fullName`, `languageCode`, `email?`, `avatarUrl?`). |

- **OTP**: 6 digits, bcrypt-hashed, 2-min TTL, max 5 attempts; `MOCK_SMS=true`
  logs the code instead of sending (dev/testing without a live +998 provider).
- **Tokens**: access = short-lived JWT; refresh = opaque random, stored as a
  SHA-256 hash for revocation/rotation.
- Responses are **snake_case** (a global interceptor) so the Flutter models'
  `fromJson` parse them unchanged after the swap.

## Stack
NestJS · TypeScript · PostgreSQL · Prisma · JWT · class-validator. Money is
`BigInt` UZS, serialized to JSON as a **string**.

## Layout
```
src/
├── main.ts              · global pipes, CORS, exception filter, BigInt JSON
├── app.module.ts        · config + Prisma + JWT wiring; feature modules added here
├── common/
│   ├── errors/          · ErrorCode (mirrors Dart FailureCode) + AppException
│   ├── filters/         · AllExceptionsFilter → { error: { code, message } }
│   ├── guards/          · JwtAuthGuard, RolesGuard
│   ├── decorators/      · @CurrentUser, @Roles
│   ├── interceptors/    · request logging
│   ├── ownership.ts     · assertOwnership() — the RLS replacement at the service layer
│   └── money.ts         · int-UZS helpers (mirror of Dart Money) + BigInt JSON patch
├── config/              · env validation + constants (royalty bounds, payout min…)
└── prisma/              · PrismaService (singleton) + global module
prisma/
├── schema.prisma        · full data model (§3)
└── seed.ts              · categories + product types
```

## Setup
```bash
npm install
cp .env.example .env        # fill DATABASE_URL + JWT secrets
npm run prisma:generate     # generate the Prisma client (no DB needed)
npm run prisma:migrate      # create/apply migrations (needs a running Postgres)
npm run db:seed             # categories + product types
npm run start:dev           # http://localhost:3000  (GET /health)
```

## Gates
```bash
npm run build               # nest build (tsc)
npm run lint                # eslint
npm test                    # jest (unit *.spec.ts)
```

## Security (the RLS replacement — BACKEND_NODE.md §9)
- `JwtAuthGuard` on every protected route.
- `assertOwnership(req.user.id, ownerId)` in every service method returning
  user-scoped data. Never trust an id from the request for "my data".
- Webhooks signature-verified + idempotent; ledger insert-only; price recomputed
  server-side; private print files only via short-lived signed URLs.
