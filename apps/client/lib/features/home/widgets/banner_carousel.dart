import 'package:artlavka_core/artlavka_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
// Hide Flutter's debug `Banner` widget — collides with our model.
import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../home_controller.dart';

/// Swipeable banner carousel (SPEC §4). Hidden entirely when there are no
/// active banners or while loading/erroring — it's decorative, not essential.
class BannerCarousel extends ConsumerStatefulWidget {
  const BannerCarousel({super.key});

  @override
  ConsumerState<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends ConsumerState<BannerCarousel> {
  final _controller = PageController(viewportFraction: 0.9);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banners = ref.watch(bannersProvider).valueOrNull ?? const [];
    if (banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: banners.length,
            itemBuilder: (_, i) => _BannerTile(banner: banners[i]),
          ),
        ),
        const SizedBox(height: AppTheme.space),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < banners.length; i++)
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == _index ? AppColors.accent : AppColors.border,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _BannerTile extends StatelessWidget {
  const _BannerTile({required this.banner});
  final Banner banner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        child: InkWell(
          onTap: () => _onTap(context),
          child: CachedNetworkImage(
            imageUrl: banner.imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            placeholder: (_, _) => Container(color: AppColors.surfaceMuted),
            errorWidget: (_, _, _) => Container(color: AppColors.surfaceMuted),
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    switch (banner.linkType) {
      case BannerLinkType.listing when banner.linkTarget != null:
        context.push('/product/${banner.linkTarget}');
      case BannerLinkType.category:
      case BannerLinkType.url:
      case BannerLinkType.listing:
      case BannerLinkType.none:
        context.push('/catalog');
    }
  }
}
