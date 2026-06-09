import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/widgets.dart';

import '../l10n/l10n.dart';

/// Thrown by [ResultX.unwrap] so providers surface a repository [Failure] as an
/// `AsyncError` while keeping its [FailureCode].
class FailureException implements Exception {
  FailureException(this.message, {this.code});
  final String message;
  final String? code;
}

extension ResultX<T> on Result<T> {
  T unwrap() => switch (this) {
    Success<T>(:final data) => data,
    Failure<T>(:final message, :final code) => throw FailureException(
      message,
      code: code,
    ),
  };
}

String failureMessage(BuildContext context, Object error) {
  if (error is FailureException) {
    return localizedFailure(context.l10n, error.code);
  }
  return context.l10n.errServer;
}
