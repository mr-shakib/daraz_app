import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_colors.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/home/screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    // ProviderScope is required by Riverpod — must wrap the entire widget tree.
    const ProviderScope(child: DarazApp()),
  );
}

class DarazApp extends StatelessWidget {
  const DarazApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daraz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.orange),
        scaffoldBackgroundColor: AppColors.white,
      ),
      home: const _AuthGate(),
    );
  }
}

// ─── Auth Gate ─────────────────────────────────────────────────────────────
// Watches [authProvider] and shows the correct screen without a router.
// AuthInitial / AuthError  → LoginScreen
// AuthLoading              → SplashScreen  (while restoring session)
// AuthAuthenticated        → HomeScreen

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return switch (authState) {
      AuthAuthenticated() => const HomeScreen(),
      AuthLoading() => const _SplashScreen(),
      _ => const LoginScreen(),
    };
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.orange,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Daraz',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
          ],
        ),
      ),
    );
  }
}
