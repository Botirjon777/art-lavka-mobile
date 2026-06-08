import '../config/constants.dart';
import '../models/design.dart';
import '../models/listing.dart';
import '../services/api_client.dart';
import '../utils/error_mapper.dart';
import '../utils/result.dart';

/// A designer's own designs + listings (BACKEND_NODE.md §5). The server scopes
/// every query to the authenticated designer (ownership).
class DesignRepository {
  DesignRepository(this._api);
  final ApiClient _api;

  Future<Result<List<Design>>> myDesigns({
    int page = 0,
    int pageSize = AppConstants.pageSize,
  }) => ErrorMapper.guard(() async {
    final res = await _api.get('/designs/me', query: {'page': page}) as Map;
    return ((res['data'] as List?) ?? const [])
        .map((e) => Design.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  });

  /// Create a new design (preview + private print path already uploaded via
  /// [StorageService]). Server sets status to `pending` for moderation.
  Future<Result<Design>> createDesign({
    required String title,
    required String previewUrl,
    required String printFilePath,
    required int widthPx,
    required int heightPx,
    String? description,
    List<String> categoryIds = const [],
  }) => ErrorMapper.guard(() async {
    final data =
        await _api.post(
              '/designs',
              data: {
                'title': title,
                'description': ?description,
                'previewUrl': previewUrl,
                'printFilePath': printFilePath,
                'widthPx': widthPx,
                'heightPx': heightPx,
                if (categoryIds.isNotEmpty) 'categoryIds': categoryIds,
              },
            )
            as Map;
    return Design.fromJson(data.cast<String, dynamic>());
  });

  /// Create or update the listing (royalty/active) for a design on a product.
  Future<Result<Listing>> upsertListing({
    required String designId,
    required String productTypeId,
    required int royaltyUzs,
    bool active = true,
  }) => ErrorMapper.guard(() async {
    final data =
        await _api.post(
              '/designs/listings',
              data: {
                'designId': designId,
                'productTypeId': productTypeId,
                'royalty': royaltyUzs,
                'active': active,
              },
            )
            as Map;
    return Listing.fromJson(data.cast<String, dynamic>());
  });

  /// Toggle a listing on/off (e.g. pull a design from sale).
  Future<Result<void>> setListingActive(String listingId, bool active) =>
      ErrorMapper.guard(() async {
        await _api.patch(
          '/designs/listings/$listingId',
          data: {'active': active},
        );
      });
}
