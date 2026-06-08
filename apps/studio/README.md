# artlavka_studio

ART-LAVKA Studio — seller app: onboard, upload prints, set royalties, view
stats, withdraw.

## Feature folders (SPEC §2)
`splash · onboarding · home · uploads · stats · earnings · profile` — each with
`*_page.dart`, `widgets/`, `*_controller.dart`, `*_state.dart`.

## The onboarding gate (SPEC §9)
**No dashboard access until `kyc_status = verified`.** After phone-OTP auth,
Studio routes into onboarding (KYC → read regulations → e-signature → pending).
The go_router `redirect` blocks every dashboard route until the profile is
verified; an admin approval flips the gate and sends a push.

> Current status: foundation shell. The onboarding flow + gate land in SPEC §14
> step 7.

## State & data
- **Riverpod**; widgets → controllers → `artlavka_core` repositories.
- `coreProvider` (in `lib/bootstrap/`) is overridden in `main()`.

## Core services consumed
`AuthService`, `DesignRepository`, `EarningsRepository`, `PayoutRepository`,
`StorageService` (print uploads + signatures).

## Run
```bash
flutter run \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```
