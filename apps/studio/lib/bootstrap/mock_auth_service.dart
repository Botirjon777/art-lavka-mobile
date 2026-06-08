import 'package:artlavka_core/artlavka_core.dart';

/// In-memory [AuthService] for development/tests (OTP `123456`), active when the
/// backend isn't configured or `--dart-define=MOCK_AUTH=true`.
class MockAuthService implements AuthService {
  static const String validCode = '123456';
  AppUser? _user;

  @override
  bool get isSignedIn => _user != null;

  @override
  String? get currentUserId => _user?.id;

  @override
  Future<Result<void>> requestOtp(String phone) async {
    final invalid = Validators.phone(phone);
    if (invalid != null) return Failure('Invalid phone', code: invalid);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return const Success(null);
  }

  @override
  Future<Result<AppUser>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (code != validCode) {
      return const Failure('Wrong code', code: FailureCode.otpWrong);
    }
    _user = AppUser(
      id: 'mock-${Validators.normalizePhone(phone)}',
      phone: Validators.normalizePhone(phone),
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
    return Success(_user!);
  }

  @override
  Future<Result<AppUser>> completeProfile({
    required String fullName,
    required String languageCode,
    String? email,
    String? avatarUrl,
  }) async {
    final current = _user;
    if (current == null) {
      return const Failure('Not signed in', code: FailureCode.unauthorized);
    }
    _user = current.copyWith(fullName: fullName, languageCode: languageCode);
    return Success(_user!);
  }

  @override
  Future<Result<AppUser>> currentUser() async {
    final current = _user;
    return current == null
        ? const Failure('Not signed in', code: FailureCode.unauthorized)
        : Success(current);
  }

  @override
  Future<Result<void>> signOut() async {
    _user = null;
    return const Success(null);
  }
}
