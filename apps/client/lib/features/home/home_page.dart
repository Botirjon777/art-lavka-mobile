import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap/core_providers.dart';
import '../../l10n/l10n.dart';
import '../../ui/cart_badge.dart';
import '../catalog/catalog_controller.dart';
import 'home_controller.dart';
import 'widgets/banner_carousel.dart';
import 'widgets/feed_section.dart';

/// Home (SPEC §4): banner swiper (news/promotions) → Best sellers →
/// Recommended → New arrivals → per-category shelves. Each shelf loads
/// independently, caches (no refetch on scroll), and hides itself when empty.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final lang = ref.watch(localeProvider).languageCode;
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.appName), actions: const [CartBadge()]),
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
            FeedSection(title: t.homeBestSellers, sort: 'popular'),
            FeedSection(title: t.homeRecommended, sort: 'new'),
            FeedSection(title: t.homeNewArrivals, sort: 'new'),
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
