// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

// ─── Profile Screen ──────────────────────────────────────────────────────────

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    final user = authState.user;
    final first = user.name.firstname;
    final last = user.name.lastname;
    final fullName =
        '${first[0].toUpperCase()}${first.substring(1)} ${last[0].toUpperCase()}${last.substring(1)}';

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SafeArea(
        child: ListView(
          children: [
            // 1. Header
            _ProfileHeader(
              fullName: fullName,
              initials: first[0].toUpperCase(),
              onLogout: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  Navigator.of(context).popUntil((r) => r.isFirst);
                }
              },
            ),
            const SizedBox(height: 10),

            // 2. Promo Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(child: _PromoCard.coins()),
                  const SizedBox(width: 10),
                  Expanded(child: _PromoCard.freebie()),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 3. My Orders
            _OrdersCard(),
            const SizedBox(height: 10),

            // 4. Recently Viewed
            _RecentlyViewedCard(),
            const SizedBox(height: 10),

            // 5. Services Grid
            _ServicesGrid(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Header ──────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final String fullName;
  final String initials;
  final VoidCallback onLogout;

  const _ProfileHeader({
    required this.fullName,
    required this.initials,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE0E0E0), width: 2),
              color: const Color(0xFF1A1A2E),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name + Stats
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _InlineStat(value: '33', label: 'Wishlist'),
                    _StatDot(),
                    _InlineStat(value: '8', label: 'Followed Stores'),
                    _StatDot(),
                    _InlineStat(value: '0', label: 'Vouchers'),
                  ],
                ),
              ],
            ),
          ),

          // Settings icon
          GestureDetector(
            onTap: onLogout,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.divider, width: 1.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.settings_outlined,
                  size: 18, color: AppColors.greyText),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  final String value;
  final String label;
  const _InlineStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.darkText,
            ),
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.greyText,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '·',
        style: TextStyle(
          fontSize: 14,
          color: AppColors.orange,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

// ─── Promo Cards ─────────────────────────────────────────────────────────────

class _PromoCard extends StatelessWidget {
  final Color accentColor;
  final Color lightColor;
  final String title;
  final String subtitleBefore;
  final String highlight;
  final String subtitleAfter;
  final String buttonLabel;
  final IconData icon;
  final IconData imageIcon;

  const _PromoCard({
    required this.accentColor,
    required this.lightColor,
    required this.title,
    required this.subtitleBefore,
    required this.highlight,
    this.subtitleAfter = '',
    required this.buttonLabel,
    required this.icon,
    required this.imageIcon,
  });

  factory _PromoCard.coins() => const _PromoCard(
        accentColor: Color(0xFFE67E00),
        lightColor: Color(0xFFFFF3E0),
        title: 'Daraz Coins',
        subtitleBefore: 'Win ',
        highlight: 'Free Gifts',
        subtitleAfter: '\nwith treasure chest',
        buttonLabel: 'Play Now',
        icon: Icons.monetization_on_rounded,
        imageIcon: Icons.generating_tokens_rounded,
      );

  factory _PromoCard.freebie() => const _PromoCard(
        accentColor: Color(0xFF7B2FBE),
        lightColor: Color(0xFFF3E5F5),
        title: 'Daraz Freebie',
        subtitleBefore: 'Invite & Win\n',
        highlight: 'Philips Mixer\nGrinder',
        subtitleAfter: '',
        buttonLabel: 'Play',
        icon: Icons.card_giftcard_rounded,
        imageIcon: Icons.blender_rounded,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area
          Container(
            height: 88,
            decoration: BoxDecoration(
              color: lightColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -14,
                  bottom: -14,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: -18,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.07),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Center(
                  child: Icon(imageIcon, color: accentColor, size: 46),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        title,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Text area
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11, height: 1.4),
                    children: [
                      TextSpan(
                        text: subtitleBefore,
                        style: const TextStyle(color: AppColors.darkText),
                      ),
                      TextSpan(
                        text: highlight,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitleAfter.isNotEmpty)
                        TextSpan(
                          text: subtitleAfter,
                          style: const TextStyle(color: AppColors.greyText),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                    child: Text(buttonLabel),
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

// ─── My Orders ───────────────────────────────────────────────────────────────

class _OrderAction {
  final IconData icon;
  final String label;
  final int badge;
  const _OrderAction(
      {required this.icon, required this.label, this.badge = 0});
}

class _OrdersCard extends StatelessWidget {
  final List<_OrderAction> _actions = const [
    _OrderAction(icon: Icons.account_balance_wallet_outlined, label: 'To Pay'),
    _OrderAction(icon: Icons.local_shipping_outlined, label: 'To Ship'),
    _OrderAction(icon: Icons.move_to_inbox_outlined, label: 'To Receive'),
    _OrderAction(
        icon: Icons.rate_review_outlined, label: 'To Review', badge: 1),
    _OrderAction(
        icon: Icons.assignment_return_outlined,
        label: 'Returns &\nCancellations'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Orders',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.darkText),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Row(
                    children: const [
                      Text('View All Orders',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.greyText)),
                      Icon(Icons.chevron_right_rounded,
                          size: 18, color: AppColors.greyText),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action icons row
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _actions
                  .map((a) => _OrderActionTile(action: a))
                  .toList(),
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),

          // Review prompt banner
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.inventory_2_outlined,
                      color: AppColors.greyText, size: 26),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Review your purchase today!',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: AppColors.darkText)),
                      SizedBox(height: 2),
                      Text('Share your review with others sho...',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.greyText)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    side: const BorderSide(
                        color: AppColors.orange, width: 1.5),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Review Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderActionTile extends StatelessWidget {
  final _OrderAction action;
  const _OrderActionTile({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6A00),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(action.icon, color: Colors.white, size: 22),
                ),
                if (action.badge > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        '${action.badge}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              action.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10, color: AppColors.darkText, height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Recently Viewed ─────────────────────────────────────────────────────────

class _RecentlyViewedCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recently Viewed',
                style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.darkText),
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: const [
                    Text('View More',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.greyText)),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.greyText),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Empty state
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Rediscover the delightful items\nyou've viewed recently!",
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                          height: 1.5),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 9),
                        elevation: 0,
                        textStyle: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      child: const Text('Continue Shopping'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0E8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const Icon(Icons.inventory_2_rounded,
                      size: 56, color: Color(0xFFD4A95A)),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Services Grid ────────────────────────────────────────────────────────────

class _ServiceItem {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  const _ServiceItem(
      {required this.icon,
      required this.label,
      required this.iconColor,
      required this.bgColor});
}

class _ServicesGrid extends StatelessWidget {
  static const List<_ServiceItem> _items = [
    _ServiceItem(
        icon: Icons.celebration_rounded,
        label: 'Daraz Candy',
        iconColor: Colors.white,
        bgColor: Color(0xFFE91E63)),
    _ServiceItem(
        icon: Icons.shopping_bag_rounded,
        label: 'Buy Any 3',
        iconColor: Colors.white,
        bgColor: Color(0xFFBFA000)),
    _ServiceItem(
        icon: Icons.location_on_rounded,
        label: 'Pickup Points',
        iconColor: Colors.white,
        bgColor: Color(0xFFE64A19)),
    _ServiceItem(
        icon: Icons.people_alt_rounded,
        label: 'My Affiliates',
        iconColor: Colors.white,
        bgColor: Color(0xFFE53935)),
    _ServiceItem(
        icon: Icons.help_outline_rounded,
        label: 'Help Center',
        iconColor: Colors.white,
        bgColor: Color(0xFF039BE5)),
    _ServiceItem(
        icon: Icons.headset_mic_rounded,
        label: 'Contact',
        iconColor: Colors.white,
        bgColor: Color(0xFF7B1FA2)),
    _ServiceItem(
        icon: Icons.star_rounded,
        label: 'My Reviews',
        iconColor: Colors.white,
        bgColor: Color(0xFF00897B)),
    _ServiceItem(
        icon: Icons.credit_card_rounded,
        label: 'Payment',
        iconColor: Colors.white,
        bgColor: Color(0xFF1565C0)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 14,
          crossAxisSpacing: 6,
          childAspectRatio: 0.82,
        ),
        itemBuilder: (context, index) {
          final item = _items[index];
          return GestureDetector(
            onTap: () {},
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: item.bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 26),
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.darkText,
                      height: 1.3),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
