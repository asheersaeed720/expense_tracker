import 'package:expense_tracker/core/enums/loan_status.dart';
import 'package:expense_tracker/core/enums/loan_type.dart';
import 'package:expense_tracker/core/models/loan.dart';
import 'package:flutter_test/flutter_test.dart';

Loan _loan({
  double amount = 1000,
  double remaining = 400,
  LoanStatus status = LoanStatus.partial,
  DateTime? dueDate,
}) {
  return Loan(
    id: 'loan-1',
    userId: 'user-1',
    personName: 'Ali',
    type: LoanType.given,
    amount: amount,
    remainingAmount: remaining,
    status: status,
    dueDate: dueDate,
  );
}

void main() {
  test('repaid fraction is the share already paid, clamped to 0..1', () {
    expect(_loan(amount: 1000, remaining: 250).repaidAmount, 750);
    expect(_loan(amount: 1000, remaining: 250).repaidFraction, 0.75);
    expect(_loan(amount: 0, remaining: 0).repaidFraction, 0);
    expect(_loan(amount: 100, remaining: 150).repaidFraction, 0);
    expect(_loan(amount: 100, remaining: 0).repaidFraction, 1);
  });

  test('a settled loan is never overdue, even when the due date has passed', () {
    final past = DateTime(2020, 1, 1);
    expect(
      _loan(status: LoanStatus.settled, dueDate: past).isOverdue,
      isFalse,
    );
    expect(
      _loan(status: LoanStatus.pending, dueDate: past).isOverdue,
      isTrue,
    );
    expect(
      _loan(dueDate: DateTime(2100, 1, 1)).isOverdue,
      isFalse,
    );
    expect(_loan(dueDate: null).isOverdue, isFalse);
  });

  test('fromJson reads numeric amounts that arrive as strings', () {
    final loan = Loan.fromJson({
      'id': 'loan-1',
      'user_id': 'user-1',
      'person_name': 'Ali',
      'type': 'taken',
      'amount': '1500.50',
      'remaining_amount': '500.25',
      'status': 'partial',
      'due_date': '2026-11-01',
    });

    expect(loan.type, LoanType.taken);
    expect(loan.amount, 1500.50);
    expect(loan.remainingAmount, 500.25);
    expect(loan.dueDate, DateTime.parse('2026-11-01'));
  });
}
