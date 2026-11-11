import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:expense_tracker/core/enums/company_tx_type.dart';
import 'package:expense_tracker/core/models/company_ledger.dart';
import 'package:expense_tracker/core/models/company_transaction.dart';
import 'package:expense_tracker/features/company/company_split.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CompanyService {
  CompanyService({SupabaseClient? client}) : _client = client ?? supabase;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Stream<CompanyLedger?> watchLedger() {
    final userId = _userId;
    if (userId == null) return Stream.value(null);

    return _client
        .from('company_ledgers')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) {
      if (rows.isEmpty) return null;
      rows.sort((a, b) {
        final aTime = (a['created_at'] ?? '').toString();
        final bTime = (b['created_at'] ?? '').toString();
        return aTime.compareTo(bTime);
      });
      return CompanyLedger.fromJson(rows.first);
    });
  }

  Future<CompanyLedger?> fetchLedger() async {
    final userId = _userId;
    if (userId == null) return null;

    final rows = await _client
        .from('company_ledgers')
        .select()
        .eq('user_id', userId)
        .order('created_at')
        .limit(1);

    if (rows.isEmpty) return null;
    return CompanyLedger.fromJson(rows.first);
  }

  Future<void> setCompanyMode(bool enabled) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');

    await _client.from('profiles').update({
      'company_mode_enabled': enabled,
    }).eq('id', userId);
  }

  Future<void> createLedger({
    required String companyName,
    required String partnerName,
    required double mySharePercent,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');

    final existing = await fetchLedger();
    if (existing != null) {
      throw StateError('A company ledger already exists.');
    }

    final shares = _shares(mySharePercent);
    await _client.from('company_ledgers').insert({
      'user_id': userId,
      'company_name': companyName.trim(),
      'partner_name': partnerName.trim(),
      'my_share_percent': shares.mine,
      'partner_share_percent': shares.partner,
    });
    await setCompanyMode(true);
  }

  Future<void> updateLedger({
    required String id,
    required String companyName,
    required String partnerName,
    required double mySharePercent,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');

    final shares = _shares(mySharePercent);
    await _client.from('company_ledgers').update({
      'company_name': companyName.trim(),
      'partner_name': partnerName.trim(),
      'my_share_percent': shares.mine,
      'partner_share_percent': shares.partner,
    }).eq('id', id).eq('user_id', userId);
  }

  Future<List<CompanyTransaction>> fetchTransactions({
    required String ledgerId,
    DateTime? start,
    DateTime? end,
    int? limit,
  }) async {
    final userId = _userId;
    if (userId == null) return [];

    var query = _client
        .from('company_transactions')
        .select()
        .eq('user_id', userId)
        .eq('ledger_id', ledgerId);

    if (start != null) query = query.gte('date', _dateOnly(start));
    if (end != null) query = query.lte('date', _dateOnly(end));

    final ordered = query.order('date', ascending: false).order('created_at', ascending: false);
    final rows = limit == null ? await ordered : await ordered.limit(limit);
    return rows.map(CompanyTransaction.fromJson).toList();
  }

  Future<CompanyTransaction?> fetchById(String id) async {
    final userId = _userId;
    if (userId == null) return null;

    final row = await _client
        .from('company_transactions')
        .select()
        .eq('id', id)
        .eq('user_id', userId)
        .maybeSingle();

    if (row == null) return null;
    return CompanyTransaction.fromJson(row);
  }

  Future<String?> fetchPersonalAccountId(String transactionId) async {
    final userId = _userId;
    if (userId == null) return null;

    final row = await _client
        .from('transactions')
        .select('account_id')
        .eq('id', transactionId)
        .eq('user_id', userId)
        .maybeSingle();

    return row?['account_id'] as String?;
  }

  Future<void> saveTransaction({
    String? id,
    required String ledgerId,
    required String companyName,
    required CompanyTxType type,
    required double amount,
    required double mySharePercent,
    required String category,
    required DateTime date,
    String? description,
    bool linkPersonal = false,
    String? personalAccountId,
    String? existingLinkedPersonalTxId,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');
    if (amount <= 0) throw ArgumentError('Amount must be greater than zero.');

    final split = CompanySplit.forType(
      type: type,
      amount: amount,
      mySharePercent: mySharePercent,
    );
    final trimmed = description?.trim();
    final payload = {
      'ledger_id': ledgerId,
      'user_id': userId,
      'type': type.value,
      'amount': CompanySplit.centsToSql(CompanySplit.toCents(amount)),
      'my_split_amount': CompanySplit.centsToSql(split.mineCents),
      'partner_split_amount': CompanySplit.centsToSql(split.partnerCents),
      'category': category,
      'description': trimmed == null || trimmed.isEmpty ? null : trimmed,
      'date': _dateOnly(date),
    };

    final wantsLink = linkPersonal &&
        type.canLinkPersonalAccount &&
        personalAccountId != null;

    if (id == null) {
      String? linkedId;
      try {
        if (wantsLink) {
          linkedId = await _insertPersonalTx(
            type: type,
            amount: amount,
            accountId: personalAccountId,
            companyName: companyName,
            date: date,
          );
        }
        await _client.from('company_transactions').insert({
          ...payload,
          'linked_personal_tx_id': linkedId,
        });
      } catch (e) {
        if (linkedId != null) {
          await _client.from('transactions').delete().eq('id', linkedId).eq('user_id', userId);
        }
        rethrow;
      }
      return;
    }

    var linkedId = existingLinkedPersonalTxId;
    if (wantsLink) {
      if (linkedId != null) {
        await _updatePersonalTx(
          id: linkedId,
          type: type,
          amount: amount,
          accountId: personalAccountId,
          companyName: companyName,
          date: date,
        );
      } else {
        linkedId = await _insertPersonalTx(
          type: type,
          amount: amount,
          accountId: personalAccountId,
          companyName: companyName,
          date: date,
        );
      }
    } else if (linkedId != null) {
      final staleId = linkedId;
      linkedId = null;
      await _client.from('company_transactions').update({
        ...payload,
        'linked_personal_tx_id': null,
      }).eq('id', id).eq('user_id', userId);
      await _client.from('transactions').delete().eq('id', staleId).eq('user_id', userId);
      return;
    }

    await _client.from('company_transactions').update({
      ...payload,
      'linked_personal_tx_id': linkedId,
    }).eq('id', id).eq('user_id', userId);
  }

  Future<void> deleteTransaction(CompanyTransaction transaction) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');

    await _client
        .from('company_transactions')
        .delete()
        .eq('id', transaction.id)
        .eq('user_id', userId);

    final linked = transaction.linkedPersonalTxId;
    if (linked != null) {
      await _client.from('transactions').delete().eq('id', linked).eq('user_id', userId);
    }
  }

  Future<String> _insertPersonalTx({
    required CompanyTxType type,
    required double amount,
    required String accountId,
    required String companyName,
    required DateTime date,
  }) async {
    final userId = _userId!;
    final personalType = type == CompanyTxType.myWithdrawal ? 'income' : 'expense';
    final categoryId = await _businessCategoryId(personalType);
    final row = await _client.from('transactions').insert({
      'user_id': userId,
      'account_id': accountId,
      'category_id': categoryId,
      'type': personalType,
      'amount': CompanySplit.centsToSql(CompanySplit.toCents(amount)),
      'description': _personalDescription(type, companyName),
      'date': _dateOnly(date),
    }).select('id').single();

    return row['id'] as String;
  }

  Future<void> _updatePersonalTx({
    required String id,
    required CompanyTxType type,
    required double amount,
    required String accountId,
    required String companyName,
    required DateTime date,
  }) async {
    final userId = _userId!;
    final personalType = type == CompanyTxType.myWithdrawal ? 'income' : 'expense';
    final categoryId = await _businessCategoryId(personalType);
    await _client.from('transactions').update({
      'account_id': accountId,
      'category_id': categoryId,
      'type': personalType,
      'amount': CompanySplit.centsToSql(CompanySplit.toCents(amount)),
      'description': _personalDescription(type, companyName),
      'date': _dateOnly(date),
    }).eq('id', id).eq('user_id', userId);
  }

  Future<String> _businessCategoryId(String type) async {
    final userId = _userId!;
    final existing = await _client
        .from('categories')
        .select('id')
        .eq('user_id', userId)
        .eq('type', type)
        .eq('name', 'Business')
        .limit(1);

    if (existing.isNotEmpty) return existing.first['id'] as String;

    final created = await _client.from('categories').insert({
      'user_id': userId,
      'name': 'Business',
      'type': type,
      'icon': 'store',
      'color': '#FDCB6E',
    }).select('id').single();

    return created['id'] as String;
  }

  String _personalDescription(CompanyTxType type, String companyName) {
    if (type == CompanyTxType.myWithdrawal) return 'Payout from $companyName';
    return 'Contribution to $companyName';
  }

  ({String mine, String partner}) _shares(double mySharePercent) {
    final mineCents = (mySharePercent * 100).round();
    if (mineCents <= 0 || mineCents >= 10000) {
      throw ArgumentError('Your share must be greater than 0 and less than 100.');
    }
    final partnerCents = 10000 - mineCents;
    return (
      mine: CompanySplit.centsToSql(mineCents),
      partner: CompanySplit.centsToSql(partnerCents),
    );
  }

  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;
}
