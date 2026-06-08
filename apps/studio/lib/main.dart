import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'bootstrap/core_providers.dart';

/// Entry point for ART-LAVKA Studio (seller app).
///
/// Same bootstrap as the client: initialize the shared core when configured and
/// inject it via a Riverpod override. After auth, Studio routes into onboarding
/// and keeps the dashboard locked until `kyc_status = verified` (SPEC §9).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ArtlavkaCore? core;
  Object? initError;
  if (Env.isConfigured) {
    try {
      core = await ArtlavkaCore.initialize();
    } catch (error) {
      initError = error;
    }
  }

  runApp(
    ProviderScope(
      overrides: [if (core != null) coreProvider.overrideWithValue(core)],
      child: ArtLavkaStudioApp(initError: initError),
    ),
  );
}
