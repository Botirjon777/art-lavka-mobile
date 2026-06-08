import 'package:meta/meta.dart';

import '../utils/json.dart';

/// What a home banner points at when tapped.
enum BannerLinkType { category, listing, url, none }

/// A promotional banner shown on the client home feed. SPEC §5.
@immutable
class Banner {
  const Banner({
    required this.id,
    required this.imageUrl,
    required this.linkType,
    this.linkTarget,
    this.sortOrder = 0,
    this.active = true,
  });

  final String id;
  final String imageUrl;
  final BannerLinkType linkType;

  /// A category slug, listing id, or absolute URL depending on [linkType].
  final String? linkTarget;
  final int sortOrder;
  final bool active;

  factory Banner.fromJson(Map<String, dynamic> json) => Banner(
    id: json['id'] as String,
    imageUrl: json['image_url'] as String,
    linkType: Json.enumByName(
      BannerLinkType.values,
      json['link_type'],
      BannerLinkType.none,
    ),
    linkTarget: Json.stringOrNull(json['link_target']),
    sortOrder: Json.intValue(json['sort_order']),
    active: Json.boolValue(json['active'], fallback: true),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'image_url': imageUrl,
    'link_type': linkType.name,
    'link_target': linkTarget,
    'sort_order': sortOrder,
    'active': active,
  };
}
