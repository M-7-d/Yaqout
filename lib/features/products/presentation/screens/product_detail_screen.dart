import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';
import '../../../reviews/presentation/providers/review_provider.dart';
import '../../../reviews/presentation/widgets/write_review_widget.dart';
import '../../../../shared/widgets/expandable_text_widget.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({required this.productId, super.key});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _imageIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ProductDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.productId != widget.productId) {
      _imageIndex = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  void _openChatAboutProduct(UserEntity? buyer, ProductEntity p) {
    if (buyer == null) return;
    context.push(
      '/chat/new?sellerId=${p.sellerId}&buyerId=${buyer.id}&productId=${p.id}',
    );
  }

  Future<void> _confirmRemoveProduct(ProductEntity p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove product?'),
        content: const Text(
          'This permanently deletes the listing. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await ref.read(productRepositoryProvider).deleteProduct(p.id);
      ref.invalidate(productDetailProvider(p.id));
      ref.invalidate(productsProvider);
      ref.invalidate(featuredProductsProvider);
      ref.invalidate(sellerProductsProvider(p.sellerId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product removed')),
      );
      context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = ref.watch(productDetailProvider(widget.productId));
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return product.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(e.toString())),
      ),
      data: (p) {
        final images = p.images;
        final n = images.length;
        final idx = n == 0 ? 0 : _imageIndex.clamp(0, n - 1);
        if (n > 0 && idx != _imageIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _imageIndex = idx);
            if (n > 1 && _pageController.hasClients) {
              _pageController.jumpToPage(idx);
            }
          });
        }

        final currentUrl = n == 0 ? '' : images[idx];
        final canMessageSeller =
            user != null && user.id != p.sellerId;
        final isOwnerOrAdmin = user != null &&
            (user.id == p.sellerId || user.isAdmin);

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                iconTheme: const IconThemeData(color: Colors.white),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  if (isOwnerOrAdmin) ...[
                    IconButton(
                      tooltip: 'Edit product',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () =>
                          context.push('/products/${p.id}/edit'),
                    ),
                    IconButton(
                      tooltip: 'Remove product',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _confirmRemoveProduct(p),
                    ),
                  ],
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (n > 1)
                        PageView.builder(
                          controller: _pageController,
                          onPageChanged: (i) =>
                              setState(() => _imageIndex = i),
                          itemCount: n,
                          itemBuilder: (ctx, i) => CachedNetworkImage(
                            imageUrl: images[i],
                            errorListener: (_) {},
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: AppColors.shimmerBase),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.shimmerBase,
                              child: const Icon(Icons.broken_image_outlined,
                                  color: AppColors.textHint, size: 48),
                            ),
                          ),
                        )
                      else if (currentUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: currentUrl,
                          errorListener: (_) {},
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.shimmerBase),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.shimmerBase,
                            child: const Icon(Icons.broken_image_outlined,
                                color: AppColors.textHint, size: 48),
                          ),
                        )
                      else
                        Container(
                          color: AppColors.primaryLight,
                          child: const Icon(Icons.image_outlined,
                              size: 80, color: AppColors.textHint),
                        ),
                      if (n > 1)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 12,
                          child: IgnorePointer(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                images.length,
                                (i) => Container(
                                  width: i == idx ? 8 : 6,
                                  height: i == idx ? 8 : 6,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == idx
                                        ? Colors.white
                                        : Colors.white38,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              if (n > 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        itemCount: images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (ctx, i) {
                          final selected = i == idx;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                i,
                                duration: const Duration(milliseconds: 280),
                                curve: Curves.easeOutCubic,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: selected ? 2.5 : 1,
                                ),
                                boxShadow: selected
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.25),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: CachedNetworkImage(
                                imageUrl: images[i],
                                errorListener: (_) {},
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: AppColors.shimmerBase,
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.shimmerBase,
                                  child: const Icon(
                                      Icons.broken_image_outlined,
                                      size: 20),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(p.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge),
                          ),
                          const SizedBox(width: 12),
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

                      if (p.avgRating != null && p.avgRating! > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              p.avgRating!.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            if (p.reviewCount != null && p.reviewCount! > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${p.reviewCount} reviews)',
                                style: const TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: p.inStock
                              ? AppColors.successLight
                              : AppColors.errorLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          p.inStock
                              ? '${p.stock} in stock'
                              : 'Stock is empty (Finished)',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: p.inStock
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      if (p.sellerName != null)
                        GestureDetector(
                          onTap: () => context.push('/sellers/${p.sellerId}'),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primaryLight,
                              child: (p.sellerAvatar != null && p.sellerAvatar!.isNotEmpty)
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: p.sellerAvatar!,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          width: 36,
                                          height: 36,
                                          color: AppColors.shimmerBase,
                                        ),
                                        errorWidget: (_, __, ___) => Center(
                                          child: Text(
                                            (p.sellerName ?? 'S')[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      (p.sellerName ?? 'S')[0].toUpperCase(),
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700),
                                    ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Sold by',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall),
                                  Text(p.sellerName!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium),
                                ],
                              ),
                            ],
                          ),
                        ),

                      const Divider(height: 36),

                      if (p.description != null) ...[
                        Text('Description',
                            style:
                                Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 10),
                        ExpandableTextWidget(
                          text: p.description!,
                          maxLines: 4,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppColors.textSecond),
                        ),
                      ],

                      const Divider(height: 36),

                      // Reviews & Ratings Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Reviews & Ratings',
                              style: Theme.of(context).textTheme.headlineSmall),
                          if (p.avgRating != null && p.avgRating! > 0)
                            Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.orange, size: 22),
                                const SizedBox(width: 4),
                                Text(
                                  p.avgRating!.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                                const Text(
                                  ' / 5.0',
                                  style: TextStyle(
                                    color: AppColors.textHint,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      ref.watch(productReviewsProvider(p.id)).when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, _) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Error loading reviews: $err',
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                        data: (reviews) {
                          final hasReviewed = user != null &&
                              reviews.any((r) => r.reviewerId == user.id);
                          final canWriteReview = user != null &&
                              user.isBuyer &&
                              user.id != p.sellerId &&
                              !hasReviewed;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (reviews.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'No reviews yet. Be the first to review this product!',
                                      style: TextStyle(
                                        color: AppColors.textHint,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: reviews.length,
                                  separatorBuilder: (_, __) =>
                                      const Divider(height: 24),
                                  itemBuilder: (ctx, idx) {
                                    final review = reviews[idx];
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: AppColors.primaryLight,
                                              backgroundImage: (review.reviewerAvatar != null &&
                                                      review.reviewerAvatar!.isNotEmpty)
                                                  ? CachedNetworkImageProvider(
                                                      review.reviewerAvatar!)
                                                  : null,
                                              child: (review.reviewerAvatar == null ||
                                                      review.reviewerAvatar!.isEmpty)
                                                  ? Text(
                                                      (review.reviewerName ?? 'B')[0]
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                        color: AppColors.primary,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    review.reviewerName ??
                                                        'Anonymous Buyer',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: AppColors.primaryDark,
                                                    ),
                                                  ),
                                                  Text(
                                                    DateFormat('MMM dd, yyyy')
                                                        .format(review.createdAt),
                                                    style: const TextStyle(
                                                      color: AppColors.textHint,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Row(
                                              children: List.generate(5, (sIdx) {
                                                return Icon(
                                                  sIdx < review.rating
                                                      ? Icons.star_rounded
                                                      : Icons.star_border_rounded,
                                                  color: Colors.orange,
                                                  size: 16,
                                                );
                                              }),
                                            ),
                                          ],
                                        ),
                                        if (review.comment != null &&
                                            review.comment!.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 42),
                                            child: Text(
                                              review.comment!,
                                              style: const TextStyle(
                                                color: AppColors.textSecond,
                                                height: 1.4,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              if (canWriteReview) ...[
                                const SizedBox(height: 32),
                                WriteReviewWidget(
                                  productId: p.id,
                                  sellerId: p.sellerId,
                                  reviewerId: user.id,
                                  onReviewSubmitted: () {
                                    ref.invalidate(productDetailProvider(p.id));
                                  },
                                ),
                              ],
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ),
            ],
          ),

          bottomNavigationBar: canMessageSeller
              ? Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    border: Border(
                        top: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.forum_outlined),
                          label: const Text('Message seller'),
                          onPressed: () => _openChatAboutProduct(user, p),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        );
      },
    );
  }
}
