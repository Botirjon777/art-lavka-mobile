import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/core_providers.dart';

/// Entry point for the ART-LAVKA customer app.
///
/// Initializes the shared core (REST API client) when configured and not in mock-auth
/// mode, then injects it via a Riverpod override. Without config (or with
/// `MOCK_AUTH=true`) the app runs against the mock auth flow so the screens are
/// fully exercisable before a live SMS provider exists (SPEC §8).
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
      child: const ArtLavkaClientApp(),
    ),
  );
}
