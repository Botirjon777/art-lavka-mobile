import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';

/// Primary filled button with idle / loading / disabled states (SPEC §10).
/// While [loading] it shows an inline spinner and ignores taps (no double-submit).
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.onAccent,
              ),
            )
          : Text(label),
    );
  }
}
