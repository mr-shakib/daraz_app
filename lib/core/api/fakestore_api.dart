import 'package:dio/dio.dart';
import '../models/product.dart';
import '../models/user.dart';
import 'fakestore_client.dart';

/// All FakeStore API calls. Methods throw [DioException] on network errors.
class FakestoreApi {
  FakestoreApi._();

  static final Dio _dio = FakestoreClient.instance;

  // ─── Auth ──────────────────────────────────────────────────────────────────

  /// Returns JWT token on success.
  static Future<String> login(String username, String password) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    return res.data!['token'] as String;
  }

  // ─── Users ─────────────────────────────────────────────────────────────────

  static Future<User> getUser(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/users/$id');
    return User.fromJson(res.data!);
  }

  /// FakeStore has users with ids 1–10; fetch user #1 as the logged-in user
  /// since the login endpoint only returns a token (no userId).
  static Future<User> getCurrentUser() => getUser(1);

  // ─── Products ──────────────────────────────────────────────────────────────

  static Future<List<Product>> getProductsByCategory(String category) async {
    final res = await _dio.get<List<dynamic>>(
      '/products/category/$category',
    );
    return res.data!
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<List<String>> getCategories() async {
    final res = await _dio.get<List<dynamic>>('/products/categories');
    return res.data!.map((e) => e as String).toList();
  }
}
