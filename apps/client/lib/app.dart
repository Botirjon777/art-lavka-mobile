import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/core_providers.dart';
import 'l10n/l10n.dart';
import 'router.dart';

/// Root of the customer app: themed, localized, router-driven.
class ArtLavkaClientApp extends ConsumerStatefulWidget {
  const ArtLavkaClientApp({super.key});

  @override
  ConsumerState<ArtLavkaClientApp> createState() => _ArtLavkaClientAppState();
}

class _ArtLavkaClientAppState extends ConsumerState<ArtLavkaClientApp> {
  @override
  void initState() {
    super.initState();
    // If a real backend session already exists, seed it so the router lands the
    // user on home/profile rather than welcome. No-op under mock auth.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = ref.read(authServiceProvider);
      if (!auth.isSignedIn) return;
      final user = (await auth.currentUser()).valueOrNull;
      if (user != null && mounted) {
        ref.read(appSessionProvider).setUser(user);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'ART-LAVKA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
