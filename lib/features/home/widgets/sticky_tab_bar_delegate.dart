import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/tab_constants.dart';

/// [SliverPersistentHeaderDelegate] that renders the tab bar.
/// When [pinned: true] is used in [SliverPersistentHeader], this becomes
/// the sticky header that remains visible once the SliverAppBar collapses.
/// The tab bar does NOT own any scrollable — it only drives [currentTabIndex].
class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final int currentIndex;
  final ValueChanged<int> onTabChanged;

  const StickyTabBarDelegate({
    required this.currentIndex,
    required this.onTabChanged,
  });

  static const double _height = 48;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(covariant StickyTabBarDelegate old) =>
      old.currentIndex != currentIndex;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: _height,
      // NOTE: color must NOT be set here when decoration is used — Flutter throws
      // an assertion if both are provided. The color lives inside BoxDecoration.
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: List.generate(kTabLabels.length, (i) {
          final isSelected = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTabChanged(i),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    kTabLabels[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? AppColors.pink
                          : AppColors.greyText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Animated selection indicator
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2.5,
                    width: isSelected ? 36 : 0,
                    decoration: BoxDecoration(
                      color: AppColors.pink,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
