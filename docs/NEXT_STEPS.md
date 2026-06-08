# ART-LAVKA — Next Steps (Steps 3–5)

> Picks up after the Foundation milestone (workspace, `artlavka_core`, backend-as-code) is complete and green.
> Covers Step 3 (Auth), Step 4 (Catalog read path), Step 5 (Cart + checkout).
> Each step lists scope, screens, states, copy hooks, and a definition of done.
> Keep this at `/docs/NEXT_STEPS.md`.

---

## Environment note (carry forward)

Flutter is at `C:\flutter` and not on PATH for the Bash tool. Use PowerShell with a PATH prefix for all Flutter/Dart commands. This is already saved to memory.

Run gate for every step: `melos run analyze`, `melos run test`, `melos run format` must all pass before a step is "done".

---

## STEP 3 — Client Auth (phone OTP)

**Goal:** a user can register and log in with a phone number + OTP, and land on a usable session. Nothing else in the client app works without this.

### Screens (in `apps/client/lib/features/auth/`)
1. **Welcome** — logo, "Log in" and "Register" buttons, language switcher (RU/UZ/EN).
2. **Register** — full name, phone (`+998 (XX) XXX-XX-XX` mask), optional email, language. Submit → request OTP.
3. **Login** — phone only → request OTP.
4. **OTP verification** — 6 single-digit boxes, auto-advance, paste support, auto-submit when full, resend countdown (60s).
5. **Profile completion** — shown only on first login (no `display name` yet): name, preferred language, optional avatar.

### Feature internals (per the spec's feature shape)
```
features/auth/
├── welcome_page.dart
├── register_page.dart
├── login_page.dart
├── otp_page.dart
├── profile_completion_page.dart
├── widgets/
│   ├── phone_field.dart          # +998 mask, numeric keyboard, validation
│   ├── otp_boxes.dart            # 6-box input, paste, auto-advance
│   └── resend_timer.dart         # 60s countdown → enabled "Resend"
├── auth_controller.dart          # Riverpod AsyncNotifier
└── auth_state.dart               # immutable: phase, phone, loading, error
```

### Logic
- All calls go through `auth_service` (already in core): `requestOtp(phone)`, `verifyOtp(phone, code)`.
- `auth_controller` holds the flow phase (`idle → otpSent → verifying → done`) and maps `Result.Failure` codes to §11 copy.
- go_router redirect: unauthenticated → welcome; authenticated but no profile → profile completion; otherwise → home.
- Guard against double-submit: button shows inline spinner + disables while in-flight.

### States & copy (wire from docs/COPY.md)
- Loading: button spinner on request/verify.
- Errors: invalid phone, wrong OTP, expired OTP, too many attempts, network down — all already written.
- Success: "Code sent. Check your messages." / "Welcome back!" / "Account created."

### Validation
- Phone: 9 digits after `+998`, reject anything else (use `Validators` from core).
- OTP: exactly 6 digits, numeric.

### Definition of done
Register and login both reach a session; first-time users complete a profile; resend timer works; all four states (idle/loading/error/success) wired; localized; analyze + test green.

**Heads-up before testing live:** Supabase needs a configured SMS provider that delivers to +998 numbers. Until that's set, test with Supabase's test OTP / a mock in `auth_service` behind an env flag so the screens are fully exercisable without live SMS.

---

## STEP 4 — Catalog Read Path

**Goal:** a logged-in user can browse home → categories → product list → product page, seeing pre-rendered mockups.

### Screens (in `apps/client/lib/features/`)
1. **home/** — banners carousel (from `banners` table), then feed sections: New, Top, Trending. Each section is a horizontal scroller of product cards.
2. **catalog/** — categories grid (gamers, memes, funny, anime…), a theme/category page (filtered product list), and search (debounced 300ms).
3. **product/** — product page: mockup viewer with color switch, size selector, price, designer name (tap → storefront), rating + reviews, "Add to cart".
4. **storefront/** — a designer's public page: their info + all their live listings.

### Data
- Use `catalog_repository` (core) — paginated (`AppConstants.pageSize`), returns `Result<List<...>>`.
- Product cards read from the `listing_cards` view (already built). Remember: `mockup_url` currently falls back to the design preview until §6 server mockups are wired — that's fine for now; the UI shouldn't care which it got.
- Reviews from `design_reviews` view.

### Rendering (per spec §6)
- Browse/product screens show the **pre-rendered mockup image** via `cached_network_image`. No client-side compositing at browse time.
- Color switch swaps to that color's mockup URL.
- Show skeleton shimmer while images/lists load.

### States
Every list/grid has three explicit states:
- Loading → skeleton cards.
- Empty → illustration + copy ("Nothing matched that. Try another word." / category empty).
- Error → message + Retry button.

### Definition of done
Home renders banners + 3 feeds; categories navigate to filtered lists; search works with debounce; product page shows mockup, switches color, lists reviews; storefront lists a designer's products; pagination + pull-to-refresh; all three states everywhere; localized; green.

---

## STEP 5 — Cart + Checkout

**Goal:** a user can build a cart, check out, pay (sandbox), and get an order with a success animation.

### Screens (in `apps/client/lib/features/cart/` and `orders/`)
1. **cart/** — line items (mockup, title, variant, qty, line price), edit qty, remove, subtotal, "Checkout".
2. **checkout/** — delivery address (saved addresses + add new), delivery method/fee, payment method (Click / Payme / Uzum), order summary, "Place order".
3. **order success** — full-screen success animation (drawn checkmark + bounce + optional confetti), order number, auto-route to tracking after ~1.8s.
4. **orders/** (tracking) — status timeline (paid → in production → printed → shipped → delivered), and on delivered, prompt to rate.

### Logic (trust the server — spec §5/§13)
- Cart synced to the `carts` table so it survives reinstall/device change.
- **Never** trust client price. On "Place order", call the `create-order` edge function — it recomputes `base_cost + royalty` from the current listing, snapshots prices onto `order_items`, creates the order, and returns a payment intent.
- Payment goes through `payment_service`; the `payment-webhook` edge function verifies the provider signature and marks the order `paid`. (Signature verification is currently stubbed with TODOs — needs real Click/Payme/Uzum credentials. Until then, run in sandbox/mock mode behind an env flag.)
- On `paid`, order enters the production queue; royalty is **not** accrued yet (that happens on delivery via `accrue-royalty`).

### States & copy
- Empty cart → "Your cart is empty. Find something you love."
- Payment failed → "Payment didn't go through. No money was taken — please try again."
- Item gone → "This item is no longer available and was removed from your cart."
- Success → "Order placed! We're getting it ready." + order number.

### Animation (spec §12)
Success overlay: self-drawing checkmark stroke, short scale bounce, optional confetti, auto-dismiss to tracking. Respect reduced-motion. Use `lottie` or a hand-built `AnimatedBuilder`.

### Definition of done
Cart persists; checkout collects address + method; `create-order` is the only price authority; sandbox payment marks order paid; success animation plays; tracking timeline reflects status; rating prompt on delivered; all states + copy; green.

---

## After Step 5 (preview of the rest, per spec §14)

6. Orders polish + reviews submission flow.
7. Studio onboarding gate (KYC + rules + e-signature + verification).
8. Studio upload flow (live client preview + server-rendered mockups — wires up §6 for real, removing the fallback).
9. Studio stats + earnings ledger + withdrawal.
10. Localization sweep, empty/error polish, optimizations (indexes, materialized views for top/best-sellers, image sizing).

---

## Cross-cutting reminders (apply to every step)

- Money is `int` UZS; format only for display.
- Widgets → controllers → repositories → Supabase. Widgets never touch Supabase directly.
- Every screen: loading + empty + error states, no blank screens.
- All user-facing strings localized RU/UZ/EN from `docs/COPY.md`.
- Secrets via `--dart-define`; nothing hardcoded.
- A step is done only when analyze + test + format are all green.

---

## Recommended order to give Claude

Do **Step 3 in full** first (auth is the unblocker), verify it runs against mock OTP, then move to Step 4. Don't start Step 5 until the catalog read path is solid, because checkout depends on real listings and prices flowing through. Build each screen with its three states from the start — retrofitting empty/error states later is the most common source of rework.
