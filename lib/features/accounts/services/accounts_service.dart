import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:expense_tracker/core/enums/account_type.dart';
import 'package:expense_tracker/core/models/account.dart';
import 'package:expense_tracker/core/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountsService {
  AccountsService({SupabaseClient? client}) : _client = client ?? supabase;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Stream<List<Account>> watchAccounts() {
    final userId = _userId;
    if (userId == null) {
      return Stream.value(const []);
    }

    return _client
        .from('accounts')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) {
      final list = rows.map((e) => Account.fromJson(e)).toList()
        ..sort((a, b) {
          if (a.isDefault != b.isDefault) {
            return a.isDefault ? -1 : 1;
          }
          return a.name.compareTo(b.name);
        });
      return list;
    });
  }

  Future<UserProfile?> fetchProfile() async {
    final userId = _userId;
    if (userId == null) return null;

    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;
    return UserProfile.fromJson(row);
  }

  Future<void> createAccount({
    required String name,
    required AccountType type,
    double initialBalance = 0,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');

    await _client.from('accounts').insert({
      'user_id': userId,
      'name': name.trim(),
      'type': type.value,
      'balance': initialBalance,
      'is_default': false,
    });
  }

  Future<void> updateAccountName({
    required String accountId,
    required String name,
  }) async {
    await _client.from('accounts').update({
      'name': name.trim(),
    }).eq('id', accountId);
  }

  Future<bool> hasTransactions(String accountId) async {
    final rows = await _client
        .from('transactions')
        .select('id')
        .eq('account_id', accountId)
        .limit(1);
    return rows.isNotEmpty;
  }

  Future<void> deleteAccount(String accountId) async {
    final account = await _client
        .from('accounts')
        .select('balance, is_default')
        .eq('id', accountId)
        .single();

    final balance = (account['balance'] as num?)?.toDouble() ?? 0;

    if (balance != 0) {
      throw StateError('Cannot delete an account with a non-zero balance.');
    }

    if (await hasTransactions(accountId)) {
      throw StateError('Cannot delete an account that has transactions.');
    }

    if (account['is_default'] == true) {
      throw StateError('Cannot delete your default account.');
    }

    await _client.from('accounts').delete().eq('id', accountId);
  }

  Future<void> transferBetweenAccounts({
    required String fromAccountId,
    required String toAccountId,
    required double amount,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');

    if (fromAccountId == toAccountId) {
      throw ArgumentError('Choose two different accounts.');
    }
    if (amount <= 0) throw ArgumentError('Amount must be greater than zero.');

    final accounts = await _client
        .from('accounts')
        .select('id, name, balance')
        .inFilter('id', [fromAccountId, toAccountId]);

    if (accounts.length != 2) {
      throw StateError('Could not find both accounts.');
    }

    final from = accounts.firstWhere((a) => a['id'] == fromAccountId);
    final to = accounts.firstWhere((a) => a['id'] == toAccountId);
    final fromBalance = (from['balance'] as num?)?.toDouble() ?? 0;

    if (fromBalance < amount) {
      throw StateError('Insufficient balance in source account.');
    }

    final today = DateTime.now().toIso8601String().split('T').first;
    final toName = to['name'] as String;
    final fromName = from['name'] as String;

    await _client.from('transactions').insert([
      {
        'user_id': userId,
        'account_id': fromAccountId,
        'type': 'expense',
        'amount': amount,
        'description': 'Transfer to $toName',
        'date': today,
      },
      {
        'user_id': userId,
        'account_id': toAccountId,
        'type': 'income',
        'amount': amount,
        'description': 'Transfer from $fromName',
        'date': today,
      },
    ]);
  }
}
