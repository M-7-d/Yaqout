import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../models/product_model.dart';
import '../../../../core/errors/exceptions.dart';

class ProductRepositoryImpl implements ProductRepository {
  final SupabaseClient _client;
  ProductRepositoryImpl(this._client);

  static const _bucket = 'product-images';

  @override
  Future<List<ProductEntity>> getProducts(ProductFilter filter) async {
    try {
      // Build query step by step — PostgREST builder keeps type through each call
      var query = _client
          .from('products')
          .select('*, profiles(full_name, avatar_url), reviews(rating)')
          .eq('status', 'active');

      if (filter.categoryId != null) {
        query = query.eq('category_id', filter.categoryId!);
      }
      if (filter.query != null && filter.query!.isNotEmpty) {
        query = query.ilike('title', '%${filter.query}%');
      }

      // Determine sort column and direction
      String orderColumn;
      bool ascending;
      switch (filter.sortBy) {
        case ProductSortBy.newest:
          orderColumn = 'created_at';
          ascending = false;
          break;
        case ProductSortBy.oldest:
          orderColumn = 'created_at';
          ascending = true;
          break;
        case ProductSortBy.priceLow:
          orderColumn = 'price';
          ascending = true;
          break;
        case ProductSortBy.priceHigh:
          orderColumn = 'price';
          ascending = false;
          break;
      }

      final data = await query
          .order(orderColumn, ascending: ascending)
          .range(filter.page * 20, filter.page * 20 + 19);

      return (data as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ProductEntity> getProductById(String id) async {
    try {
      final data = await _client
          .from('products')
          .select('*, profiles(full_name, avatar_url), reviews(rating)')
          .eq('id', id)
          .single();
      return ProductModel.fromJson(data).toEntity();
    } catch (e) {
      throw NotFoundException(message: 'Product not found: $id');
    }
  }

  @override
  Future<ProductEntity> createProduct(
    ProductEntity product,
    List<File> images,
  ) async {
    try {
      final imageUrls = await _uploadImages(product.sellerId, images);

      final data = await _client
          .from('products')
          .insert(ProductModel(
            id:          '',
            sellerId:    product.sellerId,
            categoryId:  product.categoryId,
            title:       product.title,
            description: product.description,
            price:       product.price,
            stock:       product.stock,
            images:      imageUrls,
            createdAt:   DateTime.now(),
          ).toInsertJson())
          .select()
          .single();

      return ProductModel.fromJson(data).toEntity();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<ProductEntity> updateProduct(
    ProductEntity product, {
    List<File>? newImages,
  }) async {
    try {
      var imageUrls = product.images;
      if (newImages != null && newImages.isNotEmpty) {
        final uploaded = await _uploadImages(product.sellerId, newImages);
        imageUrls = [...imageUrls, ...uploaded];
      }

      final updated = product.copyWith(images: imageUrls);
      final m = ProductModel(
        id:          updated.id,
        sellerId:    updated.sellerId,
        categoryId:  updated.categoryId,
        title:       updated.title,
        description: updated.description,
        price:       updated.price,
        stock:       updated.stock,
        isFeatured:  updated.isFeatured,
        status:      updated.status,
        images:      imageUrls,
        createdAt:   updated.createdAt,
      );

      final data = await _client
          .from('products')
          .update(m.toUpdateJson())
          .eq('id', product.id)
          .select()
          .single();

      return ProductModel.fromJson(data).toEntity();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _client.from('products').delete().eq('id', id);
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Future<List<ProductEntity>> getSellerProducts(String sellerId) async {
    try {
      final data = await _client
          .from('products')
          .select('*, profiles(full_name, avatar_url), reviews(rating)')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);
      return (data as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
    } catch (e) {
      throw ServerException(message: e.toString());
    }
  }

  @override
  Stream<List<ProductEntity>> watchFeaturedProducts() {
    return _client
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('is_featured', true)
        .map((data) => data
            .map((e) => ProductModel.fromJson(e).toEntity())
            .toList());
  }

  @override
  Future<List<ProductEntity>> searchProducts(String query) =>
      getProducts(ProductFilter(query: query));

  Future<List<String>> _uploadImages(String sellerId, List<File> files) async {
    return Future.wait(files.map((file) async {
      final safeName = _basename(file.path);
      final path =
          'products/$sellerId/${DateTime.now().millisecondsSinceEpoch}_$safeName';
      await _client.storage.from(_bucket).upload(
            path, file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );
      return _client.storage.from(_bucket).getPublicUrl(path);
    }));
  }
}

String _basename(String filePath) {
  final normalized = filePath.replaceAll(r'\', '/');
  final i = normalized.lastIndexOf('/');
  return i >= 0 ? normalized.substring(i + 1) : normalized;
}
