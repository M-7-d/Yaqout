// Product domain entity
class ProductEntity {
  final String id;
  final String sellerId;
  final String? categoryId;
  final String title;
  final String? description;
  final double price;
  final String currency;
  final int stock;
  final bool isFeatured;
  final String status; // active | draft | sold | banned
  final List<String> images;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // Joined fields (optional)
  final String? sellerName;
  final String? sellerAvatar;
  final double? avgRating;
  final int? reviewCount;

  const ProductEntity({
    required this.id,
    required this.sellerId,
    this.categoryId,
    required this.title,
    this.description,
    required this.price,
    this.currency = 'USD',
    required this.stock,
    this.isFeatured = false,
    this.status = 'active',
    this.images = const [],
    required this.createdAt,
    this.updatedAt,
    this.sellerName,
    this.sellerAvatar,
    this.avgRating,
    this.reviewCount,
  });

  String get primaryImage => images.isNotEmpty ? images.first : '';

  bool get inStock => stock > 0;

  ProductEntity copyWith({
    String? title,
    String? description,
    double? price,
    int? stock,
    String? status,
    List<String>? images,
    bool? isFeatured,
    String? categoryId,
  }) =>
      ProductEntity(
        id:          id,
        sellerId:    sellerId,
        categoryId:  categoryId  ?? this.categoryId,
        title:       title       ?? this.title,
        description: description ?? this.description,
        price:       price       ?? this.price,
        currency:    currency,
        stock:       stock       ?? this.stock,
        isFeatured:  isFeatured  ?? this.isFeatured,
        status:      status      ?? this.status,
        images:      images      ?? this.images,
        createdAt:   createdAt,
        updatedAt:   DateTime.now(),
        sellerName:  sellerName,
        sellerAvatar:sellerAvatar,
        avgRating:   avgRating,
        reviewCount: reviewCount,
      );
}

// Sort options for product listing
enum ProductSortBy {
  newest,
  oldest,
  priceLow,
  priceHigh,
}

// Filter object for paginated queries
class ProductFilter {
  final String? categoryId;
  final String? query;
  final int page;
  final ProductSortBy sortBy;

  const ProductFilter({this.categoryId, this.query, this.page = 0, this.sortBy = ProductSortBy.newest});

  ProductFilter copyWith({
    String? categoryId,
    String? query,
    int? page,
    ProductSortBy? sortBy,
  }) {
    return ProductFilter(
      categoryId: categoryId ?? this.categoryId,
      query: query ?? this.query,
      page: page ?? this.page,
      sortBy: sortBy ?? this.sortBy,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProductFilter &&
      other.categoryId == categoryId &&
      other.query == query &&
      other.page == page &&
      other.sortBy == sortBy;

  @override
  int get hashCode => Object.hash(categoryId, query, page, sortBy);
}
