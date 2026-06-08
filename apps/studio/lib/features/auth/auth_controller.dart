import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/app_session.dart';
import '../../bootstrap/core_providers.dart';

enum AuthPhase { idle, codeSent }

@immutable
class AuthState {
  const AuthState({
    this.phase = AuthPhase.idle,
    this.phone = '',
    this.submitting = false,
    this.errorCode,
  });

  final AuthPhase phase;
  final String phone;
  final bool submitting;
  final String? errorCode;

  AuthState copyWith({
    AuthPhase? phase,
    String? phone,
    bool? submitting,
    Object? errorCode = _sentinel,
  }) => AuthState(
    phase: phase ?? this.phase,
    phone: phone ?? this.phone,
    submitting: submitting ?? this.submitting,
    errorCode: errorCode == _sentinel ? this.errorCode : errorCode as String?,
  );

  static const Object _sentinel = Object();
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Studio phone-OTP login. On success, loads the designer profile so the router
/// gate can decide: onboarding vs pending vs dashboard (SPEC §9).
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthService get _auth => ref.read(authServiceProvider);
  AppSession get _session => ref.read(appSessionProvider);

  void clearError() {
    if (state.errorCode != null) state = state.copyWith(errorCode: null);
  }

  Future<bool> requestOtp(String phone) async {
    if (state.submitting) return false;
    state = state.copyWith(submitting: true, errorCode: null);
    final result = await _auth.requestOtp(phone);
    return result.fold(
      (_) {
        state = state.copyWith(
          submitting: false,
          phase: AuthPhase.codeSent,
          phone: Validators.normalizePhone(phone),
        );
        return true;
      },
      (failure) {
        state = state.copyWith(submitting: false, errorCode: failure.code);
        return false;
      },
    );
  }

  Future<bool> resend() => requestOtp(state.phone);

  Future<bool> verify(String code) async {
    if (state.submitting) return false;
    state = state.copyWith(submitting: true, errorCode: null);
    final result = await _auth.verifyOtp(phone: state.phone, code: code);
    switch (result) {
      case Success(:final data):
        _session.setUser(data);
        final profile = await ref.read(designerRepositoryProvider).myProfile();
        _session.setProfile(profile.valueOrNull);
        state = state.copyWith(submitting: false);
        return true;
      case Failure(code: final failCode):
        state = state.copyWith(submitting: false, errorCode: failCode);
        return false;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _session.clear();
    state = const AuthState();
  }
}
