import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The wired [ArtlavkaCore]. Overridden in `main()` once the REST API client
/// is initialized.
final coreProvider = Provider<ArtlavkaCore>(
  (ref) => throw StateError(
    'coreProvider was read before main() overrode it. '
    'Ensure the build has --dart-define=API_BASE_URL=...',
  ),
);

// Narrow slices used by Studio controllers.
final authServiceProvider = Provider<AuthService>(
  (ref) => ref.watch(coreProvider).auth,
);
final designRepositoryProvider = Provider<DesignRepository>(
  (ref) => ref.watch(coreProvider).designs,
);
final earningsRepositoryProvider = Provider<EarningsRepository>(
  (ref) => ref.watch(coreProvider).earnings,
);
final payoutRepositoryProvider = Provider<PayoutRepository>(
  (ref) => ref.watch(coreProvider).payouts,
);
final storageServiceProvider = Provider<StorageService>(
  (ref) => ref.watch(coreProvider).storage,
);
