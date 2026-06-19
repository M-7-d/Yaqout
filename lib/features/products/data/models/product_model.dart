import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.sellerId,
    super.categoryId,
    required super.title,
    super.description,
    required super.price,
    super.currency,
    required super.stock,
    super.isFeatured,
    super.status,
    super.images,
    required super.createdAt,
    super.updatedAt,
    super.sellerName,
    super.sellerAvatar,
    super.avgRating,
    super.reviewCount,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // images column is text[] in Supabase → returns List<dynamic>
    final rawImages = json['images'];
    final imageList = rawImages is List
        ? rawImages.map((e) => e.toString()).toList()
        : <String>[];

    // profiles join (when using .select('*, profiles(...)'))
    final profile = json['profiles'] as Map<String, dynamic>?;

    // reviews join to calculate rating
    final reviewsList = json['reviews'] as List<dynamic>?;
    double? avgRating;
    int? reviewCount;
    if (reviewsList != null && reviewsList.isNotEmpty) {
      reviewCount = reviewsList.length;
      final total = reviewsList
          .map((r) => (r['rating'] as num).toInt())
          .reduce((a, b) => a + b);
      avgRating = total / reviewCount;
    }

    return ProductModel(
      id:           json['id'] as String,
      sellerId:     json['seller_id'] as String,
      categoryId:   json['category_id'] as String?,
      title:        json['title'] as String,
      description:  json['description'] as String?,
      price:        (json['price'] as num).toDouble(),
      currency:     json['currency'] as String? ?? 'USD',
      stock:        (json['stock'] as num?)?.toInt() ?? 0,
      isFeatured:   json['is_featured'] as bool? ?? false,
      status:       json['status'] as String? ?? 'active',
      images:       imageList,
      createdAt:    DateTime.parse(json['created_at'] as String),
      updatedAt:    json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      sellerName:   profile?['full_name'] as String?,
      sellerAvatar: profile?['avatar_url'] as String?,
      avgRating:    avgRating,
      reviewCount:  reviewCount,
    );
  }

  Map<String, dynamic> toInsertJson() => {
        'seller_id':   sellerId,
        'category_id': categoryId,
        'title':       title,
        'description': description,
        'price':       price,
        'currency':    currency,
        'stock':       stock,
        'is_featured': isFeatured,
        'status':      status,
        'images':      images,
      };

  Map<String, dynamic> toUpdateJson() => {
        'title':       title,
        'description': description,
        'price':       price,
        'stock':       stock,
        'status':      status,
        'images':      images,
        'category_id': categoryId,
        'updated_at':  DateTime.now().toIso8601String(),
      };

  ProductEntity toEntity() => ProductEntity(
        id:           id,
        sellerId:     sellerId,
        categoryId:   categoryId,
        title:        title,
        description:  description,
        price:        price,
        currency:     currency,
        stock:        stock,
        isFeatured:   isFeatured,
        status:       status,
        images:       images,
        createdAt:    createdAt,
        updatedAt:    updatedAt,
        sellerName:   sellerName,
        sellerAvatar: sellerAvatar,
        avgRating:    avgRating,
        reviewCount:  reviewCount,
      );
}
