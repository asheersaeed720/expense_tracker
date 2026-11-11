import 'package:expense_tracker/config/router/go_router_refresh.dart';
import 'package:expense_tracker/config/router/route_paths.dart';
import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:expense_tracker/features/accounts/screens/accounts_screen.dart';
import 'package:expense_tracker/features/auth/screens/forgot_password_screen.dart';
import 'package:expense_tracker/features/auth/screens/login_screen.dart';
import 'package:expense_tracker/features/auth/screens/sign_up_screen.dart';
import 'package:expense_tracker/features/auth/screens/splash_screen.dart';
import 'package:expense_tracker/features/dashboard/screens/dashboard_screen.dart';
import 'package:expense_tracker/core/enums/loan_type.dart';
import 'package:expense_tracker/features/loans/screens/loan_detail_screen.dart';
import 'package:expense_tracker/features/loans/screens/loan_form_screen.dart';
import 'package:expense_tracker/features/loans/screens/loans_screen.dart';
import 'package:expense_tracker/features/reports/screens/reports_screen.dart';
import 'package:expense_tracker/features/settings/screens/settings_screen.dart';
import 'package:expense_tracker/features/shell/main_shell_screen.dart';
import 'package:expense_tracker/core/enums/company_tx_type.dart';
import 'package:expense_tracker/features/categories/screens/categories_screen.dart';
import 'package:expense_tracker/features/company/screens/company_dashboard_screen.dart';
import 'package:expense_tracker/features/company/screens/company_transactions_screen.dart';
import 'package:expense_tracker/features/company/screens/company_tx_form_screen.dart';
import 'package:expense_tracker/features/transactions/screens/transaction_detail_screen.dart';
import 'package:expense_tracker/features/transactions/screens/transaction_form_screen.dart';
import 'package:expense_tracker/features/transactions/screens/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshStream(supabase.auth.onAuthStateChange);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
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
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.dashboard,
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.transactions,
                name: 'transactions',
                builder: (context, state) => const TransactionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.loans,
                name: 'loans',
                builder: (context, state) => const LoansScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.settings,
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.accounts,
        name: 'accounts',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AccountsScreen(),
      ),
      GoRoute(
        path: RoutePaths.categories,
        name: 'categories',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: RoutePaths.reports,
        name: 'reports',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const ReportsScreen(),
      ),
      GoRoute(
        path: RoutePaths.transactionForm,
        name: 'transactionForm',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return TransactionFormScreen(transactionId: id);
        },
      ),
      GoRoute(
        path: '${RoutePaths.transactionDetail}/:id',
        name: 'transactionDetail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => TransactionDetailScreen(
          transactionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.loanForm,
        name: 'loanForm',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          final typeRaw = state.uri.queryParameters['type'];
          LoanType? initialType;
          if (typeRaw == LoanType.taken.value) {
            initialType = LoanType.taken;
          } else if (typeRaw == LoanType.given.value) {
            initialType = LoanType.given;
          }
          return LoanFormScreen(loanId: id, initialType: initialType);
        },
      ),
      GoRoute(
        path: RoutePaths.company,
        name: 'company',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CompanyDashboardScreen(),
      ),
      GoRoute(
        path: RoutePaths.companyTransactions,
        name: 'companyTransactions',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const CompanyTransactionsScreen(),
      ),
      GoRoute(
        path: RoutePaths.companyTxForm,
        name: 'companyTxForm',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          final intent = state.uri.queryParameters['intent'];
          return CompanyTxFormScreen(
            transactionId: id,
            initialType: intent == 'payout'
                ? CompanyTxType.myWithdrawal
                : CompanyTxType.income,
          );
        },
      ),
      GoRoute(
        path: '${RoutePaths.loanDetail}/:id',
        name: 'loanDetail',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => LoanDetailScreen(
          loanId: state.pathParameters['id']!,
        ),
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
