import 'package:expense_tracker/config/router/route_paths.dart';
import 'package:expense_tracker/core/models/company_transaction.dart';
import 'package:expense_tracker/core/utils/app_snackbar.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/animated_balance_text.dart';
import 'package:expense_tracker/core/widgets/app_empty_state.dart';
import 'package:expense_tracker/core/widgets/app_shimmer_list.dart';
import 'package:expense_tracker/features/accounts/providers/accounts_providers.dart';
import 'package:expense_tracker/features/company/company_categories.dart';
import 'package:expense_tracker/features/company/providers/company_providers.dart';
import 'package:expense_tracker/features/company/widgets/company_setup_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CompanyDashboardScreen extends ConsumerWidget {
  const CompanyDashboardScreen({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final ledger = ref.read(companyLedgerProvider).valueOrNull;
    if (ledger == null) return;

    final result = await showCompanySetupSheet(context, ledger: ledger);
    if (result == null || !context.mounted) return;

    try {
      await ref.read(companyServiceProvider).updateLedger(
            id: ledger.id,
            companyName: result.companyName,
            partnerName: result.partnerName,
            mySharePercent: result.mySharePercent,
          );
      if (context.mounted) {
        showAppSnackBar(context, message: 'Company workspace updated.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.dashboard);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(companyLedgerProvider);
    final recent = ref.watch(recentCompanyTransactionsProvider);
    final month = ref.watch(companyMonthOverviewProvider);
    final currency = ref.watch(profileProvider).valueOrNull?.currency ?? 'PKR';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Personal',
          onPressed: () => _leave(context),
          icon: const Icon(Icons.person_outline),
        ),
        title: Text(ledgerAsync.valueOrNull?.companyName ?? 'Company'),
        actions: [
          IconButton(
            tooltip: 'Company settings',
            onPressed: () => _edit(context, ref),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: ledgerAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: AppShimmerList(itemCount: 3, itemHeight: 96),
        ),
        skipLoadingOnReload: true,
        error: (error, _) => _Message(
          message: error.toString(),
          onRetry: () => ref.invalidate(companyLedgerProvider),
        ),
        data: (ledger) {
          if (ledger == null) {
            return const _Message(
              message: 'Turn on Company / Partner Ledger in Settings to set this up.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => refreshCompanyViews(ref),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _PoolCard(balance: ledger.totalBalance, currency: currency),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ShareCard(
                        label: 'My Share (${_pct(ledger.mySharePercent)}%)',
                        amount: ledger.myShareBalance,
                        currency: currency,
                        color: const Color(0xFF34D399),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ShareCard(
                        label:
                            '${ledger.partnerName} (${_pct(ledger.partnerSharePercent)}%)',
                        amount: ledger.partnerShareBalance,
                        currency: currency,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _MonthCard(
                  overview: month.valueOrNull,
                  currency: currency,
                  onOpen: () => context.push(RoutePaths.companyTransactions),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => context.push(RoutePaths.companyTxForm),
                        icon: const Icon(Icons.add),
                        label: const Text('Income / Expense'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(
                          RoutePaths.companyTxFormIntent('payout'),
                        ),
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Withdraw / Payout'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push(RoutePaths.companyTransactions),
                      child: const Text('See All'),
                    ),
                  ],
                ),
                recent.when(
                  loading: () => const AppShimmerList(itemCount: 3, itemHeight: 64),
                  error: (error, _) => Text(error.toString()),
                  data: (items) {
                    if (items.isEmpty) {
                      return const AppEmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: 'No company transactions yet',
                        subtitle: 'Income, shared expenses, and payouts show up here.',
                      );
                    }
                    return Column(
                      children: [
                        for (final item in items)
                          _RecentTile(item: item, currency: currency),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _pct(double value) {
    final cents = (value * 100).round();
    if (cents % 100 == 0) return '${cents ~/ 100}';
    return (cents / 100).toStringAsFixed(2);
  }
}

class _PoolCard extends StatelessWidget {
  const _PoolCard({required this.balance, required this.currency});

  final double balance;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            primary.withValues(alpha: 0.22),
            primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Combined pool',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                ),
          ),
          const SizedBox(height: 8),
          AnimatedBalanceText(
            amount: balance,
            currency: currency,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  final String label;
  final double amount;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(amount, currencyCode: currency),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthCard extends StatelessWidget {
  const _MonthCard({
    required this.overview,
    required this.currency,
    required this.onOpen,
  });

  final CompanyMonthOverview? overview;
  final String currency;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final data = overview ?? const CompanyMonthOverview(income: 0, sharedExpenses: 0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'This month',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            _line(context, 'Gross income', data.income, const Color(0xFF34D399)),
            _line(context, 'Shared expenses', data.sharedExpenses, const Color(0xFFF87171)),
            _line(context, 'Net profit', data.net, Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpen,
                child: const Text('Reports / All Transactions'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            CurrencyFormatter.format(amount, currencyCode: currency),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.item, required this.currency});

  final CompanyTransaction item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final positive = item.type.increasesPool;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(companyCategoryIcon(item.category)),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(DateFormatter.transactionDate(item.date)),
      trailing: Text(
        '${positive ? '+' : '-'}${CurrencyFormatter.format(item.amount, currencyCode: currency)}',
        style: TextStyle(
          color: positive ? const Color(0xFF34D399) : const Color(0xFFF87171),
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => context.push(RoutePaths.companyTxFormEdit(item.id)),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
