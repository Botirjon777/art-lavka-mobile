import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Localized label for a design's moderation [DesignStatus].
String designStatusLabel(AppLocalizations t, DesignStatus status) =>
    switch (status) {
      DesignStatus.draft => t.designStatusDraft,
      DesignStatus.pending => t.designStatusPending,
      DesignStatus.approved => t.designStatusApproved,
      DesignStatus.rejected => t.designStatusRejected,
    };

/// Localized message for a repository [FailureCode] (SPEC §7/§11).
String localizedFailure(AppLocalizations t, String? code) => switch (code) {
  FailureCode.network => t.errNetwork,
  FailureCode.otpWrong => t.errOtpWrong,
  FailureCode.otpExpired => t.errOtpExpired,
  FailureCode.otpThrottled => t.errOtpThrottled,
  FailureCode.invalidPhone => t.errInvalidPhone,
  FailureCode.unauthorized => t.errUnauthorized,
  _ => t.errServer,
};
