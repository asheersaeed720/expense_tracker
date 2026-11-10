class MonthlyStats {
  const MonthlyStats({
    required this.income,
    required this.expense,
  });

  final double income;
  final double expense;

  double get net => income - expense;
}
