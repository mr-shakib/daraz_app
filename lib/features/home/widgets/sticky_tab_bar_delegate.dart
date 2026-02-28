import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/tab_constants.dart';

/// [SliverPersistentHeaderDelegate] that renders the tab bar.
/// When [pinned: true] is used in [SliverPersistentHeader], this becomes
/// the sticky header that remains visible once the SliverAppBar collapses.
///
/// The tab bar is driven by a continuous [tabPosition] (double) rather than
/// a discrete integer so that the indicator and label colours update in
/// real-time as the user drags between tabs.
///
/// Examples:
///   0.0   → fully on tab 0
///   0.5   → halfway between tab 0 and tab 1
///   1.0   → fully on tab 1
///   1.75  → 75 % of the way from tab 1 toward tab 2
class StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  /// Continuous tab position. Can be fractional during a swipe gesture.
  final double tabPosition;
  final ValueChanged<int> onTabChanged;

  const StickyTabBarDelegate({
    required this.tabPosition,
    required this.onTabChanged,
  });

  static const double _height = 48;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  bool shouldRebuild(covariant StickyTabBarDelegate old) =>
      old.tabPosition != tabPosition;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: _height,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Row(
        children: List.generate(kTabLabels.length, (i) {
          // How "selected" is tab i, as a value between 0.0 and 1.0?
          //   1.0 → the indicator is exactly here
          //   0.5 → the finger is halfway between this tab and a neighbour
          //   0.0 → fully deselected
          final distance = (i - tabPosition).abs();
          final selectionFraction = (1.0 - distance).clamp(0.0, 1.0);

          final labelColor = Color.lerp(
            AppColors.greyText,
            AppColors.pink,
            selectionFraction,
          )!;

          final fontWeight = selectionFraction > 0.5
              ? FontWeight.w700
              : FontWeight.w500;

          // Indicator width scales from 0 (fully deselected) to 36 (fully
          // selected) proportionally to [selectionFraction].
          const double maxIndicatorWidth = 36.0;
          final indicatorWidth = selectionFraction * maxIndicatorWidth;

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
                      fontWeight: fontWeight,
                      color: labelColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Selection indicator — width and colour follow the gesture
                  // in real time; no AnimatedContainer needed.
                  Container(
                    height: 2.5,
                    width: indicatorWidth,
                    decoration: BoxDecoration(
                      color: AppColors.pink
                          .withValues(alpha: selectionFraction),
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
