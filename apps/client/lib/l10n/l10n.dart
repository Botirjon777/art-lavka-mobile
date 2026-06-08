import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// `context.l10n` — concise access to the generated strings.
extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Map a repository [FailureCode] to a localized, user-facing message
/// (SPEC §7/§11). Unknown/none falls back to the generic server message.
String localizedFailure(AppLocalizations t, String? code) => switch (code) {
  FailureCode.network => t.errNetwork,
  FailureCode.otpWrong => t.errOtpWrong,
  FailureCode.otpExpired => t.errOtpExpired,
  FailureCode.otpThrottled => t.errOtpThrottled,
  FailureCode.invalidPhone => t.errInvalidPhone,
  FailureCode.validation => t.errValidation,
  FailureCode.sessionExpired => t.errSessionExpired,
  FailureCode.unauthorized => t.errUnauthorized,
  FailureCode.sellerNotVerified => t.errSellerNotVerified,
  _ => t.errServer,
};
