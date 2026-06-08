/// Business constants shared by both apps.
///
/// These are policy values, not secrets — secrets come from [Env] via
/// `--dart-define`. Keep money values as `int` UZS (SPEC §5).
abstract final class AppConstants {
  // --- Money / payouts -------------------------------------------------------

  /// Minimum balance (UZS) before a designer may request a payout.
  static const int minPayoutUzs = 50000;

  /// Inclusive royalty bounds a designer may set per item (UZS).
  static const int royaltyMinUzs = 1000;
  static const int royaltyMaxUzs = 500000;

  /// Days after delivery before royalties accrue (return window).
  static const int returnWindowDays = 14;

  // --- Auth / OTP ------------------------------------------------------------

  /// Number of digits in the SMS OTP.
  static const int otpLength = 6;

  /// Seconds the "Resend code" button stays disabled.
  static const int otpResendSeconds = 60;

  // --- Uploads ---------------------------------------------------------------

  /// Minimum print-ready artwork dimensions (px) for acceptable quality.
  static const int minPrintWidthPx = 2000;
  static const int minPrintHeightPx = 2000;

  /// Accepted MIME types for print uploads.
  static const Set<String> acceptedUploadMimeTypes = {
    'image/png',
    'image/jpeg',
  };

  // --- Lists / UX ------------------------------------------------------------

  /// Default page size for paginated catalog/orders/earnings queries.
  static const int pageSize = 20;

  /// Debounce for search input, milliseconds.
  static const int searchDebounceMs = 300;

  /// Signed-URL lifetime (seconds) for private print files.
  static const int signedUrlTtlSeconds = 300;

  // --- Localization ----------------------------------------------------------

  /// Supported app languages (BCP-47 codes).
  static const List<String> supportedLanguageCodes = ['ru', 'uz', 'en'];

  /// Default language for new users.
  static const String defaultLanguageCode = 'ru';

  // --- Contract / onboarding -------------------------------------------------

  /// Version of the seller regulations currently in force. Bump when the text
  /// changes so historical signatures stay tied to the text they accepted.
  static const String contractVersion = 'v1';
}
