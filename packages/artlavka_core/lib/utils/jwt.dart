import 'dart:convert';

/// Minimal JWT reader (no signature check — the server verifies; the client only
/// reads claims like `sub` for the current user id).
abstract final class Jwt {
  /// The `sub` (subject / user id) claim, or `null` if absent/malformed.
  static String? subject(String? token) {
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final map = json.decode(payload);
      return map is Map<String, dynamic> ? map['sub'] as String? : null;
    } catch (_) {
      return null;
    }
  }
}
