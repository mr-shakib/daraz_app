import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/tab_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../profile/screens/profile_screen.dart';
import '../providers/products_provider.dart';
import '../providers/tab_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/sticky_tab_bar_delegate.dart';

// ─── Architecture Notes ────────────────────────────────────────────────────
//
// VERTICAL SCROLL OWNERSHIP:
//   A single [CustomScrollView] owns the entire vertical scroll axis.
//   There is no [TabBarView], no [PageView], no nested [ListView].
//   The [ScrollController] is created once at this level and never recreated,
//   so scroll position is preserved across tab changes.
//
// HORIZONTAL SWIPE:
//   A [GestureDetector] wraps the [CustomScrollView] and listens only to
//   [onHorizontalDragEnd]. Because Flutter's gesture arena resolves
//   conflicts by axis, the vertical scroll continues to be handled by
//   [CustomScrollView] unimpeded. The horizontal drag is intercepted here
//   and translated into a tab index change.
//
// TAB SWITCHING & SCROLL POSITION:
//   Switching tabs only updates [currentTabProvider] (for the tab bar) and
//   [_displayedTabIndex] (for the grid content) at the right time.
//   The [CustomScrollView] and its [ScrollController] are never touched,
//   so scroll offset is preserved exactly.
//
// TAB TRANSITION ANIMATION:
//   A phase-based [AnimationController] ensures only ONE [_TabGridContent]
//   is ever in the widget tree at a time:
//     Phase 1 (reverse 1→0): current content fades + slides out.
//     Phase 2 (setState):    _displayedTabIndex swaps.
//     Phase 3 (forward 0→1): new content fades + slides in.
//   [Transform.translate] is paint-only — it never affects the layout
//   geometry of the [SliverToBoxAdapter], so the sliver heights and the
//   scroll position are completely stable during animation (zero jitter).
//   [ClipRect] confines the paint to the content bounds so the sliding
//   content never bleeds over the pinned tab bar above.
//
// PULL TO REFRESH:
//   [RefreshIndicator] wraps the single [CustomScrollView]. Since there is
//   only one scrollable, it correctly intercepts the overscroll gesture from
//   any tab.
//
// TRADE-OFFS:
//   • No animated page-slide transition when switching tabs — accepted to
//     avoid the scroll-conflict introduced by [PageView].
//   • Scroll position is shared across tabs (not per-tab independent offsets).
//     The requirement says "must not reset/jump", which this satisfies.
//     Per-tab independent offsets would require multiple [ScrollController]s
//     and multiple scrollables — violating the single-scrollable constraint.
// ───────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// The single [ScrollController] for the entire screen.
  /// Created once; never reassigned so scroll position is never reset.
  late final ScrollController _scrollController;

  /// Drives the exit/enter animation for tab content.
  /// reverse() = exit (1→0), forward() = enter (0→1).
  late final AnimationController _tabAnim;

  // Collapsed / expanded extents for the SliverAppBar
  static const double _expandedHeight = 160.0;

  /// The tab whose data is currently rendered in the GridView.
  /// This is intentionally SEPARATE from [currentTabProvider] so that the
  /// tab bar indicator snaps immediately while the content animates.
  int _displayedTabIndex = 0;

  /// Whether the current animation phase is an enter (true) or exit (false).
  bool _isAnimatingIn = false;

  /// The direction of the current/last tab transition.
  bool _isGoingForward = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabAnim = AnimationController(
      vsync: this,
      // Each phase (exit or enter) is 160 ms — total visual transition ~320 ms.
      duration: const Duration(milliseconds: 160),
      value: 1.0, // start fully visible
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabAnim.dispose();
    super.dispose();
  }

  // ─── Tab navigation helpers ─────────────────────────────────────────────

  Future<void> _goToTab(int index) async {
    if (index < 0 || index >= kTabCategories.length) return;
    if (index == _displayedTabIndex) return;
    // Ignore rapid taps while an animation is running.
    if (_tabAnim.isAnimating) return;

    _isGoingForward = index > _displayedTabIndex;

    // Snap the tab bar indicator to the new tab immediately (good UX).
    ref.read(currentTabProvider.notifier).state = index;

    // ── Phase 1: animate content OUT ─────────────────────────────────────
    _isAnimatingIn = false;
    await _tabAnim.reverse(); // 1.0 → 0.0

    // ── Phase 2: swap data (single setState, no extra frames) ────────────
    setState(() => _displayedTabIndex = index);

    // ── Phase 3: animate NEW content IN ──────────────────────────────────
    _isAnimatingIn = true;
    await _tabAnim.forward(); // 0.0 → 1.0
  }

  void _nextTab() => _goToTab(ref.read(currentTabProvider) + 1);
  void _prevTab() => _goToTab(ref.read(currentTabProvider) - 1);

  // ─── Pull-to-refresh ────────────────────────────────────────────────────

  Future<void> _onRefresh() async {
    final category = kTabCategories[_displayedTabIndex];
    ref.invalidate(productsByCategoryProvider(category));
    await ref.read(productsByCategoryProvider(category).future);
  }

  @override
  Widget build(BuildContext context) {
    // currentTabProvider is watched only to keep the tab bar indicator in sync.
    final currentTab = ref.watch(currentTabProvider);
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SafeArea(
        child: _HorizontalSwipeDetector(
          onSwipeLeft: _nextTab,
          onSwipeRight: _prevTab,
          // 300 px/s velocity + 40 px travel both required → intentional swipes only
          velocityThreshold: 300.0,
          distanceThreshold: 40.0,
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.orange,
            child: CustomScrollView(
              // ── Single vertical scroll owner ─────────────────────────────
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── 1. Collapsible AppBar ──────────────────────────────────
                // pinned:true keeps the search bar visible after collapse.
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  snap: false,
                  expandedHeight: _expandedHeight,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  toolbarHeight: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: _BannerContent(
                      username: user?.name.firstname ?? '',
                      onProfileTap: user == null
                          ? null
                          : () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfileScreen(),
                                ),
                              ),
                    ),
                  ),
                  // This PreferredSize widget is what remains visible when
                  // the header is fully collapsed — search bar is always shown.
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(58),
                    child: _SearchBar(),
                  ),
                ),

                // ── 2. Sticky Tab Bar ──────────────────────────────────────
                // pinned:true → locks to top once SliverAppBar is collapsed.
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyTabBarDelegate(
                    currentIndex: currentTab,
                    onTabChanged: _goToTab,
                  ),
                ),

                // ── 3. Animated product grid ───────────────────────────────
                //
                // KEY INVARIANT: only ONE GridView is ever in the tree.
                //
                // [AnimatedBuilder] rebuilds only on animation ticks.
                // [Transform.translate] is paint-only — it does NOT affect
                // layout or the measured height of the SliverToBoxAdapter,
                // so the scroll position and sliver geometry are never
                // disturbed during the transition.
                //
                // [Opacity] widget is used here intentionally (not
                // [FadeTransition]) because we control the animation phases
                // manually and need exact opacity values.
                SliverToBoxAdapter(
                  child: ClipRect(
                    // ClipRect prevents the sliding content from painting
                    // outside the SliverToBoxAdapter bounds (i.e. over the
                    // pinned tab bar or outside the screen edges).
                    child: AnimatedBuilder(
                    animation: _tabAnim,
                    // child is rebuilt only when _displayedTabIndex changes
                    // (i.e. in Phase 2), not on every animation frame.
                    child: _TabGridContent(tabIndex: _displayedTabIndex),
                    builder: (context, child) {
                      final val = _tabAnim.value; // 0.0 → 1.0

                      // Compute horizontal offset.
                      // Transform.translate is paint-only: layout height is
                      // always the final GridView height → zero layout jitter.
                      final Offset offset;
                      if (_isAnimatingIn) {
                        // Enter: new content slides in from the appropriate edge.
                        offset = _isGoingForward
                            ? Offset((1.0 - val) * screenWidth, 0)
                            : Offset(-(1.0 - val) * screenWidth, 0);
                      } else {
                        // Exit: current content slides out to the appropriate edge.
                        // val goes 1→0 during reverse(), so (1-val) goes 0→1.
                        offset = _isGoingForward
                            ? Offset(-(1.0 - val) * screenWidth, 0)
                            : Offset((1.0 - val) * screenWidth, 0);
                      }

                      return Opacity(
                        opacity: val.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: offset,
                          child: child,
                        ),
                      );
                    },
                  ),
                  ), // ClipRect
                ), // SliverToBoxAdapter
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Horizontal swipe detector ─────────────────────────────────────────────
//
// Design decisions:
//
// 1. AXIS ISOLATION
//    [GestureDetector] here ONLY handles the horizontal drag recognizer.
//    Flutter's gesture arena uses axis-first disambiguation:
//      • Vertical component moves > kTouchSlop first → [CustomScrollView] wins,
//        horizontal drag recognizer is rejected → no swipe fires ✓
//      • Horizontal component moves > kTouchSlop first → this detector wins,
//        vertical scroll recognizer is rejected → no scroll fires ✓
//    The two axes can never both activate simultaneously.
//
// 2. INTENTIONAL SWIPE GATE (dual threshold)
//    A swipe is only registered when BOTH conditions are met:
//      a) primaryVelocity  ≥ [velocityThreshold]  (fast enough)
//      b) |horizontal travel| ≥ [distanceThreshold] (far enough)
//    This eliminates accidental micro-swipes and high-velocity taps.
//
// 3. HitTestBehavior.translucent
//    Child widgets (product cards, tab bar taps) still receive all hit-tests.
//    This detector does NOT block tap events from reaching descendants.

class _HorizontalSwipeDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final double velocityThreshold;
  /// Minimum horizontal travel (px) required to count as a swipe.
  final double distanceThreshold;

  const _HorizontalSwipeDetector({
    required this.child,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.velocityThreshold,
    required this.distanceThreshold,
  });

  @override
  State<_HorizontalSwipeDetector> createState() =>
      _HorizontalSwipeDetectorState();
}

class _HorizontalSwipeDetectorState extends State<_HorizontalSwipeDetector> {
  double? _dragStartX;
  double _dragCurrentX = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,

      // Record the start position so we can measure travel distance.
      onHorizontalDragStart: (details) {
        _dragStartX = details.globalPosition.dx;
        _dragCurrentX = details.globalPosition.dx;
      },

      // Keep current X up to date on every frame of the drag.
      onHorizontalDragUpdate: (details) {
        _dragCurrentX = details.globalPosition.dx;
      },

      // Fire only when this recognizer has already won the arena —
      // meaning Flutter confirmed the drag was primarily horizontal.
      // The vertical scroll has been rejected at this point.
      onHorizontalDragEnd: (details) {
        final startX = _dragStartX;
        _dragStartX = null;
        if (startX == null) return;

        final velocity = details.primaryVelocity ?? 0;
        final distance = _dragCurrentX - startX; // positive = right, negative = left

        // Both thresholds must be met — prevents accidental swipes.
        final isLeftSwipe =
            velocity < -widget.velocityThreshold &&
            distance < -widget.distanceThreshold;
        final isRightSwipe =
            velocity > widget.velocityThreshold &&
            distance > widget.distanceThreshold;

        if (isLeftSwipe) {
          widget.onSwipeLeft();
        } else if (isRightSwipe) {
          widget.onSwipeRight();
        }
      },

      onHorizontalDragCancel: () {
        _dragStartX = null;
        _dragCurrentX = 0;
      },

      child: widget.child,
    );
  }
}

// ─── Banner ────────────────────────────────────────────────────────────────

class _BannerContent extends StatelessWidget {
  final String username;
  final VoidCallback? onProfileTap;

  const _BannerContent({required this.username, this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.orange,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username.isNotEmpty ? 'Hello, $username 👋' : 'Welcome to Daraz',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Discover amazing products at great prices',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 56), // space for search bar PreferredSize
            ],
          ),
          // Profile avatar in top-right of the banner
          if (onProfileTap != null)
            Positioned(
              top: 0,
              right: 0,
              child: GestureDetector(
                onTap: onProfileTap,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white24,
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Search bar ────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Row(
        children: [
          // ── Bordered search field ──────────────────────────────────────
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.pink, width: 1.5),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Search products...',
                      style: TextStyle(color: AppColors.greyText, fontSize: 14),
                    ),
                  ),
                  // Camera / image-search icon
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.greyText,
                      size: 20,
                    ),
                  ),
                  // Pink "Search" button — inset so it never touches the border
                  Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.pink,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    child: const Text(
                      'Search',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Upload icon outside the search bar ─────────────────────────
          const SizedBox(width: 8),
          const Icon(
            Icons.upload_outlined,
            color: AppColors.greyText,
            size: 26,
          ),
        ],
      ),
    );
  }
}

// ─── Tab grid content (box widget, not a sliver) ────────────────────────────
//
// Renders the product grid for [tabIndex] as a plain box widget.
// [shrinkWrap: true] + [NeverScrollableScrollPhysics] means the GridView
// sizes to its content and surrenders all scroll control to the ancestor
// [CustomScrollView]. There is still exactly ONE scrollable in the tree.

class _TabGridContent extends ConsumerWidget {
  final int tabIndex;

  const _TabGridContent({required this.tabIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = kTabCategories[tabIndex];
    final asyncProducts = ref.watch(productsByCategoryProvider(category));

    return asyncProducts.when(
      loading: () => const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      ),

      error: (_, _) => SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 48, color: AppColors.greyText),
              const SizedBox(height: 12),
              const Text('Failed to load products',
                  style: TextStyle(color: AppColors.greyText)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.refresh(productsByCategoryProvider(category)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),

      data: (products) {
        if (products.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: Text('No products found.',
                  style: TextStyle(color: AppColors.greyText)),
            ),
          );
        }

        // GridView with shrinkWrap renders all items as a fixed-height box.
        // NeverScrollableScrollPhysics ensures it never intercepts scroll events.
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.60,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) =>
              ProductCard(product: products[index]),
        );
      },
    );
  }
}
