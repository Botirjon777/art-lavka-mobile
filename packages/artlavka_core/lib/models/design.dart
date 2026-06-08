import 'package:meta/meta.dart';

import '../utils/json.dart';

/// Moderation state of an uploaded print (SPEC §8 upload flow / §9 rules).
enum DesignStatus { draft, pending, approved, rejected }

/// A print uploaded by a designer.
///
/// Note: [printFilePath] is a *path* in the private `print-files` bucket — never
/// a public URL. Only production gets short-lived signed URLs (SPEC §5/§13).
/// Catalog UI uses [previewUrl] (public, watermarked).
@immutable
class Design {
  const Design({
    required this.id,
    required this.designerId,
    required this.title,
    required this.previewUrl,
    required this.printFilePath,
    required this.status,
    required this.createdAt,
    this.description,
    this.widthPx = 0,
    this.heightPx = 0,
    this.rejectionReason,
    this.categoryIds = const [],
  });

  final String id;
  final String designerId;
  final String title;
  final String? description;

  /// Public, low-res, watermarked preview used to build mockups.
  final String previewUrl;

  /// Private path to the hi-res print-ready file.
  final String printFilePath;

  final int widthPx;
  final int heightPx;
  final DesignStatus status;

  /// Set when [status] is [DesignStatus.rejected].
  final String? rejectionReason;
  final List<String> categoryIds;
  final DateTime createdAt;

  bool get isLive => status == DesignStatus.approved;

  factory Design.fromJson(Map<String, dynamic> json) => Design(
    id: json['id'] as String,
    designerId: json['designer_id'] as String,
    title: json['title'] as String? ?? '',
    description: Json.stringOrNull(json['description']),
    previewUrl: json['preview_url'] as String? ?? '',
    printFilePath: json['print_file_path'] as String? ?? '',
    widthPx: Json.intValue(json['width_px']),
    heightPx: Json.intValue(json['height_px']),
    status: Json.enumByName(
      DesignStatus.values,
      json['status'],
      DesignStatus.pending,
    ),
    rejectionReason: Json.stringOrNull(json['rejection_reason']),
    categoryIds:
        (json['category_ids'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    createdAt: Json.date(json['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'designer_id': designerId,
    'title': title,
    'description': description,
    'preview_url': previewUrl,
    'print_file_path': printFilePath,
    'width_px': widthPx,
    'height_px': heightPx,
    'status': status.name,
    'rejection_reason': rejectionReason,
    'created_at': createdAt.toIso8601String(),
  };

  Design copyWith({
    String? title,
    String? description,
    DesignStatus? status,
    String? rejectionReason,
    List<String>? categoryIds,
  }) => Design(
    id: id,
    designerId: designerId,
    previewUrl: previewUrl,
    printFilePath: printFilePath,
    widthPx: widthPx,
    heightPx: heightPx,
    createdAt: createdAt,
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    rejectionReason: rejectionReason ?? this.rejectionReason,
    categoryIds: categoryIds ?? this.categoryIds,
  );
}
