import 'package:expense_tracker/features/accounts/providers/accounts_providers.dart';
import 'package:expense_tracker/features/transactions/providers/transactions_list_provider.dart';
import 'package:expense_tracker/features/transactions/providers/transactions_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> refreshDashboard(WidgetRef ref) async {
  ref.invalidate(profileProvider);
  ref.invalidate(accountsProvider);
  ref.invalidate(recentTransactionsProvider);
  ref.invalidate(monthlyStatsProvider);
  ref.invalidate(transactionsListProvider);
  await Future<void>.delayed(const Duration(milliseconds: 300));
}
