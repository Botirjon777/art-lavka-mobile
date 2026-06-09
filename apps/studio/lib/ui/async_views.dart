import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

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
            Text(message ?? t.errServer, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.space * 2),
            OutlinedButton(onPressed: onRetry, child: Text(t.actionRetry)),
          ],
        ),
      ),
    );
  }
}

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
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
