class ReportsPeriod {
  const ReportsPeriod({
    required this.start,
    required this.end,
    this.label,
  });

  final DateTime start;
  final DateTime end;
  final String? label;

  factory ReportsPeriod.month(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0);
    return ReportsPeriod(
      start: start,
      end: end,
      label: _monthLabel(start),
    );
  }

  static String _monthLabel(DateTime monthStart) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[monthStart.month - 1]} ${monthStart.year}';
  }

  ReportsPeriod copyWith({
    DateTime? start,
    DateTime? end,
    String? label,
  }) {
    return ReportsPeriod(
      start: start ?? this.start,
      end: end ?? this.end,
      label: label ?? this.label,
    );
  }
}

class DailyExpensePoint {
  const DailyExpensePoint({required this.day, required this.amount});

  final int day;
  final double amount;
}

class CategoryExpenseSlice {
  const CategoryExpenseSlice({
    required this.categoryId,
    required this.name,
    required this.amount,
    this.colorHex,
  });

  final String categoryId;
  final String name;
  final double amount;
  final String? colorHex;

  double percentageOf(double total) => total <= 0 ? 0 : (amount / total) * 100;
}

class MonthlyIncomeExpensePoint {
  const MonthlyIncomeExpensePoint({
    required this.monthStart,
    required this.income,
    required this.expense,
  });

  final DateTime monthStart;
  final double income;
  final double expense;

  double get net => income - expense;
}

class AccountPeriodSummary {
  const AccountPeriodSummary({
    required this.accountId,
    required this.accountName,
    required this.openingBalance,
    required this.income,
    required this.expense,
    required this.closingBalance,
  });

  final String accountId;
  final String accountName;
  final double openingBalance;
  final double income;
  final double expense;
  final double closingBalance;
}

class MonthExpenseComparison {
  const MonthExpenseComparison({
    required this.currentTotal,
    required this.previousTotal,
  });

  final double currentTotal;
  final double previousTotal;

  double? get percentChange {
    if (previousTotal <= 0) return null;
    return ((currentTotal - previousTotal) / previousTotal) * 100;
  }

  String get message {
    final change = percentChange;
    if (change == null) {
      if (currentTotal <= 0) return 'No expenses recorded this month yet.';
      return 'No expenses last month to compare.';
    }
    final abs = change.abs().toStringAsFixed(0);
    if (change > 0) return 'You spent $abs% more than last month.';
    if (change < 0) return 'You spent $abs% less than last month.';
    return 'You spent the same as last month.';
  }
}
