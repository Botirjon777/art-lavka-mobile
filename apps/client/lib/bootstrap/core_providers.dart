import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_session.dart';
import 'mock_auth_service.dart';

/// The wired [ArtlavkaCore], or `null` when the build has no backend config.
/// Overridden in `main()` once the REST API client is initialized.
final coreProvider = Provider<ArtlavkaCore?>((ref) => null);

/// The active [AuthService]: the real REST one when configured, otherwise a
/// [MockAuthService] (also forced by `--dart-define=MOCK_AUTH=true`).
final authServiceProvider = Provider<AuthService>((ref) {
  final core = ref.watch(coreProvider);
  if (core == null || Env.mockAuth) return MockAuthService();
  return core.auth;
});

/// App-wide session (auth state) used by the router and screens.
final appSessionProvider = Provider<AppSession>((ref) {
  final session = AppSession();
  ref.onDispose(session.dispose);
  return session;
});

/// Current UI locale. Defaults to RU (SPEC §1); the language switcher updates it.
final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => const Locale('ru');

  void setLanguage(String code) => state = Locale(code);
}

// --- Repositories (require a configured backend; used from Step 4 onward) ----
ArtlavkaCore _requireCore(Ref ref) {
  final core = ref.watch(coreProvider);
  if (core == null) {
    throw StateError(
      'This feature needs a configured backend. Run with '
      '--dart-define=API_BASE_URL=...',
    );
  }
  return core;
}

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => _requireCore(ref).catalog,
);
final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => _requireCore(ref).orders,
);
final paymentServiceProvider = Provider<PaymentService>(
  (ref) => _requireCore(ref).payments,
);
