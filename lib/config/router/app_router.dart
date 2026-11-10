import 'package:expense_tracker/config/router/go_router_refresh.dart';
import 'package:expense_tracker/config/router/route_paths.dart';
import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:expense_tracker/features/auth/screens/forgot_password_screen.dart';
import 'package:expense_tracker/features/auth/screens/login_screen.dart';
import 'package:expense_tracker/features/auth/screens/sign_up_screen.dart';
import 'package:expense_tracker/features/auth/screens/splash_screen.dart';
import 'package:expense_tracker/features/dashboard/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshStream(supabase.auth.onAuthStateChange);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    refreshListenable: refresh,
    redirect: _redirect,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.signUp,
        name: 'signUp',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});

String? _redirect(BuildContext context, GoRouterState state) {
  final session = supabase.auth.currentSession;
  final isLoggedIn = session != null;
  final location = state.matchedLocation;

  final isAuthRoute = location == RoutePaths.login ||
      location == RoutePaths.signUp ||
      location == RoutePaths.forgotPassword;
  final isSplash = location == RoutePaths.splash;

  if (isSplash) {
    return isLoggedIn ? RoutePaths.dashboard : RoutePaths.login;
  }

  if (!isLoggedIn && !isAuthRoute) {
    return RoutePaths.login;
  }

  if (isLoggedIn && isAuthRoute) {
    return RoutePaths.dashboard;
  }

  return null;
}
