import 'package:expense_tracker/core/models/account.dart';
import 'package:expense_tracker/core/models/user_profile.dart';
import 'package:expense_tracker/features/accounts/services/accounts_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final accountsServiceProvider = Provider<AccountsService>((ref) {
  return AccountsService();
});

final accountsProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(accountsServiceProvider).watchAccounts();
});

final profileProvider = FutureProvider<UserProfile?>((ref) async {
  ref.watch(accountsProvider);
  return ref.watch(accountsServiceProvider).fetchProfile();
});

final totalBalanceProvider = Provider<double>((ref) {
  final accounts = ref.watch(accountsProvider).valueOrNull ?? const [];
  return accounts.fold<double>(0, (sum, account) => sum + account.balance);
});
