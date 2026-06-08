import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/core_providers.dart';
import 'l10n/l10n.dart';
import 'router.dart';

/// Root of ART-LAVKA Studio: themed, localized, router-driven with the KYC gate.
class ArtLavkaStudioApp extends ConsumerStatefulWidget {
  const ArtLavkaStudioApp({super.key});

  @override
  ConsumerState<ArtLavkaStudioApp> createState() => _ArtLavkaStudioAppState();
}

class _ArtLavkaStudioAppState extends ConsumerState<ArtLavkaStudioApp> {
  @override
  void initState() {
    super.initState();
    // Seed an existing backend session so the router lands on the right gate.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = ref.read(authServiceProvider);
      if (!auth.isSignedIn) return;
      final user = (await auth.currentUser()).valueOrNull;
      if (user == null || !mounted) return;
      final session = ref.read(appSessionProvider)..setUser(user);
      final profile = await ref.read(designerRepositoryProvider).myProfile();
      session.setProfile(profile.valueOrNull);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'ART-LAVKA Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }
}
