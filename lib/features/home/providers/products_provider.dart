import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/fakestore_api.dart';
import '../../../core/models/product.dart';

/// Fetches and caches products for a given category string.
/// [FutureProvider.family] means each category has its own independent,
/// cached async state. The data is NOT re-fetched on tab switches.
///
/// The FakeStore API only has 4-6 items per category, so results are tiled
/// to reach [_targetCount] for a realistic-looking grid.
const int _targetCount = 28;

final productsByCategoryProvider =
    FutureProvider.family<List<Product>, String>((ref, category) async {
  final products = await FakestoreApi.getProductsByCategory(category);
  if (products.isEmpty) return products;

  // Tile the list until we have at least [_targetCount] items.
  final tiled = <Product>[];
  while (tiled.length < _targetCount) {
    tiled.addAll(products);
  }
  final result = tiled.take(_targetCount).toList();
  // Shuffle so each refresh produces a visibly different ordering.
  result.shuffle(Random());
  return result;
});
