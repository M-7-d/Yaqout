import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/product_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/product_list_widgets.dart';

class ManageProductsScreen extends ConsumerWidget {
  const ManageProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage My Products'),
        actions: [
          IconButton(
            onPressed: () => context.push('/products/new'),
            icon: const Icon(Icons.add_rounded, size: 28),
            tooltip: 'Add Product',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
        ),
        child: user == null
            ? const ProductEmptyState(
                message: 'Please login to manage your products',
                icon: Icons.account_circle_outlined,
              )
            : _MyProductsList(userId: user.id),
      ),
    );
  }
}

class _MyProductsList extends ConsumerWidget {
  final String userId;
  const _MyProductsList({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(sellerProductsProvider(userId));
    
    return results.when(
      data: (list) => list.isEmpty
          ? ProductEmptyState(
              message: 'You haven\'t listed any products yet.',
              icon: Icons.add_business_outlined,
              actionLabel: 'List a Product',
              onAction: () => context.push('/products/new'),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: list.length,
              itemBuilder: (ctx, i) => ProductCard(
                product: list[i],
                index: i,
                onEdit: () => context.push('/products/${list[i].id}/edit'),
              ),
            ).animate().fadeIn(duration: 400.ms),
      loading: () => const ProductGridShimmer(),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }
}
