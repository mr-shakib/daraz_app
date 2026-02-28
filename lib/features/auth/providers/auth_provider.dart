import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/fakestore_api.dart';
import '../../../core/api/fakestore_client.dart';
import '../../../core/models/user.dart';

// ─── State ─────────────────────────────────────────────────────────────────

/// Sealed auth states.
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final String token;
  final User user;
  const AuthAuthenticated({required this.token, required this.user});
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthInitial()) {
    _restoreSession();
  }

  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  /// Restore session from shared prefs on app start.
  /// Uses cached user data so launch is instant — no network call needed.
  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);

    if (token == null || token.isEmpty) return; // no session to restore

    FakestoreClient.setAuthToken(token);

    if (userJson != null) {
      // Fast path: restore from cache immediately, no network call.
      try {
        final user = User.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
        state = AuthAuthenticated(token: token, user: user);
        return;
      } catch (_) {
        // Cached data corrupt — fall through to network fetch.
      }
    }

    // Slow path (first launch after update, or corrupt cache): fetch from API.
    state = const AuthLoading();
    try {
      final user = await FakestoreApi.getCurrentUser();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      state = AuthAuthenticated(token: token, user: user);
    } catch (_) {
      await prefs.remove(_tokenKey);
      FakestoreClient.clearAuthToken();
      state = const AuthInitial();
    }
  }

  Future<void> login(String username, String password) async {
    state = const AuthLoading();
    try {
      final token = await FakestoreApi.login(username, password);
      FakestoreClient.setAuthToken(token);

      final user = await FakestoreApi.getCurrentUser();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));

      state = AuthAuthenticated(token: token, user: user);
    } on Exception catch (e) {
      state = AuthError(e.toString());
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    FakestoreClient.clearAuthToken();
    state = const AuthInitial();
  }
}

// ─── Provider ──────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
