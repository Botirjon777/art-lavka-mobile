import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/foundation.dart';

/// Where the flow is: collecting a phone (`idle`) or waiting on the code (`codeSent`).
enum AuthPhase { idle, codeSent }

/// Immutable state for the auth flow (SPEC §8). No logic — see [AuthController].
@immutable
class AuthState {
  const AuthState({
    this.phase = AuthPhase.idle,
    this.phone = '',
    this.submitting = false,
    this.errorCode,
    this.pendingFullName,
    this.pendingEmail,
    this.languageCode = AppConstants.defaultLanguageCode,
  });

  /// Current step.
  final AuthPhase phase;

  /// E.164 phone the code was sent to.
  final String phone;

  /// A request/verify call is in flight — disable submit, show spinner.
  final bool submitting;

  /// Last failure ([FailureCode]); UI localizes it. Null when clean.
  final String? errorCode;

  // Captured at register so we can finish the profile right after verify.
  final String? pendingFullName;
  final String? pendingEmail;
  final String languageCode;

  AuthState copyWith({
    AuthPhase? phase,
    String? phone,
    bool? submitting,
    String? languageCode,
    Object? errorCode = _sentinel,
    Object? pendingFullName = _sentinel,
    Object? pendingEmail = _sentinel,
  }) => AuthState(
    phase: phase ?? this.phase,
    phone: phone ?? this.phone,
    submitting: submitting ?? this.submitting,
    languageCode: languageCode ?? this.languageCode,
    errorCode: errorCode == _sentinel ? this.errorCode : errorCode as String?,
    pendingFullName: pendingFullName == _sentinel
        ? this.pendingFullName
        : pendingFullName as String?,
    pendingEmail: pendingEmail == _sentinel
        ? this.pendingEmail
        : pendingEmail as String?,
  );

  static const Object _sentinel = Object();
}
