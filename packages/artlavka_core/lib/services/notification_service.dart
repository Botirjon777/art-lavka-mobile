import '../utils/result.dart';
import 'api_client.dart';

/// Push notification registration (SPEC §9: "verified → push notification").
///
/// The REST API doesn't expose a device-token endpoint yet, so these are no-ops
/// that return success. Wire to `POST /notifications/device-token` (and the FCM/
/// APNs plumbing) when the messaging work lands; the interface is here so callers
/// can depend on it now.
class NotificationService {
  NotificationService(this._api);
  // ignore: unused_field
  final ApiClient _api;

  Future<Result<void>> registerDeviceToken({
    required String token,
    required String platform,
  }) async => const Success(null);

  Future<Result<void>> unregisterDeviceToken(String token) async =>
      const Success(null);
}
