import 'package:expense_tracker/config/supabase/supabase_bootstrap.dart';
import 'package:expense_tracker/core/enums/loan_type.dart';
import 'package:expense_tracker/core/enums/transaction_type.dart';
import 'package:expense_tracker/core/models/loan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoansService {
  LoansService({SupabaseClient? client}) : _client = client ?? supabase;

  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  Stream<List<Loan>> watchLoans(LoanType type) {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);

    return _client
        .from('loans')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) {
      return rows
          .where((r) => r['type'] == type.value)
          .map(Loan.fromJson)
          .toList()
        ..sort((a, b) => b.createdAt?.compareTo(a.createdAt ?? DateTime(1970)) ?? 0);
    });
  }

  Stream<void> watchLoanChanges() {
    final userId = _userId;
    if (userId == null) return const Stream.empty();

    return _client
        .from('loans')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((_) {});
  }

  Future<LoanDetail?> fetchLoanDetail(String loanId) async {
    final userId = _userId;
    if (userId == null) return null;

    final loanRow = await _client
        .from('loans')
        .select()
        .eq('id', loanId)
        .eq('user_id', userId)
        .maybeSingle();

    if (loanRow == null) return null;

    final payments = await _client
        .from('loan_payments')
        .select()
        .eq('loan_id', loanId)
        .eq('user_id', userId)
        .order('paid_at', ascending: false)
        .order('created_at', ascending: false);

    return LoanDetail(
      loan: Loan.fromJson(loanRow),
      payments: payments.map(LoanPayment.fromJson).toList(),
    );
  }

  Future<Loan> createLoan({
    required LoanType type,
    required String personName,
    required double amount,
    String? phone,
    String? accountId,
    String? description,
    DateTime? dueDate,
    /// When false, the loan is tracked only (e.g. money moved before you used the app).
    /// No opening transaction is created and [accountId] is not stored.
    bool affectsAccountBalance = true,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');
    if (amount <= 0) throw ArgumentError('Amount must be greater than zero.');

    final linkedAccountId = affectsAccountBalance ? accountId : null;

    final insertRow = await _client
        .from('loans')
        .insert({
          'user_id': userId,
          'person_name': personName.trim(),
          'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
          'type': type.value,
          'amount': amount,
          'remaining_amount': amount,
          'account_id': linkedAccountId,
          'description':
              description?.trim().isEmpty == true ? null : description?.trim(),
          'due_date': dueDate != null ? _dateOnly(dueDate) : null,
          'status': 'pending',
        })
        .select()
        .single();

    final loan = Loan.fromJson(insertRow);

    if (affectsAccountBalance && linkedAccountId != null) {
      await _createLoanOpeningTransaction(
        loan: loan,
        accountId: linkedAccountId,
        amount: amount,
      );
    }

    return loan;
  }

  Future<void> updateLoan({
    required String loanId,
    required String personName,
    String? phone,
    String? description,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');

    await _client.from('loans').update({
      'person_name': personName.trim(),
      'phone': phone?.trim().isEmpty == true ? null : phone?.trim(),
      'description':
          description?.trim().isEmpty == true ? null : description?.trim(),
      'due_date': clearDueDate ? null : (dueDate != null ? _dateOnly(dueDate) : null),
    }).eq('id', loanId).eq('user_id', userId);
  }

  Future<void> deleteLoan(String loanId) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');

    await _client.from('loans').delete().eq('id', loanId).eq('user_id', userId);
  }

  Future<void> recordPayment({
    required Loan loan,
    required double amount,
    required String accountId,
    DateTime? paidAt,
    String? note,
  }) async {
    final userId = _userId;
    if (userId == null) throw const AuthException('Not signed in');

    if (amount <= 0) throw ArgumentError('Amount must be greater than zero.');
    if (amount > loan.remainingAmount + 0.001) {
      throw StateError('Amount cannot exceed remaining balance.');
    }

    final date = paidAt ?? DateTime.now();
    final dateStr = _dateOnly(date);

    await _client.from('loan_payments').insert({
      'loan_id': loan.id,
      'user_id': userId,
      'amount': amount,
      'account_id': accountId,
      'note': note?.trim().isEmpty == true ? null : note?.trim(),
      'paid_at': dateStr,
    });

    final transactionType = loan.type == LoanType.given
        ? TransactionType.income
        : TransactionType.expense;
    final description = loan.type == LoanType.given
        ? 'Loan repayment from ${loan.personName}'
        : 'Loan repayment to ${loan.personName}';

    await _client.from('transactions').insert({
      'user_id': userId,
      'account_id': accountId,
      'type': transactionType.value,
      'amount': amount,
      'description': description,
      'date': dateStr,
    });
  }

  Future<void> settleLoan({
    required Loan loan,
    required String accountId,
    String? note,
  }) async {
    if (loan.remainingAmount <= 0) return;

    await recordPayment(
      loan: loan,
      amount: loan.remainingAmount,
      accountId: accountId,
      note: note ?? 'Full settlement',
    );
  }

  Future<void> _createLoanOpeningTransaction({
    required Loan loan,
    required String accountId,
    required double amount,
  }) async {
    final userId = _userId!;
    final dateStr = _dateOnly(DateTime.now());

    final type = loan.type == LoanType.given
        ? TransactionType.expense
        : TransactionType.income;
    final description = loan.type == LoanType.given
        ? 'Loan to ${loan.personName}'
        : 'Loan from ${loan.personName}';

    await _client.from('transactions').insert({
      'user_id': userId,
      'account_id': accountId,
      'type': type.value,
      'amount': amount,
      'description': description,
      'date': dateStr,
    });
  }

  String _dateOnly(DateTime date) {
    return date.toIso8601String().split('T').first;
  }
}
