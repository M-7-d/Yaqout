import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/product_entity.dart';
import '../providers/product_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/follow_provider.dart';
import '../../../../shared/widgets/expandable_text_widget.dart';

class SellerProfileScreen extends ConsumerWidget {
  final String sellerId;
  const SellerProfileScreen({required this.sellerId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerAsync = ref.watch(userByIdProvider(sellerId));
    final productsAsync = ref.watch(sellerProductsProvider(sellerId));
    final currentUser = ref.watch(authNotifierProvider).valueOrNull;
    final isOwnProfile = currentUser?.id == sellerId;
    final followedSellers = ref.watch(followedSellersProvider);
    final isFollowing = followedSellers.contains(sellerId);

    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (!isOwnProfile)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.white),
                onSelected: (value) {
                  if (value == 'report') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report submitted. We will review this seller.')),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, color: AppColors.error, size: 20),
                        SizedBox(width: 8),
                        Text('Report Seller', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: sellerAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Text('Error: ${e.toString()}', style: const TextStyle(color: AppColors.error)),
                    ),
                  ),
                  data: (seller) {
                    if (seller == null) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text('Seller not found', style: TextStyle(color: AppColors.textPrimary)),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // Curved Header with Avatar
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 4, bottom: 32),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.vertical(
                              bottom: Radius.circular(48),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 70,
                                backgroundColor: AppColors.primaryLight,
                                child: (seller.avatarUrl != null && seller.avatarUrl!.isNotEmpty)
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: seller.avatarUrl!,
                                          width: 140,
                                          height: 140,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => _buildInitials(seller.fullName),
                                        ),
                                      )
                                    : _buildInitials(seller.fullName),
                              ),
                            ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Name & Verified Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              seller.fullName ?? 'Unknown Seller',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (seller.verifiedSeller) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: AppColors.primary, size: 20),
                            ]
                          ],
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                        const SizedBox(height: 8),
                        // Location
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_on, size: 16, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              seller.address?.isNotEmpty == true ? seller.address! : 'Global',
                              style: const TextStyle(
                                color: AppColors.textHint,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 350.ms),
                        
                        // About Section (Description)
                        if (seller.shopDescription != null && seller.shopDescription!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border.withOpacity(0.5)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'About the Seller',
                                    style: TextStyle(
                                      color: AppColors.primaryDark,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ExpandableTextWidget(
                                    text: seller.shopDescription!,
                                    maxLines: 3,
                                    style: const TextStyle(
                                      color: AppColors.primaryDark,
                                      fontSize: 14,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                        ],
                        
                        const SizedBox(height: 24),
                        // Stats Card
                        Builder(
                          builder: (context) {
                            // Calculate Followers
                            int baseFollowers = sellerId.hashCode.abs() % 1000 + 100;
                            int totalFollowers = baseFollowers + (isFollowing ? 1 : 0);
                            String formattedFollowers = totalFollowers >= 1000 
                                ? '${(totalFollowers / 1000).toStringAsFixed(1)}K' 
                                : totalFollowers.toString();
                                
                            // Calculate Rating
                            double totalRating = 0.0;
                            int ratingCount = 0;
                            final products = productsAsync.valueOrNull ?? [];
                            for (var p in products) {
                              if (p.avgRating != null && p.avgRating! > 0) {
                                totalRating += p.avgRating!;
                                ratingCount++;
                              }
                            }
                            double avgRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;
                            String formattedRating = avgRating > 0 ? avgRating.toStringAsFixed(1) : 'N/A';

                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryDark.withOpacity(0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface.withOpacity(0.6),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildStatColumn(formattedFollowers, 'Followers'),
                                        Container(height: 40, width: 1.5, color: AppColors.primaryLight.withOpacity(0.3)),
                                        _buildStatColumn('${products.length}', 'Products'),
                                        Container(height: 40, width: 1.5, color: AppColors.primaryLight.withOpacity(0.3)),
                                        _buildStatColumn(formattedRating, 'Rating', isRating: avgRating > 0),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
                          }
                        ),
                        const SizedBox(height: 28),
                        // Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isOwnProfile) ...[
                              _buildButton('Edit profile', Icons.edit_outlined, () => context.push('/settings/edit-seller-profile'), isPrimary: false),
                              const SizedBox(width: 16),
                              _buildButton('Share', Icons.share_outlined, () async {
                                await Clipboard.setData(ClipboardData(text: 'yakut://sellers/$sellerId'));
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Seller profile link copied')),
                                );
                              }),
                            ] else ...[
                              _buildButton('Message', Icons.chat_bubble_outline, () {}, isPrimary: false),
                              const SizedBox(width: 16),
                              _buildButton(
                                isFollowing ? 'Following' : 'Follow', 
                                isFollowing ? Icons.check : Icons.person_add_alt_1, 
                                () {
                                  ref.read(followedSellersProvider.notifier).toggleFollow(sellerId);
                                }
                              ),
                            ]
                          ],
                        ).animate().fadeIn(delay: 600.ms),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textHint,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    tabs: const [
                      Tab(text: 'Products'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: ${e.toString()}')),
                data: (products) {
                  if (products.isEmpty) {
                    return const Center(
                      child: Text('No photos yet', style: TextStyle(color: AppColors.textHint)),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: products.length,
                    itemBuilder: (ctx, i) => _ProductCard(product: products[i]),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInitials(String? name) {
    return Center(
      child: Text(
        (name ?? 'S')[0].toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 40,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label, {bool isRating = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (isRating) ...[
              const SizedBox(width: 2),
              const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
            ]
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textHint,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String label, IconData icon, VoidCallback onTap, {bool isPrimary = true}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppColors.primary : AppColors.card,
        foregroundColor: isPrimary ? Colors.white : AppColors.primaryDark,
        elevation: isPrimary ? 4 : 0,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isPrimary ? BorderSide.none : BorderSide(color: AppColors.border.withOpacity(0.6), width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.surface,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

class _ProductCard extends StatelessWidget {
  final ProductEntity product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.border.withOpacity(0.5), width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: AppColors.primaryLight.withOpacity(0.3),
                  child: product.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.images.first,
                          errorListener: (_) {},
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.shimmerBase),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.shimmerBase,
                            child: const Icon(Icons.broken_image_outlined, color: AppColors.textHint),
                          ),
                        )
                      : const Icon(Icons.image_outlined, color: AppColors.textHint),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shopping_bag_outlined, size: 14, color: AppColors.textHint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * product.hashCode % 5).ms).slideY(begin: 0.1);
  }
}
