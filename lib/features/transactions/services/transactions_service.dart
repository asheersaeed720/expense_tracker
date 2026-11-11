import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:expense_tracker/core/enums/transaction_type.dart';
import 'package:expense_tracker/features/accounts/services/accounts_service.dart';
import 'package:expense_tracker/core/models/monthly_stats.dart';
import 'package:expense_tracker/core/models/transaction_item.dart';
import 'package:expense_tracker/features/transactions/models/transaction_filters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionsService {
  TransactionsService({SupabaseClient? client, AccountsService? accountsService})
      : _client = client ?? supabase,
        _accountsService = accountsService ?? AccountsService(client: client);

  final SupabaseClient _client;
  final AccountsService _accountsService;

  static const String _selectWithJoins =
      '*, categories(name, icon, color), accounts(name)';

  String? get _userId => _client.auth.currentUser?.id;

  Stream<void> watchTransactionChanges() => _transactionChangeSignal();

  Stream<void> _transactionChangeSignal() {
    final userId = _userId;
    if (userId == null) return const Stream.empty();

    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((_) {});
  }

  Stream<List<TransactionItem>> watchRecentTransactions({int limit = 5}) async* {
    yield await fetchRecentTransactions(limit: limit);
    await for (final _ in _transactionChangeSignal()) {
      yield await fetchRecentTransactions(limit: limit);
    }
  }

  Stream<MonthlyStats> watchMonthlyStats() async* {
    yield await fetchMonthlyStats();
    await for (final _ in _transactionChangeSignal()) {
      yield await fetchMonthlyStats();
    }
  }

  Future<List<TransactionItem>> fetchRecentTransactions({int limit = 5}) async {
    final userId = _userId;
    if (userId == null) return [];

    final rows = await _client
        .from('transactions')
        .select(_selectWithJoins)
        .eq('user_id', userId)
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .limit(limit);

    return rows.map((e) => TransactionItem.fromJson(e)).toList();
  }

  Future<List<TransactionItem>> fetchFiltered({
    required TransactionFilters filters,
    required int limit,
    required int offset,
  }) async {
    final userId = _userId;
    if (userId == null) return [];

    final (start, end) = filters.resolveRange();
    var query = _client
        .from('transactions')
        .select(_selectWithJoins)
        .eq('user_id', userId)
        .gte('date', _dateOnly(start))
        .lte('date', _dateOnly(end));

    if (filters.type != null) {
      query = query.eq('type', filters.type!.value);
    }
    if (filters.accountId != null) {
      query = query.eq('account_id', filters.accountId!);
    }

    final rows = await query
        .order('date', ascending: false)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return rows.map((e) => TransactionItem.fromJson(e)).toList();
  }

  Future<FilteredTotals> fetchFilteredTotals(TransactionFilters filters) async {
    final userId = _userId;
    if (userId == null) {
      return const FilteredTotals(income: 0, expense: 0);
    }

    final (start, end) = filters.resolveRange();
    var query = _client
        .from('transactions')
        .select('type, amount')
        .eq('user_id', userId)
        .gte('date', _dateOnly(start))
        .lte('date', _dateOnly(end));

    if (filters.type != null) {
      query = query.eq('type', filters.type!.value);
    }
    if (filters.accountId != null) {
      query = query.eq('account_id', filters.accountId!);
    }

    final rows = await query;

    var income = 0.0;
    var expense = 0.0;
    for (final row in rows) {
      final amount = (row['amount'] as num).toDouble();
      if (row['type'] == 'income') {
        income += amount;
      } else {
        expense += amount;
      }
    }

    return FilteredTotals(income: income, expense: expense);
  }

  Future<TransactionItem?> fetchById(String id) async {
    final userId = _userId;
    if (userId == null) return null;

    final row = await _client
        .from('transactions')
        .select(_selectWithJoins)
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return null;
    return TransactionItem.fromJson(row);
  }

  Future<void> createTransaction({
    required TransactionType type,
    required double amount,
    required String accountId,
    required String categoryId,
    required DateTime date,
    String? description,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');
    if (amount <= 0) throw ArgumentError('Amount must be greater than zero.');

    await _client.from('transactions').insert({
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'type': type.value,
      'amount': amount,
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'date': _dateOnly(date),
    });

    await _accountsService.reconcileBalancesFromTransactions();
  }

  Future<void> updateTransaction({
    required String id,
    required TransactionType type,
    required double amount,
    required String accountId,
    required String categoryId,
    required DateTime date,
    String? description,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');
    if (amount <= 0) throw ArgumentError('Amount must be greater than zero.');

    await _client.from('transactions').update({
      'account_id': accountId,
      'category_id': categoryId,
      'type': type.value,
      'amount': amount,
      'description': description?.trim().isEmpty == true ? null : description?.trim(),
      'date': _dateOnly(date),
    }).eq('id', id).eq('user_id', userId);

    await _accountsService.reconcileBalancesFromTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');

    await _client.from('transactions').delete().eq('id', id).eq('user_id', userId);

    await _accountsService.reconcileBalancesFromTransactions();
  }

  Future<MonthlyStats> fetchMonthlyStats() async {
    final userId = _userId;
    if (userId == null) {
      return const MonthlyStats(income: 0, expense: 0);
    }

    final filters = TransactionFilters(
      datePreset: TransactionDatePreset.thisMonth,
    );
    final (start, end) = filters.resolveRange();

    final rows = await _client
        .from('transactions')
        .select('type, amount')
        .eq('user_id', userId)
        .gte('date', _dateOnly(start))
        .lte('date', _dateOnly(end));

    var income = 0.0;
    var expense = 0.0;
    for (final row in rows) {
      final amount = (row['amount'] as num).toDouble();
      if (row['type'] == 'income') {
        income += amount;
      } else {
        expense += amount;
      }
    }

    return MonthlyStats(income: income, expense: expense);
  }

  String _dateOnly(DateTime date) {
    return date.toIso8601String().split('T').first;
  }
}
