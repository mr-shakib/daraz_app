import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const List<_MockCartItem> _items = [
    _MockCartItem(
      name: 'Wireless Noise Cancelling Headphones',
      price: 'PKR 8,500',
      originalPrice: 'PKR 12,000',
      discount: '29%',
      icon: Icons.headphones_rounded,
      iconColor: Color(0xFF1976D2),
      iconBg: Color(0xFFE3F2FD),
      qty: 1,
    ),
    _MockCartItem(
      name: 'Smart Watch Series 6 — Black',
      price: 'PKR 15,900',
      originalPrice: 'PKR 22,000',
      discount: '28%',
      icon: Icons.watch_rounded,
      iconColor: Color(0xFF424242),
      iconBg: Color(0xFFF5F5F5),
      qty: 1,
    ),
    _MockCartItem(
      name: 'Men\'s Slim Fit Casual Jacket',
      price: 'PKR 3,200',
      originalPrice: 'PKR 4,800',
      discount: '33%',
      icon: Icons.checkroom_rounded,
      iconColor: AppColors.orange,
      iconBg: AppColors.orangeLight,
      qty: 2,
    ),
  ];

  int get _totalItems =>
      _items.fold(0, (sum, item) => sum + item.qty);

  String get _subtotal {
    final amounts = [8500, 15900, 6400]; // qty-adjusted
    final total = amounts.fold<int>(0, (a, b) => a + b);
    return 'PKR ${_formatNum(total)}';
  }

  String _formatNum(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    return '${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'My Cart',
              style: TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$_totalItems items',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: Column(
        children: [
          // ── Cart items ─────────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) =>
                  _CartTile(item: _items[index]),
            ),
          ),

          // ── Order summary ──────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.greyText)),
                    Text(_subtotal,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkText)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Shipping',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.greyText)),
                    Text('FREE',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF388E3C))),
                  ],
                ),
                const Divider(height: 20, color: AppColors.divider),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkText)),
                    Text(_subtotal,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange)),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('Proceed to Checkout'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Cart Tile ────────────────────────────────────────────────────────────

class _CartTile extends StatelessWidget {
  final _MockCartItem item;
  const _CartTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
        ],
      ),
      child: Row(
        children: [
          // Icon thumbnail
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: item.iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 32),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(item.price,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange)),
                    const SizedBox(width: 6),
                    Text(
                      item.originalPrice,
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.greyText,
                          decoration: TextDecoration.lineThrough),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.pink,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '-${item.discount}',
                        style: const TextStyle(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Qty chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.divider),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Qty: ${item.qty}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.darkText),
                      ),
                    ),
                    const Spacer(),
                    // Delete icon
                    Icon(Icons.delete_outline_rounded,
                        color: AppColors.greyText, size: 18),
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

class _MockCartItem {
  final String name;
  final String price;
  final String originalPrice;
  final String discount;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final int qty;

  const _MockCartItem({
    required this.name,
    required this.price,
    required this.originalPrice,
    required this.discount,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.qty,
  });
}
