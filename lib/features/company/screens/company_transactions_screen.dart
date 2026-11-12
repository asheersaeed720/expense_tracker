import 'package:expense_tracker/config/router/route_paths.dart';
import 'package:expense_tracker/core/enums/company_tx_type.dart';
import 'package:expense_tracker/core/models/company_transaction.dart';
import 'package:expense_tracker/core/utils/app_haptics.dart';
import 'package:expense_tracker/core/utils/app_snackbar.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:expense_tracker/core/utils/date_formatter.dart';
import 'package:expense_tracker/core/widgets/app_empty_state.dart';
import 'package:expense_tracker/core/widgets/app_shimmer_list.dart';
import 'package:expense_tracker/core/widgets/scaffold_with_fab.dart';
import 'package:expense_tracker/features/accounts/providers/accounts_providers.dart';
import 'package:expense_tracker/features/company/company_categories.dart';
import 'package:expense_tracker/features/company/models/company_tx_filters.dart';
import 'package:expense_tracker/features/company/providers/company_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CompanyTransactionsScreen extends ConsumerWidget {
  const CompanyTransactionsScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CompanyTransaction item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete company transaction?'),
        content: const Text(
          'This reverses the company split. A linked personal transaction is deleted too.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await AppHaptics.medium();
    try {
      await ref.read(companyServiceProvider).deleteTransaction(item);
      refreshCompanyViews(ref);
      if (context.mounted) {
        showAppSnackBar(context, message: 'Transaction deleted.');
      }
    } catch (e) {
      if (context.mounted) {
        showAppSnackBar(context, message: e.toString(), isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(companyTxFiltersProvider);
    final async = ref.watch(companyTransactionsProvider);
    final currency = ref.watch(profileProvider).valueOrNull?.currency ?? 'PKR';

    return ScaffoldWithFab(
      appBar: AppBar(title: const Text('Company transactions')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-company-transactions',
        onPressed: () => context.push(RoutePaths.companyTxForm),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => refreshCompanyViews(ref),
        child: async.when(
          skipLoadingOnReload: true,
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: const [AppShimmerList()],
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(error.toString()),
              ),
            ],
          ),
          data: (items) {
            final income = items
                .where((e) => e.type == CompanyTxType.income)
                .fold<double>(0, (sum, e) => sum + e.amount);
            final expense = items
                .where((e) => e.type == CompanyTxType.sharedExpense)
                .fold<double>(0, (sum, e) => sum + e.amount);

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search description, category, amount…',
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final trimmed = value.trim();
                    ref.read(companyTxFiltersProvider.notifier).state =
                        filters.copyWith(
                      searchQuery: trimmed.isEmpty ? null : trimmed,
                      clearSearch: trimmed.isEmpty,
                    );
                  },
                ),
                const SizedBox(height: 8),
                _DateFilters(filters: filters),
                const SizedBox(height: 8),
                _TypeFilters(filters: filters),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        _Metric('Income', income, currency, const Color(0xFF34D399)),
                        _Metric('Shared expenses', expense, currency, const Color(0xFFF87171)),
                        _Metric(
                          'Net',
                          income - expense,
                          currency,
                          Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No company transactions found',
                    subtitle: 'Try another search or adjust the filters.',
                  )
                else
                  for (final item in items)
                    Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        await _confirmDelete(context, ref, item);
                        return false;
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Theme.of(context).colorScheme.error,
                        child: const Icon(Icons.delete_outline),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(companyCategoryIcon(item.category)),
                        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(
                          '${DateFormatter.transactionDate(item.date)} · ${item.splitLabel(currency)}',
                        ),
                        trailing: Text(
                          '${item.type.increasesPool ? '+' : '-'}${CurrencyFormatter.format(item.amount, currencyCode: currency)}',
                          style: TextStyle(
                            color: item.type.increasesPool
                                ? const Color(0xFF34D399)
                                : const Color(0xFFF87171),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () => context.push(RoutePaths.companyTxFormEdit(item.id)),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.amount, this.currency, this.color);

  final String label;
  final double amount;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color)),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(amount, currencyCode: currency),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _DateFilters extends ConsumerWidget {
  const _DateFilters({required this.filters});

  final CompanyTxFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void setPreset(CompanyDatePreset preset) {
      ref.read(companyTxFiltersProvider.notifier).state =
          filters.copyWith(datePreset: preset);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _Chip(
            label: 'This month',
            selected: filters.datePreset == CompanyDatePreset.thisMonth,
            onTap: () => setPreset(CompanyDatePreset.thisMonth),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Last month',
            selected: filters.datePreset == CompanyDatePreset.lastMonth,
            onTap: () => setPreset(CompanyDatePreset.lastMonth),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'Custom',
            selected: filters.datePreset == CompanyDatePreset.custom,
            onTap: () async {
              final now = DateTime.now();
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: now,
                initialDateRange: DateTimeRange(
                  start: filters.customStart ?? DateTime(now.year, now.month, 1),
                  end: filters.customEnd ?? now,
                ),
              );
              if (range == null) return;
              ref.read(companyTxFiltersProvider.notifier).state = filters.copyWith(
                datePreset: CompanyDatePreset.custom,
                customStart: range.start,
                customEnd: range.end,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TypeFilters extends ConsumerWidget {
  const _TypeFilters({required this.filters});

  final CompanyTxFilters filters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget chip(String label, CompanyTxTypeFilter type) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: _Chip(
          label: label,
          selected: filters.typeFilter == type,
          onTap: () {
            ref.read(companyTxFiltersProvider.notifier).state =
                filters.copyWith(typeFilter: type);
          },
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('All', CompanyTxTypeFilter.all),
          chip('Income', CompanyTxTypeFilter.income),
          chip('Shared Expense', CompanyTxTypeFilter.sharedExpense),
          chip('Withdrawals', CompanyTxTypeFilter.withdrawals),
          chip('Contributions', CompanyTxTypeFilter.contributions),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    );
  }
}
