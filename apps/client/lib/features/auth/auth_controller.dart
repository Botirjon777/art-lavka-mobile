import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/app_session.dart';
import '../../bootstrap/core_providers.dart';
import 'auth_state.dart';

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

/// Drives the phone-OTP flow (SPEC §8). Widgets call these; they never touch
/// the service directly. Maps `Result.Failure` codes into [AuthState.errorCode]
/// for the UI to localize.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthService get _auth => ref.read(authServiceProvider);
  AppSession get _session => ref.read(appSessionProvider);

  void clearError() {
    if (state.errorCode != null) state = state.copyWith(errorCode: null);
  }

  /// Begin login: just a phone number.
  Future<bool> startLogin({required String phone}) =>
      _requestCode(phone: phone);

  /// Begin registration: capture name/email/language, then request a code.
  Future<bool> startRegister({
    required String fullName,
    required String phone,
    String? email,
    required String languageCode,
  }) {
    final trimmedEmail = email?.trim();
    state = state.copyWith(
      pendingFullName: fullName.trim(),
      pendingEmail: (trimmedEmail == null || trimmedEmail.isEmpty)
          ? null
          : trimmedEmail,
      languageCode: languageCode,
    );
    return _requestCode(phone: phone);
  }

  /// Re-send the code to the same phone.
  Future<bool> resend() => _requestCode(phone: state.phone);

  Future<bool> _requestCode({required String phone}) async {
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

  /// Verify the entered code. On success, sets the session; if the user gave a
  /// name at register, the profile is completed in the same step so they skip
  /// the profile-completion screen.
  Future<bool> verify(String code) async {
    if (state.submitting) return false;
    state = state.copyWith(submitting: true, errorCode: null);
    final result = await _auth.verifyOtp(phone: state.phone, code: code);
    switch (result) {
      case Success(:final data):
        var finalUser = data;
        final name = state.pendingFullName;
        if (name != null && name.isNotEmpty) {
          final completed = await _auth.completeProfile(
            fullName: name,
            languageCode: state.languageCode,
            email: state.pendingEmail,
          );
          finalUser = completed.valueOrNull ?? data;
        }
        state = state.copyWith(submitting: false);
        _session.setUser(finalUser);
        return true;
      case Failure(code: final failCode):
        state = state.copyWith(submitting: false, errorCode: failCode);
        return false;
    }
  }

  /// Save the first-login profile (login users who had no name).
  Future<bool> submitProfile({
    required String fullName,
    required String languageCode,
    String? email,
    String? avatarUrl,
  }) async {
    if (state.submitting) return false;
    state = state.copyWith(submitting: true, errorCode: null);
    final result = await _auth.completeProfile(
      fullName: fullName,
      languageCode: languageCode,
      email: email,
      avatarUrl: avatarUrl,
    );
    return result.fold(
      (user) {
        state = state.copyWith(submitting: false);
        _session.setUser(user);
        return true;
      },
      (failure) {
        state = state.copyWith(submitting: false, errorCode: failure.code);
        return false;
      },
    );
  }

  /// Sign out and reset the flow.
  Future<void> signOut() async {
    await _auth.signOut();
    _session.clear();
    state = const AuthState();
  }
}
