import 'dart:io';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  Future<List<ProductEntity>> getProducts(ProductFilter filter);
  Future<ProductEntity> getProductById(String id);
  Future<ProductEntity> createProduct(ProductEntity product, List<File> images);
  Future<ProductEntity> updateProduct(ProductEntity product, {List<File>? newImages});
  Future<void> deleteProduct(String id);
  Future<List<ProductEntity>> getSellerProducts(String sellerId);
  Stream<List<ProductEntity>> watchFeaturedProducts();
  Future<List<ProductEntity>> searchProducts(String query);
}
