/// Runtime configuration injected at build time via `--dart-define`.
///
/// Never hardcode secrets (SPEC §13). After the REST migration the apps point at
/// the NestJS API:
///
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://api.artlavka.uz
/// ```
abstract final class Env {
  /// Base URL of the ART-LAVKA REST API (no trailing slash).
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Dev flag: use a mock auth flow (fixed OTP) instead of the real API, so the
  /// auth screens are exercisable offline. Pass `--dart-define=MOCK_AUTH=true`.
  static const bool mockAuth = bool.fromEnvironment('MOCK_AUTH');

  /// `true` when the API base URL is present.
  static bool get isConfigured => apiBaseUrl.isNotEmpty;

  /// Throws [StateError] if the API base URL is missing. Call in `main()`.
  static void assertConfigured() {
    if (apiBaseUrl.isEmpty) {
      throw StateError(
        'Missing --dart-define=API_BASE_URL. See README "Run" section.',
      );
    }
  }
}
