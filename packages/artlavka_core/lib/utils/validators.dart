import '../config/constants.dart';
import 'result.dart';

/// Pure input validators.
///
/// Each returns `null` when valid, or a [FailureCode] string when invalid, so
/// the UI can resolve the localized message (see `docs/COPY.md`). Validators
/// never contain user-facing English text — that lives in the app's l10n.
abstract final class Validators {
  /// Matches a UZ phone in E.164 form: `+998` followed by exactly 9 digits.
  static final RegExp _uzPhone = RegExp(r'^\+998\d{9}$');

  /// Strip everything except digits and a single leading `+`.
  static String normalizePhone(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+')) {
      return '+${cleaned.substring(1).replaceAll('+', '')}';
    }
    // Bare `998...` or local `9-digit` -> assume UZ.
    final digits = cleaned.replaceAll('+', '');
    if (digits.startsWith('998')) return '+$digits';
    if (digits.length == 9) return '+998$digits';
    return '+$digits';
  }

  /// `null` if [phone] is a valid UZ number, else [FailureCode.invalidPhone].
  static String? phone(String? phone) {
    final value = (phone ?? '').trim();
    if (value.isEmpty) return FailureCode.invalidPhone;
    return _uzPhone.hasMatch(normalizePhone(value))
        ? null
        : FailureCode.invalidPhone;
  }

  /// `null` if non-empty after trimming, else [FailureCode.validation].
  static String? required(String? value) =>
      (value ?? '').trim().isEmpty ? FailureCode.validation : null;

  /// `null` if [code] is exactly [AppConstants.otpLength] digits.
  static String? otp(String? code) {
    final value = (code ?? '').trim();
    final ok =
        value.length == AppConstants.otpLength &&
        RegExp(r'^\d+$').hasMatch(value);
    return ok ? null : FailureCode.otpWrong;
  }

  /// `null` if [amount] is within the inclusive royalty bounds.
  static String? royalty(int amount) =>
      (amount >= AppConstants.royaltyMinUzs &&
          amount <= AppConstants.royaltyMaxUzs)
      ? null
      : FailureCode.royaltyOutOfBounds;

  /// `null` if the image is at least the minimum printable size.
  static String? printDimensions(int widthPx, int heightPx) =>
      (widthPx >= AppConstants.minPrintWidthPx &&
          heightPx >= AppConstants.minPrintHeightPx)
      ? null
      : FailureCode.uploadTooSmall;

  /// `null` if [contentType] is an accepted print upload format.
  static String? uploadFormat(String contentType) =>
      AppConstants.acceptedUploadMimeTypes.contains(contentType.toLowerCase())
      ? null
      : FailureCode.uploadWrongFormat;
}
