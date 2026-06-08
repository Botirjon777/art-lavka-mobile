# ART-LAVKA — Full Project Specification (Build From Scratch)

> The single source of truth for building the ART-LAVKA marketplace.
> Two Flutter apps (**client** + **seller/Studio**) sharing one core package, one Supabase backend.
> Keep this file in the repo at `/docs/SPEC.md` and update it as decisions change.

---

## 0. Table of Contents

1. Product overview & principles
2. Monorepo folder structure
3. Setup commands (from zero to running)
4. README files (root + each package)
5. Backend: Supabase schema, storage, RLS, edge functions
6. Product rendering logic — print on t-shirt / cup / cap
7. App logic & state management
8. Auth: registration, login, phone OTP confirmation
9. Seller onboarding (KYC + rules + e-signature)
10. UI inventory: inputs, dropdowns, tooltips, buttons
11. Copy library: error messages, success messages, tooltips
12. Animations: success order, loaders, transitions
13. Optimizations (performance, cost, build)
14. Definition of done / build order

---

## 1. Product Overview & Principles

ART-LAVKA is a print-on-demand marketplace for Uzbekistan. Designers upload prints; customers order products (t-shirts, hoodies, caps, cups, etc.) carrying those prints; ART-LAVKA prints in-house, fulfils, and delivers. Each sale pays the designer a royalty and keeps a platform margin.

Two apps share one backend:
- **ART-LAVKA** (client) — browse, order, pay, track, rate.
- **ART-LAVKA Studio** (seller) — onboard, upload prints, set royalties, view stats, withdraw.

Design principles:
- **The art is the hero.** UI stays neutral (warm off-white, one accent) so prints pop.
- **Money is sacred.** Every financial event is an append-only ledger row; balances are sums, never overwritten fields.
- **Trust the server.** Prices, payments, and royalties are computed/verified server-side, never trusted from the client.
- **Localize.** RU / UZ / EN, local payments (Click, Payme, Uzum), local delivery, UZS as integer money (no decimals).

---

## 2. Monorepo Folder Structure

Use a single Git repo with a `melos`-managed workspace.

```
artlavka/
├── melos.yaml                      # workspace orchestration
├── pubspec.yaml                    # workspace root (melos)
├── analysis_options.yaml           # shared lint rules
├── .gitignore
├── .env.example                    # never commit real .env
├── README.md                       # root readme (see §4)
├── docs/
│   ├── SPEC.md                     # THIS FILE
│   ├── COPY.md                     # copy library (see §11)
│   └── BACKEND.md                  # schema + RLS reference
│
├── packages/
│   └── artlavka_core/              # shared, NO UI widgets
│       ├── pubspec.yaml
│       ├── README.md
│       └── lib/
│           ├── artlavka_core.dart  # barrel export
│           ├── config/
│           │   ├── env.dart        # reads --dart-define values
│           │   └── constants.dart  # min payout, royalty bounds, etc.
│           ├── models/
│           │   ├── app_user.dart
│           │   ├── designer_profile.dart
│           │   ├── design.dart
│           │   ├── product_type.dart
│           │   ├── listing.dart
│           │   ├── order.dart
│           │   ├── order_item.dart
│           │   ├── ledger_entry.dart
│           │   └── payout.dart
│           ├── services/
│           │   ├── supabase_service.dart
│           │   ├── auth_service.dart
│           │   ├── storage_service.dart   # signed URLs, uploads
│           │   ├── payment_service.dart    # Click/Payme/Uzum
│           │   └── notification_service.dart
│           ├── repositories/
│           │   ├── catalog_repository.dart
│           │   ├── order_repository.dart
│           │   ├── design_repository.dart
│           │   ├── earnings_repository.dart
│           │   └── payout_repository.dart
│           ├── theme/
│           │   ├── colors.dart
│           │   ├── typography.dart
│           │   └── app_theme.dart
│           └── utils/
│               ├── money.dart       # UZS formatting
│               ├── result.dart      # Result<T> success/failure type
│               └── validators.dart  # phone, required, etc.
│
└── apps/
    ├── client/
    │   ├── pubspec.yaml
    │   ├── README.md
    │   └── lib/
    │       ├── main.dart
    │       ├── app.dart             # MaterialApp + router
    │       ├── router.dart          # go_router routes
    │       └── features/
    │           ├── splash/
    │           ├── auth/            # login, register, OTP
    │           ├── home/            # banners + feeds
    │           ├── catalog/         # categories, theme pages, search
    │           ├── product/         # product page, mockup, reviews
    │           ├── storefront/      # designer public page
    │           ├── cart/            # cart + checkout + payment
    │           ├── orders/          # tracking + rate
    │           └── profile/         # account, addresses, become-a-seller
    │
    └── studio/
        ├── pubspec.yaml
        ├── README.md
        └── lib/
            ├── main.dart
            ├── app.dart
            ├── router.dart
            └── features/
                ├── splash/
                ├── onboarding/      # register, KYC, rules, e-signature, gate
                ├── home/            # sales overview, balance
                ├── uploads/         # upload print, set royalty, status
                ├── stats/           # top prints, best sellers, charts
                ├── earnings/        # ledger, withdraw
                └── profile/         # payout info, account
```

Each `features/<name>/` folder follows the same internal shape:
```
features/product/
├── product_page.dart            # screen widget
├── widgets/                     # screen-specific widgets
│   ├── mockup_view.dart
│   ├── size_selector.dart
│   └── review_list.dart
├── product_controller.dart      # Riverpod notifier
└── product_state.dart           # immutable state class
```

---

## 3. Setup Commands (Zero to Running)

```bash
# 1. Prerequisites
#    - Flutter SDK (stable channel)
#    - Dart (bundled with Flutter)
#    - Node.js (for Supabase CLI + edge functions)
#    - Supabase CLI:  npm i -g supabase

# 2. Create the workspace
mkdir artlavka && cd artlavka
git init
flutter pub global activate melos

# 3. Create the shared package
flutter create --template=package packages/artlavka_core

# 4. Create the two apps
flutter create --org uz.artlavka --project-name artlavka_client apps/client
flutter create --org uz.artlavka --project-name artlavka_studio apps/studio

# 5. Bootstrap the workspace (links local packages)
melos bootstrap

# 6. Supabase: start local stack
supabase init
supabase start                      # local Postgres + studio
supabase db reset                   # applies migrations in supabase/migrations

# 7. Environment values (never commit real keys)
cp .env.example .env                # fill SUPABASE_URL + ANON_KEY etc.

# 8. Run an app (pass secrets via --dart-define)
cd apps/client
flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

# 9. Common workspace commands (defined in melos.yaml)
melos run analyze                   # lint all packages
melos run test                      # test all packages
melos run format                    # dart format
melos clean && melos bootstrap      # reset workspace
```

`melos.yaml` scripts to define: `analyze`, `test`, `format`, `build_client`, `build_studio`.

Build commands:
```bash
# Client release (Android)
flutter build apk --release \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
# Client release (iOS)
flutter build ipa --release --dart-define=...
```

---

## 4. README Files

### Root `README.md`
Must contain: project one-liner, the two-app architecture diagram link, prerequisites, the §3 setup commands, environment variable table, how to run each app, branch/PR conventions, and a link to `docs/SPEC.md`. Keep it short — it points to the spec, it doesn't duplicate it.

### `packages/artlavka_core/README.md`
Explains: this package holds all shared models, services, repositories, theme, and utils with **no Flutter widgets** (so it stays testable and reusable). Lists the barrel export, the `Result<T>` convention, and the rule that money is always `int` UZS.

### `apps/client/README.md` and `apps/studio/README.md`
Each explains: which app this is, the feature folders, how to run it with `--dart-define`, and which `artlavka_core` services it consumes. The studio readme additionally documents the onboarding gate (no dashboard access until `kyc_status = verified`).

---

## 5. Backend — Supabase

### Money convention
All money is `bigint` representing **UZS with no decimals**. Never use float. Format for display only (see `utils/money.dart`).

### Tables
Reuse the schema from the platform plan: `users`, `designer_profiles`, `designs`, `product_types`, `listings`, `orders`, `order_items`, `ledger`, `payouts`. Add:

**categories / themes** (gamers, memes, funny, etc.)
| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| slug | text unique | gamers, memes, funny, anime |
| name_ru / name_uz / name_en | text | localized labels |
| sort_order | int | |

**design_categories** (many-to-many)
| design_id | uuid FK | |
| category_id | uuid FK | |

**reviews**
| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| order_item_id | uuid FK | one review per delivered item |
| customer_id | uuid FK | |
| rating | int | 1–5 |
| comment | text | |
| created_at | timestamptz | |

**banners**
| id | uuid PK | image_url, link_target (category/listing/url), sort_order, active |

### Storage buckets
- `print-files` — **private**. Hi-res print-ready artwork. Only the production team gets signed URLs.
- `print-previews` — **public**. Low-res, watermarked previews used to build mockups.
- `mockups` — **public**. Cached composited product images (optional, see §6).
- `product-templates` — **public**. Blank product photos with mapping metadata.
- `signatures` — **private**. Seller e-signatures.

### Row-Level Security (essential policies)
- Customers: can read public catalog; can read/write only **their own** orders, cart, reviews, profile.
- Designers: can read/write only **their own** designs, listings, payout requests; can read only **their own** ledger and earnings.
- `print-files` bucket: no public read; access only via server-issued signed URLs for `operations`/`admin` roles.
- Moderators/admin: elevated policies for the moderation queue and payouts.
- **Never** expose another designer's earnings or another customer's orders.

### Edge functions (server-side, untrusted-client safe)
- `create-order` — recomputes price (`base_cost + royalty`) from current listing, creates order + order_items with **snapshotted** prices, returns a payment intent.
- `payment-webhook` — receives Click/Payme/Uzum callback, verifies signature, marks order `paid`, moves to production queue.
- `accrue-royalty` — on order delivered + return window passed, writes `royalty_accrued` ledger rows.
- `request-payout` — validates balance ≥ minimum threshold, creates payout, writes `payout` ledger debit.
- `generate-signed-url` — issues short-lived signed URLs for print files (production only).

---

## 6. Product Rendering Logic — Print on T-Shirt / Cup / Cap

This is the visual core of the marketplace. There are two strategies; pick per product type.

### Strategy A — Server pre-rendered mockups (recommended default)
When a designer uploads a print and selects products, an edge function (or a worker) composites the print onto each product template **once**, stores the result in the `mockups` bucket, and the app just shows a normal image. Fast for the client, consistent, cacheable.

How compositing works for each product type, using mapping metadata stored on `product_types.variants`:
- **T-shirt / hoodie / flat garment**: a rectangular "print zone" (x, y, width, height, rotation) on the template photo. The print is scaled to fit the zone, respecting aspect ratio, and alpha-composited. Different colors = different template photos (white tee, black tee).
- **Cap**: smaller front print zone, often with a slight curve allowance; keep prints simple. Same rectangular-zone approach, smaller zone.
- **Cup / mug**: the print wraps a cylinder. Two options — (1) simple: place the print in a flat "label zone" on a straight-on mug photo (good enough for catalog); (2) advanced: apply a horizontal cylindrical warp (mesh distortion) so the print curves around the mug. Start with option 1; upgrade later.

The mapping metadata per template looks like:
```json
{
  "template_url": "product-templates/tee-white-front.png",
  "print_zone": { "x": 210, "y": 180, "w": 360, "h": 480, "rotation": 0 },
  "warp": "none"            // "none" | "cylinder"
}
```

### Strategy B — Client-side live preview (for the upload screen)
In the seller app's upload flow, render the preview **live** as the designer adjusts placement, so they see the result instantly. Use Flutter's canvas: draw the template image, then draw the print clipped to the print zone (a `ClipRect` + `Transform.scale`). For mugs use a `Mesh`/shader warp or fall back to the flat label zone. This preview is throwaway; the authoritative mockup is generated server-side (Strategy A) on publish.

### Display rules
- Catalog and product pages always show the **pre-rendered mockup** (Strategy A) — never composite on the client at browse time (too slow, drains battery).
- Product page lets the user switch product color → swap to that color's template mockup.
- Always show the print on a realistic blank, never the raw print file. The raw hi-res file is private.

### Why this split
The designer needs an instant live preview while placing art (B); customers need fast, cached images while browsing (A). Doing A on the client at scale would be slow and inconsistent; doing B on the server would feel laggy during placement.

---

## 7. App Logic & State Management

- **State**: Riverpod. Each feature has a `Notifier`/`AsyncNotifier` + an immutable state class. No business logic in widgets.
- **Routing**: go_router. Auth/onboarding guards via `redirect`. In Studio, the redirect blocks all dashboard routes unless `kyc_status == verified`.
- **Data access**: widgets → controllers → repositories (in core) → Supabase. Widgets never call Supabase directly.
- **Result type**: repositories return `Result<T>` (`Success(data)` / `Failure(message, code)`), so the UI maps failures to the copy in §11 without try/catch everywhere.
- **Cart**: client-side state synced to a `carts` table so it survives reinstall/login on another device.
- **Offline/empty/loading**: every list screen has three explicit states — loading (skeletons), empty (illustration + message), error (retry button). Never a blank screen.

---

## 8. Auth — Registration, Login, Phone OTP

Primary identity is **phone number** (UZ standard). Email optional.

### Screens (both apps share the auth feature via core, but each app has its own screens)
1. **Welcome / splash** — logo, "Log in" / "Register".
2. **Register** — full name, phone (+998 prefixed), optional email, password OR OTP-only. Recommended: OTP-only (passwordless) to reduce friction.
3. **Login** — phone input → request OTP.
4. **OTP confirmation** — 6-digit code, auto-advance boxes, resend timer (e.g. 60s), paste support.
5. **Profile completion** (first login) — name, preferred language, optional avatar.

### Phone OTP flow
```
User enters +998 XX XXX XX XX
  → app calls auth_service.requestOtp(phone)
  → Supabase / SMS provider sends 6-digit code
  → user enters code (6 boxes, auto-focus next)
  → auth_service.verifyOtp(phone, code)
    → success: session created, route to home (or profile completion)
    → failure: show error copy, allow retry
  → resend disabled for 60s with countdown, then "Resend code" enabled
```

### Input rules
- Phone field: mask `+998 (XX) XXX-XX-XX`, numeric keyboard, validate 9 digits after +998.
- OTP field: 6 single-digit boxes, numeric, auto-submit when full, support clipboard paste of the whole code.
- Loading state on every submit button (spinner, disabled) to prevent double-submit.

### Studio difference
After OTP, Studio routes the user into **onboarding** (§9), not the dashboard. The dashboard stays locked until verified.

---

## 9. Seller Onboarding (Studio) — KYC + Rules + E-signature

Strict gate. No dashboard access until `kyc_status = verified`.

### Steps
1. **Account basics** — name, phone (verified via OTP), email.
2. **KYC data** — legal name, ID/passport number, optional photo of ID, payout method (card/bank), tax note.
3. **Read regulations** — full rules shown, must scroll to bottom to enable "I agree". Rules include (at minimum): no 18+/sexual content, no religious content, no war/violence content, no copyrighted/trademarked work, designer owns all rights, indemnification, royalty & payout terms.
4. **E-signature** — draw signature on a canvas (or type full name as typed signature). Store signature image in private `signatures` bucket + record `contract_version`, `signed_at`, and the regulations text hash.
5. **Submit → pending** — "Your account is under review." Dashboard locked.
6. **Verified** — admin approves; push notification; dashboard unlocks.

### Storage of acceptance
Persist: `contract_version`, `contract_accepted_at`, signature file reference, and a hash of the exact regulations text the seller saw. This is what makes the agreement enforceable later.

---

## 10. UI Inventory — Inputs, Dropdowns, Tooltips, Buttons

Build these once as shared widgets (in each app's `features/.../widgets` or a small `ui/` folder per app; keep tokens in core theme).

### Text input
- Label above field, hint inside, helper/error text below.
- States: default, focused (accent border), error (red border + message), disabled (muted), success (subtle green check).
- Numeric/phone variants use the right keyboard.
- Always reserve space for the error line so layout doesn't jump.

### Dropdowns
- Used for: size (S–XXL), product color, language, royalty presets, category filter, sort order.
- Bottom-sheet style on mobile (easier to tap), with a search box if >8 options.
- Selected value shown with the accent; chevron rotates on open.
- Multi-select (categories) uses checkboxes + an "Apply" button.

### Tooltips
- Tap-to-show on mobile (not hover). Small, single-sentence, dismiss on tap-away.
- Use sparingly: royalty explanation, "why is my upload pending", base-cost breakdown.

### Buttons
- Primary (filled accent), Secondary (outline), Text (link), Destructive (red).
- All have: idle, pressed, loading (spinner, label hidden or "Please wait"), disabled states.
- Min tap target 48×48.

### Lists & cards
- Product card: mockup image, title, designer name, price, rating stars.
- Skeleton loaders while fetching.
- Pull-to-refresh on feeds.

---

## 11. Copy Library (also keep in `docs/COPY.md`, localized RU/UZ/EN)

Write all of these in RU, UZ, EN. English shown here as the reference.

### Error messages
| Context | Message |
|---|---|
| Network down | "No connection. Check your internet and try again." |
| Generic server | "Something went wrong. Please try again." |
| Wrong OTP | "That code isn't right. Check it and try again." |
| Expired OTP | "This code has expired. Request a new one." |
| Too many OTP requests | "Too many attempts. Please wait a moment before trying again." |
| Invalid phone | "Enter a valid phone number." |
| Required field | "This field is required." |
| Payment failed | "Payment didn't go through. No money was taken — please try again." |
| Out of royalty bounds | "Royalty must be between {min} and {max} UZS." |
| Upload too small | "This image is too small to print well. Use at least {w}×{h}px." |
| Upload wrong format | "Use a PNG or JPG file." |
| Upload rejected (moderation) | "This design wasn't approved. Reason: {reason}." |
| Below payout threshold | "You can withdraw once your balance reaches {min} UZS." |
| Cart item unavailable | "This item is no longer available and was removed from your cart." |
| Session expired | "You've been signed out. Please log in again." |
| Seller not verified | "Your seller account is still under review." |

### Success messages
| Context | Message |
|---|---|
| OTP sent | "Code sent. Check your messages." |
| Logged in | "Welcome back!" |
| Registered | "Account created." |
| Order placed | "Order placed! We're getting it ready." |
| Payment confirmed | "Payment received. Thank you!" |
| Review submitted | "Thanks for your review." |
| Design uploaded | "Uploaded! It's now in review." |
| Design approved | "Your design is live." |
| Withdrawal requested | "Withdrawal requested. We'll process it on the next payout." |
| Profile saved | "Saved." |
| Address added | "Address added." |

### Tooltips
| Where | Text |
|---|---|
| Royalty field | "Your earnings per item. We add this on top of the base cost." |
| Base cost | "Covers the blank product, printing, and packaging." |
| Pending status | "We review every design before it goes live — usually within a day." |
| Print zone | "Keep important details inside the dashed area." |
| Rating stars | "Tap to rate from 1 to 5." |

### Empty states
| Screen | Text |
|---|---|
| Empty cart | "Your cart is empty. Find something you love." |
| No orders | "No orders yet. Your future purchases show up here." |
| No designs (seller) | "No designs yet. Upload your first print to start earning." |
| No search results | "Nothing matched that. Try another word." |

---

## 12. Animations

Keep motion purposeful, fast (150–300ms), and respect reduced-motion settings.

### Success order animation
After payment confirmation: a full-screen overlay — a checkmark that draws itself (stroke animation), a short bounce/scale, optional confetti burst, then auto-dismiss to the order tracking screen after ~1.8s. Use a Lottie animation or a hand-built `AnimatedBuilder` checkmark. Copy underneath: "Order placed!" then the order number.

### Loaders
- Skeleton shimmer for lists and cards (not spinners) — feels faster.
- Button inline spinner on submit.
- Pull-to-refresh native indicator.

### Transitions
- Page transitions: subtle slide/fade via go_router's `CustomTransitionPage`.
- Add-to-cart: small "fly to cart" or a cart badge bump.
- Tab switches: instant; no heavy animation.

### Upload progress (seller)
- Determinate progress bar during print-file upload, then a "processing mockup" indeterminate state, then success.

Library suggestions: `lottie` for the success/empty illustrations, Flutter's built-in implicit animations for the rest. Don't over-animate; the prints are the show.

---

## 13. Optimizations

### Performance
- **Images**: use `cached_network_image`; serve appropriately sized mockups (thumbnail vs full); lazy-load lists with pagination.
- **Pre-render mockups server-side** (§6) so browsing is just image loads.
- **Const constructors** everywhere; avoid rebuilds with fine-grained Riverpod providers.
- **Paginate** catalog/orders/earnings (e.g. 20 per page) — never load all rows.
- **Debounce** search input (300ms).

### Cost / backend
- Cache mockups in the `mockups` bucket so you composite once, not per view.
- Use database indexes on `order_items.design_id`, `ledger.designer_id`, `listings.design_id`, `orders.customer_id`.
- Compute "top prints" / "best sellers" via a scheduled materialized view refreshed periodically, not a heavy query on every dashboard open.

### Build / maintainability
- Shared code in `artlavka_core` so logic is written once for both apps.
- `--dart-define` for secrets; never hardcode keys; `.env` git-ignored.
- Strict lints (`analysis_options.yaml`) shared across the workspace.
- Snapshot prices on order items so historical orders never change.

### Security
- Private print files; signed URLs only for production role.
- Server-side price + payment verification.
- RLS on every table.
- Store e-signature + regulations hash for enforceability.

---

## 14. Definition of Done / Build Order

Build in this order so each layer rests on a working one:

1. Workspace + `artlavka_core` (theme, models, `Result`, Supabase service).
2. Supabase schema + RLS + storage buckets (local first).
3. Auth (phone OTP) shared, then client login/register screens.
4. Catalog read path: categories → product list → product page with pre-rendered mockups.
5. Cart + `create-order` edge function + payment webhook (sandbox).
6. Orders tracking + success animation + reviews.
7. Studio onboarding gate (KYC + rules + e-signature + verification).
8. Studio upload flow (live preview + server mockup generation + moderation status).
9. Studio stats + earnings ledger + withdrawal.
10. Localization (RU/UZ/EN), empty/error states, polish, optimizations.

A feature is "done" only when it has: loading + empty + error states, localized copy, the relevant success/error messages wired from §11, and passes `melos run analyze` + tests.
