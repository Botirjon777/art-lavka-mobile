import 'config/env.dart';
import 'repositories/catalog_repository.dart';
import 'repositories/design_repository.dart';
import 'repositories/earnings_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/payout_repository.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/payment_service.dart';
import 'services/storage_service.dart';
import 'services/token_store.dart';

/// Composition root for the shared layer.
///
/// Construct ONE of these in each app's `main()` via [initialize], then expose
/// its members through Riverpod providers (the apps own state mgmt; core stays
/// widget-free). Keeps wiring in one place so both apps share it.
class ArtlavkaCore {
  ArtlavkaCore._({
    required this.api,
    required this.tokens,
    required this.auth,
    required this.storage,
    required this.payments,
    required this.notifications,
    required this.catalog,
    required this.orders,
    required this.designs,
    required this.earnings,
    required this.payouts,
  });

  final ApiClient api;
  final TokenStore tokens;

  // Services
  final AuthService auth;
  final StorageService storage;
  final PaymentService payments;
  final NotificationService notifications;

  // Repositories
  final CatalogRepository catalog;
  final OrderRepository orders;
  final DesignRepository designs;
  final EarningsRepository earnings;
  final PayoutRepository payouts;

  /// Build the wired container: warm the token cache, create the API client.
  static Future<ArtlavkaCore> initialize() async {
    Env.assertConfigured();
    final tokens = TokenStore();
    await tokens.load();
    final api = ApiClient(tokenStore: tokens);
    return ArtlavkaCore._(
      api: api,
      tokens: tokens,
      auth: RestAuthService(api, tokens),
      storage: StorageService(api),
      payments: PaymentService(api),
      notifications: NotificationService(api),
      catalog: CatalogRepository(api),
      orders: OrderRepository(api),
      designs: DesignRepository(api),
      earnings: EarningsRepository(api),
      payouts: PayoutRepository(api),
    );
  }
}
