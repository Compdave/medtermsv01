// lib/app.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medtermsv01/core/services/auth_service.dart';
import 'package:medtermsv01/core/services/supabase_service.dart';
import 'package:medtermsv01/core/config/app_config.dart';
import 'package:medtermsv01/features/loginscr/screens/login_screen.dart';
import 'package:medtermsv01/features/home/screens/home_screen.dart';
import 'package:medtermsv01/features/quiz/screens/quest_page.dart';
import 'package:medtermsv01/features/modules/screens/modules_list_screen.dart';
import 'package:medtermsv01/features/leaderboard/screens/leaderboard_screen.dart';
import 'package:medtermsv01/features/profile/screens/profile_screen.dart';
import 'package:medtermsv01/features/promo/screens/promo_screen.dart';
import 'package:medtermsv01/core/theme/app_theme.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = _buildRouter(ref);

    return MaterialApp.router(
      title: 'Medical Terminology',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }

  GoRouter _buildRouter(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final isSignedIn = AuthService.isSignedIn;
        final isLoginRoute = state.matchedLocation == '/login';

        if (!isSignedIn && !isLoginRoute) return '/login';
        if (isSignedIn && isLoginRoute) return '/home';
        return null;
      },
      refreshListenable: _AuthStateListenable(ref),
      routes: [
        // Login
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),

        // Home
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),

        // Quiz / Quest Page
        GoRoute(
          path: '/quiz/:quizId',
          name: 'quiz',
          builder: (context, state) {
            final quizId = int.parse(state.pathParameters['quizId']!);
            final userId = SupabaseService.currentUserId ?? '';
            final apptype = state.uri.queryParameters['apptype'] ??
                AppConfig.instance.apptypePrefix;
            return QuestPage(
              quizId: quizId,
              userId: userId,
              apptype: apptype,
            );
          },
        ),

        // Modules List
        GoRoute(
          path: '/modules',
          name: 'modules',
          builder: (context, state) => const ModulesListScreen(),
        ),

        // Leaderboard
        GoRoute(
          path: '/leaderboard',
          name: 'leaderboard',
          builder: (context, state) => const LeaderboardScreen(),
        ),

        // Profile
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),

        // Promo / LemonSqueezy checkout
        GoRoute(
          path: '/promo/:apptype',
          name: 'promo',
          builder: (context, state) {
            final apptype = state.pathParameters['apptype']!;
            final quizIdStr = state.uri.queryParameters['quizId'];
            final quizId = quizIdStr != null ? int.tryParse(quizIdStr) : null;
            return PromoScreen(apptype: apptype, quizId: quizId);
          },
        ),
      ],

      // Error page
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Page not found: ${state.matchedLocation}',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Auth state listenable — tells GoRouter to re-evaluate redirect
// when auth state changes (sign in / sign out)
// =============================================================================

class _AuthStateListenable extends ChangeNotifier {
  _AuthStateListenable(WidgetRef ref) {
    AuthService.authStateChanges.listen((_) => notifyListeners());
  }
}
