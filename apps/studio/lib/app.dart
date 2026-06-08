import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';

/// Root widget for ART-LAVKA Studio. The onboarding gate + dashboard land in
/// later milestones (SPEC §14); this is the foundation shell.
class ArtLavkaStudioApp extends StatelessWidget {
  const ArtLavkaStudioApp({super.key, this.initError});

  final Object? initError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ART-LAVKA Studio',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: _FoundationHome(initError: initError),
    );
  }
}

class _FoundationHome extends StatelessWidget {
  const _FoundationHome({this.initError});
  final Object? initError;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final configured = Env.isConfigured && initError == null;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space * 3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('ART-LAVKA', style: text.displaySmall),
              Text(
                'Studio',
                style: text.titleLarge?.copyWith(color: AppColors.accent),
              ),
              const SizedBox(height: AppTheme.space),
              Text(
                'Seller app — foundation ready.\n'
                'Dashboard stays locked until KYC is verified.',
                style: text.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space * 3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space * 2,
                  vertical: AppTheme.space,
                ),
                decoration: BoxDecoration(
                  color: (configured ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radius),
                  border: Border.all(
                    color: configured ? AppColors.success : AppColors.warning,
                  ),
                ),
                child: Text(
                  configured
                      ? 'Backend connected'
                      : 'No backend config (run with --dart-define)',
                  style: text.bodyMedium?.copyWith(
                    color: configured ? AppColors.success : AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
