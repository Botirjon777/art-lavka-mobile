import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';

/// Inline, localized error message for a [FailureCode] (SPEC §11). Renders
/// nothing (zero height) when [code] is null, so layout doesn't jump.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, this.code});

  final String? code;

  @override
  Widget build(BuildContext context) {
    if (code == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.space),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppTheme.space),
          Expanded(
            child: Text(
              localizedFailure(context.l10n, code),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
