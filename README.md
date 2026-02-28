# Daraz UI — Flutter Hiring Task 2026

## Run Instructions

```bash
flutter pub get
flutter run
```

Login with demo credentials:  
- **Username:** `johnd`  
- **Password:** `m38rmF$`

---

## Scroll Architecture

### 1. How Horizontal Swipe Was Implemented

A `_HorizontalSwipeDetector` widget (a thin `GestureDetector` wrapper) is placed **above** the `CustomScrollView` in the widget tree. It listens only to `onHorizontalDragEnd` and changes the tab index via `currentTabProvider`.

Flutter's gesture arena resolves conflicts by axis before either recognizer is declared a winner. The `CustomScrollView` claims vertical drag; the outer `GestureDetector` claims horizontal drag. On a predominantly horizontal drag, the `GestureDetector` wins; on a predominantly vertical drag, the scroll wins. This gives clean, intentional gesture handling with no magic numbers or hack thresholds — only a velocity threshold (`300 px/s`) to filter accidental micro-swipes.

### 2. Who Owns the Vertical Scroll and Why

**`CustomScrollView`** is the single, sole owner of the vertical scroll axis. There is exactly **one** `ScrollController` in the entire screen, created once in `HomeScreen._initState()` and never recreated.

There is no `TabBarView`, no `PageView`, no nested `ListView` anywhere. The product list renders as a `SliverList` (a non-scrollable sliver) directly inside the `CustomScrollView`. When the user switches tabs, only `currentTabProvider` changes — `CustomScrollView` is untouched — so scroll position is preserved exactly.

### 3. Trade-offs and Limitations

| Decision | Reason | Trade-off |
|---|---|---|
| No `TabBarView` / `PageView` | Avoids scroll conflict; preserves single-scrollable constraint | No animated page-slide on tab switch |
| Shared scroll position across tabs | Only one scrollable exists — can't be per-tab | All tabs share the same offset; but task requires "no jump", which is satisfied |
| `FutureProvider.family` per category | Data cached independently per category after first load | Memory not freed until provider is invalidated |
| Manual swipe detection | Clean axis ownership | Diagonal drags at ~45° may be ambiguous; resolved by whichever axis moves first |

---

## Project Structure

```
lib/
  main.dart                            App entry, ProviderScope, AuthGate
  core/
    api/
      fakestore_client.dart            Dio singleton + token injection
      fakestore_api.dart               All API calls
    constants/
      app_colors.dart
      tab_constants.dart               Category slugs + display labels
    models/
      product.dart
      user.dart
  features/
    auth/
      providers/auth_provider.dart     Login / logout / session restore
      screens/login_screen.dart
    home/
      providers/
        products_provider.dart         FutureProvider.family per category
        tab_provider.dart              StateProvider<int> for current tab
      widgets/
        sticky_tab_bar_delegate.dart   SliverPersistentHeaderDelegate
        product_card.dart
        product_sliver_list.dart       Sliver — no nested scrollable
      screens/home_screen.dart         Single CustomScrollView owner
    profile/
      screens/profile_screen.dart
```

