import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_session.dart';
import 'mock_auth_service.dart';
import 'mock_designer_repository.dart';

/// The wired [ArtlavkaCore], or `null` when the build has no backend config.
final coreProvider = Provider<ArtlavkaCore?>((ref) => null);

/// Real Supabase-less REST auth when configured; mock otherwise (or MOCK_AUTH).
final authServiceProvider = Provider<AuthService>((ref) {
  final core = ref.watch(coreProvider);
  if (core == null || Env.mockAuth) return MockAuthService();
  return core.auth;
});

/// Designer onboarding/profile repository (real or mock).
final designerRepositoryProvider = Provider<DesignerRepository>((ref) {
  final core = ref.watch(coreProvider);
  if (core == null || Env.mockAuth) return MockDesignerRepository();
  return core.designer;
});

// --- Dashboard repositories (require a configured backend) ----------------
ArtlavkaCore _requireCore(Ref ref) {
  final core = ref.watch(coreProvider);
  if (core == null) {
    throw StateError('This feature needs --dart-define=API_BASE_URL=...');
  }
  return core;
}

final designRepositoryProvider = Provider<DesignRepository>(
  (ref) => _requireCore(ref).designs,
);
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => _requireCore(ref).catalog,
);
final earningsRepositoryProvider = Provider<EarningsRepository>(
  (ref) => _requireCore(ref).earnings,
);
final payoutRepositoryProvider = Provider<PayoutRepository>(
  (ref) => _requireCore(ref).payouts,
);

/// App-wide session (auth + KYC profile) the router watches.
final appSessionProvider = Provider<AppSession>((ref) {
  final session = AppSession();
  ref.onDispose(session.dispose);
  return session;
});

/// Current UI locale (default RU).
final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => const Locale('ru');

  void setLanguage(String code) => state = Locale(code);
}
