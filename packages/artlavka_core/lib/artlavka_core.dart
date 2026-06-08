/// ART-LAVKA shared core — models, services, repositories, theme, utils.
///
/// No screen widgets live here (SPEC §4) so the package stays testable and
/// reusable across both apps. Import this single barrel:
///
/// ```dart
/// import 'package:artlavka_core/artlavka_core.dart';
/// ```
library;

// Composition root
export 'core.dart';

// Config
export 'config/constants.dart';
export 'config/env.dart';

// Models
export 'models/app_user.dart';
export 'models/banner.dart';
export 'models/cart_item.dart';
export 'models/category.dart';
export 'models/design.dart';
export 'models/designer_profile.dart';
export 'models/ledger_entry.dart';
export 'models/listing.dart';
export 'models/order.dart';
export 'models/order_item.dart';
export 'models/payout.dart';
export 'models/product_type.dart';
export 'models/review.dart';

// Services
export 'services/api_client.dart';
export 'services/auth_service.dart';
export 'services/notification_service.dart';
export 'services/payment_service.dart';
export 'services/storage_service.dart';
export 'services/token_store.dart';

// Repositories
export 'repositories/catalog_repository.dart';
export 'repositories/design_repository.dart';
export 'repositories/designer_repository.dart';
export 'repositories/earnings_repository.dart';
export 'repositories/order_repository.dart';
export 'repositories/payout_repository.dart';

// Theme
export 'theme/app_theme.dart';
export 'theme/colors.dart';
export 'theme/typography.dart';

// Utils
export 'utils/error_mapper.dart';
export 'utils/json.dart';
export 'utils/jwt.dart';
export 'utils/money.dart';
export 'utils/result.dart';
export 'utils/validators.dart';
