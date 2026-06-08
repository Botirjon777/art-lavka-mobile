/**
 * Stable error codes returned in `{ error: { code, message } }`.
 *
 * These mirror the Dart `FailureCode` enum in `artlavka_core` 1:1 (same string
 * values) so the Flutter `ErrorMapper` resolves the localized copy in
 * `docs/COPY.md` unchanged after the REST swap (BACKEND_NODE.md §6).
 */
export const ErrorCode = {
  network: 'network',
  server: 'server',
  unauthorized: 'unauthorized',
  sessionExpired: 'session_expired',
  otpWrong: 'otp_wrong',
  otpExpired: 'otp_expired',
  otpThrottled: 'otp_throttled',
  invalidPhone: 'invalid_phone',
  validation: 'validation',
  paymentFailed: 'payment_failed',
  royaltyOutOfBounds: 'royalty_out_of_bounds',
  uploadTooSmall: 'upload_too_small',
  uploadWrongFormat: 'upload_wrong_format',
  uploadRejected: 'upload_rejected',
  belowPayoutThreshold: 'below_payout_threshold',
  cartItemUnavailable: 'cart_item_unavailable',
  sellerNotVerified: 'seller_not_verified',
  notFound: 'not_found',
} as const;

export type ErrorCode = (typeof ErrorCode)[keyof typeof ErrorCode];
