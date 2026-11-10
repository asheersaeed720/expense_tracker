import 'package:expense_tracker/core/enums/account_type.dart';

class Account {
  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.balance,
    this.icon,
    this.isDefault = false,
  });

  final String id;
  final String userId;
  final String name;
  final AccountType type;
  final double balance;
  final String? icon;
  final bool isDefault;

  factory Account.fromJson(Map<String, dynamic> json) {
    final type = AccountType.fromValue(json['type'] as String?);
    if (type == null) {
      throw FormatException('Unknown account type: ${json['type']}');
    }

    return Account(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: type,
      balance: _toDouble(json['balance']),
      icon: json['icon'] as String?,
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  static double _toDouble(Object? value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
