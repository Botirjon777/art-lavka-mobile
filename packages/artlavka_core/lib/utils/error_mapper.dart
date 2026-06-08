import 'dart:async';
import 'dart:io';

import '../services/api_client.dart';
import 'result.dart';

/// Maps thrown API/SDK errors to a stable [Failure] the UI can localize.
///
/// Repositories/services wrap their calls in [guard] so they never leak raw
/// exceptions across the boundary (SPEC §7 Result convention).
abstract final class ErrorMapper {
  /// Run [action], converting any throw into a typed [Failure].
  static Future<Result<T>> guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return toFailure<T>(error);
    }
  }

  /// Convert a caught [error] into a [Failure] with the right [FailureCode].
  static Failure<T> toFailure<T>(Object error) {
    final (message, code) = classify(error);
    return Failure<T>(message, code: code);
  }

  /// Returns a (debug message, [FailureCode]) pair for [error].
  static (String, String) classify(Object error) {
    if (error is ApiException) {
      // The API already returns a FailureCode-shaped code.
      return (error.message, error.code);
    }
    if (error is SocketException || error is TimeoutException) {
      return ('Network unavailable', FailureCode.network);
    }
    return (error.toString(), FailureCode.server);
  }
}
