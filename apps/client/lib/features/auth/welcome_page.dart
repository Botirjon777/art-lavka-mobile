import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../ui/language_switcher.dart';

/// Entry screen: brand, tagline, Log in / Register, language switcher (SPEC §8).
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.space * 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: Alignment.centerRight,
                child: LanguageSwitcher(),
              ),
              const Spacer(),
              Text(
                t.appName,
                style: text.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.space),
              Text(
                t.welcomeTagline,
                style: text.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.push('/login'),
                child: Text(t.authLogIn),
              ),
              const SizedBox(height: AppTheme.space * 1.5),
              OutlinedButton(
                onPressed: () => context.push('/register'),
                child: Text(t.authRegister),
              ),
              const SizedBox(height: AppTheme.space * 2),
            ],
          ),
        ),
      ),
    );
  }
}
