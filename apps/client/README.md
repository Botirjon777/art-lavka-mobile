# artlavka_client

ART-LAVKA customer app: browse, order, pay, track, rate.

## Feature folders (SPEC §2)
`splash · auth · home · catalog · product · storefront · cart · orders · profile`
— each follows the same shape: `*_page.dart`, `widgets/`, `*_controller.dart`
(Riverpod notifier), `*_state.dart` (immutable state).

> Current status: **Step 3 done** — phone-OTP auth (welcome · register · login ·
> OTP · profile completion) with the router gate. Catalog (Step 4) lands next
> (see `docs/NEXT_STEPS.md`).

## State & data
- **Riverpod** for state; widgets → controllers → `artlavka_core` repositories.
- `coreProvider` (in `lib/bootstrap/`) holds the wired `ArtlavkaCore` or `null`
  (no backend config). Widgets never touch Supabase directly.
- `appSessionProvider` (a `ChangeNotifier`) is the auth state the router watches;
  `authControllerProvider` drives the OTP flow.

## Routing
`lib/router.dart` (go_router) guards: signed-out → auth routes only; signed-in
without a display name → forced to `/profile`; otherwise → `/home`.

## Localization (RU/UZ/EN)
Strings live in `lib/l10n/*.arb`; `flutter gen-l10n` outputs `AppLocalizations`
into `lib/l10n/gen/` (git-ignored, regenerated). Use `context.l10n` and
`localizedFailure(...)` (in `lib/l10n/l10n.dart`). The language switcher updates
`localeProvider`. Re-run `flutter gen-l10n` after editing an `.arb`.

## Core services consumed
`AuthService`, `CatalogRepository`, `OrderRepository`, `PaymentService`,
`StorageService`.

## Backend
Talks to the NestJS REST API (`backend/`) via `artlavka_core`'s `ApiClient`
(Dio). JWT access/refresh tokens are stored in `flutter_secure_storage`; the
client refreshes on 401. Error responses (`{ error: { code, message } }`) map to
`Result.Failure` codes → localized copy.

## Run
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000   # Android emulator → host
```
- Runs without the define too — auth falls back to a **mock** flow so every
  screen is exercisable offline. Force the mock even when configured with
  `--dart-define=MOCK_AUTH=true`. Mock OTP code: **123456**.
- Live SMS needs the backend's SMS provider (Eskiz/Play Mobile) for +998; until
  then run the backend with `MOCK_SMS=true` (it logs the code).
