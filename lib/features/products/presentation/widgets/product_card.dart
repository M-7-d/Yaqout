import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/product_entity.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final int index;
  final VoidCallback? onEdit;
  const ProductCard({required this.product, required this.index, this.onEdit, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/products/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                Expanded(
                  child: product.primaryImage.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.primaryImage,
                          errorListener: (_) {},
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (_, __) => _shimmerBox(),
                          errorWidget: (_, __, ___) => _placeholderBox(),
                        )
                      : _placeholderBox(),
                ),
                // Info
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('\$${product.price.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppColors.accent, fontWeight: FontWeight.w800)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: product.inStock
                                  ? AppColors.successLight : AppColors.errorLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              product.inStock ? 'In stock' : 'Sold out',
                              style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600,
                                color: product.inStock
                                    ? AppColors.success : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (onEdit != null)
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 2,
                  child: InkWell(
                    onTap: onEdit,
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.edit_rounded, size: 20, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ).animate().fadeIn(
            delay: Duration(milliseconds: 60 * index),
            duration: 400.ms,
          ),
    );
  }

  Widget _placeholderBox() => Container(
        color: AppColors.shimmerBase,
        child: const Center(
            child: Icon(Icons.image_outlined, color: AppColors.textHint, size: 36)),
      );

  Widget _shimmerBox() => Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHigh,
        child: Container(color: Colors.white),
      );
}
