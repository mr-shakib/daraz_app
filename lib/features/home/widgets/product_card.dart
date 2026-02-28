import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  // ── Derived display values ─────────────────────────────────────────────
  // FakeStore has no discount data — derive a deterministic fake discount
  // so the UI looks realistic. Uses product.id so it's stable across rebuilds.
  int get _discountPercent => ((product.id % 5) + 1) * 10; // 10–50 %
  double get _originalPrice => product.price / (1 - _discountPercent / 100);
  int get _coinsSave => (product.price * 0.03).round().clamp(1, 999);
  bool get _hasFreeDelivery => product.id % 3 != 0;
  bool get _hasCoins => product.id % 2 == 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image + overlaid delivery/coin badges ─────────────────
          Stack(
            children: [
              // Full-width square image
              AspectRatio(
                aspectRatio: 1,
                child: CachedNetworkImage(
                  imageUrl: product.image,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: AppColors.lightGrey,
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.lightGrey,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.greyText,
                    ),
                  ),
                ),
              ),

              // Bottom-left badges row
              if (_hasFreeDelivery || _hasCoins)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    children: [
                      if (_hasFreeDelivery)
                        _Badge(
                          label: 'FREE DELIVERY',
                          color: const Color(0xFF00A84F),
                        ),
                      if (_hasCoins)
                        _Badge(
                          label: 'COINS',
                          color: const Color(0xFFFFB700),
                          textColor: AppColors.darkText,
                        ),
                    ],
                  ),
                ),

              // Top-right discount badge
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: const BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                  child: Text(
                    '-$_discountPercent%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Product info ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title — always 2 lines to keep grid rows aligned
                Text(
                  product.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.darkText,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),

                // Price + original price strikethrough
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '\$${_originalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.greyText,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Coins save
                if (_hasCoins)
                  Text(
                    'Coins save \$$_coinsSave',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (_hasCoins) const SizedBox(height: 3),

                // Star rating
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 13, color: AppColors.star),
                    const SizedBox(width: 2),
                    Text(
                      '${product.rating.rate.toStringAsFixed(1)} '
                      '(${product.rating.count})',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.greyText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small overlay badge ─────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _Badge({
    required this.label,
    required this.color,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      color: color,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
