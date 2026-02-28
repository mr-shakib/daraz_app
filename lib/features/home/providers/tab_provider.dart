import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The index of the currently selected tab.
/// Using [StateProvider] because tab selection is simple integer state —
/// no async work needed. All tab-content consumers rebuild only when this changes.
final currentTabProvider = StateProvider<int>((ref) => 0);
