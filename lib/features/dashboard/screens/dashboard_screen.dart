import 'package:expense_tracker/config/router/route_paths.dart';
import 'package:expense_tracker/core/models/monthly_stats.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/app_shimmer_list.dart';
import 'package:expense_tracker/features/accounts/providers/accounts_providers.dart';
import 'package:expense_tracker/features/company/providers/company_providers.dart';
import 'package:expense_tracker/features/company/widgets/workspace_switcher_pill.dart';
import 'package:expense_tracker/features/dashboard/providers/dashboard_refresh.dart';
import 'package:expense_tracker/features/dashboard/widgets/account_summary_carousel.dart';
import 'package:expense_tracker/features/dashboard/widgets/monthly_expense_overview_card.dart';
import 'package:expense_tracker/features/dashboard/widgets/monthly_stats_row.dart';
import 'package:expense_tracker/features/dashboard/widgets/recent_transactions_section.dart';
import 'package:expense_tracker/features/dashboard/widgets/total_balance_card.dart';
import 'package:expense_tracker/features/transactions/providers/transactions_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final accountsAsync = ref.watch(accountsProvider);
    final recentAsync = ref.watch(recentTransactionsProvider);
    final statsAsync = ref.watch(monthlyStatsProvider);
    final totalBalance = ref.watch(totalBalanceProvider);

    final currency = profileAsync.valueOrNull?.currency ?? 'PKR';
    final name = profileAsync.valueOrNull?.displayName ?? 'there';
    final companyOn = profileAsync.valueOrNull?.companyModeEnabled == true;
    final companyLedger = companyOn
        ? ref.watch(companyLedgerProvider).valueOrNull
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        bottom: companyLedger == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: WorkspaceSwitcherPill(
                  companyName: companyLedger.companyName,
                  onCompany: () => context.push(RoutePaths.company),
                ),
              ),
        actions: [
          IconButton(
            tooltip: 'Manage accounts',
            onPressed: () => context.push(RoutePaths.accounts),
            icon: const Icon(Icons.account_balance_wallet_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => refreshDashboard(ref),
        child: accountsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: AppShimmerList(itemCount: 4, itemHeight: 88),
          ),
          error: (error, _) => _ErrorState(
            message: error.toString(),
            onRetry: () => refreshDashboard(ref),
          ),
          data: (accounts) {
            final recent = recentAsync.valueOrNull ?? const [];
            final stats =
                statsAsync.valueOrNull ?? const MonthlyStats(income: 0, expense: 0);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Text(
                  'Hello, $name',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormatter.headerDate(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                ),
                const SizedBox(height: 20),
                TotalBalanceCard(
                  totalBalance: totalBalance,
                  currency: currency,
                ),
                const SizedBox(height: 20),
                Text(
                  'Accounts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                AccountSummaryCarousel(
                  accounts: accounts,
                  currency: currency,
                ),
                const SizedBox(height: 20),
                Text(
                  'This month',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 12),
                MonthlyStatsRow(stats: stats, currency: currency),
                const SizedBox(height: 20),
                MonthlyExpenseOverviewCard(
                  onViewReports: () => context.push(RoutePaths.reports),
                ),
                const SizedBox(height: 20),
                RecentTransactionsSection(
                  transactions: recent,
                  currency: currency,
                  onSeeAll: () => context.go(RoutePaths.transactions),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
