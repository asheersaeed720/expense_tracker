import 'package:expense_tracker/core/enums/company_tx_type.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';

class CompanyTransaction {
  const CompanyTransaction({
    required this.id,
    required this.ledgerId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.mySplitAmount,
    required this.partnerSplitAmount,
    required this.category,
    required this.date,
    this.description,
    this.linkedPersonalTxId,
  });

  final String id;
  final String ledgerId;
  final String userId;
  final CompanyTxType type;
  final double amount;
  final double mySplitAmount;
  final double partnerSplitAmount;
  final String category;
  final DateTime date;
  final String? description;
  final String? linkedPersonalTxId;

  String get title {
    final desc = description?.trim();
    if (desc != null && desc.isNotEmpty) return desc;
    return category;
  }

  String splitLabel(String currency) {
    final formatted = CurrencyFormatter.format(amount, currencyCode: currency);
    switch (type) {
      case CompanyTxType.myWithdrawal:
        return 'My Payout: -$formatted';
      case CompanyTxType.partnerWithdrawal:
        return 'Partner Payout: -$formatted';
      case CompanyTxType.myContribution:
        return 'My capital: +$formatted';
      case CompanyTxType.partnerContribution:
        return 'Partner capital: +$formatted';
      case CompanyTxType.income:
      case CompanyTxType.sharedExpense:
        final sign = type == CompanyTxType.income ? '+' : '-';
        final mine = CurrencyFormatter.format(mySplitAmount, currencyCode: currency);
        final partner = CurrencyFormatter.format(
          partnerSplitAmount,
          currencyCode: currency,
        );
        return 'Me: $sign$mine • Partner: $sign$partner';
    }
  }

  factory CompanyTransaction.fromJson(Map<String, dynamic> json) {
    final type = CompanyTxType.fromValue(json['type'] as String?);
    if (type == null) {
      throw FormatException('Unknown company transaction type: ${json['type']}');
    }

    return CompanyTransaction(
      id: json['id'] as String,
      ledgerId: json['ledger_id'] as String,
      userId: json['user_id'] as String,
      type: type,
      amount: _toDouble(json['amount']),
      mySplitAmount: _toDouble(json['my_split_amount']),
      partnerSplitAmount: _toDouble(json['partner_split_amount']),
      category: json['category'] as String? ?? 'Other',
      description: json['description'] as String?,
      date: DateTime.parse(json['date'] as String),
      linkedPersonalTxId: json['linked_personal_tx_id'] as String?,
    );
  }

  static double _toDouble(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
