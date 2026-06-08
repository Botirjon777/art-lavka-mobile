import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/core_providers.dart';

/// Entry point for ART-LAVKA Studio (seller app).
///
/// Initializes the shared core (REST API client) when configured and not in
/// mock-auth mode, then injects it via a Riverpod override. After login, the
/// router gates the dashboard until `kyc_status = verified` (SPEC §9).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ArtlavkaCore? core;
  if (Env.isConfigured && !Env.mockAuth) {
    try {
      core = await ArtlavkaCore.initialize();
    } catch (_) {
      core = null;
    }
  }

  runApp(
    ProviderScope(
      overrides: [if (core != null) coreProvider.overrideWithValue(core)],
      child: const ArtLavkaStudioApp(),
    ),
  );
}
