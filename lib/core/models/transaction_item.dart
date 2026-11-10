import 'package:expense_tracker/core/enums/transaction_type.dart';

class TransactionItem {
  const TransactionItem({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.accountId,
    this.categoryId,
    this.description,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.accountName,
  });

  final String id;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String accountId;
  final String? categoryId;
  final String? description;
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? accountName;

  String get title {
    final desc = description?.trim();
    if (desc != null && desc.isNotEmpty) return desc;
    final category = categoryName?.trim();
    if (category != null && category.isNotEmpty) return category;
    return type == TransactionType.expense ? 'Expense' : 'Income';
  }

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    final type = TransactionType.fromValue(json['type'] as String?);
    if (type == null) {
      throw FormatException('Unknown transaction type: ${json['type']}');
    }

    final category = json['categories'];
    final account = json['accounts'];
    Map<String, dynamic>? categoryMap;
    Map<String, dynamic>? accountMap;
    if (category is Map<String, dynamic>) categoryMap = category;
    if (account is Map<String, dynamic>) accountMap = account;

    return TransactionItem(
      id: json['id'] as String,
      type: type,
      amount: _toDouble(json['amount']),
      date: DateTime.parse(json['date'] as String),
      accountId: json['account_id'] as String,
      categoryId: json['category_id'] as String?,
      description: json['description'] as String?,
      categoryName: categoryMap?['name'] as String?,
      categoryIcon: categoryMap?['icon'] as String?,
      categoryColor: categoryMap?['color'] as String?,
      accountName: accountMap?['name'] as String?,
    );
  }

  static double _toDouble(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
