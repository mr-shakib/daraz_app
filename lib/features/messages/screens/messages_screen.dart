import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  static const List<_MockMessage> _messages = [
    _MockMessage(
      sender: 'Daraz Express',
      preview: 'Your order has been dispatched. Track it now!',
      time: '10:24 AM',
      unread: 2,
      icon: Icons.local_shipping_outlined,
      iconColor: Color(0xFF1976D2),
      iconBg: Color(0xFFE3F2FD),
    ),
    _MockMessage(
      sender: 'Flash Sale Alert',
      preview: 'Up to 70% off on Electronics — ends in 3 hours!',
      time: '9:10 AM',
      unread: 1,
      icon: Icons.bolt_rounded,
      iconColor: Color(0xFFFF9800),
      iconBg: Color(0xFFFFF3E0),
    ),
    _MockMessage(
      sender: 'Daraz Mall',
      preview: 'Thank you for your purchase. Rate your experience.',
      time: 'Yesterday',
      unread: 0,
      icon: Icons.storefront_outlined,
      iconColor: AppColors.pink,
      iconBg: Color(0xFFFCE4EC),
    ),
    _MockMessage(
      sender: 'Voucher Center',
      preview: 'You have 2 unclaimed vouchers expiring soon.',
      time: 'Yesterday',
      unread: 0,
      icon: Icons.confirmation_number_outlined,
      iconColor: Color(0xFF7B2FBE),
      iconBg: Color(0xFFF3E5F5),
    ),
    _MockMessage(
      sender: 'Seller: TechZone PK',
      preview: 'Hi! Your item is ready for pickup.',
      time: 'Mon',
      unread: 0,
      icon: Icons.headphones_outlined,
      iconColor: Color(0xFF00897B),
      iconBg: Color(0xFFE0F2F1),
    ),
    _MockMessage(
      sender: 'Daraz Wallet',
      preview: 'PKR 500 Daraz Cash credited to your account.',
      time: 'Mon',
      unread: 0,
      icon: Icons.account_balance_wallet_outlined,
      iconColor: Color(0xFF388E3C),
      iconBg: Color(0xFFE8F5E9),
    ),
    _MockMessage(
      sender: 'Order #3821065',
      preview: 'Your return request has been approved.',
      time: 'Sun',
      unread: 0,
      icon: Icons.assignment_return_outlined,
      iconColor: AppColors.orange,
      iconBg: AppColors.orangeLight,
    ),
    _MockMessage(
      sender: 'Daraz Support',
      preview: 'How can we help you today? Tap to chat.',
      time: 'Sun',
      unread: 0,
      icon: Icons.support_agent_rounded,
      iconColor: Color(0xFF039BE5),
      iconBg: Color(0xFFE1F5FE)),
  ];

  @override
  Widget build(BuildContext context) {
    final total = _messages.fold<int>(0, (sum, m) => sum + m.unread);
    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              'Messages',
              style: TextStyle(
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
            if (total > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.pink,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$total',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all_rounded,
                color: AppColors.greyText, size: 22),
            onPressed: () {},
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.divider),
        ),
      ),
      body: ListView.separated(
        itemCount: _messages.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 76, color: AppColors.divider),
        itemBuilder: (context, index) {
          final msg = _messages[index];
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: msg.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(msg.icon, color: msg.iconColor, size: 22),
                ),
                if (msg.unread > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                          color: AppColors.pink, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        '${msg.unread}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  msg.sender,
                  style: TextStyle(
                    fontWeight: msg.unread > 0
                        ? FontWeight.w700
                        : FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.darkText,
                  ),
                ),
                Text(msg.time,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.greyText)),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                msg.preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: msg.unread > 0
                      ? AppColors.darkText
                      : AppColors.greyText,
                ),
              ),
            ),
            onTap: () {},
          );
        },
      ),
    );
  }
}

class _MockMessage {
  final String sender;
  final String preview;
  final String time;
  final int unread;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _MockMessage({
    required this.sender,
    required this.preview,
    required this.time,
    required this.unread,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}
