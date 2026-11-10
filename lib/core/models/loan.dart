import 'package:expense_tracker/core/enums/loan_status.dart';
import 'package:expense_tracker/core/enums/loan_type.dart';

class Loan {
  const Loan({
    required this.id,
    required this.userId,
    required this.personName,
    required this.type,
    required this.amount,
    required this.remainingAmount,
    required this.status,
    this.accountId,
    this.phone,
    this.description,
    this.dueDate,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String personName;
  final LoanType type;
  final double amount;
  final double remainingAmount;
  final LoanStatus status;
  final String? accountId;
  final String? phone;
  final String? description;
  final DateTime? dueDate;
  final DateTime? createdAt;

  double get repaidAmount => amount - remainingAmount;

  double get repaidFraction =>
      amount <= 0 ? 0 : (repaidAmount / amount).clamp(0.0, 1.0);

  bool get isOverdue {
    if (dueDate == null || status == LoanStatus.settled) return false;
    final today = DateTime.now();
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    final now = DateTime(today.year, today.month, today.day);
    return due.isBefore(now);
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    final type = _loanTypeFrom(json['type'] as String?);
    final status = _loanStatusFrom(json['status'] as String?);

    return Loan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      personName: json['person_name'] as String,
      type: type,
      amount: _toDouble(json['amount']),
      remainingAmount: _toDouble(json['remaining_amount']),
      status: status,
      accountId: json['account_id'] as String?,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  static LoanType _loanTypeFrom(String? raw) {
    for (final t in LoanType.values) {
      if (t.value == raw) return t;
    }
    return LoanType.given;
  }

  static LoanStatus _loanStatusFrom(String? raw) {
    for (final s in LoanStatus.values) {
      if (s.value == raw) return s;
    }
    return LoanStatus.pending;
  }

  static double _toDouble(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}

class LoanPayment {
  const LoanPayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.paidAt,
    this.accountId,
    this.note,
  });

  final String id;
  final String loanId;
  final double amount;
  final DateTime paidAt;
  final String? accountId;
  final String? note;

  factory LoanPayment.fromJson(Map<String, dynamic> json) {
    return LoanPayment(
      id: json['id'] as String,
      loanId: json['loan_id'] as String,
      amount: Loan._toDouble(json['amount']),
      paidAt: DateTime.parse(json['paid_at'] as String),
      accountId: json['account_id'] as String?,
      note: json['note'] as String?,
    );
  }
}

class LoanDetail {
  const LoanDetail({
    required this.loan,
    required this.payments,
  });

  final Loan loan;
  final List<LoanPayment> payments;
}

class LoanTabSummary {
  const LoanTabSummary({
    required this.totalAmount,
    required this.outstanding,
  });

  final double totalAmount;
  final double outstanding;
}
