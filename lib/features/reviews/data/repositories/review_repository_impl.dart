import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/review_entity.dart';
import '../../domain/repositories/review_repository.dart';
import '../models/review_model.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final SupabaseClient _client;
  ReviewRepositoryImpl(this._client);

  @override
  Future<List<ReviewEntity>> getReviewsForProduct(String productId) async {
    try {
      final data = await _client
          .from('reviews')
          .select('*')
          .eq('product_id', productId)
          .order('created_at', ascending: false);
      
      return (data as List)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ReviewEntity> createReview({
    required String productId,
    required String reviewerId,
    required int rating,
    String? comment,
  }) async {
    try {
      final data = await _client
          .from('reviews')
          .insert(ReviewModel(
            productId: productId,
            reviewerId: reviewerId,
            rating: rating,
            comment: comment,
            createdAt: DateTime.now(),
          ).toInsertJson())
          .select()
          .single();

      return ReviewModel.fromJson(data);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }
}
