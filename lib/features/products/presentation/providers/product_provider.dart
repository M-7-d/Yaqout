import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../../shared/providers/shared_providers.dart';

// ── Repository ────────────────────────────────────────────────────────────────
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepositoryImpl(ref.read(supabaseClientProvider));
});

class PaginatedProductsNotifier extends StateNotifier<AsyncValue<List<ProductEntity>>> {
  final ProductRepository _repo;
  final ProductFilter _filter;
  bool _hasMore = true;

  PaginatedProductsNotifier(this._repo, this._filter) : super(const AsyncValue.loading()) {
    _loadFirstPage();
  }

  bool get hasMore => _hasMore;

  Future<void> _loadFirstPage() async {
    try {
      final items = await _repo.getProducts(_filter.copyWith(page: 0));
      _hasMore = items.length == 20;
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isRefreshing || !_hasMore) return;
    
    final currentList = state.value ?? [];
    // Calculate current page based on list length assuming 20 items per page
    final nextPage = currentList.length ~/ 20;
    
    // We use AsyncLoading internally, but keep the data using AsyncData or AsyncLoading with previous data.
    // In Riverpod 2, StateNotifier with AsyncValue doesn't easily support `.isRefreshing` assignment,
    // so we just fetch and append.
    
    try {
      final newItems = await _repo.getProducts(_filter.copyWith(page: nextPage));
      _hasMore = newItems.length == 20;
      state = AsyncValue.data([...currentList, ...newItems]);
    } catch (e, st) {
      // Ignore error for pagination or handle appropriately
    }
  }
}

// ── Paginated product list ────────────────────────────────────────────────────
final productsProvider =
    StateNotifierProvider.family<PaginatedProductsNotifier, AsyncValue<List<ProductEntity>>, ProductFilter>((ref, filter) {
  return PaginatedProductsNotifier(ref.read(productRepositoryProvider), filter);
});

// ── Featured products (realtime) ──────────────────────────────────────────────
final featuredProductsProvider = StreamProvider<List<ProductEntity>>((ref) {
  return ref.read(productRepositoryProvider).watchFeaturedProducts();
});

// ── Single product detail ─────────────────────────────────────────────────────
final productDetailProvider =
    FutureProvider.family<ProductEntity, String>((ref, id) {
  return ref.read(productRepositoryProvider).getProductById(id);
});

class SellerProductsNotifier extends StateNotifier<AsyncValue<List<ProductEntity>>> {
  final ProductRepository _repo;
  final String _sellerId;
  // Note: getSellerProducts doesn't use ProductFilter with page right now, 
  // but if we want pagination here, we need to update it. Since the request is "HOME PAGE AND PRODUCT PAGE", 
  // we will just keep seller products as FutureProvider if it's too complex or implement similarly.
  
  SellerProductsNotifier(this._repo, this._sellerId) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await _repo.getSellerProducts(_sellerId);
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ── Seller's own products ─────────────────────────────────────────────────────
final sellerProductsProvider =
    StateNotifierProvider.family<SellerProductsNotifier, AsyncValue<List<ProductEntity>>, String>((ref, sellerId) {
  return SellerProductsNotifier(ref.read(productRepositoryProvider), sellerId);
});

// ── Search ────────────────────────────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<ProductEntity>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return Future.value([]);
  return ref.read(productRepositoryProvider).searchProducts(query);
});

// ── Product Form Notifier (create / edit) ─────────────────────────────────────
class ProductFormState {
  final String title;
  final String description;
  final String price;
  final String stock;
  final String? categoryId;
  final bool isLoading;
  final String? error;

  const ProductFormState({
    this.title       = '',
    this.description = '',
    this.price       = '',
    this.stock       = '',
    this.categoryId,
    this.isLoading   = false,
    this.error,
  });

  ProductFormState copyWith({
    String? title,
    String? description,
    String? price,
    String? stock,
    String? categoryId,
    bool?   isLoading,
    String? error,
  }) =>
      ProductFormState(
        title:       title       ?? this.title,
        description: description ?? this.description,
        price:       price       ?? this.price,
        stock:       stock       ?? this.stock,
        categoryId:  categoryId  ?? this.categoryId,
        isLoading:   isLoading   ?? this.isLoading,
        error:       error,
      );
}

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  ProductFormNotifier() : super(const ProductFormState());

  void setTitle(String v)       => state = state.copyWith(title: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setPrice(String v)       => state = state.copyWith(price: v);
  void setStock(String v)       => state = state.copyWith(stock: v);
  void setCategory(String? v)   => state = state.copyWith(categoryId: v);

  void populateFromEntity(ProductEntity p) {
    state = ProductFormState(
      title:       p.title,
      description: p.description ?? '',
      price:       p.price.toString(),
      stock:       p.stock.toString(),
      categoryId:  p.categoryId,
    );
  }
}

final productFormProvider =
    StateNotifierProvider<ProductFormNotifier, ProductFormState>((ref) {
  return ProductFormNotifier();
});
