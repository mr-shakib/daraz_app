import 'package:dio/dio.dart';

/// Singleton Dio client pre-configured for FakeStore API.
class FakestoreClient {
  FakestoreClient._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://fakestoreapi.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static Dio get instance => _dio;

  /// Inject an auth token into all subsequent requests.
  static void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
}
