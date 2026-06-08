# artlavka_core

Shared core for both ART-LAVKA apps. Holds **all** shared logic and **no Flutter
screen widgets** (only theme tokens depend on Flutter), so it stays testable and
reusable. SPEC §4.

## What's inside
- **`config/`** — `Env` (reads `--dart-define`), `AppConstants` (royalty bounds,
  payout minimum, page size, …).
- **`models/`** — immutable data classes with `fromJson`/`toJson`/`copyWith`.
- **`services/`** — `ApiClient` (Dio + JWT attach/refresh interceptor, error →
  `ApiException`), `TokenStore` (secure JWT storage), `AuthService` (phone OTP),
  `StorageService` (presigned uploads + signed print-file URL), `PaymentService`
  (`POST /orders`), `NotificationService`.
- **`repositories/`** — catalog, order, design, earnings, payout. Each returns
  `Result<T>`.
- **`theme/`** — `AppColors`, `AppTypography`, `AppTheme` (warm off-white, one accent).
- **`utils/`** — `Result<T>`, `Money` (UZS), `Validators`, `Json`, `ErrorMapper`.
- **`core.dart`** — `ArtlavkaCore`, the composition root the apps wire into Riverpod.

## Conventions
- **Money is always `int` UZS.** Never float. `Money.format(...)` is display-only.
- **`Result<T>`** everywhere a call can fail: `Success(data)` or
  `Failure(message, code:)`. `code` is a stable `FailureCode` the UI localizes
  (see `docs/COPY.md`). Services wrap calls in `ErrorMapper.guard`.
- **No widgets.** UI lives in the apps; this package must stay Flutter-light.

## Barrel
```dart
import 'package:artlavka_core/artlavka_core.dart';
```

## Test
```bash
flutter test    # or: dart run melos test
```
