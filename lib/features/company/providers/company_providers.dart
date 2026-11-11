import 'package:expense_tracker/core/enums/company_tx_type.dart';
import 'package:expense_tracker/core/models/company_ledger.dart';
import 'package:expense_tracker/core/models/company_transaction.dart';
import 'package:expense_tracker/features/company/models/company_tx_filters.dart';
import 'package:expense_tracker/features/company/services/company_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final companyServiceProvider = Provider<CompanyService>((ref) {
  return CompanyService();
});

final companyLedgerProvider = StreamProvider<CompanyLedger?>((ref) {
  return ref.watch(companyServiceProvider).watchLedger();
});

final companyTxFiltersProvider = StateProvider<CompanyTxFilters>((ref) {
  return const CompanyTxFilters();
});

final companyTransactionsProvider =
    FutureProvider<List<CompanyTransaction>>((ref) async {
  final ledger = await ref.watch(companyLedgerProvider.future);
  if (ledger == null) return const [];

  final filters = ref.watch(companyTxFiltersProvider);
  final (start, end) = filters.resolveRange();
  final rows = await ref.watch(companyServiceProvider).fetchTransactions(
        ledgerId: ledger.id,
        start: start,
        end: end,
      );

  final query = filters.searchQuery?.trim().toLowerCase();
  return [
    for (final row in rows)
      if (filters.matchesType(row.type) && _matchesSearch(row, query)) row,
  ];
});

final recentCompanyTransactionsProvider =
    FutureProvider<List<CompanyTransaction>>((ref) async {
  final ledger = await ref.watch(companyLedgerProvider.future);
  if (ledger == null) return const [];
  return ref.watch(companyServiceProvider).fetchTransactions(
        ledgerId: ledger.id,
        limit: 5,
      );
});

class CompanyMonthOverview {
  const CompanyMonthOverview({
    required this.income,
    required this.sharedExpenses,
  });

  final double income;
  final double sharedExpenses;

  double get net => income - sharedExpenses;
}

final companyMonthOverviewProvider =
    FutureProvider<CompanyMonthOverview>((ref) async {
  final ledger = await ref.watch(companyLedgerProvider.future);
  if (ledger == null) {
    return const CompanyMonthOverview(income: 0, sharedExpenses: 0);
  }

  final now = DateTime.now();
  final rows = await ref.watch(companyServiceProvider).fetchTransactions(
        ledgerId: ledger.id,
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0),
      );

  var income = 0.0;
  var shared = 0.0;
  for (final row in rows) {
    if (row.type == CompanyTxType.income) income += row.amount;
    if (row.type == CompanyTxType.sharedExpense) shared += row.amount;
  }
  return CompanyMonthOverview(income: income, sharedExpenses: shared);
});

bool _matchesSearch(CompanyTransaction row, String? query) {
  if (query == null || query.isEmpty) return true;
  final haystack = [
    row.title,
    row.category,
    row.type.label,
    row.amount.toString(),
    row.description ?? '',
  ].join(' ').toLowerCase();
  return haystack.contains(query);
}

void refreshCompanyViews(WidgetRef ref) {
  ref.invalidate(companyTransactionsProvider);
  ref.invalidate(recentCompanyTransactionsProvider);
  ref.invalidate(companyMonthOverviewProvider);
  ref.invalidate(companyLedgerProvider);
}
