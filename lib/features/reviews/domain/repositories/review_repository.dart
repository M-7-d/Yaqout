import '../entities/review_entity.dart';

abstract class ReviewRepository {
  Future<List<ReviewEntity>> getReviewsForProduct(String productId);
  Future<ReviewEntity> createReview({
    required String productId,
    required String reviewerId,
    required int rating,
    String? comment,
  });
}
