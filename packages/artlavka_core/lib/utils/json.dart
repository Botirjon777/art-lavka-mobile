/// Small, defensive JSON helpers for model `fromJson` factories.
///
/// The API returns dynamic maps; these coerce values safely so a single
/// unexpected null doesn't crash a whole list parse.
abstract final class Json {
  /// Parse a [DateTime] from an ISO-8601 string; `null` if absent/unparseable.
  static DateTime? dateOrNull(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
    return null;
  }

  /// Parse a required [DateTime], falling back to epoch if missing.
  static DateTime date(Object? value) =>
      dateOrNull(value) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  /// Coerce to `int` (handles num and numeric strings). UZS money path.
  static int intValue(Object? value, {int fallback = 0}) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v) ?? fallback,
    _ => fallback,
  };

  /// Coerce to `int?`.
  static int? intOrNull(Object? value) =>
      value == null ? null : intValue(value);

  /// Coerce to `bool` (handles bool, 0/1, "true"/"false").
  static bool boolValue(Object? value, {bool fallback = false}) =>
      switch (value) {
        final bool v => v,
        final num v => v != 0,
        'true' || 't' || '1' => true,
        'false' || 'f' || '0' => false,
        _ => fallback,
      };

  /// Coerce to `String?` (trims; empty -> null).
  static String? stringOrNull(Object? value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }

  /// Resolve an enum by its [Enum.name], falling back when unknown/missing.
  static T enumByName<T extends Enum>(
    List<T> values,
    Object? name,
    T fallback,
  ) {
    final key = name?.toString();
    for (final v in values) {
      if (v.name == key) return v;
    }
    return fallback;
  }

  /// Cast a JSON list of maps, skipping malformed entries.
  static List<Map<String, dynamic>> listOfMaps(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList();
  }
}
