import 'package:expense_tracker/core/enums/transaction_type.dart';

enum TransactionDatePreset {
  thisMonth,
  lastMonth,
  custom,
}

class TransactionFilters {
  const TransactionFilters({
    this.datePreset = TransactionDatePreset.thisMonth,
    this.customStart,
    this.customEnd,
    this.type,
    this.accountId,
  });

  final TransactionDatePreset datePreset;
  final DateTime? customStart;
  final DateTime? customEnd;
  final TransactionType? type;
  final String? accountId;

  TransactionFilters copyWith({
    TransactionDatePreset? datePreset,
    DateTime? customStart,
    DateTime? customEnd,
    TransactionType? type,
    String? accountId,
    bool clearType = false,
    bool clearAccount = false,
  }) {
    return TransactionFilters(
      datePreset: datePreset ?? this.datePreset,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      type: clearType ? null : (type ?? this.type),
      accountId: clearAccount ? null : (accountId ?? this.accountId),
    );
  }

  (DateTime start, DateTime end) resolveRange() {
    final now = DateTime.now();
    switch (datePreset) {
      case TransactionDatePreset.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        return (start, end);
      case TransactionDatePreset.lastMonth:
        final start = DateTime(now.year, now.month - 1, 1);
        final end = DateTime(now.year, now.month, 0);
        return (start, end);
      case TransactionDatePreset.custom:
        final start = customStart ?? DateTime(now.year, now.month, 1);
        final end = customEnd ?? now;
        return (start, end);
    }
  }

  @override
  bool operator ==(Object other) {
    return other is TransactionFilters &&
        other.datePreset == datePreset &&
        _sameDay(other.customStart, customStart) &&
        _sameDay(other.customEnd, customEnd) &&
        other.type == type &&
        other.accountId == accountId;
  }

  @override
  int get hashCode => Object.hash(
        datePreset,
        customStart?.millisecondsSinceEpoch,
        customEnd?.millisecondsSinceEpoch,
        type,
        accountId,
      );

  static bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class FilteredTotals {
  const FilteredTotals({
    required this.income,
    required this.expense,
  });

  final double income;
  final double expense;

  double get net => income - expense;
}
