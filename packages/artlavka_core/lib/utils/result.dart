import 'package:meta/meta.dart';

/// The single return type for every repository call.
///
/// Repositories never throw across their boundary — they return a [Result] so
/// the UI can map a [Failure] straight to localized copy (see `docs/COPY.md`)
/// without `try/catch` scattered through widgets.
@immutable
sealed class Result<T> {
  const Result();

  /// `true` when this is a [Success].
  bool get isSuccess => this is Success<T>;

  /// `true` when this is a [Failure].
  bool get isFailure => this is Failure<T>;

  /// The value if [Success], otherwise `null`.
  T? get valueOrNull => switch (this) {
    Success<T>(:final data) => data,
    Failure<T>() => null,
  };

  /// Collapse both branches into a single value.
  R fold<R>(
    R Function(T data) onSuccess,
    R Function(Failure<T> failure) onFailure,
  ) => switch (this) {
    Success<T>(:final data) => onSuccess(data),
    final Failure<T> f => onFailure(f),
  };

  /// Transform the success value, preserving a [Failure] unchanged.
  Result<R> map<R>(R Function(T data) transform) => switch (this) {
    Success<T>(:final data) => Success(transform(data)),
    Failure<T>(:final message, :final code) => Failure(message, code: code),
  };
}

/// A successful result carrying [data].
@immutable
final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;

  @override
  bool operator ==(Object other) => other is Success<T> && other.data == data;

  @override
  int get hashCode => data.hashCode;
}

/// A failed result.
///
/// [message] is a stable, machine-meaningful description (English reference);
/// the UI keys off [code] (a [FailureCode]) to pick the localized message.
@immutable
final class Failure<T> extends Result<T> {
  const Failure(this.message, {this.code});
  final String message;
  final String? code;

  /// Re-type a failure to a different generic without losing its payload.
  Failure<R> cast<R>() => Failure<R>(message, code: code);

  @override
  bool operator ==(Object other) =>
      other is Failure<T> && other.message == message && other.code == code;

  @override
  int get hashCode => Object.hash(message, code);
}

/// Stable failure codes the UI maps to localized copy.
///
/// These are intentionally not human text — see `docs/COPY.md` for the RU/UZ/EN
/// strings each one resolves to.
abstract final class FailureCode {
  static const network = 'network';
  static const server = 'server';
  static const unauthorized = 'unauthorized';
  static const sessionExpired = 'session_expired';
  static const otpWrong = 'otp_wrong';
  static const otpExpired = 'otp_expired';
  static const otpThrottled = 'otp_throttled';
  static const invalidPhone = 'invalid_phone';
  static const validation = 'validation';
  static const paymentFailed = 'payment_failed';
  static const royaltyOutOfBounds = 'royalty_out_of_bounds';
  static const uploadTooSmall = 'upload_too_small';
  static const uploadWrongFormat = 'upload_wrong_format';
  static const uploadRejected = 'upload_rejected';
  static const belowPayoutThreshold = 'below_payout_threshold';
  static const cartItemUnavailable = 'cart_item_unavailable';
  static const sellerNotVerified = 'seller_not_verified';
  static const notFound = 'not_found';
}
