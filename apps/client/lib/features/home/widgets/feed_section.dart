import 'package:artlavka_core/artlavka_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/l10n.dart';
import '../../catalog/widgets/product_card.dart';
import '../home_controller.dart';

/// A horizontal "shelf" of product cards for one feed (a category, or newest).
/// Renders nothing when the section is empty so the home stays tidy.
class FeedSection extends ConsumerWidget {
  const FeedSection({
    super.key,
    required this.title,
    this.categorySlug,
    this.sort,
  });

  final String title;
  final String? categorySlug;
  final String? sort;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.l10n;
    final text = Theme.of(context).textTheme;
    final feed = ref.watch(
      feedListingsProvider((category: categorySlug, sort: sort)),
    );

    return feed.when(
      loading: () =>
          const _ShelfBox(child: Center(child: CircularProgressIndicator())),
      error: (_, _) => const SizedBox.shrink(),
      data: (listings) {
        if (listings.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.space * 2,
                AppTheme.space * 2,
                AppTheme.space * 2,
                AppTheme.space,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: text.titleLarge),
                  TextButton(
                    onPressed: () => context.push('/catalog'),
                    child: Text(t.homeSeeAll),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space * 2,
                ),
                itemCount: listings.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppTheme.space * 2),
                itemBuilder: (_, i) => SizedBox(
                  width: 150,
                  child: ProductCard(
                    listing: listings[i],
                    onTap: () => context.push('/product/${listings[i].id}'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShelfBox extends StatelessWidget {
  const _ShelfBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(height: 250, child: child);
}
