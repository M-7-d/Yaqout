import 'package:hive/hive.dart';

part 'product_adapter.g.dart';

@HiveType(typeId: 1)
class HiveProduct extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String sellerId;

  @HiveField(2)
  final String? categoryId;

  @HiveField(3)
  final String title;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  final double price;

  @HiveField(6)
  final String? currency;

  @HiveField(7)
  final int stock;

  @HiveField(8)
  final bool isFeatured;

  @HiveField(9)
  final String? status;

  @HiveField(10)
  final List<String>? images;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime? updatedAt;

  @HiveField(13)
  final String? sellerName;

  @HiveField(14)
  final String? sellerAvatar;

  @HiveField(15)
  final double? avgRating;

  @HiveField(16)
  final int? reviewCount;

  HiveProduct({
    required this.id,
    required this.sellerId,
    this.categoryId,
    required this.title,
    this.description,
    required this.price,
    this.currency,
    required this.stock,
    this.isFeatured = false,
    this.status,
    this.images,
    required this.createdAt,
    this.updatedAt,
    this.sellerName,
    this.sellerAvatar,
    this.avgRating,
    this.reviewCount,
  });

  factory HiveProduct.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final imageList = rawImages is List
        ? rawImages.map((e) => e.toString()).toList()
        : <String>[];

    return HiveProduct(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      categoryId: json['category_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      status: json['status'] as String? ?? 'active',
      images: imageList,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      sellerName: json['seller_name'] as String?,
      sellerAvatar: json['seller_avatar'] as String?,
      avgRating: json['avg_rating'] as double?,
      reviewCount: json['review_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'stock': stock,
      'is_featured': isFeatured,
      'status': status,
      'images': images,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'seller_name': sellerName,
      'seller_avatar': sellerAvatar,
      'avg_rating': avgRating,
      'review_count': reviewCount,
    };
  }
}
