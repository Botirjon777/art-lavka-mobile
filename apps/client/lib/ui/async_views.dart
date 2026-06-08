import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// Centered loading indicator for a screen/section.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: CircularProgressIndicator(),
    ),
  );
}

/// Error state with a Retry button (SPEC §7 — never a blank screen).
class ErrorRetryView extends StatelessWidget {
  const ErrorRetryView({super.key, required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final t = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space * 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 40, color: AppColors.inkFaint),
            const SizedBox(height: AppTheme.space),
            Text(
              message ?? t.errServer,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTheme.space * 2),
            OutlinedButton(onPressed: onRetry, child: Text(t.actionRetry)),
          ],
        ),
      ),
    );
  }
}

/// Empty state with an illustration glyph + message.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space * 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: AppColors.inkFaint),
            const SizedBox(height: AppTheme.space),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only 0–5 star rating row.
class RatingStars extends StatelessWidget {
  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.count,
  });

  final double rating;
  final double size;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            rating >= i
                ? Icons.star
                : (rating >= i - 0.5 ? Icons.star_half : Icons.star_border),
            size: size,
            color: AppColors.warning,
          ),
        if (count != null && count! > 0) ...[
          const SizedBox(width: 4),
          Text('$count', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
