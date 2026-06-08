import '../config/constants.dart';
import '../models/order.dart';
import '../models/review.dart';
import '../services/api_client.dart';
import '../utils/error_mapper.dart';
import '../utils/result.dart';

/// Customer orders + review submission (BACKEND_NODE.md §5). Order creation +
/// payment go through [PaymentService] / the server (price authority).
class OrderRepository {
  OrderRepository(this._api);
  final ApiClient _api;

  Future<Result<List<Order>>> myOrders({
    int page = 0,
    int pageSize = AppConstants.pageSize,
  }) => ErrorMapper.guard(() async {
    final res = await _api.get('/orders/me', query: {'page': page}) as Map;
    return ((res['data'] as List?) ?? const [])
        .map((e) => Order.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  });

  Future<Result<Order>> order(String id) => ErrorMapper.guard(() async {
    final data = await _api.get('/orders/$id') as Map;
    return Order.fromJson(data.cast<String, dynamic>());
  });

  /// Submit a 1–5 review for a delivered order item.
  Future<Result<Review>> submitReview({
    required String orderItemId,
    required int rating,
    String? comment,
  }) => ErrorMapper.guard(() async {
    final data =
        await _api.post(
              '/reviews',
              data: {
                'orderItemId': orderItemId,
                'rating': rating.clamp(1, 5),
                'comment': ?comment,
              },
            )
            as Map;
    return Review.fromJson(data.cast<String, dynamic>());
  });

  /// Reviews for a design (product page).
  Future<Result<List<Review>>> reviewsForDesign(String designId) =>
      ErrorMapper.guard(() async {
        final data =
            await _api.get('/catalog/designs/$designId/reviews') as List;
        return data
            .map((e) => Review.fromJson((e as Map).cast<String, dynamic>()))
            .toList();
      });
}
