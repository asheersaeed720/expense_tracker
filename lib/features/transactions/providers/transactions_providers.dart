import 'package:expense_tracker/core/models/monthly_stats.dart';
import 'package:expense_tracker/core/models/transaction_item.dart';
import 'package:expense_tracker/features/transactions/services/transactions_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final transactionsServiceProvider = Provider<TransactionsService>((ref) {
  return TransactionsService();
});

final recentTransactionsProvider =
    StreamProvider<List<TransactionItem>>((ref) {
  return ref.watch(transactionsServiceProvider).watchRecentTransactions();
});

final monthlyStatsProvider = StreamProvider<MonthlyStats>((ref) {
  return ref.watch(transactionsServiceProvider).watchMonthlyStats();
});
