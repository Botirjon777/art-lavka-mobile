/// UZS money helpers.
///
/// Money in ART-LAVKA is ALWAYS an `int` of Uzbekistani so'm with no decimals
/// (see SPEC §5). This class only *formats* for display — it never rounds or
/// does arithmetic that could lose value. Do math on the raw `int`.
abstract final class Money {
  /// Non-breaking space (U+00A0) thousands separator, so a price never wraps
  /// mid-number. Written as an escape so the source stays pure ASCII.
  static const String groupSeparator = ' ';

  /// Default currency suffix shown to users.
  static const String suffix = "so'm";

  /// Group digits, e.g. `1234567` -> `1 234 567`.
  ///
  /// Negative amounts keep the sign in front.
  static String group(int amount) {
    final negative = amount < 0;
    final digits = amount.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(groupSeparator);
      buffer.write(digits[i]);
    }
    return negative ? '-${buffer.toString()}' : buffer.toString();
  }

  /// Format for display, e.g. `1234567` -> `1 234 567 so'm`.
  ///
  /// Pass [withSuffix] = false for places that render the currency separately.
  static String format(int amount, {bool withSuffix = true}) =>
      withSuffix ? '${group(amount)}$groupSeparator$suffix' : group(amount);
}
