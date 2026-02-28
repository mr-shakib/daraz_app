import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/tab_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/products_provider.dart';
import '../providers/tab_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/sticky_tab_bar_delegate.dart';

// ─── Architecture Notes ────────────────────────────────────────────────────
//
// SLIVER STRUCTURE (top → bottom):
//   1. SliverAppBar (pinned, zero expand) — search bar, always visible.
//   2. SliverToBoxAdapter — horizontal banner carousel.
//        Uses a PageView driven by a Timer (NeverScrollableScrollPhysics).
//        No horizontal gesture recognizer → no conflict with tab swipe.
//   3. SliverPersistentHeader (pinned) — tab bar sticks once banner scrolls off.
//   4. SliverToBoxAdapter — gesture-driven swipe content.
//
// VERTICAL SCROLL: single CustomScrollView owns the axis.
// HORIZONTAL SWIPE: GestureDetector on the Scaffold body with axis isolation.
//   Drag progress is tracked in real-time via [_swipeAnim]:
//     • 0.0 = settled on [_settledTabIndex]
//     • 1.0 = fully transitioned to [_targetTabIndex]
//   During drag, both the current and target content panels are rendered
//   side-by-side (clipped) and translated proportionally to swipe distance.
//   On finger-lift the controller snaps to 1.0 (complete) or 0.0 (cancel)
//   depending on velocity and travel distance.
//   The tab-bar indicator receives a continuous [double tabPosition] so it
//   follows the drag in real time rather than jumping between integers.
// ───────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  /// The single [ScrollController] for the entire screen.
  late final ScrollController _scrollController;

  // Height of the always-visible pinned search bar.
  static const double _searchBarHeight = 58.0;

  // ─── Swipe state ──────────────────────────────────────────────────────

  /// The tab that is fully visible when no swipe is in progress.
  int _settledTabIndex = 0;

  /// The tab being swiped toward. null when idle.
  int? _targetTabIndex;

  /// true  = swiping from settled → higher index (left swipe)
  /// false = swiping from settled → lower  index (right swipe)
  bool _dragForward = true;

  /// Horizontal start position of the current drag on screen (px).
  double? _dragStartX;

  /// Screen width — cached in [build] so gesture handlers can reference it
  /// without a [BuildContext].
  double _screenWidth = 400.0;

  /// Drives swipe progress: 0.0 = settled, 1.0 = transition complete.
  ///
  /// During a drag this is set directly (`value = pixels / screenWidth`).
  /// After finger-lift it is animated to 0 or 1.
  /// An [addListener] on this controller calls [setState] so every frame
  /// during an animation (or direct-drive) triggers a rebuild.
  late final AnimationController _swipeAnim;

  // ─── Computed helpers ────────────────────────────────────────────────

  /// Continuous tab position for the indicator, e.g. 0.5 = halfway between
  /// tab 0 and tab 1.
  double get _tabPosition {
    final target = _targetTabIndex;
    if (target == null) return _settledTabIndex.toDouble();
    final direction = _dragForward ? 1.0 : -1.0;
    return _settledTabIndex + direction * _swipeAnim.value;
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _swipeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _swipeAnim.dispose();
    super.dispose();
  }

  // ─── Tab-tap navigation (programmatic) ──────────────────────────────

  void _goToTab(int index) {
    if (index < 0 || index >= kTabCategories.length) return;
    if (index == _settledTabIndex) return;
    if (_swipeAnim.isAnimating) return;

    _dragForward = index > _settledTabIndex;
    _targetTabIndex = index;
    ref.read(currentTabProvider.notifier).state = index;

    _swipeAnim.animateTo(
      1.0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    ).then((_) {
      if (mounted) _commitSwipe();
    });
  }

  // ─── Swipe completion / cancellation ────────────────────────────────

  /// Called when the animation reaches 1.0 — makes the target the new settled
  /// tab and resets the animation to 0 without triggering a visible frame.
  void _commitSwipe() {
    final target = _targetTabIndex;
    if (target == null) return;
    // Update settled index BEFORE resetting the controller so the build that
    // follows _swipeAnim.value = 0 renders the correct single panel.
    _settledTabIndex = target;
    _targetTabIndex = null;
    ref.read(currentTabProvider.notifier).state = _settledTabIndex;
    _swipeAnim.value = 0.0; // silent reset — listener calls setState once more
  }

  /// Snaps the animation back to 0 (cancelled / not enough gesture).
  void _cancelSwipe() {
    _swipeAnim
        .animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        )
        .then((_) {
          if (mounted) {
            setState(() {
              _targetTabIndex = null;
              ref.read(currentTabProvider.notifier).state = _settledTabIndex;
            });
          }
        });
  }

  // ─── Gesture handlers ────────────────────────────────────────────────

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_swipeAnim.isAnimating) return;
    _dragStartX = details.globalPosition.dx;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final startX = _dragStartX;
    if (startX == null) return;

    final delta = details.globalPosition.dx - startX;

    // ── Determine drag direction and set target on first meaningful move ──
    if (_targetTabIndex == null) {
      if (delta < 0 && _settledTabIndex < kTabCategories.length - 1) {
        _dragForward = true;
        _targetTabIndex = _settledTabIndex + 1;
        // Move indicator ahead immediately so it follows the drag.
        ref.read(currentTabProvider.notifier).state = _targetTabIndex!;
      } else if (delta > 0 && _settledTabIndex > 0) {
        _dragForward = false;
        _targetTabIndex = _settledTabIndex - 1;
        ref.read(currentTabProvider.notifier).state = _targetTabIndex!;
      } else {
        return; // already at first/last tab — nothing to do
      }
    }

    // ── Guard: ignore if user reverses direction mid-gesture ─────────────
    final correctDir =
        (_dragForward && delta < 0) || (!_dragForward && delta > 0);
    if (!correctDir) {
      // Treat reversal as a cancel and reset.
      _swipeAnim.value = 0.0;
      _targetTabIndex = null;
      ref.read(currentTabProvider.notifier).state = _settledTabIndex;
      _dragStartX = details.globalPosition.dx; // reset origin
      return;
    }

    // ── Drive animation proportionally to drag travel ─────────────────
    final progress = (delta.abs() / _screenWidth).clamp(0.0, 1.0);
    _swipeAnim.value = progress; // triggers setState via addListener
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _dragStartX = null;
    if (_targetTabIndex == null) return;

    final velocity = details.primaryVelocity ?? 0.0;
    final progress = _swipeAnim.value;

    // Complete when travel > 50 % OR fast enough velocity in the right dir.
    const velocityThreshold = 500.0;
    final fastEnough =
        (_dragForward && velocity < -velocityThreshold) ||
        (!_dragForward && velocity > velocityThreshold);

    if (progress > 0.5 || fastEnough) {
      _swipeAnim
          .animateTo(
            1.0,
            duration: Duration(milliseconds: ((1.0 - progress) * 200).round()),
            curve: Curves.easeOut,
          )
          .then((_) {
            if (mounted) _commitSwipe();
          });
    } else {
      _cancelSwipe();
    }
  }

  void _onHorizontalDragCancel() {
    _dragStartX = null;
    if (_targetTabIndex != null) _cancelSwipe();
  }

  // ─── Dual-panel swipe content builder ───────────────────────────────────
  //
  // When idle: renders a single _TabGridContent for [_settledTabIndex].
  // During swipe: renders TWO panels in a Stack, each translated by the
  // current swipe progress so the UI is 1-to-1 with the user's finger:
  //
  //   progress = _swipeAnim.value  (0.0 → 1.0)
  //   screenWidth = _screenWidth
  //
  //   Forward swipe (left, going to a higher index):
  //     • Current panel: x = -progress × screenWidth   (slides out left)
  //     • Target  panel: x =  (1-progress) × screenWidth (slides in from right)
  //
  //   Backward swipe (right, going to a lower index):
  //     • Current panel: x = +progress × screenWidth   (slides out right)
  //     • Target  panel: x = -(1-progress) × screenWidth (slides in from left)
  //
  // Both panels are wrapped in ClipRect (caller) so they never overflow.
  // Stack sizes to max(current, target) height — imperceptible during motion.
  Widget _buildSwipeContent() {
    final target = _targetTabIndex;
    final progress = _swipeAnim.value;

    // ── Idle: single panel, no overhead ──────────────────────────────────
    if (target == null || progress == 0.0) {
      return _TabGridContent(tabIndex: _settledTabIndex);
    }

    final currentOffset = _dragForward
        ? Offset(-progress * _screenWidth, 0)
        : Offset(progress * _screenWidth, 0);

    final targetOffset = _dragForward
        ? Offset((1.0 - progress) * _screenWidth, 0)
        : Offset(-(1.0 - progress) * _screenWidth, 0);

    return Stack(
      children: [
        Transform.translate(
          offset: currentOffset,
          child: _TabGridContent(tabIndex: _settledTabIndex),
        ),
        Transform.translate(
          offset: targetOffset,
          child: _TabGridContent(tabIndex: target),
        ),
      ],
    );
  }

  // ─── Pull-to-refresh ────────────────────────────────────────────────────

  Future<void> _onRefresh() async {
    final category = kTabCategories[_settledTabIndex];
    ref.invalidate(productsByCategoryProvider(category));
    await ref.read(productsByCategoryProvider(category).future);
  }

  @override
  Widget build(BuildContext context) {
    // Watch only to keep _goToTab in sync; tab bar is driven by _tabPosition.
    ref.watch(currentTabProvider);
    final authState = ref.watch(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    // Cache screen width so gesture callbacks can access it without context.
    _screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.lightGrey,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          // ── Axis isolation: Flutter's arena gives vertical drags to the
          // CustomScrollView; horizontal drags are claimed by this detector.
          onHorizontalDragStart: _onHorizontalDragStart,
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          onHorizontalDragCancel: _onHorizontalDragCancel,
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.orange,
            child: CustomScrollView(
              // ── Single vertical scroll owner ─────────────────────────────
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── 1. Pinned search bar ───────────────────────────────────
                // expandedHeight == toolbarHeight → no collapsing, always
                // the same height. The search bar is always fully visible.
                SliverAppBar(
                  pinned: true,
                  floating: false,
                  snap: false,
                  toolbarHeight: _searchBarHeight,
                  expandedHeight: _searchBarHeight,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.pin,
                    background: _SearchBar(),
                  ),
                ),

                // ── 2. Banner carousel ────────────────────────────────────
                // Scrolls away with the page. Once it leaves the viewport,
                // the tab bar (below) pins to the top.
                SliverToBoxAdapter(
                  child: _BannerCarousel(
                    username: user?.name.firstname ?? '',
                  ),
                ),

                // ── 3. Sticky Tab Bar ──────────────────────────────────────
                // pinned:true → locks to top once the banner sliver scrolls off.
                // [tabPosition] is a continuous double so the indicator tracks
                // the drag in real time (e.g. 0.5 = halfway between tab 0 and 1).
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickyTabBarDelegate(
                    tabPosition: _tabPosition,
                    onTabChanged: _goToTab,
                  ),
                ),

                // ── 4. Gesture-driven swipe content ───────────────────────
                // During a swipe two _TabGridContent panels are rendered
                // side-by-side inside a ClipRect:
                //   • Current panel translates from x=0 → x=±screenWidth
                //   • Target  panel translates from x=∓screenWidth → x=0
                // Progress is the raw _swipeAnim.value (0.0-1.0) so the
                // visual movement is always 1:1 with the user's finger.
                SliverToBoxAdapter(
                  child: ClipRect(
                    child: _buildSwipeContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Banner carousel ──────────────────────────────────────────────────────
//
// Uses a [PageView] with [NeverScrollableScrollPhysics] driven entirely by
// a [Timer]. No horizontal gesture recognizer is registered, so the outer
// GestureDetector (in HomeScreen) handles tab-swipe without any arena conflict.

class _BannerSlide {
  final String assetPath;
  const _BannerSlide({required this.assetPath});
}

class _BannerCarousel extends StatefulWidget {
  final String username;
  const _BannerCarousel({required this.username});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  static const _slides = [
    _BannerSlide(assetPath: 'assets/promotion/elevem11.png'),
    _BannerSlide(assetPath: 'assets/promotion/daraz_club.png'),
    _BannerSlide(assetPath: 'assets/promotion/azadi_sale.jpg'),
  ];

  late final PageController _pageCtrl;
  late final Timer _timer;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    // Auto-advance every 3 seconds.
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      _current = (_current + 1) % _slides.length;
      if (_pageCtrl.hasClients) {
        _pageCtrl.animateToPage(
          _current,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Slides ──────────────────────────────────────────────────────
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageCtrl,
            // NeverScrollableScrollPhysics → no horizontal gesture recognizer
            // registered. Timer drives all page transitions. This eliminates
            // any arena conflict with the outer _HorizontalSwipeDetector.
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return _BannerSlideTile(slide: slide);
            },
          ),
        ),

        // ── Dot indicators ───────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (i) {
              final isActive = i == _current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.orange : AppColors.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _BannerSlideTile extends StatelessWidget {
  final _BannerSlide slide;
  const _BannerSlideTile({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      slide.assetPath,
      width: double.infinity,
      height: 180,
      fit: BoxFit.cover,
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
