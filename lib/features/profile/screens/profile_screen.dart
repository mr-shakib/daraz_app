import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    final user = authState.user;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
              }
            },
            icon: const Icon(Icons.logout_rounded,
                color: Colors.white, size: 18),
            label: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // ── Avatar & Name ──────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.orange,
                  child: Text(
                    user.name.firstname[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user.username}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ── Info Card ──────────────────────────────────────────────────
          _InfoCard(
            title: 'Contact',
            items: [
              _InfoItem(
                icon: Icons.email_outlined,
                label: 'Email',
                value: user.email,
              ),
              _InfoItem(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: user.phone,
              ),
            ],
          ),

          const SizedBox(height: 12),

          _InfoCard(
            title: 'Address',
            items: [
              _InfoItem(
                icon: Icons.location_on_outlined,
                label: 'Location',
                value: user.address.formatted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Reusable info card ────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoItem> items;

  const _InfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.orange,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          ...items.map(
            (item) => ListTile(
              leading: Icon(item.icon, color: AppColors.orange, size: 22),
              title: Text(
                item.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.greyText,
                ),
              ),
              subtitle: Text(
                item.value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.darkText,
                  fontWeight: FontWeight.w500,
                ),
              ),
              dense: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}
