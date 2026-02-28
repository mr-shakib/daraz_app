import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/tab_constants.dart';
import '../providers/products_provider.dart';
import 'product_card.dart';

/// Renders the product list for the currently selected tab as a set of slivers.
/// This is used inside the single [CustomScrollView] — it must NOT create
/// any nested scrollable.
class ProductSliverList extends ConsumerWidget {
  final int tabIndex;

  const ProductSliverList({super.key, required this.tabIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = kTabCategories[tabIndex];
    final asyncProducts = ref.watch(productsByCategoryProvider(category));

    return asyncProducts.when(
      loading: () => const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      ),

      error: (err, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 52, color: AppColors.greyText),
              const SizedBox(height: 12),
              Text(
                'Failed to load products',
                style: const TextStyle(
                    color: AppColors.greyText, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(
                  productsByCategoryProvider(category),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),

      data: (products) {
        if (products.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Text(
                'No products found.',
                style: TextStyle(color: AppColors.greyText),
              ),
            ),
          );
        }

        // SliverGrid with 2 columns — no nested scrollable.
        // mainAxisExtent gives a fixed row height so all cards align
        // regardless of title length.
        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              // aspect ratio: image (square) + ~118px info area
              // computed as width / totalHeight → tuned for typical screen
              childAspectRatio: 0.60,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => ProductCard(product: products[index]),
              childCount: products.length,
            ),
          ),
        );
      },
    );
  }
}
