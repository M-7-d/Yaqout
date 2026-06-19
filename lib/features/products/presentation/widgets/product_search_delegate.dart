import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/product_entity.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/product_provider.dart';
import 'product_card.dart';
import 'product_list_widgets.dart';

class ProductSearchDelegate extends SearchDelegate {
  ProductSearchDelegate();

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text('Search for products...'));
    }

    return Consumer(
      builder: (context, ref, _) {
        final results = ref.watch(productsProvider(ProductFilter(query: query.trim())));
        return results.when(
          data: (list) => list.isEmpty
              ? ProductEmptyState(
                  message: 'No results found for "$query"',
                  icon: Icons.search_off_rounded,
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) => ProductCard(product: list[i], index: i),
                ),
          loading: () => const ProductGridShimmer(),
          error: (e, _) => Center(child: Text(e.toString())),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return Container(color: AppColors.surface);
    }

    return Consumer(
      builder: (context, ref, _) {
        // Show live results as suggestions
        final results = ref.watch(productsProvider(ProductFilter(query: query.trim())));
        return results.when(
          data: (list) => list.isEmpty
              ? const SizedBox.shrink()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final p = list[i];
                    return ListTile(
                      leading: p.primaryImage.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(p.primaryImage, width: 40, height: 40, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.image_outlined),
                      title: Text(p.title),
                      subtitle: Text('\$${p.price.toStringAsFixed(2)}'),
                      onTap: () {
                        close(context, null);
                        context.push('/products/${p.id}');
                      },
                    );
                  },
                ),
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => const SizedBox.shrink(),
        );
      },
    );
  }
}
