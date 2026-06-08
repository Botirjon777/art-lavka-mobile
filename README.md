# ART-LAVKA

Print-on-demand marketplace for Uzbekistan. Designers upload prints; customers
order products (t-shirts, hoodies, caps, cups) carrying them; ART-LAVKA prints,
fulfils, and delivers. Each sale pays the designer a royalty and keeps a margin.

Two Flutter apps share one core package and one backend:

- **`apps/client`** — ART-LAVKA (customer): browse, order, pay, track, rate.
- **`apps/studio`** — ART-LAVKA Studio (seller): onboard, upload, stats, withdraw.
- **`packages/artlavka_core`** — shared models, services, repositories, theme,
  utils. **No screen widgets.**
- **`backend/`** — NestJS + Prisma REST API (replacing Supabase).

> **Backend migration in progress.** We are moving from Supabase to a NestJS
> REST backend the team maintains directly — see [`docs/BACKEND_NODE.md`](docs/BACKEND_NODE.md)
> (the new source of truth) and its §8 migration plan. The `supabase/` folder
> stays until REST parity is verified, then it's removed. The Flutter side is
> unaffected during the build: widgets → controllers → repositories means only
> the repositories' internals change (Supabase calls → REST) at swap time.

> Full design & decisions: [`docs/SPEC.md`](docs/SPEC.md).
> Copy: [`docs/COPY.md`](docs/COPY.md) · Next steps: [`docs/NEXT_STEPS.md`](docs/NEXT_STEPS.md).

## Prerequisites
- Flutter SDK (stable) + Dart (bundled)
- Node.js 20+ (backend runtime + tooling)
- PostgreSQL (the backend database)
- Melos is a workspace dev-dependency (run via `dart run melos …`); no global install needed.

## Workspace layout
The Flutter side is a Dart **pub workspace** (`workspace:` in the root
`pubspec.yaml`) managed with **melos**. One `flutter pub get` at the root
resolves all three Dart packages. `backend/` is a separate Node project (not part
of the pub workspace).

```
artlavka/
├── apps/client          · customer app (Flutter)
├── apps/studio          · seller app (Flutter)
├── packages/artlavka_core
├── backend/             · NestJS + Prisma REST API
├── supabase/            · legacy Supabase (removed after REST parity)
└── docs/                · SPEC, BACKEND_NODE, COPY, NEXT_STEPS
```

The backend has its own setup and gates — see [`backend/README.md`](backend/README.md).

## Setup (zero to running)
```bash
# 1. Resolve the Flutter workspace
flutter pub get

# 2. Backend (see backend/README.md for full setup)
cd backend
npm install
cp .env.example .env          # fill DATABASE_URL + JWT secrets
npm run prisma:generate
npm run prisma:migrate         # needs a running Postgres
npm run db:seed
npm run start:dev              # http://localhost:3000

# 3. Run an app, pointing it at the API
cd ../apps/client
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000   # Android emulator → host
```
The apps run without `API_BASE_URL` too — auth falls back to a mock flow (OTP
`123456`) so you can develop UI before the backend is up.

## Environment variables
**Flutter apps** (via `--dart-define`):
| Name | Notes |
|---|---|
| `API_BASE_URL` | Base URL of the NestJS API (no trailing slash) |
| `MOCK_AUTH` | `true` forces the offline mock auth flow |

**Backend** (`.env`): `DATABASE_URL`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`,
`MOCK_SMS`, `PAYMENTS_SANDBOX`, `S3_*` — see [`backend/.env.example`](backend/.env.example).

## Workspace commands (melos)
```bash
dart run melos analyze   # flutter analyze every package
dart run melos test      # run all package tests
dart run melos format    # dart format (fails if unformatted)
dart run melos build_client
dart run melos build_studio
```

## Conventions
- Money is **always `int` UZS** (no decimals). Format only for display.
- Repositories return `Result<T>` (`Success`/`Failure`) — UI maps failure codes
  to localized copy. No raw exceptions cross the repo boundary.
- Prices/payments/royalties are computed and verified **server-side**.
- Branch per feature; PRs target `main`; keep `docs/SPEC.md` updated as decisions change.
