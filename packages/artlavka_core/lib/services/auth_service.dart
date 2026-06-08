import '../models/app_user.dart';
import '../utils/error_mapper.dart';
import '../utils/jwt.dart';
import '../utils/result.dart';
import '../utils/validators.dart';
import 'api_client.dart';
import 'token_store.dart';

/// Phone-OTP authentication (SPEC §8). Passwordless: request a code, verify it.
///
/// An interface so apps can swap in a mock implementation for development /
/// tests (e.g. with `MOCK_AUTH=true`) without touching screens or controllers.
abstract interface class AuthService {
  bool get isSignedIn;
  String? get currentUserId;

  /// Send a 6-digit OTP to [phone] (normalized to E.164 first).
  Future<Result<void>> requestOtp(String phone);

  /// Verify [code] for [phone]; on success a session (tokens) is stored.
  Future<Result<AppUser>> verifyOtp({
    required String phone,
    required String code,
  });

  /// Persist first-login profile fields (SPEC §8 profile completion).
  Future<Result<AppUser>> completeProfile({
    required String fullName,
    required String languageCode,
    String? email,
    String? avatarUrl,
  });

  /// Load the current user's profile.
  Future<Result<AppUser>> currentUser();

  Future<Result<void>> signOut();
}

/// REST-backed [AuthService] (talks to the NestJS `/auth` endpoints).
///
/// Request bodies use camelCase keys (the API's DTOs); responses are snake_case
/// (parsed by the models' `fromJson`).
class RestAuthService implements AuthService {
  RestAuthService(this._api, this._tokens);
  final ApiClient _api;
  final TokenStore _tokens;

  @override
  bool get isSignedIn => _tokens.cachedAccessToken != null;

  @override
  String? get currentUserId => Jwt.subject(_tokens.cachedAccessToken);

  @override
  Future<Result<void>> requestOtp(String phone) async {
    final invalid = Validators.phone(phone);
    if (invalid != null) return Failure('Invalid phone', code: invalid);
    return ErrorMapper.guard(() async {
      await _api.post(
        '/auth/otp/request',
        data: {'phone': Validators.normalizePhone(phone)},
      );
    });
  }

  @override
  Future<Result<AppUser>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final invalid = Validators.otp(code);
    if (invalid != null) return Failure('Invalid code', code: invalid);
    return ErrorMapper.guard(() async {
      final data =
          await _api.post(
                '/auth/otp/verify',
                data: {'phone': Validators.normalizePhone(phone), 'code': code},
              )
              as Map;
      await _tokens.save(
        access: data['access_token'] as String,
        refresh: data['refresh_token'] as String,
      );
      return AppUser.fromJson((data['user'] as Map).cast<String, dynamic>());
    });
  }

  @override
  Future<Result<AppUser>> completeProfile({
    required String fullName,
    required String languageCode,
    String? email,
    String? avatarUrl,
  }) => ErrorMapper.guard(() async {
    final data =
        await _api.patch(
              '/auth/me',
              data: {
                'fullName': fullName,
                'languageCode': languageCode,
                'email': ?email,
                'avatarUrl': ?avatarUrl,
              },
            )
            as Map;
    return AppUser.fromJson(data.cast<String, dynamic>());
  });

  @override
  Future<Result<AppUser>> currentUser() => ErrorMapper.guard(() async {
    final data = await _api.get('/auth/me') as Map;
    return AppUser.fromJson(data.cast<String, dynamic>());
  });

  @override
  Future<Result<void>> signOut() => ErrorMapper.guard(() async {
    final refresh = await _tokens.refreshToken();
    if (refresh != null) {
      try {
        await _api.post('/auth/logout', data: {'refreshToken': refresh});
      } catch (_) {
        // Best-effort server-side revoke; always clear locally below.
      }
    }
    await _tokens.clear();
  });
}
