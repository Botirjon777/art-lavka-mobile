import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../bootstrap/core_providers.dart';
import '../../l10n/l10n.dart';
import '../../ui/cart_badge.dart';
import '../auth/auth_controller.dart';
import '../catalog/catalog_controller.dart';
import 'home_controller.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/feed_section.dart';

/// Home: banners + "New arrivals" + a shelf per category (SPEC §4). Each section
/// loads independently and hides itself when empty/erroring (never a blank wall).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final lang = ref.watch(localeProvider).languageCode;
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.appName),
        actions: [
          IconButton(
            tooltip: t.navOrders,
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => context.push('/orders'),
          ),
          const CartBadge(),
          IconButton(
            tooltip: t.actionSignOut,
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(bannersProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(feedListingsProvider);
        },
        child: ListView(
          children: [
            const SizedBox(height: AppTheme.space * 2),
            const BannerCarousel(),
            FeedSection(title: t.homeNewArrivals),
            ...categories
                .maybeWhen(data: (c) => c, orElse: () => const <Category>[])
                .map(
                  (c) =>
                      FeedSection(title: c.nameFor(lang), categorySlug: c.slug),
                ),
            const SizedBox(height: AppTheme.space * 3),
          ],
        ),
      ),
    );
  }
}
