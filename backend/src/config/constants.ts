/**
 * Business constants — the server-side mirror of the Dart `AppConstants`.
 * Money values are `bigint` UZS. These are policy, not secrets.
 */
export const AppConstants = {
  // Money / payouts
  minPayoutUzs: 50_000n,
  royaltyMinUzs: 1_000n,
  royaltyMaxUzs: 500_000n,
  returnWindowDays: 14,

  // Auth / OTP
  otpLength: 6,
  otpTtlSeconds: 120,
  otpMaxAttempts: 5,
  otpResendSeconds: 60,

  // Uploads
  minPrintWidthPx: 2000,
  minPrintHeightPx: 2000,
  acceptedUploadMimeTypes: ['image/png', 'image/jpeg'],

  // Lists / paging
  pageSize: 20,
  signedUrlTtlSeconds: 300,

  // Localization
  supportedLanguageCodes: ['ru', 'uz', 'en'],
  defaultLanguageCode: 'ru',

  // Contract
  contractVersion: 'v1',
} as const;
