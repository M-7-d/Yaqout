// Review domain entity
class ReviewEntity {
  final String id;
  final String productId;
  final String reviewerId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  // Joined profile fields (optional)
  final String? reviewerName;
  final String? reviewerAvatar;

  const ReviewEntity({
    required this.id,
    required this.productId,
    required this.reviewerId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.reviewerName,
    this.reviewerAvatar,
  });
}
