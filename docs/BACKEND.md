# ART-LAVKA Backend Reference

Schema, RLS, storage, and edge functions. Authoritative SQL lives in
`supabase/migrations/`; this is the human-readable map. See SPEC §5 for intent.

## Migrations
| File | Contains |
|---|---|
| `0001_schema.sql` | Enums + all tables. Money is `bigint` UZS. |
| `0002_views_indexes.sql` | `listing_cards`, `designer_balances`, `design_reviews` views; indexes; `handle_new_user` trigger. |
| `0003_rls.sql` | `is_staff()` + every RLS policy (default-deny). |
| `0004_storage.sql` | Buckets + storage object policies. |
| `seed.sql` | Categories + product types (with print-zone metadata). |

## Tables (summary)
- **users** — 1:1 with `auth.users`; phone identity, role, language.
- **designer_profiles** — KYC + contract acceptance (version, hash, signature path).
- **categories** / **design_categories** — themes and the M:N to designs.
- **product_types** — blank products; `base_cost` + `variants` JSON (template + `print_zone` + `warp`).
- **designs** — uploaded prints; public `preview_url`, private `print_file_path`, moderation `status`.
- **listings** — a design on a product at a `royalty`; price = base_cost + royalty.
- **orders** / **order_items** — items snapshot `unit_base_cost` + `unit_royalty` (history never changes).
- **ledger** — append-only signed money events; balance = SUM(amount).
- **payouts** — withdrawals; creating one writes a `payoutDebit` ledger row.
- **reviews** — one per delivered `order_item` (unique).
- **banners**, **cart_items**, **device_tokens**.

## Views
- **listing_cards** — one row per active listing of an approved design, with
  title, designer name, mockup url, rating, and `category_slugs text[]` (filter
  with `contains`). Definer view; exposes only safe public columns.
- **designer_balances** — `SUM(ledger.amount)` per designer. `security_invoker`
  so a caller only sums their own rows.
- **design_reviews** — reviews joined to their design + reviewer name.

## RLS principles (SPEC §5)
- Default-deny; enable RLS on every table.
- Customers: read public catalog; read/write only their own orders, cart, reviews, profile.
- Designers: read/write only their own designs, listings, payout requests; read only their own ledger/earnings.
- `print-files`: no public read — only `generate-signed-url` (service role) issues URLs to `operations`/`admin`.
- Staff (`operations`/`moderator`/`admin`) get elevated policies via `is_staff()`.
- Trusted writes (orders, ledger, payouts) happen in edge functions using the **service role**, which bypasses RLS.

## Storage buckets
| Bucket | Visibility | Contents |
|---|---|---|
| `print-files` | private | Hi-res print-ready artwork. Signed URLs to production only. |
| `print-previews` | public | Low-res watermarked previews for mockups. |
| `mockups` | public | Cached composited product images. |
| `product-templates` | public | Blank product photos + mapping metadata. |
| `signatures` | private | Seller e-signatures. |

## Edge functions
| Function | JWT | Purpose |
|---|---|---|
| `create-order` | required | Recompute price from current listing, snapshot onto order/items, return payment intent. |
| `payment-webhook` | none | Verify provider signature, mark order paid, queue production. |
| `accrue-royalty` | none (scheduled) | After delivery + return window, write `royaltyAccrued` ledger credits. Idempotent. |
| `request-payout` | required | Validate balance ≥ min, create payout + matching ledger debit. |
| `generate-signed-url` | required | Staff-only short-lived signed URL for a print file. |

### Required function env
`SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, plus payment
provider secrets (`CLICK_SECRET`, `PAYME_KEY`, `UZUM_KEY`) and `PAYMENTS_SANDBOX`
for local testing.
