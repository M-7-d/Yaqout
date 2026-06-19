import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../core/widgets/app_logo.dart';
import '../widgets/product_card.dart';

import '../widgets/product_search_delegate.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  ProductSortBy _selectedSort = ProductSortBy.newest;

  static const _sortOptions = [
    {'sort': ProductSortBy.newest, 'label': 'Newest', 'icon': Icons.schedule_rounded},
    {'sort': ProductSortBy.oldest, 'label': 'Oldest', 'icon': Icons.history_rounded},
    {'sort': ProductSortBy.priceLow, 'label': 'Price ↑', 'icon': Icons.arrow_upward_rounded},
    {'sort': ProductSortBy.priceHigh, 'label': 'Price ↓', 'icon': Icons.arrow_downward_rounded},
  ];

  ProductFilter get _currentFilter => ProductFilter(sortBy: _selectedSort);

  String get _activeSortLabel =>
      (_sortOptions.firstWhere((o) => o['sort'] == _selectedSort)['label'] as String);

  @override
  Widget build(BuildContext context) {
    final featured   = ref.watch(featuredProductsProvider);
    final allProducts= ref.watch(productsProvider(_currentFilter));
    final user       = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const AppLogo(width: 90, color: Colors.white),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white, size: 28),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(),
              );
            },
            tooltip: 'Search products',
          ),
          const SizedBox(width: 8),
        ],
      ),
      extendBodyBehindAppBar: true,

      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(featuredProductsProvider);
          ref.invalidate(productsProvider);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification scrollInfo) {
            if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
              ref.read(productsProvider(_currentFilter).notifier).loadMore();
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
              // ── Curved Header ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Curved background
                    ClipPath(
                      clipper: _HeaderCurveClipper(),
                      child: Container(
                        height: 220,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                        ),
                      ),
                    ).animate().slideY(begin: -1, end: 0, duration: 600.ms, curve: Curves.easeOutQuad),
                    
                    ClipPath(
                      clipper: _HeaderCurveClipper(),
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryLight.withOpacity(0.1),
                              AppColors.primaryDark.withOpacity(0.05),
                            ],
                          ),
                        ),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).moveY(begin: 0, end: 15, duration: 3.seconds, curve: Curves.easeInOut),

                    Positioned(
                      left: 20,
                      top: 110,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, ${user?.fullName?.split(' ')[0] ?? 'Explorer'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Find your next treasure today',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),    
                  ],
                ),
              ),

              // ── Featured banner ─────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      featured.when(
                        data:  (list) => list.isEmpty
                            ? const SizedBox.shrink()
                            : _FeaturedCarousel(products: list),
                        loading: () => _FeaturedShimmer(),
                        error:   (e, _) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ),

              // ── "All Products" heading + Filter button ──────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('All Products',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black)),
                      GestureDetector(
                        onTap: () => _showSortSheet(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: _selectedSort != ProductSortBy.newest
                                ? AppColors.primary.withOpacity(0.15)
                                : AppColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedSort != ProductSortBy.newest
                                  ? AppColors.primary.withOpacity(0.5)
                                  : AppColors.border.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sort_rounded,
                                size: 18,
                                color: _selectedSort != ProductSortBy.newest
                                    ? AppColors.primary
                                    : AppColors.textHint,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _activeSortLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedSort != ProductSortBy.newest
                                      ? AppColors.primary
                                      : AppColors.textHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              allProducts.when(
                data: (list) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: list.isEmpty
                      ? SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.search_off_rounded, size: 48, color: AppColors.textHint.withOpacity(0.5)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No products found',
                                    style: TextStyle(
                                      color: AppColors.textHint,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => ProductCard(product: list[i], index: i),
                            childCount: list.length,
                          ),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                        ),
                ),
                loading: () => SliverToBoxAdapter(child: _GridShimmer()),
                error: (e, _) => SliverToBoxAdapter(
                  child: Center(
                    child: Text(AppStrings.genericError,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ),
              ),
              
              // Load more indicator
              if (allProducts.hasValue && ref.read(productsProvider(_currentFilter).notifier).hasMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 100.0, top: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
            ],
          ),
        ),
      ),

      // FAB for sellers
      floatingActionButton: user?.isSeller == true || user?.isAdmin == true
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/products/new'),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Add Product',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            )
          : null,
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Sort Products', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ..._sortOptions.map((opt) {
              final sortVal = opt['sort'] as ProductSortBy;
              final isSelected = _selectedSort == sortVal;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedSort = sortVal);
                    Navigator.pop(ctx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])
                          : null,
                      color: isSelected ? null : AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : AppColors.border.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(opt['icon'] as IconData, size: 20, color: isSelected ? Colors.white : AppColors.textHint),
                        const SizedBox(width: 12),
                        Text(
                          opt['label'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textHint,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Featured Carousel ─────────────────────────────────────────────────────────
class _FeaturedCarousel extends StatelessWidget {
  final List<ProductEntity> products;
  const _FeaturedCarousel({required this.products});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: products.length,
        controller: PageController(viewportFraction: 0.9),
        itemBuilder: (ctx, i) {
          final p = products[i];
          return GestureDetector(
            onTap: () => context.push('/products/${p.id}'),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: AppColors.primaryGradient,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  if (p.primaryImage.isNotEmpty)
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: p.primaryImage,
                        errorListener: (_) {},
                        fit: BoxFit.cover,
                        color: Colors.black26,
                        colorBlendMode: BlendMode.darken,
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.black26,
                          child: const Icon(Icons.broken_image_outlined,
                              color: Colors.white54, size: 40),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 16, left: 16, right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.title,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700,
                                fontSize: 16),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                          Text('\$${p.price.toStringAsFixed(2)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w800,
                                  )),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Featured',
                          style: TextStyle(color: Colors.white,
                              fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Shimmer placeholders ──────────────────────────────────────────────────────
class _FeaturedShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHigh,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _GridShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, mainAxisSpacing: 12,
          crossAxisSpacing: 12, childAspectRatio: 0.72,
        ),
        itemCount: 6,
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: AppColors.shimmerBase,
          highlightColor: AppColors.shimmerHigh,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCurveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
