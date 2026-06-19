import '../../domain/entities/review_entity.dart';

class ReviewModel extends ReviewEntity {
  const ReviewModel({
    String? id,
    required super.productId,
    required super.reviewerId,
    required super.rating,
    super.comment,
    required super.createdAt,
    super.reviewerName,
    super.reviewerAvatar,
  }) : super(id: id ?? '');

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // profiles join (when using .select('*, profiles(...)'))
    final profile = json['profiles'] as Map<String, dynamic>?;

    return ReviewModel(
      id:             json['id'] as String,
      productId:      json['product_id'] as String,
      reviewerId:     json['reviewer_id'] as String,
      rating:         (json['rating'] as num).toInt(),
      comment:        json['comment'] as String?,
      createdAt:      DateTime.parse(json['created_at'] as String),
      reviewerName:   profile?['full_name'] as String?,
      reviewerAvatar: profile?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'product_id':  productId,
        'reviewer_id': reviewerId,
        'rating':      rating,
        'comment':     comment,
        'created_at':  createdAt.toIso8601String(),      };
}
