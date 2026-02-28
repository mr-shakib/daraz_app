# Daraz UI — Flutter Hiring Task 2026

## Run Instructions

```bash
flutter pub get
flutter run
```

**Login credentials:**
- **Username:** `johnd`
- **Password:** `m38rmF$`

> Tested on Flutter 3.29 / Dart 3.7. No extra setup required.

---

## Mandatory Explanation — Scroll Architecture

> This section addresses the three required points in the evaluation brief.

---

### 1. How Horizontal Swipe Was Implemented

**Approach: axis-isolated `GestureDetector` wrapper — no `PageView`, no `TabBarView`.**

A private widget called `_HorizontalSwipeDetector` (in `home_screen.dart`) wraps the entire `CustomScrollView`. It registers **only** horizontal drag callbacks (`onHorizontalDragStart`, `onHorizontalDragUpdate`, `onHorizontalDragEnd`) and nothing else.

```
SafeArea
└── _HorizontalSwipeDetector          ← horizontal axis only
    └── RefreshIndicator
        └── CustomScrollView          ← vertical axis only
            ├── SliverAppBar          (pinned search bar)
            ├── SliverToBoxAdapter    (banner carousel — timer-driven, no touch)
            ├── SliverPersistentHeader (sticky tab bar)
            └── SliverToBoxAdapter    (animated product grid — not scrollable)
```

**How axis isolation works in Flutter's gesture arena:**

Flutter's `GestureArenaManager` resolves pointer events using a "claim by axis" protocol built into `DragGestureRecognizer`. When a pointer moves:

1. If the **vertical** displacement exceeds `kTouchSlop` first → `CustomScrollView`'s internal `VerticalDragGestureRecognizer` wins. All other recognizers (including the horizontal one) are **rejected** and dropped for that pointer. The page never swipes.
2. If the **horizontal** displacement exceeds `kTouchSlop` first → `_HorizontalSwipeDetector`'s `HorizontalDragGestureRecognizer` wins. The scroll's vertical recognizer is rejected. The scroll never moves.
3. If both axes are exactly equal (near-diagonal), Flutter picks the recognizer that declared interest first. In practice this means the `CustomScrollView`'s vertical recognizer wins (it is a child, declares first in the arena). This is the intentional conservative default — **accidental scrolls are prevented more than accidental swipes**.

**Dual-threshold intentional-swipe gate:**

A swipe fires only when **both** conditions are satisfied at `onHorizontalDragEnd`:

| Condition | Threshold | Purpose |
|-----------|-----------|---------|
| `primaryVelocity` ≥ 300 px/s | velocity | Rejects slow, tentative horizontal slides |
| `|horizontal travel|` ≥ 40 px | distance | Rejects high-velocity but tiny taps |

```dart
// _HorizontalSwipeDetectorState.onHorizontalDragEnd
final isLeftSwipe  = velocity < -velocityThreshold && distance < -distanceThreshold;
final isRightSwipe = velocity >  velocityThreshold && distance >  distanceThreshold;
```

**Why not `PageView` or `TabBarView`?**

Both of those widgets own their own `ScrollPosition` on the horizontal axis. When placed inside a `CustomScrollView`, Flutter cannot resolve the competing scroll positions without developer-side hacks (`NeverScrollableScrollPhysics` on the outer, `physics` overrides, `NestedScrollView` coordination). Each workaround introduces new edge cases. The thin `GestureDetector` approach keeps axes completely orthogonal from the start — no framework plumbing required.

**Banner carousel note:**

The `_BannerCarousel` is a `PageView` internally, but its `physics` is set to `NeverScrollableScrollPhysics`. It only advances via a `Timer`. It does **not** register any touch-based drag recognizer, so it cannot interfere with either the vertical scroll or the horizontal swipe detector.

---

### 2. Who Owns the Vertical Scroll and Why

**Single owner: the `CustomScrollView` in `_HomeScreenState`.**

There is exactly **one** `ScrollController` in the entire screen, created in `initState()` and disposed in `dispose()`. It is never recreated or reassigned.

```dart
// _HomeScreenState
late final ScrollController _scrollController; // created once, never replaced

@override
void initState() {
  super.initState();
  _scrollController = ScrollController();
  // ...
}
```

**Why `CustomScrollView` and not a `ListView` or `NestedScrollView`?**

`CustomScrollView` is the only Flutter scrollable that accepts `Sliver` children natively. Slivers have two critical properties that make them the right tool here:

- **`SliverPersistentHeader(pinned: true)`** — the tab bar sticks to the top of the viewport once the banner scrolls past it, without any secondary scroll. There is no inner `ListView` or `SingleChildScrollView` holding the tab bar. The stickiness is handled by the sliver protocol itself (the sliver communicates its pinned geometry directly to the `Viewport`).
- **`SliverList` / `SliverToBoxAdapter` for product content** — the product grid is a *non-scrollable sliver* laid out directly inside the outer `CustomScrollView`. There is no `ListView` inside a `ListView`, no `shrinkWrap: true`, no nested scroll.

**Why this matters:**

Every additional `Scrollable` widget to the tree adds a new `ScrollPosition` and a new gesture recognizer that competes in the arena. The rule of the task ("correct single-scroll architecture") is satisfied by ensuring only `CustomScrollView._controller` can respond to vertical drag at any time.

When the user taps a tab or swipes to change categories:
- `currentTabProvider` (a `StateProvider<int>`) updates → the `StickyTabBarDelegate` repaints.
- `_displayedTabIndex` updates inside `_goToTab()` → the `SliverToBoxAdapter` holding the product grid rebuilds.
- The `CustomScrollView` is **never replaced or scrolled programmatically**. Its scroll position does not move.

This means the user's scroll offset is preserved across tab changes. If they scroll down to product 20 on "electronics" and then swipe to "jewellery" and back, they return to the same offset without any programmatic `animateTo` call.

---

### 3. Trade-offs and Limitations

| Decision | Reason | Trade-off / Limitation |
|----------|--------|------------------------|
| **No `TabBarView` / `PageView` for content** | Avoids competing `ScrollPosition` on the horizontal axis; no gesture conflict possible | No built-in horizontal page-slide animation between tab content panes. Replaced with a custom fade + slide `AnimationController`. |
| **Shared vertical scroll position across tabs** | There is only one `ScrollController` — it cannot have per-tab offsets | All tabs share the same Y offset. Switching from a long list to a short one may leave the user "below the fold". In practice this is acceptable for a product feed where the page top is natural after a tab change, and a programmatic `animateTo(0)` could be added trivially. |
| **Manual `_HorizontalSwipeDetector`** | Clean axis ownership with zero interference from the framework | The diagonal drag edge case (~45° angle) is resolved by whichever recognizer wins the arena first (vertical by priority). A very short, fast diagonal tap could theoretically be ambiguous, though this is imperceptible in practice due to the dual threshold. |
| **`FutureProvider.family` per category** | API data is cached independently per category key after the first load; no global invalidation | Memory is not freed until the provider is explicitly invalidated (via pull-to-refresh or logout). For a large category list this could accumulate, but `fakestore` has only 5 categories. |
| **`AnimationController` for tab transition** | Provides directional slide + fade that mirrors real tab feel without a `PageView` | Two-phase animation (exit → enter, 160 ms each) adds ~320 ms of delay before new content is fully visible. Rapid tab taps during animation are ignored (guarded by `_tabAnim.isAnimating`). |
| **`SliverPersistentHeader` for tab bar** | Native sliver stickiness — no extra scroll coordinate system | Requires a hand-written `SliverPersistentHeaderDelegate`. The `maxExtent` and `minExtent` must be hardcoded; they cannot react to `MediaQuery` font-scaling without an additional layout pass. |
| **`HitTestBehavior.translucent` on the swipe detector** | Tap events still reach children (product cards, tab taps) | Children below the gesture detector will all receive hit-test candidates. This is the correct behavior but should be documented so future developers do not mistakenly set `opaque` and break taps. |

---

## Project Structure

```
lib/
  main.dart                              App entry, ProviderScope, AuthGate
  core/
    api/
      fakestore_client.dart              Dio singleton + bearer-token interceptor
      fakestore_api.dart                 All API calls (login, products, user)
    constants/
      app_colors.dart                    Brand colour palette
      tab_constants.dart                 Category slugs + display labels
    models/
      product.dart                       fromJson / toJson
      user.dart
  features/
    auth/
      providers/auth_provider.dart       Login / logout / session restore (SharedPrefs)
      screens/login_screen.dart
    home/
      providers/
        products_provider.dart           FutureProvider.family keyed by category slug
        tab_provider.dart                StateProvider<int> — current tab index
      widgets/
        sticky_tab_bar_delegate.dart     SliverPersistentHeaderDelegate (no nested scroll)
        product_card.dart
        product_sliver_list.dart         SliverList — deliberately not a scrollable
      screens/home_screen.dart           Single CustomScrollView + HorizontalSwipeDetector
    cart/
      screens/cart_screen.dart
    messages/
      screens/messages_screen.dart
    profile/
      screens/profile_screen.dart
    shell/
      screens/shell_screen.dart          BottomNavigationBar scaffold
```

---

## Screenshots

| Home + Banner | Electronics | Jewellery | Men's Wear |
|:---:|:---:|:---:|:---:|
| ![Home with banner](screenshot/home_with_banner.png) | ![Electronics tab](screenshot/electronics_tab.png) | ![Jewellery tab](screenshot/jewelery_tab.png) | ![Men's wear tab](screenshot/mens_wear_tab.png) |
